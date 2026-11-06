## 1. Goal

Reject eight-cell FA-rank pilot batches whose admissions do not share one source lock, and make the common lock explicit and verifiable when creating or resuming a plan.

## 2. Implemented

- `validate_batch()` now rejects missing or empty source maps, changed source digests, and changed source path sets across the eight admissions.
- The batch returns the canonical SHA-256 of the common `source_sha256` map. `make_plan()` stores it at plan level and in each job.
- `_plan_contract_valid()` requires a valid plan lock, checks each job's lock, reloads each admission, and compares its source map with the plan lock before resume or execution.
- Launcher review found that the current Codex copy would produce an eight-worker plan, while the retained candidate admission plan specifies four workers. The launcher now pins four concurrent cell workers; plan validation and execution reject a different count.
- Regenerated a no-fit plan using the current launcher and retained recovery source. The CLI returned `plan_validated_no_fits_started`; the plan records four concurrent workers and `execution_started=false`.
- A read-only local and Totoro record scan found no target-cell admissions, coordinate markers, or allocated-seed matches in the inspected roots. It did not run any fits.

## 3a. Decisions and Rejected Alternatives

Use the existing canonical JSON SHA-256 helper so source-map identity is stable and already participates in plan integrity. Do not infer a source lock from only the first admission. Do not merge the distinct current and recovery source trees during this slice.

Assumption made without asking: the complete source map is the identity unit for the batch. If this is wrong, the source-lock contract and its tests must be revised before a measured pre-run.

## 4. Files Touched

- `sim/arc1/run_pilot_cells.py`
- `test/test_arc1_pilot_cells.py`
- `docs/dev-log/after-task/2026-10-24-arc1-source-lock-consistency.md` (this report)
- `/private/tmp/arc1-pilot-admission-candidate-20261023/` (candidate batch, eight admissions, candidate plan, CLI plan, and collision-audit receipt)
- `/private/tmp/arc1-pilot-admission-issue-draft.md`

No source code was changed in the recovery tree. Other pre-existing dirty files in the Codex worktree were preserved. No commit or push was made.

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s test -p 'test_arc1_pilot_cells.py'` passed 23/23; `test_arc1_rank_pilot_amendment.py` passed 8/8.
- The two new negative tests passed after the implementation: divergent digest/path-set rejection and resume-plan rejection after a changed admission was rehashed.
- A worker-count regression test verifies that a four-worker plan is valid and an eight-worker resume plan is rejected.
- Before the fix, the batch regression failed because `ValueError` was not raised for both source-map mutations. The resume regression failed because the altered plan was accepted.
- The recovery-tree targeted suites passed 42/42 in the prior slice.
- The current launcher CLI planning mode returned `plan_validated_no_fits_started` and wrote a four-worker plan; it did not launch Julia.
- Local collision scan: 109 retained admission/receipt/run metadata records across the recovery evidence and 12 prior admission directories; no target-cell admissions or seed/coordinate collisions.
- The retained Totoro collision scan used the already-running ControlMaster only. It examined 342 metadata files, 174 admissions, 276 standard attempt markers across 111 `arc1-*` roots under `~/hsq_work`, plus the one additional directory named `hsquared-arc1-transport-20261005`. No target-cell admissions, attempt markers, seed overlaps, or files beneath any of the eight canonical candidate output paths were found. Result payloads were not opened. A follow-up read of the two remaining top-level admission files found both were development N80/null records with 60 seeds each and zero overlap with the candidate allocation. The named package-check script contained no seed or pilot-coordinate literals and was not executed.
- Candidate source lock: `ee78d8730bda749793ac761df95af22a4934ced9383658f3d32d39003bbf8a57`. Original candidate plan digest: `fc31b0684727f01d79fa840ba9b6fcdec3cf5d237f91118a8907766b2d7727ef`. Current-launcher no-fit plan digest: `3c7e0fe1b5ab1c2eec51b84f5c17c5c679cb5f3bb4fe764ba8b76d2d624f6044`; its file is `/private/tmp/arc1-pilot-current-launcher-dryrun-20261024-four-workers/results/plan.json` and it records four workers with `execution_started=false`. Updated collision receipt SHA-256: `5ce61d7f68aa10c1a0632252ab79dc7db4aa5e8705a2898c657efa8dbc82c526`.
- The prior annotated seed `11447647806120141284` does not occur in the candidate allocations.

## 6. Tests of the Tests

The new test first demonstrated the exact failure twice: changing one source digest or removing one source path was accepted. The resume test also demonstrated that a changed admission could be rehashed and accepted by the old plan validator. Those three negative cases now reject through the real batch or resume validation path. A fourth regression confirms that the retained four-worker plan is accepted while an eight-worker plan is rejected.

## 7a. Issue Ledger

The local draft `/private/tmp/arc1-pilot-admission-issue-draft.md` remains open. The collision scan is scoped to the inspected local roots and Totoro `~/hsq_work`; it is not a complete inventory of every possible record location and is not integrated into admission. The candidate source lock has not received a fresh independent freeze review. A prior GitHub issue-creation attempt was denied with HTTP 403, so no public issue was created.

## 8. Consistency Audit

Checked the neighboring pilot-amendment tests and both plan creation and resume validation. The current Codex worktree's launcher and test files have different hashes from the recovery copy; neither copy was substituted for the other. The retained handoff documents are included in the recovery candidate's source map. G0 and G1 remain met; G2 through G8 remain open; covered count remains 7; v7 remains HOLD.

The current worktree had 36 dirty paths after this report was created. The two launcher files remain untracked, and all other dirty paths were left as found. `docs/dev-log/check-log.md` was not edited because lane preflight showed 19 other refs with work absent from this checkout. `docs/dev-log/coordination-board.md` was not edited because the owner explicitly protected it.

## 9. What Did Not Go Smoothly

The first closeout-helper call used a relative path and resolved into the protected Dropbox checkout; the write was denied and created no file. The helper was rerun with an absolute path into this managed worktree. Two test setup mistakes were corrected before the meaningful red runs: the first fixture lacked a source map, and one resume test named a nonexistent helper. No protected file or checkout was changed.

## 10. Known Residuals

- The candidate plan is not permission to run. No fits, pre-run, seed execution, or remote compute were started.
- The read-only collision scan does not prove absence of records outside the inspected roots and is not an admission-time rejection check.
- The source lock is a candidate, not a reviewed source freeze. The current Codex and recovery source trees remain divergent.
- The current launcher can validate and plan against the retained recovery source without fitting. Collision screening is bounded to the inspected roots; it is not an admission-time no-reuse proof. No fit may start until a separate measured pre-run and owner execution approval are complete.
- No gate status changed. G2 through G8 remain open, `public_covered_count` remains 7, and v7 remains HOLD.
- No Julia package suite, R parity suite, documentation build, or full package check was run in this slice.

## 11. Team Learning

Source identity must be checked at batch construction and again after reloading every admission during plan validation. A plan should carry the common digest explicitly so a rebuilt admission cannot silently change one job's source while preserving the rest of the batch contract.

Memory receipt: `route.py` found no LOAD-FIRST manifest for this isolated worktree. The `graft` command was unavailable, so exact local source ranges and tests were used after the graph fallback failed. Project instructions were supplied in the user message. Golden Set: not checked; this was launcher contract code and did not change estimator behavior.

## 12. Cross-Product Coverage

Covers the Julia-side FA-rank pilot batch admission and resume source-lock contract. It does NOT cover R access or parity, FA likelihood correctness, selector performance, interval calibration, any pilot outcome, full Arc 1 gates, GPU, or release readiness.
