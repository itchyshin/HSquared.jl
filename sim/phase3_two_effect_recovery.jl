using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the general two-effect REML estimator
(`fit_two_effect_reml`) — an additive genetic effect PLUS a second random effect
(here a common-environment / litter effect).

Deliberately outside `test/` so the suite stays RNG-free. The prior one-off note
recorded that the additive variance was UNDERESTIMATED on a small *confounded*
design (the second effect aliased the genetic family). This harness fixes the
identifiability by assigning the common-environment groups INDEPENDENTLY of the
pedigree, so the pedigree-structured additive covariance and the block-structured
group covariance have distinct patterns and all three variance components are
separable.

Model: `y = μ + u1[animal] + u2[group] + e`, with
`u1 ~ N(0, A·σ1²)` (additive, pedigree `A`), `u2 ~ N(0, I·σ2²)` (common
environment over groups assigned at random), `e ~ N(0, I·σe²)`.

Run from the repository root:

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase3_two_effect_recovery.jl

Predeclared: seeds 20260618..20260622; truth (σ1², σ2², σe²) = (1.0, 0.5, 1.0),
μ = 2.0; half-sib design with 20 sires, 40 dams, 800 offspring (q = 860) and 80
random common-environment groups. Gate: converged AND rel(σ̂1²) ≤ 0.40 AND
rel(σ̂2²) ≤ 0.40 AND rel(σ̂e²) ≤ 0.25.
"""

const SEEDS = [20260618, 20260619, 20260620, 20260621, 20260622]
const S1 = 1.0
const S2 = 0.5
const SE = 1.0
const MU = 2.0
const REL1 = 0.40
const REL2 = 0.40
const RELE = 0.25

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

function _run(seed; nsire = 20, ndam = 40, noffspring = 800, ngroup = 80)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv1 = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv1))))
    q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    u1 = (LA * randn(rng, q)) .* sqrt(S1)
    group = [rand(rng, 1:ngroup) for _ in 1:q]          # independent of pedigree
    u2 = randn(rng, ngroup) .* sqrt(S2)
    X = ones(q, 1)
    Z1 = Matrix(1.0I, q, q)
    Z2 = zeros(q, ngroup)
    for a in 1:q
        Z2[a, group[a]] = 1.0
    end
    Ainv2 = Matrix(1.0I, ngroup, ngroup)
    e = randn(rng, q) .* sqrt(SE)
    y = MU .+ u1 .+ Z2 * u2 .+ e
    fit = HSquared.fit_two_effect_reml(y, X, Z1, Ainv1, Z2, Ainv2;
                                       initial = (sigma1 = 1.0, sigma2 = 1.0, sigma_e2 = 1.0))
    vc = fit.variance_components
    rel1 = abs(vc.sigma1 - S1) / S1
    rel2 = abs(vc.sigma2 - S2) / S2
    rele = abs(vc.sigma_e2 - SE) / SE
    pass = fit.converged && rel1 <= REL1 && rel2 <= REL2 && rele <= RELE
    return (seed = seed, q = q, converged = fit.converged,
            sigma1 = vc.sigma1, sigma2 = vc.sigma2, sigma_e2 = vc.sigma_e2,
            rel1 = rel1, rel2 = rel2, rele = rele, pass = pass)
end

function main()
    results = [_run(seed) for seed in SEEDS]
    for r in results
        @printf("[%s] seed=%d animals=%d converged=%s  σ̂1²=%.3f (rel %.3f) σ̂2²=%.3f (rel %.3f) σ̂e²=%.3f (rel %.3f)\n",
            r.pass ? "PASS" : "FAIL", r.seed, r.q, r.converged,
            r.sigma1, r.rel1, r.sigma2, r.rel2, r.sigma_e2, r.rele)
    end
    npass = count(r -> r.pass, results)
    @printf("SUMMARY two-effect-recovery seeds=%d passed=%d  truth(σ1²,σ2²,σe²)=(%.1f,%.1f,%.1f)  max_rel1=%.3f max_rel2=%.3f max_rele=%.3f\n",
        length(results), npass, S1, S2, SE,
        maximum(r.rel1 for r in results), maximum(r.rel2 for r in results),
        maximum(r.rele for r in results))
    all(r -> r.pass, results) || exit(1)
end

main()
