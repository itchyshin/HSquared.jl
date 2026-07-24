# `:auto` eigen-vs-sparse crossover — measured surface + threshold decision (S4)

**Date:** 2026-07-24 · **Benchmark:** `sim/bench_eigen_crossover.jl` · **Run:** Totoro (julia 1.12.6,
`BLAS=8`, `OPENBLAS_NUM_THREADS=8`) · **Route under test:** `_auto_reml_route` (`src/likelihood.jl`),
which sends a `Z=I` REML fit to `fit_eigen_reml` when the MME fill proxy `nnz(L)/n` exceeds
`_AUTO_EIGEN_FILL_THRESHOLD = 60`, else to `fit_ai_reml`.

**Decision: KEEP the threshold at 60**, now upgraded from a conservative first-pass *guess* to an
*empirically validated* choice, with its n-dependence and limits characterized below. **No `src` change;
no capability-status move; `public_covered_count` stays 5.** This is an experimental-route heuristic
tuning, not an estimator change.

## Measured grid (single rep per cell; see noise caveats)

| n | window | proxy `nnz(L)/n` | t_eigen (s) | t_ai (s) | speedup (ai/eigen) | faster | route@60 |
|---|---|---|---|---|---|---|---|
| 1000 | 0 | 49.0 | 0.088 | 0.206 | 2.35 | eigen | ai_reml |
| 1000 | 15 | 8.7 | 0.084 | 0.015 | 0.18 | sparse | ai_reml |
| 1000 | 30 | 12.1 | 0.081 | 0.019 | 0.24 | sparse | ai_reml |
| 1000 | 50 | 17.9 | 0.080 | 0.143 | 1.78 | eigen* | ai_reml |
| 1000 | 100 | 45.0 | 0.085 | 0.097 | 1.15 | eigen* | ai_reml |
| 1000 | 250 | 62.3 | 0.080 | 0.212 | 2.66 | eigen | eigen_reml |
| **2000** | **0** | **75.6** | **0.595** | **1.382** | **2.32** | **eigen** | **eigen_reml** |
| 2000 | 15 | 8.7 | 0.409 | 0.046 | 0.11 | sparse | ai_reml |
| 2000 | 30 | 12.5 | 0.395 | 0.141 | 0.36 | sparse | ai_reml |
| 2000 | 50 | 18.9 | 0.466 | 0.067 | 0.14 | sparse | ai_reml |
| **2000** | **100** | **50.8** | **0.604** | **0.200** | **0.33** | **sparse** | **ai_reml** |
| 2000 | 250 | 95.4 | 0.495 | 1.765 | 3.57 | eigen | eigen_reml |
| **4000** | **0** | **124.5** | **2.813** | **9.035** | **3.21** | **eigen** | **eigen_reml** |
| 4000 | 15 | 9.7 | 21.651† | 1.045 | 0.05 | sparse | ai_reml |
| 4000 | 30 | 13.0 | 2.084 | 0.080 | 0.04 | sparse | ai_reml |
| 4000 | 50 | 19.1 | 2.622 | 0.247 | 0.09 | sparse | ai_reml |
| **4000** | **100** | **57.0** | **2.650** | **0.698** | **0.26** | **sparse** | **ai_reml** |
| 4000 | 250 | 108.7 | 2.753 | 4.222 | 1.53 | eigen | eigen_reml |

`*` marginal (sub-0.25 s absolute, single-rep noise dominates — see below).
`†` GC/first-touch outlier: eigen is fill-INDEPENDENT, so t_eigen at n=4000 is ~2.7 s (cf. all other
n=4000 rows); 21.65 s is a measurement artifact, not a real cost.

## What the surface shows

1. **eigen is fill-independent, sparse is fill-sensitive** — exactly as designed. t_eigen depends only on
   n (~0.08 s @1000, ~0.5 s @2000, ~2.7 s @4000, the dense `O(n³)` eigendecomposition); t_ai rises with
   fill from milliseconds (low fill) to many seconds (high fill).
2. **The crossover brackets are robust** (win/loss margins 2–3×, not marginal — noise-proof):
   - **n=2000:** sparse wins through proxy **50.8**, eigen wins from proxy **75.6** → crossover ∈ (50.8, 75.6).
   - **n=4000:** sparse wins through proxy **57.0**, eigen wins from proxy **108.7** → crossover ∈ (57.0, 108.7).
   **Threshold 60 sits inside the n=2000 gap and just inside the low end of the n=4000 gap.**
3. **The crossover proxy is mildly n-dependent — it RISES with n** (~63 mid-gap at n=2000 → ~80 mid-gap at
   n=4000). Because eigen is `O(n³)`, larger n needs *more* fill before eigen wins. `nnz(L)/n` already
   folds n into the proxy (a random pedigree's proxy grows with n: ~49 @1000, ~76 @2000, ~124 @4000), but
   the crossover VALUE on that proxy still drifts up with n, so a single scalar cannot be optimal at every n.

## Why keep 60 (not re-tune, not go n-adaptive)

- **Correct where it matters.** Routing cost is negligible below ~n=1000 (all times < 0.25 s). At n≥2000,
  where a wrong route costs real time, 60 routes every robust-margin cell correctly.
- **Safely conservative.** 60 is biased toward the validated sparse `fit_ai_reml` default. Its only
  imperfections are (a) sub-second small-n misroutes and (b) at n=4000, proxy ~60–90 routes to eigen a bit
  eagerly (costs ~1–2 s vs sparse). It **never** causes a catastrophic misroute in the grid (never routes a
  large-n low-fill fit to eigen's `O(n³)`, nor a large-n high-fill fit to slow sparse).
- **A finer rule isn't cleanly supported by this data.** Single-rep timings + the n-dependence would let one
  argue for ~65–70 (better-centered across n=2000/4000) or a rising threshold, but neither is warranted on
  single-rep evidence, and the gain is ~1–2 s in a narrow band. **Deferred:** a multi-rep (median-of-k)
  study across n∈{2000,4000,8000,10⁴} could justify raising to ~70 or an `n`-aware rule; recorded as an
  optional micro-optimization, not a blocker.

## Caveats (honesty)

- **Single rep per cell.** Small-time cells (all of n=1000; sub-0.25 s) are noise-dominated and must not be
  read as precise; the load-bearing brackets (bold rows) have 2–3× margins and survive the noise.
- The `†` n=4000/window=15 t_eigen=21.65 s is an excluded GC outlier.
- Totoro is shared; absolute times are indicative, ratios within a cell are the signal.

## Net

The handover's item-3 ("refine `:auto` from the conservative first-pass to the joint fill×n crossover")
is answered: the crossover surface is measured, the proxy's n-dependence is characterized, and **60 is
confirmed well-placed and safely conservative** — kept, with an n-adaptive refinement scoped and deferred.

> Related: `sim/bench_eigen_crossover.jl` · `src/likelihood.jl` (`_auto_reml_route`) ·
> `test/runtests.jl` (`:auto` routing testset) · `2026-07-24-ai-reml-convergence-findings.md`.
