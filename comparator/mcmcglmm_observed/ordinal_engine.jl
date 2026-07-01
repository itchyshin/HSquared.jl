# MCMCglmm ORDINAL same-estimand comparator — ENGINE side (K=3 threshold/liability).
# REQUIRES the v0.6 h² integration (the :ordered_probit FIT is #215 and the ordinal
# per-category observed h² is #223 — they only coexist once the PRs are merged; this
# was run from a worktree on the integration commit, NOT plain `main`).
# Simulate K=3 ordinal-probit data (identified iid random effect), fit, write the
# engine points + data for ordinal_fit.R.
#
# Run (from an integration build): julia --project=. comparator/mcmcglmm_observed/ordinal_engine.jl
using HSquared, Random, LinearAlgebra, SparseArrays
Random.seed!(20260701)

G, n = 400, 8                       # N = 3200
σ2a_true, μ_true = 0.8, 0.3
θ_true = [0.0, 1.0]                 # K=3; θ1 fixed at 0 by the engine's identification
Φ = HSquared._norm_cdf
catprob(η) = (θ = vcat(-Inf, θ_true, Inf); [Φ(θ[k+1]-η) - Φ(θ[k]-η) for k in 1:3])

u = sqrt(σ2a_true) .* randn(G); groups = Int[]; y = Int[]
for g in 1:G, _ in 1:n
    p = catprob(μ_true + u[g]); r = rand()
    push!(groups, g); push!(y, r < p[1] ? 1 : (r < p[1]+p[2] ? 2 : 3))
end
N = length(y)
X = ones(N,1); Z = sparse(1:N, groups, 1.0, N, G); Ainv = sparse(1.0I, G, G)

fit = fit_laplace_reml(Float64.(y), X, Matrix(Z), Matrix(Ainv); family = :ordered_probit)
σ2a = fit.variance_components.sigma_a2; cuts = fit.variance_components.cutpoints
h = nongaussian_heritability(fit)
println("ENGINE :ordered_probit N=$N G=$G converged=", fit.converged,
        " sigma_a2=", round(σ2a,digits=5), " cutpoints=", round.(cuts,digits=4))
println("  h2_liability=", round(h.h2_latent,digits=6),
        "  h2_obs_by_category=", round.(h.h2_observation_by_category,digits=6))

sp = @__DIR__
open(joinpath(sp,"ordinal_data.csv"),"w") do io
    println(io,"id,group,y"); for i in 1:N; println(io,"$i,$(groups[i]),$(y[i])"); end
end
open(joinpath(sp,"ordinal_engine.csv"),"w") do io
    println(io,"quantity,engine_point")
    println(io,"sigma_a2,$(σ2a)"); println(io,"mu,$(fit.beta[1])"); println(io,"theta2,$(cuts[2])")
    println(io,"h2_liability,$(h.h2_latent)")
    for k in 1:3; println(io,"h2obs_cat$k,$(h.h2_observation_by_category[k])"); end
end
println("  wrote ordinal_data.csv ($N rows) + ordinal_engine.csv")
