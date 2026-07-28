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

Measured crossover — Apple Mac Studio, julia 1.12.6, single-thread, random-mating high-fill
pedigrees, **median of 3 timed runs** after a discarded warm-up. A MEASUREMENT on one machine, NOT
a performance claim, NOT a CI gate. Source: `sim/matrix_free_crossover_benchmark.jl` → committed
`sim/matrix_free_crossover.tsv` (which also carries per-cell min/max and peak RSS):

| q | fill `nnz(L)/n` | `fit_ai_reml` | `fit_matrix_free_reml` | ratio | agreement with the exact optimum |
|---|---|---|---|---|---|
| 1 000 | 50 | 0.22 s | 1.73 s | 0.13× (exact wins) | 1.7e-2 |
| 2 000 | 77 | 1.05 s | 2.88 s | 0.37× (exact wins) | 3.0e-3 |
| 5 000 | 151 | 25.0 s | 9.12 s | **2.74×** | 4.7e-3 |
| 10 000 | 262 | 231.4 s | 13.9 s | **16.59×** | 4.7e-3 |

Run-to-run spread is small relative to the effect (q=10 000 exact: median 231.4 s, range
[229.5, 234.0]; matrix-free 13.94 s, range [13.93, 14.06]), so the crossover is not a timing
artifact. The single-run figures this table replaces (0.38× / 2.80× / 15.32×) came from a scratch
script and are superseded — see "Corrections" below.

The exact path grows super-linearly in fill; the matrix-free path roughly linearly. The mechanism is
the one F0 identified: at q=20 000 the sparse Cholesky costs 0.35 s but the per-iteration Takahashi
selected inverse costs 381 s. F6 removes the **selected inverse**, not the factorization.

## What this does NOT establish (read this before citing any number above)

- **It is not recovery-to-truth.** Every leg — the ASReml one included — compares against another
  **estimator**. No pre-declared known-truth bias/MCSE gate was run. This is the leg that matters
  most, and it remains open.
- **The external comparator IS now discharged.** ASReml-R 4.2.0.482 (R 4.6.1) agrees with the exact
  `fit_ai_reml` to **1.31e-7 / 8.07e-8**, and is centred on the matrix-free across-seed mean at
  0.51/0.49 SD (`nprobe`=128) → 0.33/0.30 SD (`nprobe`=512). ASReml was handed the **pedigree**, not
  our `Ainv`, and built its own inverse — so the Henderson construction is validated too, not just
  the optimiser. **Estimand only; no ASReml timing recorded** (§4 fence).
- **No evidence above `n = 10 000`.** This is the weakest link in the slice, and the reason the
  `:auto` divert was withheld: a route firing at `n > 20 000` on a threshold measured at n=5000
  would have been auto-selecting a stochastic estimator in a regime never measured.
- **The estimator is STOCHASTIC.** Its fixed point is the exact optimum perturbed by Monte-Carlo
  error (∝ `1/√nprobe`), deterministic given `seed`. `nprobe = 64` is untuned — no study relates
  `nprobe` to variance-component error at scale.
- No calibrated intervals, no `>2` components, no non-Gaussian, not wired into the R bridge.

A covered flip OWES: the pre-declared recovery gate at tail scale, a spawned **Rose** audit (G8),
the R bridge, and maintainer **G10**. The external-comparator leg is discharged; recovery-to-truth
is not, and it is the one that decides whether this estimator is trustworthy rather than merely
consistent with our other one.

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

## Corrections applied after the first landing (2026-07-28, same day)

Three defects in the originally-committed slice, found by post-landing recon and fixed:

1. **The numbers did not trace to a committed script.** `sim/matrix_free_crossover_benchmark.jl`
   was written but **never run**; the figures in the docs came from a scratch file in a job tmp
   directory. The repo rule is that every number traces to a committed script
   (`docs/design/17-wave-F-foundation-and-genomic-gpu.md:59-60`). The harness has now been run and
   `sim/matrix_free_crossover.tsv` is committed. **The numbers moved** — most visibly 15.32× →
   16.59× at q=10 000 — which is precisely why the rule exists.
2. **Single runs, not median-of-3.** The harness now follows the house convention
   (`sim/cpu_fit_benchmark.jl:167`) and records min/max alongside the median.
3. **The machine was mis-attributed.** The capability row said "local psychdhcp68-class machine",
   copied from the F0 doc. The run was on an Apple Mac Studio. Corrected everywhere.

A fourth change is an owner decision rather than a defect: the `:auto` divert to the matrix-free
fitter was **removed** — see below.

## Design decisions and rationale

- **The matrix-free fitter is OPT-IN ONLY; `:auto` never selects it** (owner decision, 2026-07-28).
  The first landing routed `:auto` to it at `n > 20 000` and fill > 150. That threshold was measured
  at n=5000, so the route would have fired *only* in a regime where the fitter had never been
  measured — auto-selecting a stochastic estimator on the strength of a number obtained somewhere
  else. `_auto_reml_route` no longer accepts a matrix-free threshold argument at all, and a
  `MethodError` test pins that, so re-wiring the divert cannot pass silently.
  `_AUTO_MATRIX_FREE_FILL_THRESHOLD = 150.0` remains as a **recorded but unwired** anchor.
- **Re-wiring it is gated on a pre-declared recovery gate at `n > 20 000`** — the tail-scale gate in
  the follow-up plan.
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
- `test/runtests.jl` — 2 new testsets (32 tests); updated the `length(validation)` count assertion
  55 → 56 and added an id check.
- `docs/src/fitting-at-scale.md` — new single-effect section, corrected the falsified `K=1` claim,
  corrected the stale loglik claim, extended the honest-scope list.
- `docs/src/api.md`, `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`.

## Checks

| Check | Result |
|---|---|
| Full `Pkg.test()` — run 1 | **FAILED**: `length(validation) == 55` vs 56. My earlier grep saw the `validation_status()` call but not the count assertion two lines below it; I had concluded there was no count assertion. Suite aborts at the first failing testset, so nothing after it ran. |
| Full `Pkg.test()` — run 2 (pre-fence) | **PASSED**, exit 0, zero failures suite-wide; new testsets 19/19 + 8/8 = 27. |
| Full `Pkg.test()` — run 3 (post-fence, post-ASReml) | **PASSED**, exit 0, `Testing HSquared tests passed`, zero failures/errors suite-wide; new testsets **19/19 (fitter) + 13/13 (opt-in fence) = 32** — the count every status surface claims. Independently re-run and confirmed by the spawned Rose. |
| ASReml-R comparator | `Rscript comparator/run_asreml_matfree.R` exit **0** = AGREE |
| Crossover benchmark | `sim/matrix_free_crossover_benchmark.jl` → committed `sim/matrix_free_crossover.tsv` |
| `julia --project=docs docs/make.jl` | exit 0; 6 warnings, all pre-existing/environmental; no unresolved `@ref` (verified the new anchor in `docs/build/.documenter/`) |
| `bash tools/preamble_cap.sh` | CAP OK |
| `tools/status_cache.json` | refreshed 55 → **56 rows**, `public_covered_count` unchanged at **5** (it feeds the published mission-control `status.json`; F6 had left it stale — Rose C5) |

## Active lenses and spawned agents

- **Spawned subagents:** one `Explore` agent (read-only recon of the comparator harness, the ASReml
  fence, the gate protocol, and toolchain availability) — that recon is what surfaced the
  provenance gap and the fact that ASReml-R is installed while sommer is not.
- **Rose: OWED, not yet run.** At first landing I judged none owed, on the grounds that nothing was
  flipped and no public claim made. That was **under-stated**: `docs/src/fitting-at-scale.md` is
  published Documenter output and now carries a speed-up table, which the routing table's "any
  public claim / pre-publish / repo-visibility → Rose (mandatory)" trigger covers. It has not fired
  only because the commits are local and PR #274 is draft. A real spawned Rose is required before
  this branch is pushed.
- **Review lenses (perspectives, not spawned):** Gauss/Karpinski (matrix-free numerics, router
  cost), Curie/Fisher/Mrode (what the evidence does and does not support, comparator design).

## Next steps

1. **Pre-declared recovery gate at tail scale** (`n > 20 000`, high fill) — the leg that decides
   whether this estimator is trustworthy rather than merely consistent with our other one. Freeze
   before running, F5 pattern. Needs cluster compute; Totoro is Shinichi's, so this needs Szymek's
   own allocation or an access request.
2. **At-scale external comparator** — the ASReml run is q=2000, below the crossover. A comparator
   in the high-fill exact-infeasible tail is still owed (Rose C4b; the `V3-NEFFECT-MATFREE-FIT`
   precedent). Note the natural limit: any external tool forms the MME too, so far enough into the
   tail there is no external oracle by construction — the same reasoning doc-25 records for the
   multi-effect twin.
3. **`nprobe` vs error study** at scale, to replace the untuned default of 64.
4. **Re-wiring `:auto`** is gated on (1). Until then the fitter stays opt-in.
5. Unchanged and carried forward: the R bridge for BOTH staged fitters, and owner G10 for
   `fit_eigen_reml` / `fit_ai_reml`.
6. Pre-existing, not F6-caused: `docs/src/validation-status.md`'s hand-maintained "Current Rows"
   table has drifted from `validation_status()` (it omits `V1-EIGEN-REML`, `V6-ORDINAL`,
   `V6-GAMMA`, and now `V1-MATFREE-REML`), while the `@example` block on the same page renders all
   56 live rows. Worth its own slice (Rose).
