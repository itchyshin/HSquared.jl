# Independent specification-identity correction review

## 1. Goal

PASS for the narrow original-specification identity repair. Astra high independent review of Gauss/Sol's final packet. Base likelihood5219cf48; proposed source `1a6fa73396566ba66a785960b8df4db7201f98b0d8c9f2953b9676e68d917f9d`. This resolves the two existing package identity assertions and neighboring affected result routes. Full package completion remains parent-owned.

## 2. Implemented

No author or live edits. Applied exact patch `c23943a50d88dd19ad3a3013d5307525fb66879fdc5b1087f35e0bbbcfc16c7a` to a separate pinned base, verified exact replay, inspected all changes, independently ran original and new tests.

## 3a. Decisions and Rejected Alternatives

Preserve validated computational buffers. Select the original reference at the result boundary when normalized method and converted canonical precision match; retain the validated specification for actual method/Q changes. This preserves prior mutable-input identity without claiming immutable snapshots.

## 4. Files Touched

Only this owned directory and the final panel scratch report. No live source, tests or runner changed.

| Artifact | SHA256 |
| --- | --- |
| `package/src/likelihood.jl` | `1a6fa73396566ba66a785960b8df4db7201f98b0d8c9f2953b9676e68d917f9d` |
| `package/test/likelihood_original_spec_regression.jl` | `c6b1fc2735044e53c8d5cb9049cd0ac6c1a42f3ed81d749bfc9fe03eb15d721c` |
| `independent-controls-before-packet.jl` | `ad1caf7a986d58d25fa3da38b82b2b8559248950215cd83f6b05d0ba589b8f16` |
| `independent-controls.jl` | `a380e0cc3e5788f601cdf0380639e13dbddc038eba63553edc3ce4d1ee0e968b` |
| `review.log` | `9d1f40fc0fb53b4b2793055de23af62f1396d315c21e4db1131f2679567404f8` |
| `replay.json` | `ea5d3d7911f856c51f41c6b7c67ea33ea0e2d76d3945a051efcbd4da670afeb3` |
| `body-verify.json` | `29ec6de2d34e1281193fec0a1dce61555268351830534ddc3da7ac480d38fb52` |

## 5. Checks Run

All44 author inventory entries verified. Applied patch reproduces tested source and new test exactly. Copied original37-check test body occurs verbatim in the current live runner, including both identity assertions. Independently verified all four computation bodies equal baseline after removing only reference capture/selection/storage statements.

330/330 PASS:64new identity tests+202ingress guards+37unchanged original tests+27independent controls. Exit0,29.40s, Julia1.10.0, measured Julia/BLAS1. Estimated under2min before launch, explicit120s timeout, existing Project/Manifest/depot, startup/compiled modules disabled. The tiny author tests use one iteration; original37 retains its existing settings. No simulation, broad package run or campaign here.

## 6. Tests of the Tests

Author red51pass13fail remains pinned. The earlier misleading green-001 filename actually records the same unchanged-baseline failure and is disclosed. No old test was weakened.

Independent control sketch was frozen before packet readiness at ad1caf7a986d58d25fa3da38b82b2b8559248950215cd83f6b05d0ba589b8f16. Its initial assumption placed identity inside the validator. The author's valid design separates computational validation from result identity, so the review adapted the internal call through `_likelihood_result_spec` before executing. Both versions are preserved; no failing engine behavior is concealed. Public identity assertions are independently covered by the untouched original37 and new64 tests.

## 7a. Issue Ledger

- Original dense/sparse result identity: resolved at proposed bytes.
- AI/Henderson neighbors and dispatches: resolved by same reference-selection rule and direct tests.
- Method override and true precision canonicalization: validated specification retained, original remains unchanged, obsolete relationship diagonal cache dropped only for canonicalized Q.
- Finite/rank/SPD validation: preserved;202 existing ingress tests remain green.
- Full final package and bridge freshness: pending parent execution on applied source.

## 8. Consistency Audit

Independent controls cover equivalent Float32 input conversion, p=n supplied solve, rejection of REML saturation, unchanged IDs, method-only override, canonical-Q-only change, combined method/Q change, old cache preservation or removal, and invalid/overflowing response or rank loss. Computation always uses validated buffers even when result.spec returns the caller object. Later caller mutation retains the previously documented responsibility.

No objective, starts, covariance transforms, mathematical results, profile/PEV/uncertainty helper or iterative source change is in this delta. Predicted source-root aggregate after applying this sole delta to the panel target: `2ae2c98f8bc7e664a6e07571a08775359d79698689470bc19feb97657d420869`.

## 9. What Did Not Go Smoothly

The original input component review missed this existing compatibility assertion; the full package caught it. This review restores the exact old test as a required control. Reviewer internal-control setup was adapted transparently as above. No independent numerical failure occurred.

## 10. Known Residuals

Original specification aliases caller state. No concurrent mutation or immutable result guarantee. Prior inference/conditioning/range debts remain unchanged. Final integrated package run still required.

## 11. Team Learning

Numerical equivalence does not preserve reference identity. Keep computation buffers separate from established stored-model contracts and include original package assertions in focused repairs.

## 12. Cross-Product Coverage

Covers dense ML/REML, sparse REML, scalar AI and supplied Henderson result-spec identity and their dispatches. This does NOT cover whole-package completion, R bridge freshness, calibration, new capabilities, GPU or release. Parent may apply only this exact delta, register the new test once and resume final checks.
