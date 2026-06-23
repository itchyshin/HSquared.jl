using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the fitted Bernoulli-probit (threshold /
liability-scale) animal model (`fit_laplace_reml(...; family = :bernoulli_probit)`).

Deliberately outside `test/` so the suite stays RNG-free. It simulates the classic
liability-threshold DGP: breeding values `u ~ N(0, A·σ²a)` on the LATENT (liability)
scale, an independent residual `e ~ N(0,1)` (the probit identifiability convention
fixes the liability residual variance at 1), and a binary observation
`yᵢ = 1[μ + uₐ + eᵢ > 0]`. The estimator profiles the single `σ²a` (Brent) over the
probit Laplace marginal.

GATING follows the established `V6-BERNOULLI` precedent for binary (information-poor)
families: the HARD GATE is on the RELIABLE signal — `converged` AND a NON-COLLAPSED
interior `σ̂²a` (> `SIGMA_FLOOR`) AND latent correlation `cor(û,u) ≥ COR_FLOOR`. The
`σ²a` MAGNITUDE (`rel(σ̂²a) ≤ REL_REPORT`) is REPORTED-NOT-GATED: binary single-
threshold data carries little variance information, so the `σ²a` point estimate
carries the documented Laplace-for-binary DOWNWARD bias (an ordinal ≥3-category
design would be more informative). The gate/floors are PREDECLARED below BEFORE
running, honoring the no-post-hoc-relaxation rule.

Run from the repository root (thread-capped):

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase6_threshold_recovery.jl

Predeclared (BEFORE running): seeds 20260618..20260622; truth σ²a = 1.0 (liability
scale), μ = 0.0; half-sib design 15 sires, 30 dams, 300 offspring (q = 345). HARD
GATE = `converged` ∧ `σ̂²a > 0.01` ∧ `cor(û,u) ≥ 0.5`. `rel(σ̂²a) ≤ 0.45` is reported.
"""

const SEEDS = [20260618, 20260619, 20260620, 20260621, 20260622]
const SIGMA_A2 = 1.0
const MU = 0.0
const SIGMA_FLOOR = 0.01    # interior / non-collapsed σ̂²a
const REL_REPORT = 0.45     # reported magnitude flag only — NOT a hard gate
const COR_FLOOR = 0.5

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
    # liability-threshold: y = 1[μ + u + e > 0], e ~ N(0,1)
    y = Float64[(MU + u[a] + randn(rng)) > 0 ? 1.0 : 0.0 for a in 1:q]
    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :bernoulli_probit,
                                    initial = (sigma_a2 = 1.0,))
    sa2 = fit.variance_components.sigma_a2
    rel = abs(sa2 - SIGMA_A2) / SIGMA_A2
    uhat = fit.breeding_values
    ubar = sum(u) / q; uhbar = sum(uhat) / q
    cu = sum((u .- ubar) .* (uhat .- uhbar))
    cor = cu / sqrt(sum(abs2, u .- ubar) * sum(abs2, uhat .- uhbar))
    pass = fit.converged && sa2 > SIGMA_FLOOR && cor >= COR_FLOOR
    mag_ok = rel <= REL_REPORT
    return (seed = seed, q = q, converged = fit.converged, sigma_a2 = sa2,
            rel = rel, cor = cor, pass = pass, mag_ok = mag_ok)
end

function main()
    results = [_run(seed) for seed in SEEDS]
    for r in results
        @printf("[%s] seed=%d animals=%d converged=%s  σ̂²a=%.3f (truth %.2f, rel %.3f %s)  cor(û,u)=%.3f\n",
            r.pass ? "PASS" : "FAIL", r.seed, r.q, r.converged, r.sigma_a2, SIGMA_A2, r.rel,
            r.mag_ok ? "mag✓" : "mag✗(not gated)", r.cor)
    end
    npass = count(r -> r.pass, results)
    nmag = count(r -> r.mag_ok, results)
    @printf("SUMMARY threshold-recovery (probit, liability) seeds=%d gated_pass=%d (converged∧interior∧cor) | mag(rel≤%.2f)=%d/%d reported-not-gated | mean_sigma_a2=%.3f mean_rel=%.3f min_cor=%.3f\n",
        length(results), npass, REL_REPORT, nmag, length(results),
        sum(r.sigma_a2 for r in results) / length(results),
        sum(r.rel for r in results) / length(results),
        minimum(r.cor for r in results))
    all(r -> r.pass, results) || exit(1)
end

main()
