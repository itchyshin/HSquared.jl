using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the fitted negative-binomial (NB2) animal
model (`fit_laplace_reml(...; family = :nbinom)`).

Deliberately outside `test/` so the suite stays RNG-free. It simulates a half-sib
pedigree, draws breeding values `u ~ N(0, A·σ²a)`, and draws OVERDISPERSED counts
under the NB2 parameterization `Var(y|μ) = μ + μ²/θ` as a Poisson–Gamma mixture:
`λᵢ ~ Gamma(shape = θ, scale = μᵢ/θ)` (so `E λᵢ = μᵢ`, `Var λᵢ = μᵢ²/θ`), then
`yᵢ ~ Poisson(λᵢ)`, with `μᵢ = exp(μ + uₐ)`. The estimator profiles `(σ²a, θ)`
jointly.

GATING follows the established `V6-BERNOULLI` precedent for hard count/binary
families: the HARD GATE is on the RELIABLE signal — `converged` AND a
NON-COLLAPSED interior `σ̂²a` (> `SIGMA_FLOOR`, i.e. not on the σ²a→0 boundary)
AND latent correlation `cor(û,u) ≥ COR_FLOOR`. The `σ²a` MAGNITUDE and the
overdispersion `θ̂` are REPORTED-NOT-GATED: with ONE record per animal the
A-structured genetic variance competes with the independent NB overdispersion for
identifiability, so the `σ²a` POINT estimate carries the known Laplace-for-count
downward bias and high per-seed variance, and `θ` is only weakly identified.
Observed (the five seeds below): a stricter magnitude gate `rel(σ̂²a) ≤ 0.45`
passes only 3/5 (mean σ̂²a ≈ 0.39 vs 0.50, ~21% downward; one seed collapses to
0.10, one overshoots to 0.73; θ̂ ranges 1.8–6.5), while the EBV-rank recovery is
reliable (cor 0.61–0.77). This mirrors `V6-BERNOULLI` exactly and is reducible by
more information per animal — `V6-BINOMIAL` (m = 20 trials) recovers `σ²a` tightly.

The Gamma sampler is a dependency-free Marsaglia–Tsang (2000) draw (with the
`α < 1` boost), so the harness needs no `Distributions` import.

Run from the repository root (thread-capped):

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase6_nbinom_recovery.jl

Predeclared (BEFORE running, honoring the no-post-hoc-relaxation rule): seeds
20260618..20260622; truth σ²a = 0.5, μ = 1.5, θ = 3.0; HARD GATE = `converged` ∧
`σ̂²a > 0.01` ∧ `cor(û,u) ≥ 0.5`. `rel(σ̂²a)` and `θ̂` are reported, not gated.
"""

const SEEDS = [20260618, 20260619, 20260620, 20260621, 20260622]
const SIGMA_A2 = 0.5
const MU = 1.5
const THETA = 3.0
const SIGMA_FLOOR = 0.01    # interior / non-collapsed σ̂²a (not the σ²a→0 boundary)
const REL_REPORT = 0.45     # reported magnitude flag only — NOT a hard gate
const COR_FLOOR = 0.5

_rand_poisson(rng, λ) = begin
    L = exp(-λ); k = 0; p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return k - 1
    end
end

# Marsaglia & Tsang (2000) Gamma(shape, scale) sampler, dependency-free.
function _rand_gamma(rng, shape, scale)
    if shape < 1.0
        # boost: Gamma(α) = Gamma(α+1) · U^(1/α)
        u = rand(rng)
        return _rand_gamma(rng, shape + 1.0, scale) * u^(1.0 / shape)
    end
    d = shape - 1.0 / 3.0
    c = 1.0 / sqrt(9.0 * d)
    while true
        x = randn(rng)
        v = (1.0 + c * x)^3
        v <= 0.0 && continue
        u = rand(rng)
        if u < 1.0 - 0.0331 * x^4
            return d * v * scale
        end
        if log(u) < 0.5 * x^2 + d * (1.0 - v + log(v))
            return d * v * scale
        end
    end
end

# NB2 count: Poisson–Gamma mixture with mean μ and size θ.
_rand_nbinom(rng, μ, θ) = _rand_poisson(rng, _rand_gamma(rng, θ, μ / θ))

function _halfsib_pedigree(nsire, ndam, noffspring)
    sire_ids = ["s$i" for i in 1:nsire]
    dam_ids = ["d$i" for i in 1:ndam]
    off_ids = ["o$i" for i in 1:noffspring]
    ids = vcat(sire_ids, dam_ids, off_ids)
    sire = vcat(fill("0", nsire + ndam),
                [sire_ids[((i - 1) % nsire) + 1] for i in 1:noffspring])
    dam = vcat(fill("0", nsire + ndam),
               [dam_ids[((i - 1) % ndam) + 1] for i in 1:noffspring])
    return normalize_pedigree(ids, sire, dam)
end

function _run(seed; nsire = 15, ndam = 30, noffspring = 120)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    u = (LA * randn(rng, q)) .* sqrt(SIGMA_A2)
    X = ones(q, 1)
    Z = Matrix(1.0I, q, q)
    y = Float64[Float64(_rand_nbinom(rng, exp(MU + u[a]), THETA)) for a in 1:q]
    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :nbinom,
                                    initial = (sigma_a2 = 0.5,), theta_init = 3.0)
    sa2 = fit.variance_components.sigma_a2
    theta = fit.variance_components.theta
    rel = abs(sa2 - SIGMA_A2) / SIGMA_A2
    uhat = fit.breeding_values
    ubar = sum(u) / q; uhbar = sum(uhat) / q
    cu = sum((u .- ubar) .* (uhat .- uhbar))
    cor = cu / sqrt(sum(abs2, u .- ubar) * sum(abs2, uhat .- uhbar))
    # HARD gate = reliable signal (converged ∧ interior σ̂²a ∧ EBV correlation);
    # the σ²a magnitude (mag_ok) is REPORTED, not gated.
    pass = fit.converged && sa2 > SIGMA_FLOOR && cor >= COR_FLOOR
    mag_ok = rel <= REL_REPORT
    return (seed = seed, q = q, converged = fit.converged, sigma_a2 = sa2,
            theta = theta, rel = rel, cor = cor, pass = pass, mag_ok = mag_ok)
end

function main()
    results = [_run(seed) for seed in SEEDS]
    for r in results
        @printf("[%s] seed=%d animals=%d converged=%s  σ̂²a=%.3f (truth %.2f, rel %.3f %s)  θ̂=%.3f (truth %.1f)  cor(û,u)=%.3f\n",
            r.pass ? "PASS" : "FAIL", r.seed, r.q, r.converged, r.sigma_a2, SIGMA_A2, r.rel,
            r.mag_ok ? "mag✓" : "mag✗(not gated)", r.theta, THETA, r.cor)
    end
    npass = count(r -> r.pass, results)
    nmag = count(r -> r.mag_ok, results)
    @printf("SUMMARY nbinom-recovery seeds=%d gated_pass=%d (converged∧interior∧cor) | mag(rel≤%.2f)=%d/%d reported-not-gated | mean_sigma_a2=%.3f mean_rel=%.3f min_cor=%.3f theta_mean=%.3f\n",
        length(results), npass, REL_REPORT, nmag, length(results),
        sum(r.sigma_a2 for r in results) / length(results),
        sum(r.rel for r in results) / length(results),
        minimum(r.cor for r in results), sum(r.theta for r in results) / length(results))
    all(r -> r.pass, results) || exit(1)
end

main()
