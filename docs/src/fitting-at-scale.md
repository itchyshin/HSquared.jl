# Fitting at scale: exact vs matrix-free

`HSquared.jl` has **two** engines for the `K`-independent-random-effect mixed model, and
[`fit_multi_effect`](@ref) chooses between them by feasibility. This page explains the choice,
the accuracy-vs-feasibility trade, and how to control it.

!!! warning "Experimental · opt-in · not the default fit"
    Everything on this page is experimental and validation-scale. The public
    default fit path is the univariate Gaussian animal model; these
    multi-effect engines are opt-in. Timings below are measurements, not a
    production-performance claim.

## The two engines

| | exact | matrix-free |
|---|---|---|
| function | [`fit_sparse_multi_effect_aireml`](@ref) | [`fit_multi_effect_mc_reml`](@ref) |
| method | sparse AI-REML (exact gradient from a Cholesky **selected inverse**) | Monte-Carlo EM-REML (matrix-free solves + a **Hutchinson stochastic trace**) |
| forms/factorizes `C`? | **yes** — a sparse Cholesky each iteration | **no** — only "matrix × vector" |
| accuracy | exact | approximate — the gradient carries a Monte-Carlo standard error |
| where it wins | small–moderate size (exact, few iterations) | very large size, where the factorization is infeasible |

**Why two?** With a *single* random effect the animal-model factorization stays sparse and scales
to very large pedigrees. But with *two or more* random effects (a contemporary-group, maternal, or
permanent-environment term alongside the animal effect) the sparse Cholesky **fills in** — the
factor becomes far denser than `C` — and past roughly `10⁵` individuals it becomes infeasible in
memory and time (measured: the direct multi-effect path is already ~quadratic by `q ≈ 50 000`; a
METIS reordering did **not** fix it). The matrix-free engine never forms or factorizes `C`, so it
has no fill wall — it has stayed feasible fitting `K = 3` models to 200 000 individuals in testing (the matrix-free *solve* it is built on reaches a million) — but it pays
with Monte-Carlo noise in the variance-component gradient.

This is the same accuracy-for-feasibility trade a variational approximation makes: you reach for
the approximate engine **only** where the exact one cannot run.

## Choosing automatically

```julia
fit = fit_multi_effect(y, X, effects)                 # method = :auto (the default)
```

`:auto` routes on feasibility:

- a **single** random effect (`K = 1`), or `N = p + Σqᵢ ≤ direct_max_n` → **exact**;
- otherwise → **matrix-free**, printing a one-line `@info` that it switched and that the estimates
  carry a Monte-Carlo standard error.

```julia
fit = fit_multi_effect(y, X, effects; method = :exact)        # force exact (may run out of memory)
fit = fit_multi_effect(y, X, effects; method = :matrix_free)  # force matrix-free (accept MC noise)
```

!!! note "The `:auto` threshold is a heuristic"
    `direct_max_n` (default `200_000`) is a **coarse, machine-agnostic** cutoff calibrated to the
    measured `K ≥ 2` factorization cost, deliberately conservative and always overridable. It is
    **not** a precise per-problem fill prediction — that is future work. When in doubt on a large
    problem, try `method = :exact` first; if it fits in memory, its answer is exact.

The returned `NamedTuple` carries a `dispatch` field (`:exact` or `:matrix_free`) recording which
engine ran. The two result shapes differ: the matrix-free result has a `trace_mcse` (and **no**
`loglik` — a matrix-free REML log-likelihood needs a stochastic log-determinant, which is not yet
implemented).

## Reading the Monte-Carlo noise

When the matrix-free engine runs, the fit reports `trace_mcse` — the Monte-Carlo standard error of
the score-trace terms, i.e. the noise you traded for feasibility. It shrinks like `1/√nprobe`
(more probe vectors ⇒ tighter). If you need a tighter answer, raise `nprobe`:

```julia
fit = fit_multi_effect(y, X, effects; method = :matrix_free, nprobe = 256)
```

The matrix-free fit **reproduces** the exact AI-REML variance components as `nprobe` grows: in the
recovery gate it tracks the exact estimator on identical data, with the Monte-Carlo perturbation
controllable by `nprobe`.

## Honest scope

- These engines fit **variance components + BLUPs** for `K` independent Gaussian random effects.
  They are not the public default, not calibrated-interval methods, and the matrix-free engine is a
  supplied-machinery estimator whose scale evidence is machine-specific (see the validation-status
  page and the v0.8 recovery-checkpoints).
- The exact engine's small-sample recovery is the covered `V3-NEFFECT-REML` result. The matrix-free
  engine's added claim is only that its Monte-Carlo approximation **reproduces** that exact fit.
