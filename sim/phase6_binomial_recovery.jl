using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the fitted Binomial (logit) animal model
(`fit_laplace_reml(...; family = :binomial, n_trials = m)`).

Deliberately outside `test/` so the suite stays RNG-free. It is the scientific
counterpart to `sim/phase6_bernoulli_recovery.jl`: the single-trial Bernoulli
fit recovers the latent breeding values well but leaves `σ̂²a` DOWNWARD-biased and
uncalibrated, because binary data carries little variance information. With more
trials per record the data is far more informative, and the same Laplace REML
estimator recovers `σ̂²a` TIGHTLY — so the binary "bias" is fundamentally an
information effect, not an estimator flaw.

Model: half-sib pedigree, `u ~ N(0, A·σ²a)` on the logit scale, and
`yᵢ ~ Binomial(m, logistic(μ + uₐ))`.

Run from the repository root:

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase6_binomial_recovery.jl

Predeclared: seeds 20260618..20260622; truth σ²a = 1.0 (logit scale), μ = 0.0;
m = 20 trials/record; half-sib design with 15 sires, 30 dams, 300 offspring
(q = 345). Gate: converged AND rel(σ̂²a) ≤ 0.30 AND cor(û, u) ≥ 0.80.
"""

const SEEDS = [20260618, 20260619, 20260620, 20260621, 20260622]
const SIGMA_A2 = 1.0
const MU = 0.0
const NTRIALS = 20
const REL_MAX = 0.30
const COR_FLOOR = 0.80

_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))
_rand_binomial(rng, m, p) = sum(rand(rng) < p ? 1 : 0 for _ in 1:m)

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
    y = Float64[_rand_binomial(rng, NTRIALS, _logistic(MU + u[a])) for a in 1:q]
    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :binomial, n_trials = NTRIALS,
                                    initial = (sigma_a2 = 1.0,))
    sa2 = fit.variance_components.sigma_a2
    rel = abs(sa2 - SIGMA_A2) / SIGMA_A2
    uhat = fit.breeding_values
    ubar = sum(u) / q; uhbar = sum(uhat) / q
    cu = sum((u .- ubar) .* (uhat .- uhbar))
    cor = cu / sqrt(sum(abs2, u .- ubar) * sum(abs2, uhat .- uhbar))
    pass = fit.converged && rel <= REL_MAX && cor >= COR_FLOOR
    return (seed = seed, q = q, converged = fit.converged, sigma_a2 = sa2,
            rel = rel, cor = cor, pass = pass)
end

function main()
    results = [_run(seed) for seed in SEEDS]
    for r in results
        @printf("[%s] seed=%d animals=%d trials=%d converged=%s  σ̂²a=%.3f (truth %.2f, rel %.3f)  cor(û,u)=%.3f\n",
            r.pass ? "PASS" : "FAIL", r.seed, r.q, NTRIALS, r.converged, r.sigma_a2, SIGMA_A2, r.rel, r.cor)
    end
    npass = count(r -> r.pass, results)
    @printf("SUMMARY binomial-recovery seeds=%d passed=%d (gate: rel≤%.2f AND cor≥%.2f)  max_rel=%.3f  min_cor=%.3f\n",
        length(results), npass, REL_MAX, COR_FLOOR,
        maximum(r.rel for r in results), minimum(r.cor for r in results))
    all(r -> r.pass, results) || exit(1)
end

main()
