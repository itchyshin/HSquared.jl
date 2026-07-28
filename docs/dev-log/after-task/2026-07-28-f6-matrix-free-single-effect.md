# After-task — F6: matrix-free Monte-Carlo REML for the single-effect animal model

**Date:** 2026-07-28 · **Lane:** Julia engine (`HSquared.jl`) · **Branch:**
`codex/2026-07-13-v07-performance-localization` · **Owner:** Szymek (directed this session) ·
**Commits:** uncommitted at time of writing.

## Task goal

Implement **F6** — the lever the Wave-F F0 decision identified and DEFERRED
(`docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`): wire the
already-benchmarked matrix-free PCG machinery into the animal-model fit loop, for the regime F0
measured infeasible (HIGH fill-in AND `n` past the dense eigen cap, where `fit_ai_reml` walls at
1529 s / q=20 000 and `fit_eigen_reml` is unavailable).

Fences carried in: `public_covered_count` stays **5**; no capability flip without a FRESH Rose +
owner G10; D1 PAUSED (D-68); TMB deferred; R twin not edited; the quarantined sim file untouched.

## Outcome (met, with the scope honestly narrowed by what the evidence supports)

**F6 is implemented, routed, tested, and documented — as `experimental`. Nothing flipped.**

The task was **mis-scoped going in**, and correcting that is the main result. F6 was framed as
"wire the matrix-free PCG into the AI-REML fit loop", implying new numerics. In fact the v0.8-S2
matrix-free machinery (`mc_reml_block_traces`, `fit_multi_effect_mc_reml`, `matrix_free_reml_loglik`,
`matrix_free_reml_information`) already existed for `K ≥ 2`, and a feasibility probe showed it runs
**unmodified** for the single-effect animal model as `K = 1`, recovering `fit_ai_reml`. So the real
gap was (a) an `AnimalModelFit`-returning single-effect face and (b) a route to it. **No new
numerics were written.**

Measured crossover (local, single-thread, random-mating high-fill pedigrees; a MEASUREMENT on one
machine, NOT a performance claim, NOT a CI gate):

| q | fill `nnz(L)/n` | `fit_ai_reml` | `fit_matrix_free_reml` | ratio | agreement with the exact optimum |
|---|---|---|---|---|---|
| 2 000 | 77 | 1.06 s | 2.78 s | 0.38× (exact wins) | 3.0e-3 |
| 5 000 | 151 | 24.7 s | 8.8 s | **2.80×** | 4.7e-3 |
| 10 000 | 262 | 220.1 s | 14.4 s | **15.32×** | 4.7e-3 |

The exact path grows super-linearly in fill; the matrix-free path roughly linearly. The mechanism is
the one F0 identified: at q=20 000 the sparse Cholesky costs 0.35 s but the per-iteration Takahashi
selected inverse costs 381 s. F6 removes the **selected inverse**, not the factorization.

## What this does NOT establish (read this before citing any number above)

- **It is not recovery-to-truth.** Every leg compares against `fit_ai_reml`. That is agreement with
  **another estimator**. No pre-declared known-truth bias/MCSE gate was run.
- **No external comparator.** No `sommer` / BLUPF90 same-estimand leg.
- **No evidence at the tail the route actually serves.** All measurements are `n ≤ 10 000`; the
  `:auto` route fires only at `n > 20 000`. The fill threshold 150 is measured at n=5000 and
  **extrapolated** into that tail. This is the weakest link in the slice.
- **The estimator is STOCHASTIC.** Its fixed point is the exact optimum perturbed by Monte-Carlo
  error (∝ `1/√nprobe`), deterministic given `seed`. `nprobe = 64` is untuned — no study relates
  `nprobe` to variance-component error at scale.
- No calibrated intervals, no `>2` components, no non-Gaussian, not wired into the R bridge.

A covered flip OWES: the pre-declared recovery gate at tail scale, an external comparator, a
spawned **Rose** audit (G8), the R bridge, and maintainer **G10**.

## Findings beyond the task

1. **The checked-out ref was wrong, and silently so.** The session began on `main`, **153 commits
   behind** the live branch. The resume prompt's entrypoint
   (`docs/dev-log/handover/2026-07-24-claude-handover.md`) does not exist on `main`, nor does the
   `native-engine-arc/` directory or either staged fitter's evidence. Because `CLAUDE.md` imports
   `AGENTS.md`, the session's auto-loaded doctrine was the **stale 2026-07-08** snapshot. Rehydration
   caught it only because the handover file was missing. **The one-command resume in that handover
   does not check out the branch it documents** — worth fixing in the next handover.
2. **The "4 foreign dirty files" fence is stale.** Commit `2278811c` (2026-07-25) LANDED three of
   them onto the branch; only `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` remains
   quarantined.
3. **`fit_multi_effect`'s `:auto` still hard-codes `K == 1 → :exact`**, justified in-comment by "the
   animal-model MME stays sparse-feasible to very large `q`" — precisely the assumption F0
   falsified. NOT changed (out of scope; it is that function's documented contract), but flagged in
   the docs with a pointer to `fit_animal_model(target = :auto)`, which routes on measured fill.
4. **A stale doc claim corrected:** `fitting-at-scale.md` stated a matrix-free REML loglik "is not
   yet implemented"; `matrix_free_reml_loglik` has existed since v0.8-S2 (V8.1).
5. **`gh` is not installed on this machine** — CI and PR #274 state could not be checked from here.

## Design decisions and rationale

- **The `:auto` route fires ONLY at `n > max_dense_n` AND fill > 150.** Below the dense cap the
  router's behaviour is byte-unchanged. Diverting a fit the *validated exact* path can handle to a
  *stochastic* estimator would be a silent estimator substitution — a worse failure than being slow.
  Users can force it anywhere with `target = :matrix_free`.
- **Threshold 150 is anchored to the lowest fill at which matrix-free was MEASURED to win** (q=5000,
  2.80×), not invented — and its extrapolation into the tail is documented as owed work, in the code
  comment, the capability row, the debt row, and the public docs.
- **The loglik is EXACT, not stochastic.** `fit_matrix_free_reml` calls `sparse_reml_loglik` once at
  the converged estimate: two Choleskys and no selected inverse. That is affordable *precisely
  because* the selinv, not the factorization, was the wall. `compute_loglik = false` skips it.
- **The recovery test's rtol is 5e-2, deliberately loose.** A tight rtol on a stochastic estimator
  would assert something false. The test also pins that a *different* seed moves the estimate — i.e.
  it is genuinely Monte-Carlo, not accidentally deterministic.

## Files changed

New:
- `sim/matrix_free_crossover_benchmark.jl` — opt-in crossover harness (measures wall clock **and**
  agreement; a speed win that loses the optimum is not a win).
- `docs/dev-log/check-log.d/2026-07-28-f6-matrix-free-single-effect.md`.
- this report.

Modified:
- `src/iterative_solve.jl` — `fit_matrix_free_reml` (adapter over the `K=1` case).
- `src/likelihood.jl` — `_AUTO_MATRIX_FREE_FILL_THRESHOLD`, third route in `_auto_reml_route`,
  `_coerce_fit_target`, `fit_animal_model` dispatch + docstring routing table.
- `src/HSquared.jl` — export.
- `src/validation_status.jl` — `V1-MATFREE-REML` row (56 rows total).
- `test/runtests.jl` — 2 new testsets (27 tests); updated the `length(validation)` count assertion
  55 → 56 and added an id check.
- `docs/src/fitting-at-scale.md` — new single-effect section, corrected the falsified `K=1` claim,
  corrected the stale loglik claim, extended the honest-scope list.
- `docs/src/api.md`, `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`.

## Checks

| Check | Result |
|---|---|
| New testsets (isolated) | 27/27 pass |
| Full `Pkg.test()` — run 1 | **FAILED**: `length(validation) == 55` vs 56. My earlier grep saw the `validation_status()` call but not the count assertion two lines below it; I had concluded there was no count assertion. Suite aborts at the first failing testset, so nothing after it ran. |
| Full `Pkg.test()` — run 2 | **PASSED**, exit 0, `Testing HSquared tests passed`, zero failures/errors across the whole suite. The two new testsets: 19/19 (fitter, 1m13.8s) + 8/8 (router, 0.1s). |
| `julia --project=docs docs/make.jl` | exit 0; 6 warnings, all pre-existing/environmental; no unresolved `@ref` (verified the new anchor in `docs/build/.documenter/`) |

## Active lenses and spawned agents

- **Spawned subagents: NONE.** No Rose audit was run — none is owed, since no public claim is made
  and no promotion is attempted. A fresh Rose IS owed before any covered flip.
- **Review lenses (perspectives, not spawned):** Gauss/Karpinski (matrix-free numerics, router
  cost), Curie/Fisher (what the evidence does and does not support), Rose (the not-covered fences).

## Next steps

1. **Owner call:** is the extrapolated 150 threshold acceptable, or should the route stay
   force-only (`target = :matrix_free`) until measured at `n > 20 000`? The latter is the
   conservative reading of the doctrine.
2. **Pre-declared recovery gate at tail scale** + an external comparator — the two legs a covered
   flip needs. Both need compute beyond this laptop; Totoro is Shinichi's, so this needs Szymek's
   own allocation.
3. **`nprobe` vs error study** at scale, to replace the untuned default.
4. Unchanged and carried forward: the R bridge for BOTH staged fitters, and owner G10 for
   `fit_eigen_reml` / `fit_ai_reml`.
