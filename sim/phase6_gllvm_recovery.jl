using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in known-truth recovery harness for the genetic-GLLVM REML estimator
(`fit_gllvm_laplace_reml`).

Deliberately OUTSIDE `test/` so the committed suite stays RNG-free. It simulates a
half-sib pedigree, draws `K` independent genetic latent factors `g[·,k] ~ N(0, A)`,
forms `η[i,t] = μ + Σ_k Λ[t,k] g[i,k]`, samples responses from the chosen family, fits
the genetic-GLLVM REML, and measures recovery of the ROTATION-INVARIANT among-trait
genetic covariance `G_lat = ΛΛ'` (the loadings themselves are rotation-nonidentified).

Four predeclared scenarios:
- **A — Poisson rank-1 (`K=1`)**, `q=240`: a single common genetic factor.
- **B — Poisson rank-2 (`K=2`)**, `q=120`: a genuine two-factor structure with NON-degenerate
  among-trait genetic correlations.
- **C — Bernoulli rank-1 (`K=1`)**, `q=240` (binary logit): single common genetic factor
  on the latent logit scale. EXPECTED to show downward bias in `G_lat` recovery — the
  known Laplace-for-binary information effect — and is reported honestly, not gated.
- **D — Binomial(20) rank-1 (`K=1`)**, `q=240`: 20 binary trials per record; more
  information than Bernoulli ⇒ less downward bias.

Structured non-Gaussian (Laplace) REML recovery is HARD and is NOT claimed to pass a
tight gate; this records the honest empirical recovery, mirroring the other
`sim/phase6_*_recovery.jl` opt-in studies.

Run from the repository root (single-threaded, niced):

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. sim/phase6_gllvm_recovery.jl
"""

const REL_GATE = 0.45

# ---------------------------------------------------------------------------
# Samplers
# ---------------------------------------------------------------------------

_rand_poisson(rng, λ) = begin
    L = exp(-λ); k = 0; p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return k - 1
    end
end

_logistic(x) = 1.0 / (1.0 + exp(-x))

# Bernoulli(logistic(η)) draw — returns 0.0 or 1.0
_rand_bernoulli(rng, η) = rand(rng) < _logistic(η) ? 1.0 : 0.0

# Binomial(n_trials, logistic(η)) draw — returns Float64 success count
function _rand_binomial(rng, η, n_trials)
    p = _logistic(η)
    s = 0.0
    for _ in 1:n_trials
        s += rand(rng) < p ? 1.0 : 0.0
    end
    return s
end

# ---------------------------------------------------------------------------
# Pedigree helper
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Generic runner — accepts a response-sampler closure f(rng, η[i,t]) → y
# ---------------------------------------------------------------------------

function _run_generic(Λtrue, μ, seed, nsire, ndam, noffspring, family,
                      sample_response; report_cor = false)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    T, K = size(Λtrue)
    LA = cholesky(Symmetric(A)).L
    g = hcat([LA * randn(rng, q) for _ in 1:K]...)
    η = μ .+ g * transpose(Λtrue)
    Y = [sample_response(rng, η[i, t]) for i in 1:q, t in 1:T]
    fit = HSquared.fit_gllvm_laplace_reml(Y, Ainv, family;
                                          rank = K, initial = copy(Λtrue), iterations = 3000)
    Gtrue = Λtrue * transpose(Λtrue); Ghat = fit.genetic_covariance
    rel = norm(Ghat - Gtrue) / norm(Gtrue)
    corerr = report_cor ? _mean_offdiag_cor_error(Ghat, Gtrue) : NaN
    return (seed = seed, q = q, converged = fit.converged, rel = rel, corerr = corerr)
end

# Poisson-specific runner (used by scenarios A and B, unchanged behaviour)
function _run(Λtrue, μ, seed, nsire, ndam, noffspring; report_cor = false)
    _run_generic(Λtrue, μ, seed, nsire, ndam, noffspring,
                 HSquared.PoissonResponse(),
                 (rng, η) -> Float64(_rand_poisson(rng, exp(η)));
                 report_cor = report_cor)
end

# ---------------------------------------------------------------------------
# Scenario dispatcher
# ---------------------------------------------------------------------------

function _scenario(name, family_label, Λtrue, μ, seeds, nsire, ndam, noffspring,
                   family, sample_response;
                   report_cor = false, gated = true)
    T, K = size(Λtrue)
    @printf("\n== Scenario %s: %s, T=%d, K=%d, μ=%.1f ==\n",
            name, family_label, T, K, μ)
    @printf("truth Λ = %s\n", string(Λtrue))
    rels = Float64[]; cors = Float64[]; npass = 0
    for s in seeds
        r = _run_generic(Λtrue, μ, s, nsire, ndam, noffspring, family, sample_response;
                         report_cor = report_cor)
        push!(rels, r.rel); report_cor && push!(cors, r.corerr)
        r.rel <= REL_GATE && r.converged && (npass += 1)
        if report_cor
            @printf("  seed %d  q=%d  conv=%s  rel(Glat)=%.4f  mean|Δρ|=%.4f\n",
                    r.seed, r.q, string(r.converged), r.rel, r.corerr)
        else
            @printf("  seed %d  q=%d  conv=%s  rel(Glat)=%.4f\n",
                    r.seed, r.q, string(r.converged), r.rel)
        end
    end
    @printf("  → mean rel(Glat)=%.4f", sum(rels) / length(rels))
    report_cor && @printf(", mean|Δρ|=%.4f", sum(cors) / length(cors))
    if gated
        @printf("   passed(rel≤%.2f & conv): %d/%d\n", REL_GATE, npass, length(seeds))
    else
        @printf("   REPORTED-NOT-GATED (see note): %d/%d below threshold\n",
                npass, length(seeds))
    end
end

function main()
    println("Genetic-GLLVM REML known-truth recovery (Poisson + Bernoulli + Binomial)")

    # ------------------------------------------------------------------
    # Scenarios A and B: Poisson (existing, unchanged)
    # ------------------------------------------------------------------
    _scenario("A (rank-1)", "Poisson",
              reshape([1.0, 0.7, 0.5], 3, 1), 1.0,
              [20260620, 20260621, 20260622, 20260623, 20260624],
              20, 40, 180,
              HSquared.PoissonResponse(),
              (rng, η) -> Float64(_rand_poisson(rng, exp(η))))

    _scenario("B (rank-2, non-degenerate ρ)", "Poisson",
              [1.0 0.0; 0.5 0.8; 0.3 0.9], 1.0,
              [20260620, 20260621, 20260622, 20260623, 20260624],
              10, 20, 90,
              HSquared.PoissonResponse(),
              (rng, η) -> Float64(_rand_poisson(rng, exp(η)));
              report_cor = true)

    # ------------------------------------------------------------------
    # Scenario C: Bernoulli rank-1
    # μ=0.0 gives marginal prevalence ~0.5 — non-degenerate binary data.
    # Λ=[0.9,0.6,0.4] on the logit scale.  EXPECTED downward bias in
    # G_lat recovery (single-trial information effect) — REPORTED-NOT-GATED.
    # ------------------------------------------------------------------
    println("\n--- NOTE: Scenario C (Bernoulli) uses logit link. ---")
    println("    The Laplace-for-binary information effect causes KNOWN DOWNWARD BIAS")
    println("    in G_lat recovery. Results are REPORTED-NOT-GATED.")
    _scenario("C (Bernoulli rank-1)", "Bernoulli logit",
              reshape([0.9, 0.6, 0.4], 3, 1), 0.0,
              [20260620, 20260621, 20260622, 20260623, 20260624],
              20, 40, 180,
              HSquared.BernoulliResponse(),
              _rand_bernoulli;
              gated = false)

    # ------------------------------------------------------------------
    # Scenario D: Binomial(20) rank-1
    # Same DGP as C but with m=20 trials per record.  More information
    # ⇒ substantially less downward bias; gated at the same REL_GATE=0.45.
    # ------------------------------------------------------------------
    println("\n--- NOTE: Scenario D (Binomial m=20) uses logit link. ---")
    println("    More trials ⇒ more information ⇒ less bias than Bernoulli.")
    n_trials = 20
    _scenario("D (Binomial-20 rank-1)", "Binomial(20) logit",
              reshape([0.9, 0.6, 0.4], 3, 1), 0.0,
              [20260620, 20260621, 20260622, 20260623, 20260624],
              20, 40, 180,
              HSquared.BinomialResponse(n_trials),
              (rng, η) -> _rand_binomial(rng, η, n_trials))

    println()
    println("NOTE: structured non-Gaussian REML recovery is HARD; this is an HONEST opt-in")
    println("record, not a tight-gate claim. Rank-1 ⇒ ±1 correlations by construction (recovery")
    println("on G_lat); rank-2 has non-degenerate ρ so it also reports correlation recovery.")
    println("Bernoulli scenario C is REPORTED-NOT-GATED due to known Laplace-for-binary bias.")
end

main()
