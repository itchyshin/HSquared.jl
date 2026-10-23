## 1. Goal

Repair five reproduced malformed-input defects in genomic utility contracts and record their bounded Julia source-review evidence. No new fitted capability or public release claim was intended.

## 2. Implemented

- Reject non-finite marker weights and non-finite weighted scale.
- Reject colliding LOCO keys after string conversion.
- Require finite positive residual variance in the direct marker scan.
- Reject non-finite supplied-null statistics before threshold calculation.
- Validate finite symmetric single-step matrices, positive-definite `A`/`Ainv` and output, unique genotyped rows, and parameter domains.
- Add 19 assertions to the already registered engine-controls test file, including the valid `G = A[g,g]` reduction, BigFloat conversion overflow, weighted scale overflow, finite-matrix validation, negative omega, and final precision definiteness.
- Clarify the `single_step_inverse` input requirements in the user-facing genomic article.

## 3a. Decisions and Rejected Alternatives

- Keep genomic functionality experimental and validation-scale. Input guards do not validate estimation, inferential calibration, or performance.
- Reject invalid matrices instead of allowing `Symmetric` to silently select one triangle. Tiny floating-point asymmetry within a scale-relative tolerance is averaged after validation.
- Keep sparse-provenance, dense-path, scale-cutoff, and marker-scan-conditioning work as explicit carried findings.

## 4. Files Touched

- `src/genomic.jl`
- `test/test_212_engine_controls.jl`
- `docs/src/genomic-models.md`
- `GATES.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/source-review/2026-09-29-wave4-genomic.md`
- `docs/dev-log/after-task/2026-09-29-genomic-input-contracts.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`

## 5. Checks Run

- Julia 1.10.0 full `Pkg.test()` with four Julia threads and one BLAS thread passed using `JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`; the log ends `Testing HSquared tests passed`. The final focused test passes 19/19.
- `git diff --check` passed.
- `bash tools/preamble_cap.sh` passed at 11,024/14,000 bytes with one snapshot entry.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-09-29-genomic-input-contracts.md` passed the report structure check. Its integrated acceptance-ledger check exits 1 because the programme gates A2, E1, and V3 remain open; `node .../gate-check.mjs --status GATES.md` reports 8 met and 3 unmet.
- Julia docs build passed from `/private/tmp/hsq-genomic-docs-copy` after syncing the candidate and attaching its Git pointer. Existing missing-docstring, local deployment autodetection, and absent favicon/config warnings remain.
- No hosted CI or R check was run.

## 6. Tests of the Tests

The first added assertions were run against the unfixed implementation first: eight checks failed, reproducing invalid values, silent key collision, and missing errors. Post-fix review then found the Float64 BigFloat overflow; that regression failed before its fix. The final 19 assertions pass, including the valid single-step identity reduction and weighted-scale overflow guard. The full package suite also passes with those tests registered.

## 7a. Issue Ledger

- Fixed: five reproduced invalid-input classes listed in the Wave 4 packet.
- Carried: sparse provenance densification; dense SNP identity/APY/LOCO paths; metafounder ordering; scale-sensitive APY/scan cutoffs; normal-equation conditioning; permutation calibration.
- Closed: independent post-fix numerical review confirmed the changed CPU contracts and found no new defect.
- Open: programme gates A2, E1, and V3, whole-wave panel signoff, and remaining source spans.

## 8. Consistency Audit

The test file is included in the package test runner. Capability status and the public R-Julia model contract are unchanged. This is engine input validation only; no fitted capability, estimator claim, or release status was promoted. GATES E1 and V3 remain open.

## 9. What Did Not Go Smoothly

The unified session poll emitted a shell-wrapper error after the Julia test process had completed. The test log was checked directly and confirms exit-zero completion text. A Python invocation was mistakenly used on the R closeout checker, then corrected by running it with `Rscript`; no repository files were affected by either command error.

## 10. Known Residuals

The full source review remains incomplete. Existing sparse and scale limitations remain as listed above; they were not within this slice's five repaired input-contract findings. Next, continue the remaining source-review spans in bounded waves. The 200-seed FA recovery run remains held pending explicit approval because its current estimate is about 8.5 hours.

## 11. Team Learning

Initial review used independent numerical and genetics lenses; the implementation stayed within the exact source/test lease. Post-fix numerical review and Rose claim audit found the bounded claims supported with carried limitations. No external literature or compute campaign was needed.

## 12. Cross-Product Coverage

Covers malformed-input guards for selected Julia genomic utilities and their registered tests. Does not cover the R bridge, genomic model calibration, performance, broad source-review signoff, unusual inheritance, CUDA/GPU, or any submission, registry action, or release tag.
