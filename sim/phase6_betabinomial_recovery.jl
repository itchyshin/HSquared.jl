using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the fitted beta-binomial (overdispersed
logit) animal model (`fit_laplace_reml(...; family = :beta_binomial, n_trials = m,
rho = ρ)`).

Deliberately outside `test/` so the suite stays RNG-free. It simulates a half-sib
pedigree, draws breeding values `u ~ N(0, A·σ²a)` on the logit scale, and draws
OVERDISPERSED success counts as a Beta–Binomial mixture: the per-record success
probability is `pᵢ ~ Beta(αᵢ, βᵢ)` with `αᵢ = mᵢ·s`, `βᵢ = (1−mᵢ)·s`,
`mᵢ = logistic(μ + uₐ)`, `s = (1−ρ)/ρ` (so `E pᵢ = mᵢ` and the intra-class
correlation is ρ), then `yᵢ ~ Binomial(m, pᵢ)`. The estimator profiles `σ²a`
(Brent) at the SAME SUPPLIED FIXED ρ used to simulate (joint `(σ²a, ρ)` estimation
is explicit follow-up); the Beta draw injects extra (non-genetic) variance, so
this is HARDER than the plain Binomial recovery (`sim/phase6_binomial_recovery.jl`).

GATING follows the established `V6-BERNOULLI` / `V6-NBINOM` precedent for hard
overdispersed families: the HARD GATE is on the RELIABLE signal — `converged` AND
a NON-COLLAPSED interior `σ̂²a` (> `SIGMA_FLOOR`, not the σ²a→0 boundary) AND latent
correlation `cor(û,u) ≥ COR_FLOOR`. The `σ²a` MAGNITUDE is REPORTED-NOT-GATED
(`rel(σ̂²a) ≤ REL_REPORT` is a reported flag only): the overdispersion competes
with the A-structured genetic variance, so the `σ²a` POINT estimate carries the
known Laplace-for-overdispersed-data downward bias and per-seed variance. The
gate/floors are PREDECLARED below BEFORE running, honoring the
no-post-hoc-relaxation rule.

The Beta sampler is `Beta(α,β) = G1/(G1+G2)` with `Gᵢ ~ Gamma(·,1)` drawn by a
dependency-free Marsaglia–Tsang (2000) routine (no `Distributions` import).

Run from the repository root (thread-capped):

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase6_betabinomial_recovery.jl

Predeclared (BEFORE running): seeds 20260618..20260622; truth σ²a = 1.0 (logit
scale), μ = 0.0; m = 20 trials/record; overdispersion ρ = 0.2; half-sib design
15 sires, 30 dams, 300 offspring (q = 345). HARD GATE = `converged` ∧ `σ̂²a > 0.01`
∧ `cor(û,u) ≥ 0.5`. `rel(σ̂²a) ≤ 0.45` is reported, not gated.
"""

const SEEDS = [20260618, 20260619, 20260620, 20260621, 20260622]
const SIGMA_A2 = 1.0
const MU = 0.0
const NTRIALS = 20
const RHO = 0.2
const SIGMA_FLOOR = 0.01    # interior / non-collapsed σ̂²a (not the σ²a→0 boundary)
const REL_REPORT = 0.45     # reported magnitude flag only — NOT a hard gate
const COR_FLOOR = 0.5

_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))
_rand_binomial(rng, m, p) = sum(rand(rng) < p ? 1 : 0 for _ in 1:m)

# Marsaglia & Tsang (2000) Gamma(shape, scale=1) sampler, dependency-free.
function _rand_gamma(rng, shape)
    if shape < 1.0
        u = rand(rng)
        return _rand_gamma(rng, shape + 1.0) * u^(1.0 / shape)
    end
    d = shape - 1.0 / 3.0
    c = 1.0 / sqrt(9.0 * d)
    while true
        x = randn(rng)
        v = (1.0 + c * x)^3
        v <= 0.0 && continue
        u = rand(rng)
        if u < 1.0 - 0.0331 * x^4
            return d * v
        end
        if log(u) < 0.5 * x^2 + d * (1.0 - v + log(v))
            return d * v
        end
    end
end

# Beta(α,β) via two Gamma draws.
function _rand_beta(rng, α, β)
    g1 = _rand_gamma(rng, α)
    g2 = _rand_gamma(rng, β)
    return g1 / (g1 + g2)
end

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

function _run(seed; nsire = 15, ndam = 30, noffspring = 300)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    u = (LA * randn(rng, q)) .* sqrt(SIGMA_A2)
    X = ones(q, 1)
    Z = Matrix(1.0I, q, q)
    s = (1.0 - RHO) / RHO
    y = Vector{Float64}(undef, q)
    for a in 1:q
        mp = _logistic(MU + u[a])
        p = _rand_beta(rng, mp * s, (1.0 - mp) * s)   # overdispersed success prob ~ Beta
        y[a] = Float64(_rand_binomial(rng, NTRIALS, p))
    end
    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :beta_binomial,
                                    n_trials = NTRIALS, rho = RHO,
                                    initial = (sigma_a2 = 1.0,))
    sa2 = fit.variance_components.sigma_a2
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
            rel = rel, cor = cor, pass = pass, mag_ok = mag_ok)
end

function main()
    results = [_run(seed) for seed in SEEDS]
    for r in results
        @printf("[%s] seed=%d animals=%d m=%d ρ=%.2f converged=%s  σ̂²a=%.3f (truth %.2f, rel %.3f %s)  cor(û,u)=%.3f\n",
            r.pass ? "PASS" : "FAIL", r.seed, r.q, NTRIALS, RHO, r.converged, r.sigma_a2,
            SIGMA_A2, r.rel, r.mag_ok ? "mag✓" : "mag✗(not gated)", r.cor)
    end
    npass = count(r -> r.pass, results)
    nmag = count(r -> r.mag_ok, results)
    @printf("SUMMARY betabinomial-recovery (m=%d, ρ=%.2f) seeds=%d gated_pass=%d (converged∧interior∧cor) | mag(rel≤%.2f)=%d/%d reported-not-gated | mean_sigma_a2=%.3f mean_rel=%.3f min_cor=%.3f\n",
        NTRIALS, RHO, length(results), npass, REL_REPORT, nmag, length(results),
        sum(r.sigma_a2 for r in results) / length(results),
        sum(r.rel for r in results) / length(results),
        minimum(r.cor for r in results))
    all(r -> r.pass, results) || exit(1)
end

main()
