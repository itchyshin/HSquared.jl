using HSquared, LinearAlgebra
for (label,fun) in [
 ("lowrank overflow",()->HSquared.lowrank_covariance(fill(1e308,2,1))),
 ("FA overflow",()->HSquared.factor_analytic_covariance(fill(1e308,2,1),ones(2))),
 ("invalid h zero",()->HSquared._fd_hessian(x->-sum(abs2,x)/2,[1.,1.];h=0.)),
 ("invalid h negative",()->HSquared._fd_hessian(x->-sum(abs2,x)/2,[1.,1.];h=-1e-4)),
 ("infinite likelihood",()->HSquared.nested_lrt(-Inf,0.;df=1)),
 ("finite overflow statistic",()->HSquared.nested_lrt(-1e308,1e308;df=1)),
 ("chi tail infinite",()->HSquared._chisq_sf(Inf,1)),
 ("label duplicate MME",()->HSquared.multivariate_mme([1. 2.;3. 4.;2. 5.],ones(3,1),[1. 0.;0. 1.;1. 0.],Matrix{Float64}(I,2,2),Matrix{Float64}(I,2,2),Matrix{Float64}(I,2,2);ids=["a","a"],traits=["t","t"]).breeding_values)
 ]
 try println(label,": ",fun()) catch err println(label,": ERROR ",typeof(err)," ",sprint(showerror,err)) end
end
