using HSquared, LinearAlgebra, Serialization, SHA, TOML
BLAS.set_num_threads(1)
root = "/private/tmp/fa-unit-order-results-20260930"
d = deserialize(joinpath(root,"fixture.jls"))
manifest = TOML.parsefile(joinpath(root,"manifest.toml"))
names = ["baseline","units_D1","units_inverse_D1","order_3142","order_4321"]
eye = Matrix{Float64}(I,4,4)
maps = [eye,Matrix(Diagonal([2.,.5,1.5,.8])),Matrix(Diagonal(1 ./ [2.,.5,1.5,.8])),eye[:,[3,1,4,2]],eye[:,[4,3,2,1]]]
perms = [[1,2,3,4],[1,2,3,4],[1,2,3,4],[3,1,4,2],[4,3,2,1]]
function dense(Y,G,R)
    n,t=size(Y);p=size(d.X,2);q=size(d.Z,2)
    A = inv(Symmetric(Matrix(d.Ainv)))
    B=Matrix(d.Z)*A*transpose(Matrix(d.Z))
    V=kron(G,B)+kron(R,Matrix{Float64}(I,n,n))
    X=kron(Matrix{Float64}(I,t,t),d.X);y=vec(Y)
    ch=cholesky(Symmetric(V));VX=ch\X;vy=ch\y
    fixed=cholesky(Symmetric(transpose(X)*VX));beta=fixed\(transpose(X)*vy)
    residual=y-X*beta;weighted=ch\residual
    ll=-.5*((n*t-p*t)*log(2pi)+logdet(ch)+logdet(fixed)+dot(residual,weighted))
    ebv=kron(G,A*transpose(Matrix(d.Z)))*weighted
    (;ll,beta=reshape(beta,p,t),ebv=reshape(ebv,q,t))
end
function arrayhash(a)
    io=IOBuffer();write(io,string(size(a)),UInt8(0));write(io,reinterpret(UInt8,vec(Matrix{Float64}(a))))
    bytes2hex(sha256(take!(io)))
end
for k in (:Y,:X,:Z,:Ainv,:G,:R,:loadings)
    @assert arrayhash(getproperty(d,k))==manifest["data_array_sha256"][string(k)]
end
@assert arrayhash(reshape(d.uniqueness,:,1))==manifest["data_array_sha256"]["uniqueness"]
@assert bytes2hex(sha256(join(d.ids,",")))==manifest["data_array_sha256"]["ids"]
@assert bytes2hex(sha256(join(d.traits,"\0")))==manifest["data_array_sha256"]["traits"]
@assert manifest["fixed_trait_metric"] ≈ sqrt.(diag(d.G+d.R))
@assert length(names)==manifest["expected_fit_denominator"]==5
@assert manifest["initial_keyword_supplied"]==false
results=deserialize(joinpath(root,"all_results.jls"));@assert Set(keys(results))==Set(names)
base=results["baseline"];S=Diagonal(1 ./ sqrt.(diag(d.G+d.R)))
maxll=0.;maxbeta=0.;maxebv=0.;maxg=0.;maxr=0.;maxoracle=0.
for (i,name) in enumerate(names)
    saved=deserialize(joinpath(root,name*".jls"));M=maps[i];Mi=inv(M);f=saved.result.fit
    @assert saved.case.M==M && saved.case.permutation==perms[i]
    @assert saved.input_Y==d.Y*M
    @assert isempty(saved.result.failures) && f.converged && isfinite(f.loglik)
    @assert f.traits==d.traits[perms[i]] && f.breeding_values.ids==d.ids
    @assert all(a->all(isfinite,a),(f.genetic_covariance,f.residual_covariance,f.genetic_loadings,f.genetic_uniqueness,f.beta,f.breeding_values.values))
    dg=f.fa_start_diagnostics
    @assert dg.strategy==:default_and_balanced && dg.starts_attempted==2
    @assert [s.name for s in dg.starts]==[:default,:balanced]
    @assert all(s->s.valid && s.converged && s.iterations<=10000,dg.starts)
    chosen=dg.starts[argmax([s.loglik for s in dg.starts])]
    @assert chosen.name==dg.selected_start && chosen.iterations==f.iterations && chosen.loglik≈f.loglik
    mapped=(G=transpose(Mi)*f.genetic_covariance*Mi,R=transpose(Mi)*f.residual_covariance*Mi,
            psi=diag(transpose(Mi)*Diagonal(f.genetic_uniqueness)*Mi),
            loadings=transpose(Mi)*f.genetic_loadings,beta=f.beta*Mi,ebv=f.breeding_values.values*Mi)
    for k in keys(mapped);@assert isapprox(getproperty(mapped,k),getproperty(saved.result.mapped,k);rtol=1e-12,atol=1e-12);end
    independent=dense(saved.input_Y,f.genetic_covariance,f.residual_covariance)
    global maxll=max(maxll,abs(independent.ll-f.loglik))
    global maxbeta=max(maxbeta,norm(independent.beta-f.beta))
    global maxebv=max(maxebv,norm(independent.ebv-f.breeding_values.values))
    @assert abs(independent.ll-f.loglik)<1e-8
    @assert isapprox(independent.beta,f.beta;rtol=1e-9,atol=1e-9)
    @assert isapprox(independent.ebv,f.breeding_values.values;rtol=1e-9,atol=1e-9)
    g=norm(S*(mapped.G-base.mapped.G)*S)/norm(S*base.mapped.G*S)
    r=norm(S*(mapped.R-base.mapped.R)*S)/norm(S*base.mapped.R*S)
    cmp=deserialize(joinpath(root,name*"_comparison.jls"))
    @assert isapprox(g,cmp.g_error;rtol=1e-10,atol=1e-14)
    @assert isapprox(r,cmp.r_error;rtol=1e-10,atol=1e-14)
    @assert cmp.category=="interior_agreement" && cmp.interior && cmp.agreement && !cmp.sensitivity
    @assert isapprox(abs(f.loglik+(size(d.Y,1)-rank(d.X))*logabsdet(M)[1]-base.fit.loglik),cmp.ll_error;atol=1e-12)
    @assert isapprox(mapped.beta,base.mapped.beta;rtol=2e-3,atol=1e-5)
    @assert isapprox(mapped.ebv,base.mapped.ebv;rtol=2e-3,atol=1e-5)
    global maxg=max(maxg,g);global maxr=max(maxr,r)
end
pairs=[("truth",d.G,d.R)]
append!(pairs,[(name,results[name].mapped.G,results[name].mapped.R) for name in names])
for (pair,G,R) in pairs
    original=dense(d.Y,G,R)
    for M in maps
        transformed=dense(d.Y*M,transpose(M)*G*M,transpose(M)*R*M)
        err=abs(transformed.ll-original.ll+(size(d.Y,1)-size(d.X,2))*logabsdet(M)[1])
        @assert err<1e-8
        @assert isapprox(transformed.beta*inv(M),original.beta;rtol=1e-9,atol=1e-9)
        @assert isapprox(transformed.ebv*inv(M),original.ebv;rtol=1e-9,atol=1e-9)
        global maxoracle=max(maxoracle,err)
    end
end
println("PASS five raw fits and 30 independent fixed-covariance map identities; no refits or RNG")
println("max_raw_loglik_error=$maxll max_raw_beta_norm_error=$maxbeta max_raw_ebv_norm_error=$maxebv")
println("max_fixed_metric_G=$maxg max_fixed_metric_R=$maxr max_oracle_ll_shift_error=$maxoracle")
