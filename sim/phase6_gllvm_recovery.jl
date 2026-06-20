using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the genetic-GLLVM REML estimator
(`fit_gllvm_laplace_reml`).

Deliberately OUTSIDE `test/` so the committed suite stays RNG-free. It simulates a
half-sib pedigree, draws `K` independent genetic latent factors `g[·,k] ~ N(0, A)`,
forms `η[i,t] = μ + Σ_k Λ[t,k] g[i,k]`, samples Poisson counts
`y[i,t] ~ Poisson(exp(η[i,t]))` (Knuth sampler), fits the genetic-GLLVM REML, and
measures recovery of the ROTATION-INVARIANT among-trait genetic covariance
`G_lat = ΛΛ'` (the loadings themselves are rotation-nonidentified).

Two predeclared scenarios:
- **A — rank-1 (`K=1`)**, `q=240`: a single common genetic factor. The implied
  genetic correlations are `±1` BY CONSTRUCTION, so recovery is assessed on `G_lat`
  (variances + covariances) via the relative Frobenius error `‖Ĝ−G‖_F/‖G‖_F`.
- **B — rank-2 (`K=2`)**, `q=120`: a genuine two-factor structure with NON-degenerate
  among-trait genetic correlations, so it also reports the genetic-correlation
  recovery `mean |ρ̂ − ρ|` over the off-diagonal — the key biological quantity.

Structured non-Gaussian (Laplace) REML recovery is HARD and is NOT claimed to pass a
tight gate; this records the honest empirical recovery, mirroring the other
`sim/phase6_*_recovery.jl` opt-in studies.

Run from the repository root (single-threaded, niced):

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 julia --project=. sim/phase6_gllvm_recovery.jl
"""

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

# mean off-diagonal absolute genetic-correlation error for a t×t G
function _mean_offdiag_cor_error(Ghat, Gtrue)
    Rh = genetic_correlation(Ghat); Rt = genetic_correlation(Gtrue)
    t = size(Gtrue, 1)
    s = 0.0; n = 0
    for i in 1:t, j in (i + 1):t
        s += abs(Rh[i, j] - Rt[i, j]); n += 1
    end
    return n == 0 ? 0.0 : s / n
end

function _run(Λtrue, μ, seed, nsire, ndam, noffspring; report_cor = false)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    T, K = size(Λtrue)
    LA = cholesky(Symmetric(A)).L
    g = hcat([LA * randn(rng, q) for _ in 1:K]...)
    η = μ .+ g * transpose(Λtrue)
    Y = [Float64(_rand_poisson(rng, exp(η[i, t]))) for i in 1:q, t in 1:T]
    fit = HSquared.fit_gllvm_laplace_reml(Y, Ainv, HSquared.PoissonResponse();
                                          rank = K, initial = copy(Λtrue), iterations = 3000)
    Gtrue = Λtrue * transpose(Λtrue); Ghat = fit.genetic_covariance
    rel = norm(Ghat - Gtrue) / norm(Gtrue)
    corerr = report_cor ? _mean_offdiag_cor_error(Ghat, Gtrue) : NaN
    return (seed = seed, q = q, converged = fit.converged, rel = rel, corerr = corerr)
end

function _scenario(name, Λtrue, μ, seeds, nsire, ndam, noffspring; report_cor = false)
    T, K = size(Λtrue)
    @printf("\n== Scenario %s: Poisson, T=%d, K=%d, μ=%.1f ==\n", name, T, K, μ)
    @printf("truth Λ = %s\n", string(Λtrue))
    rels = Float64[]; cors = Float64[]; npass = 0
    for s in seeds
        r = _run(Λtrue, μ, s, nsire, ndam, noffspring; report_cor = report_cor)
        push!(rels, r.rel); report_cor && push!(cors, r.corerr)
        r.rel <= REL_GATE && r.converged && (npass += 1)
        if report_cor
            @printf("  seed %d  q=%d  conv=%s  rel(Glat)=%.4f  mean|Δρ|=%.4f\n", r.seed, r.q, string(r.converged), r.rel, r.corerr)
        else
            @printf("  seed %d  q=%d  conv=%s  rel(Glat)=%.4f\n", r.seed, r.q, string(r.converged), r.rel)
        end
    end
    @printf("  → mean rel(Glat)=%.4f", sum(rels) / length(rels))
    report_cor && @printf(", mean|Δρ|=%.4f", sum(cors) / length(cors))
    @printf("   passed(rel≤%.2f & conv): %d/%d\n", REL_GATE, npass, length(seeds))
end

function main()
    println("Genetic-GLLVM REML known-truth recovery (Poisson)")
    _scenario("A (rank-1)", reshape([1.0, 0.7, 0.5], 3, 1), 1.0,
              [20260620, 20260621, 20260622, 20260623, 20260624], 20, 40, 180)
    _scenario("B (rank-2, non-degenerate ρ)", [1.0 0.0; 0.5 0.8; 0.3 0.9], 1.0,
              [20260620, 20260621, 20260622, 20260623, 20260624], 10, 20, 90; report_cor = true)
    println("\nNOTE: structured non-Gaussian REML recovery is HARD; this is an HONEST opt-in")
    println("record, not a tight-gate claim. Rank-1 ⇒ ±1 correlations by construction (recovery")
    println("on G_lat); rank-2 has non-degenerate ρ so it also reports correlation recovery.")
end

main()
