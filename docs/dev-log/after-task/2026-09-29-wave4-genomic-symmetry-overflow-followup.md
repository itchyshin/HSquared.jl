# After-task report: Wave 4 genomic symmetry and overflow follow-up

## 1. Goal

Close exact-source numerical and documentation findings in the reviewed Julia genomic relationship slice while preserving the broader FA/GLLVM and engine-review gates.

## 2. Implemented

- Moved the in-place symmetry helper before the `genomic_relationship_matrix` docstring so the documentation belongs to the public function.
- Added finite checks after Float64 conversion of `G`, after conversion of `ridge`, and after ridge addition to the APY core.
- Changed single-step matrix symmetry validation to compare each off-diagonal pair on its own scale, then average accepted entries in place.
- Reject nonfinite constructed relationship or precision matrices. The weighted-overflow fixture now proves its denominator is finite while its cross-product overflows.
- No capability or validation-status row was promoted.

## 3a. Decisions and Rejected Alternatives

- Retained strict pairwise relative symmetry checks. A matrix-wide tolerance can conceal asymmetry in a lower-scale block; a unit-sized absolute tolerance also rejects valid small-scale structure inconsistently.
- Retained the existing scale-relative APY conditional-variance cutoff as a cancellation heuristic. It is not treated as a certified error bound.
- Did not optimize the duplicate APY finite scan or claim a speed improvement without a benchmark.

## 4. Files Touched

- `src/genomic.jl`
- `test/wave1_numerical_contracts.jl`
- `test/test_212_engine_controls.jl`
- `docs/src/validation-status.md` (generated during the local docs build from current status; no capability promotion)
- `GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/source-review/2026-09-29-wave4-genomic-symmetry-overflow-followup.md`
- `docs/dev-log/check-log.d/2026-09-29-wave4-genomic-symmetry-overflow-followup.md`
- This report

## 5. Checks Run

- Focused API-docstring, single-step, and Wave 1 numerical tests passed: 3/3, 25/25, and 126/126. The relationship-construction assertions passed 16/16; APY finite-input/scale assertions passed 8/8; partial-core formula and Schur-cutoff tests passed 5/5.
- Full Julia 1.10 `Pkg.test()` passed with exit 0 and ended `Testing HSquared tests passed`, using the final implementation source. After that full run, the weighted-overflow test was strengthened with explicit finite-scale and infinite-cross-product assertions; the exact final Wave 1 test then passed.
- `julia --project=docs docs/make.jl` exited 0. Documenter reported orphan docstrings and local VitePress/deployment defaults; it did not deploy.
- `git diff --check` passed on the three source/test files. `bash tools/preamble_cap.sh` passed at 11,024/14,000 bytes.
- Gauss and Karpinski reviewed the exact implementation source and found no remaining component-level correctness blocker. No benchmark or CI dispatch was run.

## 6. Tests of the Tests

Before the single-step change, a mixed-scale asymmetric matrix with a `1e12` entry and a smaller asymmetric `2 × 2` block was accepted. The new test expects rejection and passes. The weighted overflow test separately asserts its scale remains finite and its cross-product is nonfinite, then verifies the constructor rejects it. APY tests cover overflow on conversion and ridge addition, compare a partial-core result with an explicit block formula, and exercise Schur variances on both sides of the cancellation cutoff. The public API-docstring test confirms `genomic_relationship_matrix` has a docstring.

## 7a. Issue Ledger

- The reviewed docstring-binding, APY conversion/ridge-overflow, mixed-scale single-step symmetry, and weighted-constructor nonfinite-output findings are repaired and locally tested.
- Component reviews pass. Wave 4 and E1 remain open for other source spans and whole-wave signoff.
- A2 and V3 remain open; FA inference, GLLVM calibration/comparator evidence, and exact twin validation are incomplete.
- This work does NOT close the FA/GLLVM programme, the entire Julia engine review, broad statistical validation, or any release gate.

## 8. Consistency Audit

Implementation, tests, and documentation agree that CPU genomic relationship outputs are finite and exactly symmetric, APY rejects nonfinite Float64 arithmetic, and single-step inputs must be symmetric at the pair level. The generated validation-status page retained existing capability statuses. The count stays 7; no GPU, release, or public capability claim changed.

## 9. What Did Not Go Smoothly

The first full package test used the default Julia depot and stopped before tests because its manifest-usage pidfile was not writable. The captured rerun used the writable temporary depot and passed. The first docs build could not write its generated status page from the managed worktree; the authorized local retry exited 0. The first weighted-overflow fixture overflowed its scale too early; review caught this, and the final fixture now proves finite scale and overflowing cross-product directly.

## 10. Known Residuals

- This is a bounded component repair, not full Wave 4 or E1 signoff.
- A2 and V3 remain open. No R source or bridge change was made in this slice.
- The APY positivity cutoff is heuristic. APY remains dense validation-scale, and no performance benchmark was run.
- The report structure check passes. The integrated closeout compiler remains red because the active programme, Wave 1, Wave 2 bridge, and this programme's acceptance ledgers retain unmet gates.
- Hosted CI, a post-push check, registry submission, CRAN submission, release tag, and GPU work were not performed.

## 11. Team Learning

Numerical guard tests should establish that a fixture reaches the intended guard. A finite input can overflow before or after the boundary under test, so the test should assert the relevant intermediate conditions when practical. Pairwise matrix contracts should be tested with blocks spanning multiple magnitudes.

## 12. Cross-Product Coverage

This slice covers Julia genomic relationship constructors, APY inversion, single-step symmetry validation, their tests, and the generated Julia validation-status page. It does NOT cover R implementation, R-Julia parity, FA/GLLVM release readiness, remaining Julia source spans, CI, GPU execution, or any external release action. The twin programme goal remains active.

Memory receipt: no brain-memory change was needed; repository source review and test receipts are the durable record. Golden Set: no new fitted reference result was added.
