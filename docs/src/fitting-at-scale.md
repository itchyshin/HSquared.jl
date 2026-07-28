# Fitting at scale: exact vs matrix-free

`HSquared.jl` has **two** engines for the `K`-independent-random-effect mixed model, and
[`fit_multi_effect`](@ref) chooses between them by feasibility. This page explains the choice,
the accuracy-vs-feasibility trade, and how to control it.

!!! warning "Experimental"
    Everything on this page is experimental and validation-scale. The public default fit path is
    the univariate Gaussian animal model; these multi-effect engines are opt-in.

## The two engines

| | exact | matrix-free |
|---|---|---|
| function | [`fit_sparse_multi_effect_aireml`](@ref) | [`fit_multi_effect_mc_reml`](@ref) |
| method | sparse AI-REML (exact gradient from a Cholesky **selected inverse**) | Monte-Carlo EM-REML (matrix-free solves + a **Hutchinson stochastic trace**) |
| forms/factorizes `C`? | **yes** — a sparse Cholesky each iteration | **no** — only "matrix × vector" |
| accuracy | exact | approximate — the gradient carries a Monte-Carlo standard error |
| where it wins | small–moderate size (exact, few iterations) | very large size, where the factorization is infeasible |

**Why two?** With *two or more* random effects (a contemporary-group, maternal, or
permanent-environment term alongside the animal effect) the sparse Cholesky **fills in** — the
factor becomes far denser than `C` — and past roughly `10⁵` individuals it becomes infeasible in
memory and time (measured: the direct multi-effect path is already ~quadratic by `q ≈ 50 000`; a
METIS reordering did **not** fix it). The matrix-free engine never forms or factorizes `C`, so it
has no fill wall — it has stayed feasible fitting `K = 3` models to 200 000 individuals in testing (the matrix-free *solve* it is built on reaches a million) — but it pays
with Monte-Carlo noise in the variance-component gradient.

A *single* random effect is usually the easy case — but **not always**, and the difference is
**fill-in, not size**. See the next section.

This is the same accuracy-for-feasibility trade a variational approximation makes: you reach for
the approximate engine **only** where the exact one cannot run.

## The single-effect animal model: size is not the problem, fill is

For the univariate animal model the same two-engine choice exists —
[`fit_ai_reml`](@ref) (exact) versus [`fit_matrix_free_reml`](@ref) (matrix-free) — and
[`fit_animal_model`](@ref) with `target = :auto` picks between them (plus the eigen-once path).

The intuition "one random effect, so the factorization stays sparse" is **only true for
well-structured pedigrees**. What decides cost is the fill-in of the MME Cholesky, `nnz(L)/n`:

| pedigree | fill `nnz(L)/n` | `fit_ai_reml` | machine |
|---|---|---|---|
| half-sib, q = 300 000 | ~17–19 | 2.3 s | DRAC (`fir`) |
| random-mating, q = 10 000 | 262 | 132 s | Totoro |
| random-mating, q = 20 000 | 471 | 1 529 s (~25 min) | Totoro |

A high-fill pedigree at **1/15th the size** costs ~660× more. Field data from livestock and most
managed populations is low-fill and needs none of this; densely interconnected pedigrees — small
founder bases, random mating, deep overlapping generations — are where it bites.

!!! warning "These rows are from different machines, and so is the table further down"
    The three rows above come from two clusters
    (`docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`), and the
    crossover table later on this page is a Mac Studio. **Do not read them as one series.** The
    same fit — `fit_ai_reml` at q = 10 000, fill 262 — is 132 s on Totoro and 231 s on the Mac
    Studio. Each table is internally consistent; across tables only the *shape* carries meaning.

The mechanism is specific and worth knowing, because it is *not* the factorization. At
q = 20 000 the sparse Cholesky takes 0.35 s; the **Takahashi selected inverse** that supplies
AI-REML's exact score trace takes 381 s, and it is recomputed every iteration. That single term
is the wall. [`fit_matrix_free_reml`](@ref) replaces it with a matrix-free Hutchinson stochastic
trace and PCG solves, so `C` is never assembled or factorized during the fit:

```julia
fit = fit_animal_model(spec; target = :matrix_free)     # or fit_matrix_free_reml(spec)
```

Measured crossover on high-fill pedigrees — a measurement on one machine, not a performance
claim. Timings are the **median of 3 runs** after a discarded warm-up, single-threaded on an Apple
Mac Studio (julia 1.12.6). Reproduce with `sim/matrix_free_crossover_benchmark.jl`; the committed
numbers, including per-cell min/max, are in `sim/matrix_free_crossover.tsv`:

| q | fill | exact | matrix-free | speed-up | agreement with the exact optimum |
|---|---|---|---|---|---|
| 1 000 | 50 | 0.22 s | 1.73 s | 0.13× (exact wins) | 1.7e-2 |
| 2 000 | 77 | 1.05 s | 2.88 s | 0.37× (exact wins) | 3.0e-3 |
| 5 000 | 151 | 25.0 s | 9.12 s | **2.74×** | 4.7e-3 |
| 10 000 | 262 | 231.4 s | 13.9 s | **16.6×** | 4.7e-3 |

The exact path grows super-linearly in fill; the matrix-free one roughly linearly. Note the
agreement column: it is a Monte-Carlo *approximation*, not equality — see
[Reading the Monte-Carlo noise](@ref) below.

!!! warning "The matrix-free fitter is opt-in — `:auto` will not choose it for you"
    `target = :auto` routes only between the two **exact** fitters. It never selects
    `fit_matrix_free_reml`, and you must ask for it explicitly.

    That is deliberate, and it is a fence rather than an oversight. The regime a route would serve
    — high fill past the dense eigen cap — is exactly the regime in which this fitter has **not**
    been measured: the crossover above was measured at `n ≤ 10 000`, so routing on it at
    `n > 20 000` would be extrapolation. Handing you a Monte-Carlo estimate you did not ask for,
    on the strength of a number measured somewhere else, is a worse failure than being slow.

    Wiring it into `:auto` needs a pre-declared recovery gate in that tail first. Until then:
    `fit_animal_model(spec; target = :matrix_free)`.

## Choosing automatically (multi-effect)

```julia
fit = fit_multi_effect(y, X, effects)                 # method = :auto (the default)
```

`:auto` routes on feasibility:

- a **single** random effect (`K = 1`), or `N = p + Σqᵢ ≤ direct_max_n` → **exact**;
- otherwise → **matrix-free**, printing a one-line `@info` that it switched and that the estimates
  carry a Monte-Carlo standard error.

!!! warning "`fit_multi_effect`'s `K = 1` shortcut assumes low fill"
    That `K = 1` → exact rule is a *structural* assumption, and a high-fill single-effect pedigree
    breaks it (see the previous section). For the univariate animal model prefer
    [`fit_animal_model`](@ref) with `target = :auto`, which routes on measured fill rather than on
    `K`; or pass `method = :matrix_free` here explicitly.

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
engine ran. The two result shapes differ: the matrix-free result adds a `trace_mcse`, and its
`loglik` is `NaN` unless you ask for it with `compute_loglik = true` — the matrix-free REML
log-likelihood needs a stochastic log-determinant ([`matrix_free_reml_loglik`](@ref), estimated by
stochastic Lanczos quadrature), so it carries its own Monte-Carlo error, reported as `loglik_mcse`.

The single-effect [`fit_matrix_free_reml`](@ref) differs here: it returns the standard
`AnimalModelFit`, and its log-likelihood is **exact**, not stochastic. It can afford one
[`sparse_reml_loglik`](@ref) call at the converged estimate because that costs two Choleskys and
**no** selected inverse — and the selected inverse, not the factorization, was the wall it exists
to avoid. Set `compute_loglik = false` to skip even that.

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
- The same fence applies to the single-effect [`fit_matrix_free_reml`](@ref) (`V1-MATFREE-REML`,
  **experimental**). It is validated to recover the `fit_ai_reml` optimum within Monte-Carlo error
  on committed high-fill fixtures — and that is agreement with *another estimator*, not
  recovery-to-truth. A pre-declared known-truth recovery gate at tail scale and an external
  same-estimand comparator are **owed** before any covered claim. It is not wired into the R
  bridge and moves no public capability count.
- Every timing on this page is a **measurement on the machine that ran it**, not a performance
  claim or a competitive benchmark, and none of it is a CI gate.
- Both `:auto` fill thresholds (60 for eigen-once, 150 for matrix-free) are **first-pass scalar
  heuristics**. The true crossover is a joint fill × `n` surface; the 150 anchor was measured at
  `n = 5 000` and extrapolated into the `n > 20 000` tail it serves. Mapping that surface properly
  is owed work.
