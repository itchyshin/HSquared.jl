## 1. Goal

Review and record exact-current E1 findings in the genomic construction and scan portions of `src/genomic.jl`, preserving lane ownership and the no-GPU boundary.

## 2. Implemented

- Gauss reviewed genomic construction, provenance, APY, and LOCO code on the exact candidate hash.
- Karpinski reviewed the single, mixed, and LOCO scan core on the same source hash.
- Reproduced six input or numerical failure cases in short local probes and recorded the existing scan oracle and performance limits.
- Made no source or test edits because other refs carry overlapping work on `src/genomic.jl`.

## 3a. Decisions and Rejected Alternatives

- Kept `src/genomic.jl` and shared tests untouched because lane preflight found six refs with work absent from this checkout; one ref removes the symmetry guards implicated by a reproduced failure.
- Recorded concrete repairs and validation needed, but did not select between symmetry rejection and roundoff-safe symmetrization before the overlap owner decides.
- Did not treat component reviews as whole-file E1 signoff.

## 4. Files Touched

- `docs/dev-log/source-review/2026-09-29-genomic-core-exact-review.md`
- `docs/dev-log/check-log.d/2026-09-29-genomic-core-exact-review.md`
- `docs/dev-log/after-task/2026-09-29-genomic-core-exact-review.md`
- `GATES.md`

The reviewed source and tests were not changed by this slice.

## 5. Checks Run

- Gauss and Karpinski reported exact-current scoped review on `src/genomic.jl` hash `72423bd1523dbcf25ef55081d89328c12004797637d8506e17e5ff574a87c021`.
- Local Julia probes reproduced weighted inversion rejection, two singular APY results from infinities, scale-based APY refusal, unusable zero-ridge activation, infinite VanRaden output, and accepted missing LOCO labels.
- Existing registered tests cover simple weighted relationships, APY all-core equivalence, LOCO supplied-frequency subsetting, and small GLS projection. They do not cover the reproduced edge cases or multiple markers per LOCO group.
- No full package suite or benchmark was run for this read-only review. The full suite previously passed before this review, but it is not evidence that these newly reproduced edge cases are fixed.
- The E1 gate remains open. The broader programme remains at 8/11, with A2, E1, and V3 open.

## 6. Tests of the Tests

The deterministic probes establish that current behavior violates the expected construction-to-inverse and finite precision contracts. The registered zero-ridge test checks fingerprints but not inverse residual quality, so it would pass while the large residual remains. Existing APY negative tests cover empty/out-of-range cores and negative ridge, not nonfinite values or scale changes. No new regression test was added because the shared source and central test files have ownership conflicts.

## 7a. Issue Ledger

- P1 carried: weighted relationship output can be rejected by its own exact-symmetry inverse guard.
- P2 carried: APY accepts infinite inputs and returns singular precision.
- P2 carried: APY's fixed absolute conditional-variance cutoff is unit-scale dependent.
- P2 carried: zero-ridge activation yields a numerically unusable inverse on a registered fixture.
- P3 carried: finite valid inputs can overflow relationship construction; missing LOCO labels are stringified and accepted.
- Carried: scan type stability, dense memory scaling, repeated allocations, conditioning limits, and multi-marker LOCO cache coverage.
- Ownership action: user decision is required before editing `src/genomic.jl` or shared tests because preflight reports overlapping refs.

## 8. Consistency Audit

The weighted inversion issue affects a documented construction followed by its documented inverse. The APY finding concerns the same `Q` precision contract at finite and extreme scales. The activation test fixture currently allows zero ridge and verifies hashes rather than inverse usability. The scan review remains bounded to lines 639-1157 and does not claim sparse-scale readiness. No capability, validation-debt, or covered-count row was changed. The current public limitations remain intact.

## 9. What Did Not Go Smoothly

An initial exploratory zero-ridge probe used a different marker matrix and errored before yielding a result. I replaced it with the exact registered fixture and reproduced the issue. A separate review subagent could not start because the agent thread limit was reached. Source edits were stopped when lane preflight found overlapping references.

## 10. Known Residuals

All six reported findings remain unfixed in this checkout. Current behavior therefore still includes reproducible precision failures. The rest of `src/genomic.jl`, including marker effect and summary routes and single-step fitting, has not received a complete current-source review in this slice. Whole-file E1, FA signoff A2, and final twin checks V3 remain open. No GPU execution, release submission, registry submission, merge, or public tag occurred.

## 11. Team Learning

Memory receipt: loaded the HSquared operating contract and canonical repo LOAD-FIRST manifest. The R-public/Julia-engine boundary, lane preflight, and validation-first rule shaped the work.

Golden Set: checked the registered cases with `python3 ~/shinichi-brain/tools/memory_regression.py --list`; no case directly covers the reproduced genomic precision contracts, so no case was run.

## 12. Cross-Product Coverage

This review covers the Julia genomic construction, APY and LOCO helpers, and a portion of the marker scan engine. It does NOT cover the full Julia genomic file, R behavior, R-Julia parity, FA or GLLVM estimation, inference calibration, GPU execution, CRAN submission, Julia registry submission, or public release tags.
