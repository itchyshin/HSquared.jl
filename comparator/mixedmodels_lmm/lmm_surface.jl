# Shared Gaussian LMM surface for the MixedModels.jl comparator lane (HSquared.jl #275).
#
# MixedModels.jl is a Julia-native mixed-model engine, so a comparison on the surface both
# engines share separates "our engine" from "an R-to-Julia bridge" (every other comparator
# in this repo crosses that boundary). The shared surface is deliberately small:
#
#   y = X*beta + Z1*u1 [+ Z2*u2] + e,   u_k ~ N(0, s_k^2 I),   e ~ N(0, s_e^2 I)
#
# REML, Gaussian, independent iid random intercepts (one-way, or two crossed factors),
# one continuous covariate. MixedModels.jl has no pedigree or relationship-matrix API, so
# every animal-model term is OUTSIDE this surface (those stay with sommer, BLUPF90, ...).
#
# This file imports neither MixedModels nor any comparator package: it holds the scenario
# generator, the engine fit, the closed-form ANOVA oracle and the agreement arithmetic, so
# the test suite can exercise them without the opt-in environment. The MixedModels leg
# lives in `run_mixedmodels_lmm.jl` and is gated on HSQUARED_RUN_MIXEDMODELS=true.
module HSquaredMixedModelsSurface

using HSquared
using LinearAlgebra
using Random
using SparseArrays

export LMMScenario, LMMData, SCENARIOS, mixedmodels_lane_enabled, simulate_lmm,
       engine_lmm_fit, anova_oracle_one_way, compare_lmm

"""
    LMMScenario(name, n, ngroups, sigmas, sigma_e, beta, seed)

One predeclared design. `ngroups` has one entry per random-intercept factor (1 or 2);
`sigmas` holds the matching standard deviations. `beta` is `(intercept, slope)`; a `nothing`
slope drops the covariate (intercept-only).
"""
struct LMMScenario
    name::Symbol
    n::Int
    ngroups::Vector{Int}
    sigmas::Vector{Float64}
    sigma_e::Float64
    beta::Vector{Float64}
    seed::Int
    balanced::Bool
end

struct LMMData
    y::Vector{Float64}
    X::Matrix{Float64}
    groups::Vector{Vector{Int}}
end

# Predeclared before any run. `balanced = true` means every group has n / ngroups records.
const SCENARIOS = LMMScenario[
    LMMScenario(:oneway_balanced_small, 2_000, [100], [0.8], 1.0, [2.0], 20260275, true),
    LMMScenario(:oneway_cov_2k, 2_000, [100], [0.8], 1.0, [2.0, 0.5], 20260276, false),
    LMMScenario(:oneway_cov_20k, 20_000, [1_000], [0.8], 1.0, [2.0, 0.5], 20260277, false),
    LMMScenario(:oneway_cov_100k, 100_000, [5_000], [0.8], 1.0, [2.0, 0.5], 20260278, false),
    LMMScenario(:crossed_cov_20k, 20_000, [200, 100], [0.7, 0.5], 1.0, [2.0, 0.5], 20260279, false),
]

"""True only when the opt-in MixedModels leg was requested (`HSQUARED_RUN_MIXEDMODELS=true`)."""
mixedmodels_lane_enabled() = get(ENV, "HSQUARED_RUN_MIXEDMODELS", "") == "true"

"""Deterministic simulation of one scenario (same seed, same data, every run)."""
function simulate_lmm(sc::LMMScenario)
    rng = MersenneTwister(sc.seed)
    n = sc.n
    K = length(sc.ngroups)
    groups = Vector{Vector{Int}}(undef, K)
    for k in 1:K
        m = sc.ngroups[k]
        groups[k] = sc.balanced ? [mod1(i, m) for i in 1:n] : [rand(rng, 1:m) for _ in 1:n]
    end
    ncov = length(sc.beta) - 1
    X = ncov == 0 ? ones(n, 1) : hcat(ones(n), randn(rng, n, ncov))
    y = X * sc.beta .+ sc.sigma_e .* randn(rng, n)
    for k in 1:K
        u = sc.sigmas[k] .* randn(rng, sc.ngroups[k])
        y .+= u[groups[k]]
    end
    return LMMData(y, Matrix{Float64}(X), groups)
end

"""
    engine_lmm_fit(d::LMMData; tol = 1e-10, iterations = 200)

Fit the surface with HSquared's sparse AI-REML (`fit_sparse_multi_effect_aireml`): one
`(Z_k, I)` pair per random-intercept factor. Returns variance components, fixed effects,
convergence, iteration count and wall seconds (model set-up included).
"""
function engine_lmm_fit(d::LMMData; tol::Real = 1e-10, iterations::Integer = 200)
    n = length(d.y)
    effects = Tuple{SparseMatrixCSC{Float64,Int},SparseMatrixCSC{Float64,Int}}[]
    for g in d.groups
        q = maximum(g)
        push!(effects, (sparse(1:n, g, ones(n), n, q), sparse(1.0I, q, q)))
    end
    t0 = time_ns()
    fit = HSquared.fit_sparse_multi_effect_aireml(d.y, d.X, effects;
                                                  tol = tol, iterations = iterations)
    seconds = (time_ns() - t0) / 1e9
    return (sigmas = collect(Float64, fit.variance_components.sigmas),
            sigma_e2 = Float64(fit.variance_components.sigma_e2),
            beta = collect(Float64, fit.beta),
            converged = fit.converged,
            iterations = fit.iterations,
            seconds = seconds)
end

"""
    anova_oracle_one_way(y, g)

Closed-form REML estimates for a balanced one-way random-intercept model with an
intercept-only mean: `sigma_e2 = MSW`, `sigma_g2 = (MSB - MSW) / m`, valid when
`MSB > MSW` (otherwise the REML optimum is the boundary `sigma_g2 = 0`). It uses neither
engine, so it is an independent check that the engine and MixedModels target the same
estimand on this surface.
"""
function anova_oracle_one_way(y::AbstractVector, g::AbstractVector{<:Integer})
    ng = maximum(g)
    n = length(y)
    m = n / ng
    all(count(==(j), g) == m for j in 1:ng) ||
        throw(ArgumentError("anova_oracle_one_way requires a balanced design"))
    ybar = sum(y) / n
    gm = [sum(y[g .== j]) / m for j in 1:ng]
    ssb = m * sum((gm .- ybar) .^ 2)
    ssw = sum((y[i] - gm[g[i]])^2 for i in 1:n)
    msb = ssb / (ng - 1)
    msw = ssw / (n - ng)
    msb > msw || throw(ArgumentError("MSB <= MSW: REML optimum is on the boundary"))
    return (sigma_g2 = (msb - msw) / m, sigma_e2 = msw, beta0 = ybar)
end

"""
    compare_lmm(engine, other; rtol_var = 1e-3, rtol_beta = 1e-6)

Agreement table between two fits carrying `sigmas`, `sigma_e2`, `beta`, `converged`. A row
passes when the relative difference (against the larger magnitude, floored at 1e-8) is at
most the tolerance. Either fit not converged fails the whole comparison: agreement of two
non-converged iterates says nothing about the estimand. Reports agreement, never "parity".
"""
function compare_lmm(engine, other; rtol_var::Real = 1e-3, rtol_beta::Real = 1e-6)
    length(engine.sigmas) == length(other.sigmas) ||
        throw(ArgumentError("fits carry a different number of random-effect variances"))
    length(engine.beta) == length(other.beta) ||
        throw(ArgumentError("fits carry a different number of fixed effects"))
    rel(a, b) = abs(a - b) / max(abs(a), abs(b), 1e-8)
    rows = NamedTuple{(:quantity, :engine, :other, :absdiff, :reldiff, :tol, :pass),
                      Tuple{String,Float64,Float64,Float64,Float64,Float64,Bool}}[]
    function add(q, a, b, tol)
        r = rel(a, b)
        push!(rows, (quantity = q, engine = a, other = b, absdiff = abs(a - b),
                     reldiff = r, tol = Float64(tol), pass = r <= tol))
    end
    for k in eachindex(engine.sigmas)
        add("sigma_g$(k)_2", engine.sigmas[k], other.sigmas[k], rtol_var)
    end
    add("sigma_e2", engine.sigma_e2, other.sigma_e2, rtol_var)
    for j in eachindex(engine.beta)
        add("beta$(j - 1)", engine.beta[j], other.beta[j], rtol_beta)
    end
    both = engine.converged && other.converged
    return (rows = rows, both_converged = both, agree = both && all(r.pass for r in rows))
end

end # module
