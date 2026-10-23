## 1. Goal

Reject materially asymmetric single-step relationship matrices across small and large numeric scales without changing valid symmetric inputs.

## 2. Implemented

The single-step symmetry validator now compares normalized asymmetry against a relative tolerance. Tests cover tiny and huge asymmetric inputs and a tiny symmetric positive-definite control.

## 3a. Decisions and Rejected Alternatives

- Removed the unit-sized absolute tolerance floor because it accepts substantial relative asymmetry for small relationship matrices.
- Normalize by the largest absolute matrix entry before differencing. This avoids overflow from subtracting extreme finite values and from summing row norms.
- Keep downstream positive-definiteness checks responsible for rejecting symmetric but invalid relationship matrices.

## 4. Files Touched

- `src/genomic.jl`
- `test/test_212_engine_controls.jl`
- `GATES.md`
- `docs/dev-log/source-review/2026-09-29-wave4-genomic-symmetry.md`
- `docs/dev-log/check-log.d/2026-09-29-wave4-genomic-symmetry.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-genomic-scale-symmetry.md`

## 5. Checks Run

- TDD focused test before the code change reproduced the failure: the tiny asymmetric matrix did not throw.
- Focused `test/test_212_engine_controls.jl`: 24/24 passed.
- Full Julia 1.10.0 `Pkg.test()`: passed, ending `Testing HSquared tests passed`. The existing Project/Manifest mismatch warning remains. No resolve or update was run.
- `git diff --check`: passed.
- The new source-review packet, check-log shard, after-task report, appended log entries, and `GATES.md` passed `slop_check.py` with zero findings in the new prose.
- The after-task structure check passed. Its integrated acceptance check remains open for four programme ledgers and root `GATES.md`; the root ledger has A2, E1, and V3 open.
- Independent numerical review of the exact final source and test hashes passed.

## 6. Tests of the Tests

The new tiny asymmetric regression failed against the old implementation and passes against the normalized check. Large asymmetric and tiny symmetric controls cover scale behavior and prevent blanket rejection of small matrices.

## 7a. Issue Ledger

- Fixed: materially asymmetric small-scale single-step relationship input was accepted and silently symmetrized.
- Open: broader Wave 4 source spans and panel signoff; FA engine review A2; final R/bridge checks V3.

## 8. Consistency Audit

The validator checks finite converted values, verifies symmetry, then symmetrizes only within the scale-relative tolerance. Existing symmetry and positive-definiteness tests pass. No API, capability status, validation-debt status, or covered-count change was made.

## 9. What Did Not Go Smoothly

The shared lane-lease tool required elevated access because its registry is outside the writable repository roots. The initial sandboxed lease command reported a grant but created no lease; an elevated retry recorded the required paths. The integration suite emitted the existing Project/Manifest mismatch warning.

## 10. Known Residuals

No whole-file genomic review, broad scale campaign, external comparator, R bridge validation, hosted CI, release action, or GPU work is established by this repair.

## 11. Team Learning

A tolerance with `max(1, scale)` has an absolute floor and can erase meaningful asymmetry for small-scale covariance matrices. Normalize before comparing to keep the criterion relative without overflow.

Memory receipt: repository route resolution did not load a LOAD-FIRST manifest in this worktree. Lane preflight, the committed coordination board, and exact source-review packets were consulted. No external literature or sister-project scout was run.

## 12. Cross-Product Coverage

This covers the Julia single-step relationship-matrix symmetry validator and its local tests. It does NOT cover R bridge behavior, other relationship constructors, calibration, other estimators, FA/GLLVM acceptance, unusual inheritance, CUDA/GPU, or release readiness.
