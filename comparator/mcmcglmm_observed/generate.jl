using HSquared
using LinearAlgebra
using Random

# Deterministic A = I / repeated-records Poisson (log-link) dataset + the engine
# `nongaussian_heritability` OBSERVATION-scale h² POINT, serialized for the MCMCglmm
# observation-scale h² comparator (`run_mcmcglmm.R`).
#
# WHY THIS DESIGN. With A = I the additive breeding value is a plain iid random
# intercept — identical to an `id` random effect in MCMCglmm — so no pedigree is
# needed and both engines fit the same random-intercept GLMM. Multiple records per
# individual (i) identify σ²a for count data and (ii) let MCMCglmm estimate the
# latent units (over-dispersion) residual SEPARATELY from σ²a. The DGP has NO
# record-level over-dispersion, so that residual concentrates near 0 and MCMCglmm's
# `var.p = rowSums(VCV) ≈ V_A` — matching the engine's integration convention
# (var.p = predictor variance V_A + V_fixed; doc-19 §2.2), which removes the
# over-dispersion-convention gap that afflicts the fitting comparators.
#
# DISTRIBUTIONAL (Bayesian-posterior vs asymptotic-point) agreement, NOT machine
# precision and NOT a validation of unbiasedness (both share the Poisson GLMM
# information limit). See README.md.
#
# Run from the repository root:
#   PATH="$HOME/.juliaup/bin:$PATH" julia --project=. comparator/mcmcglmm_observed/generate.jl

const SEED = 20260701
const N_IND = 300
const N_REP = 6
const SIGMA_A2 = 0.5
const MU = 0.8
const OUTDIR = @__DIR__

# inverse-transform Poisson sampler (deterministic given rng; avoids a Distributions dep)
_rand_pois(rng, lam) = begin
    lam <= 0 && return 0
    L = exp(-lam)
    k = 0
    p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return k - 1
    end
end

function main()
    rng = MersenneTwister(SEED)
    a = randn(rng, N_IND) .* sqrt(SIGMA_A2)               # iid breeding values (A = I)
    n = N_IND * N_REP
    ind = repeat(1:N_IND; inner = N_REP)                  # record -> individual
    y = Float64[_rand_pois(rng, exp(MU + a[ind[r]])) for r in 1:n]
    X = ones(n, 1)
    Z = zeros(n, N_IND)                                   # record x individual incidence
    for r in 1:n
        Z[r, ind[r]] = 1.0
    end
    Ainv = Matrix(1.0I, N_IND, N_IND)                     # A = I  ⇒  Ainv = I

    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :poisson,
                                    initial = (sigma_a2 = 0.5,))
    fit.converged || error("engine fit did not converge")
    h2 = HSquared.nongaussian_heritability(fit)           # μ defaults to the single intercept
    payload = HSquared.nongaussian_result_payload(fit)
    sa2 = payload.variance_components.sigma_a2
    beta = collect(Float64, payload.fixed_effects)

    open(joinpath(OUTDIR, "data.csv"), "w") do io
        println(io, "id,count")
        for r in 1:n
            println(io, "i", ind[r], ",", Int(round(y[r])))
        end
    end
    open(joinpath(OUTDIR, "engine_h2.csv"), "w") do io
        println(io, "field,value")
        println(io, "h2_observation,", h2.h2_observation)
        println(io, "sigma_a2,", sa2)
        println(io, "mu,", beta[1])
        println(io, "n_ind,", N_IND)
        println(io, "n_rep,", N_REP)
        println(io, "n_records,", n)
        println(io, "mean_count,", sum(y) / n)
        println(io, "sigma_a2_truth,", SIGMA_A2)
        println(io, "mu_truth,", MU)
        println(io, "seed,", SEED)
    end

    println("engine target written to ", OUTDIR)
    println("  h2_observation = ", round(h2.h2_observation, digits = 6))
    println("  sigma_a2 = ", round(sa2, digits = 4), " (truth ", SIGMA_A2, ")")
    println("  intercept = ", round(beta[1], digits = 4), " (truth ", MU, ")")
    println("  n_ind = ", N_IND, ", n_rep = ", N_REP,
            ", mean count = ", round(sum(y) / n, digits = 3),
            ", converged = ", fit.converged)
end

main()
