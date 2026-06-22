using HSquared
using LinearAlgebra
using Printf
using Random

"""
Opt-in binomial INFORMATION-GRADIENT study (#44 gate 2 evidence).

Characterizes how Laplace-REML recovery of the latent additive variance σ²a
improves as the number of Bernoulli trials per record grows — the "information
effect" that motivates the per-record varying-trial activation. The SAME
estimator and the SAME simulated breeding values `u` are reused across an
n_trials ladder, so the only thing that changes per rung is the trial count (and
hence the variance information in the data).

Deliberately outside `test/` (uses RNG) and NOT a CI gate — this is descriptive
characterization, not a pass/fail recovery gate. The gated single-point endpoints
live in `sim/phase6_bernoulli_recovery.jl` (m = 1) and
`sim/phase6_binomial_recovery.jl` (common m = 20 and per-record n ∈ 1:30).

ADEMP:
- Aim: σ̂²a rel-bias falls monotonically with trials/record; binary (m = 1) is
  the downward-biased, information-limited endpoint, large m recovers tightly.
- Data: half-sib pedigree (15 sires, 30 dams, 300 offspring; q = 345),
  `u ~ N(0, A·σ²a)` on the logit scale, σ²a = 1.0, μ = 0.0; per rung m,
  `yₐ ~ Binomial(m, logistic(μ + uₐ))`; the per-record rung draws nₐ ~ U{1..30}
  (the general cbind(successes, failures) GLMM via `BinomialVectorResponse`).
- Estimand: σ²a (latent/logit scale) and EBV recovery cor(û, u).
- Method: `fit_laplace_reml(...; family = :binomial, n_trials = m)`.
- Performance: per-rung mean σ̂²a, mean rel-bias, and mean cor(û, u) over 5 seeds.

Run from the repository root:

    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 julia --project=. sim/phase6_binomial_information_gradient.jl
"""

const SEEDS = [20260618, 20260619, 20260620, 20260621, 20260622]
const SIGMA_A2 = 1.0
const MU = 0.0
const LADDER = [1, 2, 5, 10, 20]   # trials/record; m = 1 is Bernoulli
const NT_RANGE = 1:30              # per-record varying rung

_logistic(η) = η >= 0 ? 1.0 / (1.0 + exp(-η)) : (e = exp(η); e / (1.0 + e))
_rand_binom(rng, m, p) = sum(rand(rng) < p ? 1 : 0 for _ in 1:m)
_mean(v) = sum(v) / length(v)

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

function _relcor(fit, u, q)
    sa2 = fit.variance_components.sigma_a2
    rel = abs(sa2 - SIGMA_A2) / SIGMA_A2
    uhat = fit.breeding_values
    ubar = sum(u) / q
    uhbar = sum(uhat) / q
    cu = sum((u .- ubar) .* (uhat .- uhbar))
    cor = cu / sqrt(sum(abs2, u .- ubar) * sum(abs2, uhat .- uhbar))
    return (sigma_a2 = sa2, rel = rel, cor = cor, converged = fit.converged)
end

# Per seed, build the design + breeding values ONCE, then reuse `u` across the
# whole n_trials ladder so each rung differs only in trials/record.
function _seed_setup(seed; nsire = 15, ndam = 30, noffspring = 300)
    rng = MersenneTwister(seed)
    ped = _halfsib_pedigree(nsire, ndam, noffspring)
    Ainv = pedigree_inverse(ped)
    A = Matrix(inv(Symmetric(Matrix(Ainv))))
    q = length(ped.ids)
    LA = cholesky(Symmetric(A)).L
    u = (LA * randn(rng, q)) .* sqrt(SIGMA_A2)
    X = ones(q, 1)
    Z = Matrix(1.0I, q, q)
    return (rng = rng, Ainv = Ainv, q = q, u = u, X = X, Z = Z)
end

function _fit_common(s, m)
    y = Float64[_rand_binom(s.rng, m, _logistic(MU + s.u[a])) for a in 1:s.q]
    fit = HSquared.fit_laplace_reml(y, s.X, s.Z, s.Ainv; family = :binomial,
                                    n_trials = m, initial = (sigma_a2 = 1.0,))
    return _relcor(fit, s.u, s.q)
end

function _fit_perrecord(s)
    nt = [rand(s.rng, NT_RANGE) for _ in 1:s.q]
    y = Float64[_rand_binom(s.rng, nt[a], _logistic(MU + s.u[a])) for a in 1:s.q]
    fit = HSquared.fit_laplace_reml(y, s.X, s.Z, s.Ainv; family = :binomial,
                                    n_trials = nt, initial = (sigma_a2 = 1.0,))
    r = _relcor(fit, s.u, s.q)
    return (r..., nt_mean = sum(nt) / s.q)
end

function main()
    setups = [_seed_setup(seed) for seed in SEEDS]
    q = setups[1].q
    println("Binomial information gradient — σ²a recovery vs trials/record")
    @printf("design: half-sib q=%d, σ²a=%.2f (logit), μ=%.1f, seeds=%d\n\n",
            q, SIGMA_A2, MU, length(SEEDS))
    @printf("%-14s %10s %10s %10s %8s\n",
            "trials/rec", "mean σ̂²a", "mean rel", "mean cor", "conv")
    rungs = NamedTuple[]
    for m in LADDER
        rs = [_fit_common(s, m) for s in setups]
        rung = (label = (m == 1 ? "1 (Bern)" : string(m)), m = m,
                msa = _mean([r.sigma_a2 for r in rs]),
                mrel = _mean([r.rel for r in rs]),
                mcor = _mean([r.cor for r in rs]),
                nc = count(r -> r.converged, rs))
        push!(rungs, rung)
        @printf("%-14s %10.3f %10.3f %10.3f %6d/%d\n",
                rung.label, rung.msa, rung.mrel, rung.mcor, rung.nc, length(rs))
    end
    prs = [_fit_perrecord(s) for s in setups]
    @printf("%-14s %10.3f %10.3f %10.3f %6d/%d  (mean n=%.1f)\n", "per-record",
            _mean([r.sigma_a2 for r in prs]), _mean([r.rel for r in prs]),
            _mean([r.cor for r in prs]), count(r -> r.converged, prs), length(prs),
            _mean([r.nt_mean for r in prs]))
    lo = rungs[1]
    hi = rungs[end]
    @printf("\nGradient: mean rel-bias(σ̂²a) %.3f at m=1 (Bernoulli) -> %.3f at m=%d; cor %.3f -> %.3f.\n",
            lo.mrel, hi.mrel, hi.m, lo.mcor, hi.mcor)
    println("Descriptive characterization of the information effect (not a CI gate).")
end

main()
