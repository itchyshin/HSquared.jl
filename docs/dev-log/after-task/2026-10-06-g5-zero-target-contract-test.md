## 1. Goal

Add deterministic v4 regression evidence that exact-zero additive-variance and permanent-environment-variance targets stay fixed in their reduced models, while a singular all-zero residual proposal remains refused.

## 2. Implemented

Added a controlled `_arc1_raw_nuisance` test for both target components. It checks every positive-start base, both exact-zero nuisance faces, the fixed target coordinate, and the all-zero intersection. The final test also calls the production `_arc1_profile_reml` path for a finite positive-residual profile and a singular residual-zero proposal, while the injected likelihood checks that refusal reaches the objective call record.

This is a Julia contract regression only. It does not establish interval formation or calibration.

## 3a. Decisions and Rejected Alternatives

Kept the test deterministic with injected optimizer and likelihood callbacks. No simulation, fit campaign, method change, interval threshold change, or status promotion was justified by this test gap.

## 4. Files Touched

- `test/arc1_profiles_v4.jl`
- `docs/dev-log/check-log.d/2026-10-06-g5-zero-target-contract-test.log` (intermediate 257-test run)
- `docs/dev-log/check-log.d/2026-10-06-g5-zero-target-contract-test-v2.log` (final 261-test run)
- `docs/dev-log/check-log.d/2026-10-06-g5-zero-target-contract-test.md`
- `docs/dev-log/after-task/2026-10-06-g5-zero-target-contract-test.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`

## 5. Checks Run

- `julia --startup-file=no --project=. test/arc1_profiles_v4.jl` with Julia 1.10.0, one Julia thread, one BLAS thread, and a scratch-first depot: exit 0 after 26.467 s; 261/261 tests passed (30 engine-path tests and 231 bounded-control tests). Final raw output is `docs/dev-log/check-log.d/2026-10-06-g5-zero-target-contract-test-v2.log`, SHA-256 `6d19d3f898a28448e34f14e9c24b6234760a58f12b5ba59c3e8e6c9850aeabaf`.
- The earlier 257/257 run remains preserved as intermediate evidence; it is superseded for the final test count by v2, not erased.
- `git diff --check`: exit 0.
- `python3 ~/shinichi-brain/tools/slop_check.py docs/dev-log/after-task/2026-10-06-g5-zero-target-contract-test.md`: 0 findings.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <absolute report path>`: required structure passes; overall check then refuses closeout because the Arc 1, auto-FA-rank, and H2 non-GPU ledgers still have unmet gates. The continuing project goal remains open.
- `python3 ~/shinichi-brain/tools/evidence_gate.py --root "$PWD"`: not applicable; this Julia repo has no `memory/evidence-registry.tsv`.
- Arc 1 status after this slice: G2-G5 and G8 remain open; G0, G1, G6, and G7 are recorded as verified in the current checkpoint and gate ledger. This deterministic contract test changes no gate state.

## 6. Tests of the Tests

The test asserts the target coordinate in all captured BFGS bases and in every generated face and intersection. It also checks each held-zero and physical-zero coordinate, exercises the production profile function at positive and zero residual variance, and verifies that a residual-zero objective proposal is labeled `:singular_proposal`. No deliberate mutation run was performed.

## 7a. Issue Ledger

- Fixed: no direct v4 regression covered target `Va = 0` or `Vpe = 0` while constructing exact-zero nuisance faces.
- Deferred: G5 formation and all-attempt coverage calibration remain unverified.

## 8. Consistency Audit

Reviewed `_arc1_raw_nuisance` and the neighbouring v4 boundary, centered-corner, and nuisance-history tests. The source initializes the target in `base`, keeps it out of nuisance coordinates, builds exact-zero faces from that base, and evaluates the intersection. Existing v4 tests cover the residual-target path; the new regression covers zero additive and permanent-environment targets. Capability status, R controls, and public claims were not changed.

## 9. What Did Not Go Smoothly

The first new assertion compared the synthetic objective status with optimizer refusal statuses. The focused run exposed the mismatch; the test now records and checks those statuses separately. A run without the scratch-first Julia depot stopped at a read-only compiled-cache pidfile before test loading; the retained passing run used the existing scratch depot. The brain-installed `closeout.py` resolves relative report paths under the brain root, so its initial generator invocation did not create a project report. The report was written in the worktree and checked with the absolute-path structural validator instead.

## 10. Known Residuals

The profile method remains a candidate. This test does not prove numerical optimizer convergence, interval formation, coverage, boundary calibration, R parity, or any Arc 1 acceptance gate. G2-G5 and G8 remain open. The checkpoint and current gate ledger record G0, G1, G6, and G7 as verified; this test advances none of them.

## 11. Team Learning

When a profile target is exactly zero, test that the target coordinate remains fixed through every nuisance face and the intersection. Treat objective-evaluation status and optimizer status as separate evidence fields.

Memory receipt: the repo’s LOAD-FIRST route manifest was not found for this managed worktree; repository `AGENTS.md`, the Arc 1 checkpoint, and the current source/tests governed the slice. The matching local H2 memory lead was treated as context, not as proof. Golden Set checks were not in scope for this callback-level regression.

## 12. Cross-Product Coverage

Covers: Julia internal v4 raw nuisance-profile boundary construction, production profile status on positive and singular residual proposals, and deterministic singular-proposal refusal propagation.

Does NOT cover: R controls or bridge parity, interval calibration, automatic factor-rank selection, other model families, public capability status, release readiness, or GPU execution.
