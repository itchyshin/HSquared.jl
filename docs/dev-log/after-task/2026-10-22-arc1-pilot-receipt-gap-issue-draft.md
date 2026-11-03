# Issue #474 record: preserve source-bound Arc 1 pilot receipts

**Status:** Posted as [HSquared.jl issue #474](https://github.com/itchyshin/HSquared.jl/issues/474) on 2026-10-23.

## Title

Arc 1: retain source-bound FA pilot receipts and independent pins

## Body

### Problem

The G2/G3 aggregator requires a complete nine-cell pilot receipt bundle and a separate trusted pin map. A bounded Totoro inventory found raw result files for N80/null pilot outers 1–14. Each of the other eight scenario output roots has seven result/admission files under the development phase, not the pilot phase. These files do not form a complete nine-cell pilot bundle. The N80/null raw outputs have not been verified against the exact source, protocol, seeds, or required reference maxima, so no G2/G3 gate credit follows.

The earlier N80/null summary reports 25 usable attempts out of 30, with failures at outers 4, 7, 20, 25, and 28. That tally remains diagnostic; it has not been tied to the 14 inventoried pilot outputs or a complete source-bound receipt bundle.

### Scope

Recover and package already-retained pilot outputs only. Do not rerun consumed seeds or change the frozen experiment protocol. Keep the post-outcome 24/30 pilot-feasibility screen separately identified. It does not waive source, receipt, reference-audit, selection-rule, or confirmation requirements.

### Acceptance criteria

- Every required G2/G3 pilot cell has all 30 attempted outcomes represented, including failures, with no replacements.
- Each outcome has a verifier-accepted receipt bound to the exact source, protocol, and seed; the independent pin map is stored separately and verifies the expected cell.
- The frozen aggregator runs on the complete bundle and records the original 29/30 result.
- The separately versioned 24/30 pilot screen is evaluated only after frozen checks pass and reports usable, unusable, K0, K1, and conditional K1 counts per cell.
- Missing result bodies and unresolved reference maxima remain explicit holds; aggregate counts alone do not meet a gate.
- Retained bundle, pin map, hashes, and checker output are recorded in the Arc 1 evidence ledger.

## Evidence basis and limits

The inventory inspected only file names, paths, and sizes. The N80/null pilot output tree contains 14 files named .result.json and 14 named .full.jls, with one run-admission.json per outer. No separate pin-named file appeared in the searched N80/null pilot output, admission, and source roots. The eight other scenario output trees each contain seven results with development-phase admissions and no pilot-phase admissions. The bounded search does not claim that every possible retained location was checked. No fit bodies or seed values were opened, and no fits or seed reruns were run.
