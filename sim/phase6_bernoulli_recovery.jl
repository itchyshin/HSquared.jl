using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the fitted Bernoulli (logit) animal model
(`fit_laplace_reml(...; family = :bernoulli)`).

Deliberately outside `test/` so the suite stays RNG-free. It simulates a half-sib
pedigree, draws breeding values `u ~ N(0, A·σ²a)` on the logit/liability scale and
binary responses `yᵢ ~ Bernoulli(logistic(μ + uₐ))`, fits the Laplace-REML
estimator, and checks recovery.

Honest split of what the method does (predeclared):

  * GATED — latent/EBV recovery. The posterior-mode breeding values track the
    true `u` well (correlation), and the variance estimate does NOT collapse to a
    search boundary. These are the reliable signals.
  * REPORTED, NOT GATED — the variance-component point estimate `σ̂²a`. Single-
    trial binary data carries little variance information and the Laplace
    approximation is known to bias the binary variance component DOWNWARD; the
    estimate is noisy across seeds. We report `σ̂²a` and its relative error for
    transparency, but do not gate on it (cf. the Phase-3 `h²` split). Calibrating
    `σ̂²a` would need many binomial trials per record and/or a bias correction.

Run from the repository root:

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase6_bernoulli_recovery.jl

Predeclared: seeds 20260618..20260622; truth σ²a = 1.0 (logit scale), μ = 0.0
(baseline prevalence ≈ 0.5, the most informative binary case); half-sib design
with 25 sires, 50 dams, 1000 offspring (q = 1075). Gate: converged AND
0.1 < σ̂²a < 5.0 (did not collapse to a boundary) AND cor(û, u) ≥ 0.5.
"""

const SEEDS = [20260618, 20260619, 20260620, 20260621, 20260622]
const SIGMA_A2 = 1.0
const MU = 0.0
const COR_FLOOR = 0.5
const SA2_LO = 0.1
const SA2_HI = 5.0

_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))

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

function _run(seed; nsire = 25, ndam = 50, noffspring = 1000)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    u = (LA * randn(rng, q)) .* sqrt(SIGMA_A2)
    X = ones(q, 1)
    Z = Matrix(1.0I, q, q)
    y = Float64[rand(rng) < _logistic(MU + u[a]) ? 1.0 : 0.0 for a in 1:q]
    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :bernoulli,
                                    initial = (sigma_a2 = 1.0,))
    sa2 = fit.variance_components.sigma_a2
    rel = abs(sa2 - SIGMA_A2) / SIGMA_A2
    uhat = fit.breeding_values
    ubar = sum(u) / q; uhbar = sum(uhat) / q
    cu = sum((u .- ubar) .* (uhat .- uhbar))
    cor = cu / sqrt(sum(abs2, u .- ubar) * sum(abs2, uhat .- uhbar))
    prevalence = sum(y) / q
    pass = fit.converged && SA2_LO < sa2 < SA2_HI && cor >= COR_FLOOR
    return (seed = seed, q = q, converged = fit.converged, sigma_a2 = sa2,
            rel = rel, cor = cor, prevalence = prevalence, pass = pass)
end

function main()
    results = [_run(seed) for seed in SEEDS]
    for r in results
        @printf("[%s] seed=%d animals=%d converged=%s  σ̂²a=%.3f (truth %.2f, rel %.3f, reported)  cor(û,u)=%.3f  prev=%.3f\n",
            r.pass ? "PASS" : "FAIL", r.seed, r.q, r.converged, r.sigma_a2, SIGMA_A2, r.rel, r.cor, r.prevalence)
    end
    npass = count(r -> r.pass, results)
    @printf("SUMMARY bernoulli-recovery seeds=%d passed=%d (gate: cor≥%.1f, interior σ̂²a)  min_cor=%.3f  σ̂²a∈[%.3f,%.3f] (downward-biased, reported)\n",
        length(results), npass, COR_FLOOR,
        minimum(r.cor for r in results),
        minimum(r.sigma_a2 for r in results), maximum(r.sigma_a2 for r in results))
    all(r -> r.pass, results) || exit(1)
end

main()
