using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the fitted Poisson animal model
(`fit_laplace_reml(...; family = :poisson)`).

Deliberately outside `test/` so the suite stays RNG-free. It simulates a half-sib
pedigree, draws breeding values `u ~ N(0, A·σ²a)` and counts
`yᵢ ~ Poisson(exp(μ + uₐ))` (Knuth sampler), fits the Laplace-REML estimator, and
checks recovery of `σ²a` (Laplace VC estimation of count data is known to be
somewhat downward-biased at small scale, so the threshold is loose) plus the
latent-effect recovery (correlation of the posterior mode with the true `u`).

Run from the repository root:

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase6_poisson_recovery.jl

Predeclared: seeds 20260618..20260622; truth σ²a = 0.5, μ = 1.5; gate
rel(σ̂²a) ≤ 0.40 AND latent correlation ≥ 0.5 (the σ²a estimate is the harder,
gated target; the correlation is reported as supporting evidence).
"""

const SEEDS = [20260618, 20260619, 20260620, 20260621, 20260622]
const SIGMA_A2 = 0.5
const MU = 1.5
const THRESHOLD = 0.40
const COR_FLOOR = 0.5

_rand_poisson(rng, λ) = begin
    L = exp(-λ); k = 0; p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return k - 1
    end
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
    y = Float64[Float64(_rand_poisson(rng, exp(MU + u[a]))) for a in 1:q]
    fit = HSquared.fit_laplace_reml(y, X, Z, Ainv; family = :poisson,
                                    initial = (sigma_a2 = 0.5,))
    sa2 = fit.variance_components.sigma_a2
    rel = abs(sa2 - SIGMA_A2) / SIGMA_A2
    uhat = fit.breeding_values
    ubar = sum(u) / q; uhbar = sum(uhat) / q
    cu = sum((u .- ubar) .* (uhat .- uhbar))
    cor = cu / sqrt(sum(abs2, u .- ubar) * sum(abs2, uhat .- uhbar))
    pass = fit.converged && rel <= THRESHOLD && cor >= COR_FLOOR
    return (seed = seed, q = q, converged = fit.converged, sigma_a2 = sa2,
            rel = rel, cor = cor, pass = pass)
end

function main()
    results = [_run(seed) for seed in SEEDS]
    for r in results
        @printf("[%s] seed=%d animals=%d converged=%s  σ̂²a=%.3f (truth %.2f, rel %.3f)  cor(û,u)=%.3f\n",
            r.pass ? "PASS" : "FAIL", r.seed, r.q, r.converged, r.sigma_a2, SIGMA_A2, r.rel, r.cor)
    end
    npass = count(r -> r.pass, results)
    @printf("SUMMARY poisson-recovery seeds=%d passed=%d max_rel=%.3f min_cor=%.3f\n",
        length(results), npass, maximum(r.rel for r in results), minimum(r.cor for r in results))
    all(r -> r.pass, results) || exit(1)
end

main()
