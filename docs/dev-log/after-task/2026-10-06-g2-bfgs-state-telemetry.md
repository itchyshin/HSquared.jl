## 1. Goal

Add optional diagnostic telemetry for accepted Optim BFGS iterations, including the full gradient and inverse-Hessian state, without changing normal fit results. Validate the telemetry before further G2 diagnosis.

## 2. Implemented

`_arc1_fa_bfgs` now accepts an optional `optimizer_state_events` vector. Only when supplied, it enables Optim's stored extended trace. A postprocessor records each accepted iteration's parameters, gradient, inverse Hessian, step, reconstructed search direction, BFGS displacement, rounded coordinate displacement, gradient change, curvature, and inferred update/reset status. The default call still stores no trace.

Independent exact-source review passed on the final source and test hashes below. The review found and corrected a precision defect: Optim uses `alpha * direction` for its BFGS update, while subtracting stored coordinates can round differently. The telemetry now uses Optim's update displacement and retains coordinate subtraction separately.

## 3a. Decisions and Rejected Alternatives

- Kept the existing Optim BFGS implementation and all numerical acceptance/refusal rules unchanged.
- Used Optim's own extended trace rather than a copied optimizer implementation. This limits the diagnostic change to opt-in state retention.
- Classified reconstructed Hessian agreement with a floating-point tolerance. This is a consistency check, not bitwise reproduction of Optim's fused arithmetic.
- Replayed two previously consumed failure starts under a fresh exact-source admission, with telemetry enabled. These remain diagnostic replays and do not alter any study denominator.

## 4. Files Touched

- `src/arc1_fa.jl`
- `test/arc1_optimizer_contracts.jl`
- `docs/dev-log/check-log.d/2026-10-06-g2-bfgs-state-telemetry.log`
- `docs/dev-log/check-log.d/2026-10-06-g2-bfgs-state-telemetry.md`
- `docs/dev-log/after-task/2026-10-06-g2-bfgs-state-telemetry.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`

Other dirty files in the shared worktree belong to earlier or parallel Arc 1 work and were left untouched.

## 5. Checks Run

- Exact-source Astra review: PASS. Source SHA-256 `937b6c3eee3513819f2115e21e1e0cdf52805b7396742c0957667662ba39316f`; test SHA-256 `09ce900ae3a41ccb77f1767c140e4477a1d6b3aa8bb31172ede4264ce3e15133`.
- `JULIA_DEPOT_PATH=/private/tmp/hsq-arc1-telemetry-depot-20261006:/Users/z3437171/.julia JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. test/arc1_optimizer_contracts.jl`: exit 0, 497/497 passed in 17.7 seconds. Log SHA-256 `3c4fd0fdf86f6882727f8bbb0a755152c57bfae41e012e05c4251f71c1b361b0`.
- `python3 -B tools/arc1_manifest.py --validate-only`: exit 0; checked 644,480 unique outer and nested seed values. This was an integrity check only.
- `python3 ~/shinichi-brain/tools/arc_gate_lock.py verify LOOP/lanes/arc1-gaussian-reliability-20261002`: pass.
- `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --status --scope arc1-gaussian-reliability`: G2, G3, G4, G5, and G8 remain unmet. Four boxes are marked met; three have runnable checks without approval records, so the status command did not execute those checks.
- `bash tools/preamble_cap.sh` and scoped `git diff --check`: pass.
- Fresh Astra exact-source admission for the two retained-start replay: PASS. Both replay processes exited 0; total runtime 18.693 seconds; post-run sources matched. Result hashes and detailed counts are in the lane checkpoint and check log.

The first Julia invocation stopped before tests because the shared depot denied a compile-lock write. The successful run used a scratch-first depot. No test is reported as passed from the failed invocation.

## 6. Tests of the Tests

Synthetic trace cases cover positive-curvature update, non-positive-curvature skip, inverse-Hessian reset, inconsistent Hessian detection, missing trace metadata, and the `1e16` coordinate-rounding witness. The production integration case checks that traced and untraced fits return identical result and line-search summaries. No deliberate source mutation run was performed.

## 7a. Issue Ledger

- Fixed: coordinate subtraction can differ from Optim's BFGS update displacement at large parameter magnitudes. The regression now distinguishes the two.
- Open: two retained replays still terminate at Wolfe line-search failure. The traces show 109/166 BFGS updates and no skips or resets, so this diagnostic does not explain the failure.
- Unchanged: scientific gates, thresholds, refusal criteria, seed accounting, and capability status.

## 8. Consistency Audit

Reviewed the pinned Optim implementation in `bfgs.jl`, `perform_linesearch.jl`, `optimize.jl`, and `api.jl`. Successful iteration traces occur after the Hessian update; failed line searches stop before a trace row. Checked the frozen gate lock and manifest integrity. The exact-source reviewer confirmed that opt-in trace storage leaves the ordinary objective-evaluation path unchanged.

## 9. What Did Not Go Smoothly

The initial review correctly rejected the first reconstruction because it used rounded coordinate differences. I changed it to use Optim's recorded step and reconstructed direction, added a large-magnitude rounding regression, and requested a fresh exact-source review. Julia also needed a scratch-first depot because the shared compile cache was not writable in this task sandbox.

## 10. Known Residuals

The telemetry is engineering evidence only. It does not establish a numerical defect, candidate eligibility, ordinary-fit reliability, rank-selection performance, interval calibration, or any G2-G8 acceptance result. The two admitted diagnostic replays do not establish the cause of Wolfe failure and do not qualify G2. The wider non-GPU HSquared goal remains incomplete.

## 11. Team Learning

For BFGS replay, record the optimizer's actual update displacement (`step * direction`) separately from the rounded change in stored coordinates. Tests should include large values where floating-point addition loses part of the step. Memory receipt: repository `AGENTS.md`, Graft source cards, and the after-task and Unlazy procedures were consulted; `route.py` returned no LOAD-FIRST manifest for this worktree. Golden Set: not checked; no matching regression set was identified for this bounded Optim telemetry change.

Style assessment: 2/10, medium confidence. Genre/coverage: engineering closeout, whole report. Evidence/repair: the concrete statement that “Optim uses `alpha * direction`” and the enumerated test controls make the result easy to check; no prose change needed. Gates: science pass within the telemetry-only scope; facts pass against the exact-source review, focused test log, and gate-status output; references not applicable because the report uses no external references. Provenance: self-review of this draft, 2026-10-06, after reviewing the cited source and output.

## 12. Cross-Product Coverage

Covers: opt-in diagnostic state capture for the Julia Arc 1 FA BFGS path.

Does NOT cover: default R user behavior, R-Julia parity, production status promotion, other optimizers, other factor ranks, simulation calibration, releases, publication, or GPU execution.
