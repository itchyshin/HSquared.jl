using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in COVERAGE-CALIBRATION study for the non-Gaussian `sigma_a2` profile-LRT
interval (`laplace_reml_interval`, family = :poisson / :binomial) - #44 gate 2.

The interval is documented as asymptotic with NO coverage calibration; this
records the empirical coverage at validation scale (the first such evidence).
Deliberately outside `test/` (RNG) and NOT a CI gate - descriptive
characterization. The interval's shape/bracketing/clamping is already validated
in `test/runtests.jl` (V6-FIT); this only measures coverage.

ADEMP:
- Aim: empirical coverage of the level-`LEVEL` profile-LRT interval for `sigma_a2`,
  and how often each endpoint clamps (a clamped endpoint is the search bound, NOT
  a confidence limit - reported separately so a one-sided/degenerate interval is
  visible, not hidden inside a coverage number).
- Data: half-sib q=345, `u ~ N(0, A sigma_a2)`, sigma_a2 = 1.0 (latent), mu = 0;
  Poisson `y ~ Poisson(exp(mu+u))`; Binomial `y ~ Binomial(m=20, logistic(mu+u))`.
- Method: `fit_laplace_reml` + `laplace_reml_interval(level=LEVEL, marginal=:laplace)`.
- Performance: coverage = mean(truth in [lower, upper]) over converged reps;
  endpoint-clamp rates; mean width.

CPU NOTE: each rep is a point fit + TWO profile root-finds (~10s/rep, BLAS-heavy).
This is expensive at the default 150 reps; CAP the BLAS threads and/or use a small
[nreps] so it does not peg the machine. Run:

    PATH="\$HOME/.juliaup/bin:\$PATH" OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 \\
      julia --project=. sim/phase6_nongaussian_interval_coverage.jl [nreps]
"""

const SIGMA_A2 = 1.0
const MU = 0.0
const LEVEL = 0.95
const NTRIALS = 20
const DEFAULT_REPS = 150

_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))
_rand_binom(rng, m, p) = sum(rand(rng) < p ? 1 : 0 for _ in 1:m)

function _rand_pois(rng, lam)
    lam <= 0 && return 0
    L = exp(-lam)
    k = 0
    p = 1.0
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

# Build the design (pedigree, Ainv, Cholesky of A) ONCE; vary only data per rep.
function _design(nsire, ndam, noff)
    ped = _halfsib(nsire, ndam, noff)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    return (Ainv = Ainv, q = q, L = cholesky(Symmetric(A)).L,
            X = ones(q, 1), Z = Matrix(1.0I, q, q))
end

function _one(D, family, seed)
    rng = MersenneTwister(seed)
    u = (D.L * randn(rng, D.q)) .* sqrt(SIGMA_A2)
    ci = try
        if family === :poisson
            y = Float64[_rand_pois(rng, exp(MU + u[a])) for a in 1:D.q]
            laplace_reml_interval(y, D.X, D.Z, D.Ainv; family = :poisson, level = LEVEL)
        else
            y = Float64[_rand_binom(rng, NTRIALS, _logistic(MU + u[a])) for a in 1:D.q]
            laplace_reml_interval(y, D.X, D.Z, D.Ainv; family = :binomial,
                                  n_trials = NTRIALS, level = LEVEL)
        end
    catch
        nothing
    end
    ci === nothing && return nothing
    covered = ci.converged && (ci.lower <= SIGMA_A2 <= ci.upper)
    return (converged = ci.converged, covered = covered, lc = ci.lower_clamped,
            uc = ci.upper_clamped, width = ci.upper - ci.lower)
end

function _report(D, family, reps)
    rs = filter(!isnothing, [_one(D, family, 20260700 + i) for i in 1:reps])
    conv = filter(r -> r.converged, rs)
    n = max(length(conv), 1)
    cov = count(r -> r.covered, conv) / n
    lc = count(r -> r.lc, conv) / n
    uc = count(r -> r.uc, conv) / n
    mw = sum(r -> r.width, conv) / n
    @printf("%-9s reps=%d converged=%d  coverage(%.0f%%)=%.3f  lower_clamped=%.2f  upper_clamped=%.2f  mean_width=%.3f\n",
            String(family), length(rs), length(conv), LEVEL * 100, cov, lc, uc, mw)
end

function main()
    reps = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : DEFAULT_REPS
    println("Non-Gaussian sigma_a2 profile-LRT interval coverage (truth sigma_a2=",
            SIGMA_A2, ", level=", LEVEL, ")")
    println("design: half-sib q=345, mu=0; Binomial m=", NTRIALS, "; reps=", reps)
    D = _design(15, 30, 300)
    _report(D, :poisson, reps)
    _report(D, :binomial, reps)
    println("Descriptive coverage characterization (asymptotic LRT at validation ",
            "scale; clamp rates flag one-sided/degenerate intervals; not a CI gate).")
end

main()
