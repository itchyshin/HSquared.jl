using HSquared, SparseArrays, LinearAlgebra, DelimitedFiles, Printf
S = ENV["AUDIT_DIR"]
yid,_=readdlm(joinpath(S,"yid.csv"),',',header=true); Xr,_=readdlm(joinpath(S,"X.csv"),',',header=true)
pedr,_=readdlm(joinpath(S,"ped.csv"),',',String,header=true)
y=Float64.(yid[:,1]); aid=string.(yid[:,2]); X=Float64.(Xr)
miss(v)=[isempty(s)||s=="NA" ? "0" : s for s in v]
ped=normalize_pedigree(strip.(pedr[:,1]), miss(strip.(pedr[:,3])), miss(strip.(pedr[:,2])))
Ainv=pedigree_inverse(ped); q=size(Ainv,1)
pos=Dict(string(v)=>i for (i,v) in enumerate(ped.ids))
Z=sparse(1:length(y),[pos[a] for a in aid],ones(length(y)),length(y),q)
eff=[(Z,Ainv),(Z,spdiagm(0=>ones(q)))]
best(f,n=3)=minimum(@elapsed(f()) for _ in 1:n)
@printf("%-10s %-8s %5s %8s   %-40s\n","tol","initial","iters","time","sigma_a2 / sigma_pe2 / sigma_e2")
for tol in (1e-8, 1e-6, 1e-4, 1e-3), init in (nothing, :auto)
    f = fit_sparse_multi_effect_aireml(y,X,eff; initial=init, tol=tol)
    t = best(()->fit_sparse_multi_effect_aireml(y,X,eff; initial=init, tol=tol))
    @printf("%-10.0e %-8s %5d %7.3fs   %.7f / %.7f / %.7f\n", tol, string(init),
            f.iterations, t, f.variance_components.sigmas[1],
            f.variance_components.sigmas[2], f.variance_components.sigma_e2)
end
