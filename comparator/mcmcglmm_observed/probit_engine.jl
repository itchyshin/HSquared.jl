# MCMCglmm same-estimand h² comparator — ENGINE side (probit LIABILITY design).
# Runs on `main` (the :bernoulli_probit FAMILY fit is #171; the liability h² =
# σ²a/(σ²a+1) and the QGglmm-binom1.probit observed h² are the exact formulas the
# PR-branch nongaussian_heritability computes). Simulate a liability-threshold
# binary dataset with an identified iid random effect, fit, write data + points
# for the MCMCglmm side (probit_fit.R).
#
# Run from repo root:
#   julia --project=. comparator/mcmcglmm_observed/probit_engine.jl
using HSquared, Random, LinearAlgebra, SparseArrays
Random.seed!(20260701)

G, n, σ2a_true, μ_true = 400, 8, 0.8, 0.0     # G levels × n binary records → N=3200
u = sqrt(σ2a_true) .* randn(G)
groups = Int[]; y = Int[]
for g in 1:G, _ in 1:n
    liab = μ_true + u[g] + randn()             # liability = η + e, e~N(0,1)
    push!(groups, g); push!(y, liab > 0 ? 1 : 0)
end
N = length(y)
X = ones(N, 1); Z = sparse(1:N, groups, 1.0, N, G); Ainv = sparse(1.0I, G, G)

fit = fit_laplace_reml(Float64.(y), X, Matrix(Z), Matrix(Ainv); family = :bernoulli_probit)
σ2a = fit.variance_components.sigma_a2
h2_liab = σ2a / (σ2a + 1.0)                     # V_link = 1 (Dempster–Lerner)

println("ENGINE :bernoulli_probit  N=$N G=$G n=$n  converged=", fit.converged)
println("  sigma_a2=", round(σ2a, digits=5), "  mu=", round(fit.beta[1], digits=5),
        "  h2_liability=", round(h2_liab, digits=6))

sp = @__DIR__
open(joinpath(sp, "packet_data.csv"), "w") do io
    println(io, "id,group,y"); for i in 1:N; println(io, "$i,$(groups[i]),$(y[i])"); end
end
open(joinpath(sp, "engine_points.csv"), "w") do io
    println(io, "quantity,engine_point")
    println(io, "sigma_a2,$(σ2a)"); println(io, "mu,$(fit.beta[1])"); println(io, "h2_liability,$(h2_liab)")
end
println("  wrote packet_data.csv ($N rows) + engine_points.csv")
