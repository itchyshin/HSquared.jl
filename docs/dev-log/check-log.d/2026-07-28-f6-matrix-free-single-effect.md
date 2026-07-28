# Check log — F6: matrix-free Monte-Carlo REML for the single-effect animal model

**2026-07-28 · Claude lane · branch `codex/2026-07-13-v07-performance-localization` · Szymek (owner-directed)**

Discharges the F6 lever the Wave-F F0 decision DEFERRED
(`docs/dev-log/recovery-checkpoints/2026-07-24-f0-adversarial-highfill-decision.md`): the high-fill,
`n > 20 000` tail where `fit_ai_reml` walls and the eigen-once rescue is past its dense cap.

## What was checked

| Check | Command / method | Result |
|---|---|---|
| Working ref | `git checkout` the live branch | local checkout was on `main`, **153 commits behind**; the 07-24 arc is branch-only (see Finding 1) |
| K=1 feasibility probe | scratch `f6_k1_smoke.jl`, local, high-fill random-mating pedigrees | the EXISTING v0.8-S2 multi-effect matrix-free fitter runs UNMODIFIED as `K=1` and recovers `fit_ai_reml` (see Finding 2) |
| Crossover measurement (scratch, superseded) | scratch harness, single runs | exact÷matrix-free 0.38× / 2.80× / 15.32× — **did not trace to a committed script; superseded** |
| Crossover measurement (committed) | `sim/matrix_free_crossover_benchmark.jl` → `sim/matrix_free_crossover.tsv`, median of 3, Mac Studio | exact÷matrix-free **0.13× / 0.37× / 2.74× / 16.59×** at fill 50 / 77 / 151 / 262; agreement 1.7e-2 / 3.0e-3 / 4.7e-3 / 4.7e-3; run-to-run spread small vs the effect |
| New API smoke | scratch `f6_api_smoke.jl` | direct call, both `target` spellings, determinism, extractors, `compute_loglik=false`, router branches, guards — all as designed |
| New testsets (isolated) | `julia --project=. <extracted testsets>` | 27/27 pre-fence; **32/32 post-fence** (19 fitter + 13 opt-in fence) |
| Full suite (run 1) | `julia --project=. -e 'using Pkg; Pkg.test()'` | **FAILED** — `length(validation) == 55` vs 56 (Finding 4). Suite aborts at the first failing testset, so nothing after it ran |
| Full suite (run 2) | same, after updating the count assertion 55 → 56 | **PASSED**, exit 0, `Testing HSquared tests passed`, zero failures/errors suite-wide; new testsets 19/19 + 8/8 |
| Preamble cap | `bash tools/preamble_cap.sh` | **CAP OK** — 8673 B / 14000 B (~2168 tok), 1 snapshot entry / cap 1 |
| `:auto` opt-in fence (owner decision) | routing testset re-inverted | 13/13 — `:auto` yields only exact fitters across n × fill × `Z≠I`; `MethodError` pins that the matrix-free threshold is not a routing knob |
| ASReml-R external comparator | `julia comparator/prepare_asreml_matfree.jl && Rscript comparator/run_asreml_matfree.R` | **AGREE, exit 0** — vs exact `fit_ai_reml` 1.31e-7/8.07e-8; vs matrix-free 0.51/0.49 SD (nprobe 128) → 0.33/0.30 SD (nprobe 512). ESTIMAND only, no timing recorded |
| Docs build | `julia --project=docs docs/make.jl` | exit 0; **6 warnings, all pre-existing/environmental** (38 undocumented internal helpers; logo/favicon/deploy). No unresolved `@ref` — verified the new section cross-reference compiled to a real anchor in `docs/build/.documenter/fitting-at-scale.md` |

## Findings worth carrying forward

1. **The resume prompt's entrypoint did not exist on the checked-out ref.** `main` stops at
   2026-07-13; the entire 07-14→07-25 arc, including
   `docs/dev-log/handover/2026-07-24-claude-handover.md`, lives only on
   `codex/2026-07-13-v07-performance-localization`. Consequence: the session's auto-loaded
   `CLAUDE.md`/`AGENTS.md` was the **stale 2026-07-08** snapshot until the branch was checked out.
   The 4 "foreign never-commit" files named in that handover are also stale as a fence — 3 of the 4
   were LANDED by `2278811c` (2026-07-25); only the quarantined sim file remains.
2. **F6 was mis-scoped as "build a matrix-free fitter"; it was an adapter + a router branch.** The
   matrix-free machinery (`mc_reml_block_traces`, `fit_multi_effect_mc_reml`, SLQ loglik,
   matrix-free AI matrix) already existed for `K ≥ 2` and ran for `K = 1` with no change. NO new
   numerics were written. What was missing was (a) an `AnimalModelFit`-returning single-effect face
   and (b) a route to it.
3. **`fit_multi_effect`'s `:auto` still hard-codes `K == 1 → :exact`** on the comment "the
   animal-model MME stays sparse-feasible to very large `q`" — the assumption F0 falsified. NOT
   changed here (out of scope, and it is that function's documented contract); flagged in
   `docs/src/fitting-at-scale.md` with a pointer to `fit_animal_model(target = :auto)`.
4. **A stale doc claim was corrected in passing:** `fitting-at-scale.md` said a matrix-free REML
   loglik "is not yet implemented". `matrix_free_reml_loglik` has existed since v0.8-S2 (V8.1).

## Verdict

F6 implemented as an **opt-in** fitter. `fit_matrix_free_reml` recovers the `fit_ai_reml` optimum
within Monte-Carlo error and overtakes it by **16.59×** at fill 262 (median of 3, one Mac Studio —
a measurement, not a performance claim), and ASReml-R independently confirms the estimand at
validation scale. **But this is cross-estimator agreement, NOT recovery-to-truth** — ASReml is
another estimator, and no pre-declared known-truth gate has been run. There is **no measurement
above `n = 10 000`**, which is why the `:auto` divert was withheld rather than shipped on an
extrapolated threshold.

## Fences

`public_covered_count` stays **5** · capability-status row = **experimental**, nothing flipped ·
debt row `V1-MATFREE-REML` = **partial** · `:auto` never selects the stochastic fitter (owner
decision; opt-in only) · **no ASReml timing recorded or implied — the §4 honesty fence stands** ·
no R-lane file touched · D1 PAUSED and untouched · the quarantined
`sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` left alone · every timing here is a
MEASUREMENT on one machine, not a performance claim and not a CI gate.

**Rose (G8): RUN — real spawned `rose-systems-auditor`, verdict CLEAR-WITH-CHANGES, all changes
applied.** At first landing I judged none owed (no flip, no public claim); that was under-stated,
since `docs/src/fitting-at-scale.md` is published Documenter output carrying a speed-up table.
Rose confirmed the two known repairs (provenance, machine attribution), verified the §4 ASReml
fence holds "including by juxtaposition", and found five further defects — the most serious a
**push-blocker**: the published `fit_matrix_free_reml` docstring still documented the removed
`:auto` route, i.e. a public page asserting a safety fence did not exist. Also: a mixed-machine
fill table on the published page (the same defect as Finding 2, one table higher), a "~60×" that
was arithmetic from a different row than the sentence named (correct: ~660×), a mis-cited doc-16
provision plus an over-broad comparator discharge, and a stale `tools/status_cache.json` feeding
the published status page. A FRESH promote-specific Rose is still required at any covered flip.

Evidence: `docs/dev-log/after-task/2026-07-28-f6-matrix-free-single-effect.md` ·
`sim/matrix_free_crossover_benchmark.jl` · `src/iterative_solve.jl` (`fit_matrix_free_reml`) ·
`src/likelihood.jl` (`_auto_reml_route`, `_AUTO_MATRIX_FREE_FILL_THRESHOLD`) · `test/runtests.jl`
(2 new testsets, 32 tests) · `docs/src/fitting-at-scale.md`.
