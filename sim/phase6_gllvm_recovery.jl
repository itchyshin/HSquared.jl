using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the genetic-GLLVM REML estimator
(`fit_gllvm_laplace_reml(...; family = PoissonResponse())`).

Deliberately OUTSIDE `test/` so the committed suite stays RNG-free. It simulates a
half-sib pedigree, draws `K` independent genetic latent factors `g[·,k] ~ N(0, A)`,
forms `η[i,t] = μ + Σ_k Λ[t,k] g[i,k]`, samples Poisson counts
`y[i,t] ~ Poisson(exp(η[i,t]))` (Knuth sampler), fits the genetic-GLLVM REML, and
measures recovery of the ROTATION-INVARIANT among-trait genetic covariance
`G_lat = ΛΛ'` (the loadings themselves are rotation-nonidentified). The reported
metric is the relative Frobenius error `‖Ĝ − G‖_F / ‖G‖_F` and the per-trait genetic
variance recovery.

Structured non-Gaussian (Laplace) REML recovery is HARD and is NOT claimed to pass a
tight gate — this harness records the honest empirical recovery, mirroring the other
`sim/phase6_*_recovery.jl` opt-in studies. With a rank-1 truth (`K = 1`) the implied
among-trait genetic correlations are `±1` BY CONSTRUCTION (one common genetic factor);
recovery is therefore assessed on `G_lat` (variances + covariances), not on the
degenerate correlations.

Run from the repository root (single-threaded, niced):

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase6_gllvm_recovery.jl

Predeclared: seeds 20260620..20260624; truth `Λ = [1.0, 0.7, 0.5]` (T=3, K=1),
`μ = 1.0`; report `rel(G_lat) = ‖Ĝ − G‖_F/‖G‖_F` with a LOOSE gate `≤ 0.45`.
"""

const SEEDS = [20260620, 20260621, 20260622, 20260623, 20260624]
const LAMBDA_TRUE = reshape([1.0, 0.7, 0.5], 3, 1)   # T = 3, K = 1
const MU = 1.0
const REL_GATE = 0.45

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

function _run(seed; nsire = 20, ndam = 40, noffspring = 180)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    T, K = size(LAMBDA_TRUE)
    LA = cholesky(Symmetric(A)).L
    g = hcat([LA * randn(rng, q) for _ in 1:K]...)          # q×K, each column ~ N(0, A)
    η = MU .+ g * transpose(LAMBDA_TRUE)                     # q×T
    Y = [Float64(_rand_poisson(rng, exp(η[i, t]))) for i in 1:q, t in 1:T]

    fit = HSquared.fit_gllvm_laplace_reml(Y, Ainv, HSquared.PoissonResponse();
                                          rank = K, initial = copy(LAMBDA_TRUE),
                                          iterations = 2000)
    G_true = LAMBDA_TRUE * transpose(LAMBDA_TRUE)
    Ghat = fit.genetic_covariance
    rel = norm(Ghat - G_true) / norm(G_true)
    return (seed = seed, q = q, converged = fit.converged, rel = rel,
            var_true = diag(G_true), var_hat = diag(Ghat))
end

function main()
    T, K = size(LAMBDA_TRUE)
    @printf("Genetic-GLLVM REML recovery (Poisson, T=%d, K=%d, μ=%.1f)\n", T, K, MU)
    @printf("truth Λ = %s ⇒ G_lat = ΛΛ'\n\n", string(vec(LAMBDA_TRUE)))
    @printf("%-12s %5s %6s %10s   %s\n", "seed", "q", "conv", "rel(Glat)", "diag(Ĝ) vs diag(G)")
    rels = Float64[]
    npass = 0
    for s in SEEDS
        r = _run(s)
        push!(rels, r.rel)
        r.rel <= REL_GATE && r.converged && (npass += 1)
        @printf("%-12d %5d %6s %10.4f   %s vs %s\n", r.seed, r.q, string(r.converged),
                r.rel, string(round.(r.var_hat; digits = 3)), string(round.(r.var_true; digits = 3)))
    end
    @printf("\nmean rel(Glat) = %.4f   |   passed (rel ≤ %.2f AND converged): %d/%d\n",
            sum(rels) / length(rels), REL_GATE, npass, length(SEEDS))
    println("\nNOTE: structured non-Gaussian REML recovery is HARD; this is an HONEST")
    println("opt-in record, not a tight-gate claim. Rank-1 truth ⇒ ±1 genetic correlations")
    println("by construction, so recovery is assessed on G_lat (variances + covariances).")
end

main()
