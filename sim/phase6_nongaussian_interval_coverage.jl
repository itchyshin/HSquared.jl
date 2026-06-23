using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in COVERAGE-CHARACTERIZATION study for the non-Gaussian `sigma_a2` profile-LRT
interval (`laplace_reml_interval`) — #44 gate 2 / backlog H6.

The interval covers `family = :poisson` / `:bernoulli` / `:binomial` /
`:bernoulli_probit` UNIFORMLY through one shared `_resolve_single_family` +
`target`/`_profile_root` path. Its shape/bracketing/clamping is already validated
deterministically in `test/runtests.jl` (V6-FIT); this records the EMPIRICAL coverage
at validation scale, the first such evidence. Deliberately outside `test/` (RNG) and
NOT a CI gate — a descriptive characterization, read as "appears conservative /
over-covering", NEVER a calibrated coverage GUARANTEE.

ADEMP:
- Aim: empirical coverage of the level-`L` profile-LRT interval for `sigma_a2`, and
  how often each endpoint CLAMPS. A clamped endpoint is the search bound, NOT a
  confidence limit, so coverage is computed ONLY over NON-DEGENERATE reps (converged,
  not double-clamped) and the clamp rate is reported SEPARATELY — a degenerate
  (flat-profile) interval is visible, not hidden inside a coverage number. (Binary
  `:bernoulli`/`:bernoulli_probit` data is information-poor, so most reps double-clamp;
  the "coverage" there is over the few non-degenerate reps and is reported as such.)
- Data: half-sib, `u ~ N(0, A·sigma_a2)`, mu = 0. Poisson `y ~ Poisson(exp(η))`;
  Bernoulli `y ~ Bernoulli(logistic(η))`; Binomial `y ~ Binomial(m, logistic(η))`;
  Bernoulli-probit `y = 1[η + e > 0]`, `e ~ N(0,1)`.
- Method: `fit_laplace_reml` + `laplace_reml_interval(level, marginal = :laplace)`.
- Performance: coverage = mean(truth ∈ [lower, upper]) over non-degenerate reps;
  endpoint-clamp rates; mean width (non-degenerate); swept over level × truth sigma_a2.

CPU NOTE: each rep is a point fit + TWO profile root-finds (BLAS-heavy). The prior
multithreaded run was KILLED for pegging cores. MANDATORY: cap BLAS threads and use a
small rep count + a modest design. A TSV is written next to this file. Run:

    PATH="\$HOME/.juliaup/bin:\$PATH" OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 \\
      JULIA_NUM_THREADS=1 julia --project=. sim/phase6_nongaussian_interval_coverage.jl [nreps]
"""

const MU = 0.0
const NTRIALS = 20
const LEVELS = (0.90, 0.95)
const SIGMA_A2S = (0.25, 1.0)
const DEFAULT_REPS = 15
# Coverage sweep over the logit/log families + the new Bernoulli leg. The probit
# family shares the IDENTICAL interval contract (locked by the CI cross-family test)
# but is omitted here to bound BLAS cost; binary `:bernoulli` is the degenerate-flat
# case whose clamp rate this characterization most needs.
const FAMILIES = (:poisson, :bernoulli, :binomial)

_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))
_rand_binom(rng, m, p) = sum(rand(rng) < p ? 1 : 0 for _ in 1:m)

function _rand_pois(rng, lam)
    lam <= 0 && return 0
    L = exp(-lam); k = 0; p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return k - 1
    end
end

function _halfsib(nsire, ndam, noff)
    s = ["s$i" for i in 1:nsire]
    d = ["d$i" for i in 1:ndam]
    o = ["o$i" for i in 1:noff]
    ids = vcat(s, d, o)
    sire = vcat(fill("0", nsire + ndam), [s[((i - 1) % nsire) + 1] for i in 1:noff])
    dam = vcat(fill("0", nsire + ndam), [d[((i - 1) % ndam) + 1] for i in 1:noff])
    return normalize_pedigree(ids, sire, dam)
end

# Modest design (q = 165): smaller than the q=345 recovery sims to bound BLAS cost on
# the two-root-find interval; coverage is a validation-scale CHARACTERIZATION, so the
# smaller design + small rep count are honest (and flagged in the row/checkpoint).
function _design(nsire = 15, ndam = 30, noff = 120)
    ped = _halfsib(nsire, ndam, noff)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    return (Ainv = Ainv, q = q, L = cholesky(Symmetric(A)).L,
            X = ones(q, 1), Z = Matrix(1.0I, q, q))
end

function _draw_y(D, family, u, rng)
    η = MU .+ u
    if family === :poisson
        return Float64[_rand_pois(rng, exp(η[a])) for a in 1:D.q]
    elseif family === :bernoulli
        return Float64[rand(rng) < _logistic(η[a]) ? 1.0 : 0.0 for a in 1:D.q]
    elseif family === :binomial
        return Float64[_rand_binom(rng, NTRIALS, _logistic(η[a])) for a in 1:D.q]
    else # :bernoulli_probit — liability threshold
        return Float64[(η[a] + randn(rng)) > 0 ? 1.0 : 0.0 for a in 1:D.q]
    end
end

function _one(D, family, sigma_a2, level, seed)
    rng = MersenneTwister(seed)
    u = (D.L * randn(rng, D.q)) .* sqrt(sigma_a2)
    y = _draw_y(D, family, u, rng)
    ci = try
        kw = family === :binomial ? (; n_trials = NTRIALS) : (;)
        laplace_reml_interval(y, D.X, D.Z, D.Ainv; family = family, level = level, kw...)
    catch
        nothing
    end
    ci === nothing && return nothing
    degenerate = ci.lower_clamped && ci.upper_clamped     # flat profile: NOT a CI
    covered = ci.converged && !degenerate && (ci.lower <= sigma_a2 <= ci.upper)
    return (converged = ci.converged, degenerate = degenerate, covered = covered,
            lc = ci.lower_clamped, uc = ci.upper_clamped, width = ci.upper - ci.lower)
end

function main()
    reps = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : DEFAULT_REPS
    D = _design()
    tsv = joinpath(@__DIR__, "phase6_nongaussian_interval_coverage.tsv")
    open(tsv, "w") do io
        println(io, "family\tsigma_a2\tlevel\treps\tconverged\tnondegenerate\tcoverage\tlower_clamped\tupper_clamped\tmean_width")
        @printf("Non-Gaussian σ²a profile-LRT interval coverage (half-sib q=%d, μ=0, Binomial m=%d, reps=%d)\n",
                D.q, NTRIALS, reps)
        println("coverage is over NON-DEGENERATE (converged, not double-clamped) reps; clamp rates reported separately")
        for family in FAMILIES, sa2 in SIGMA_A2S, level in LEVELS
            rs = filter(!isnothing,
                        [_one(D, family, sa2, level, 20260700 + i) for i in 1:reps])
            conv = filter(r -> r.converged, rs)
            nondeg = filter(r -> r.converged && !r.degenerate, rs)
            nd = max(length(nondeg), 1)
            cov = count(r -> r.covered, nondeg) / nd
            lc = length(conv) == 0 ? 0.0 : count(r -> r.lc, conv) / length(conv)
            uc = length(conv) == 0 ? 0.0 : count(r -> r.uc, conv) / length(conv)
            mw = length(nondeg) == 0 ? NaN : sum(r -> r.width, nondeg) / length(nondeg)
            @printf("%-16s σ²a=%.2f level=%.2f  conv=%d  nondeg=%d  coverage=%.3f  lc=%.2f uc=%.2f  mw=%.3f\n",
                    String(family), sa2, level, length(conv), length(nondeg), cov, lc, uc, mw)
            @printf(io, "%s\t%.2f\t%.2f\t%d\t%d\t%d\t%.3f\t%.3f\t%.3f\t%.4f\n",
                    String(family), sa2, level, length(rs), length(conv), length(nondeg), cov, lc, uc, mw)
        end
    end
    println("TSV written to ", tsv)
    println("Descriptive coverage characterization (asymptotic LRT, validation scale, ",
            "small reps); read as conservative/over-covering, NOT a calibrated coverage guarantee.")
end

main()
