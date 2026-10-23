# Likelihood original-specification identity correction

## 1. Goal

Repair the concrete integrated L3 regression that replaced the caller's original AnimalModelSpec in fitted results. Prepare an isolated exact delta for independent review and parent application.

Base `src/likelihood.jl`: `5219cf48be1933a01afe4bb5ba40278d4610b455b5fd7d85a078ce2947c10e57`. The base contains the integrated L1/L2/L3 source after the parent-authorized 21:15:50 UTC integration. HEAD at assignment is `6271cfd58651e69cd27a64dcf02cb8960a29e260`. Full package run stopped at the original Phase 1 fitting assertions `fit.spec === spec` and `sparse_fit.spec === reml_spec`.

## 2. Implemented

Added `_likelihood_result_spec(original, validated)`. It returns the original specification when its method and Float64-converted precision match the validated method and canonical precision. It returns the validated specification when method or canonical precision actually changes.

Dense ML/REML fitting, sparse REML fitting, scalar AI fitting and supplied Henderson results select the stored specification through this helper. Their computational specification remains the validated Float64/sparse copy. Validation and canonical buffers are completed before any objective or solve. The four function bodies differ only by capturing the original reference, selecting the result reference and storing that reference in the result constructor.

The AnimalModelFit docstring describes the unchanged-model identity contract and the method/canonicalization exceptions. Existing input validation, finite results, objective formulas, optimizer controls and covariance transforms remain unchanged.

## 3a. Decisions and Rejected Alternatives

Historical `_validated_sparse_relationship_spec` returned the original spec when canonical precision equaled the converted input, and produced a new spec for an actual canonicalization. The L3 replacement always reconstructed the spec, inadvertently removing ordinary identity. The correction restores that identity at the result boundary while preserving validated computational buffers.

An actual method override still records the requested method in the returned computational specification. This retains the existing L3 method-override control. Accepted precision roundoff is represented by its canonical symmetric matrix; its previous relationship-diagonal cache is dropped. The original input arrays and metadata are not mutated.

Returning the caller's reference retains the established mutable-input semantics. This is no immutable snapshot or concurrent input-mutation guarantee.

## 4. Files Touched

Owned root: `/private/tmp/hsq-likelihood-original-spec-fix-20260930/`. Source is `package/src/likelihood.jl`; new test is `test/likelihood_original_spec_regression.jl`. Copied project/source dependencies, tests, baseline, failed preparation scripts, logs and run receipts remain in this root. No live source, runner, original test, Git state or another lane's file was edited.

| Delivery | SHA256 |
| --- | --- |
| Prepared source | `1a6fa73396566ba66a785960b8df4db7201f98b0d8c9f2953b9676e68d917f9d` |
| Unified source/new-test patch | `c23943a50d88dd19ad3a3013d5307525fb66879fdc5b1087f35e0bbbcfc16c7a` |
| New regression | `c6b1fc2735044e53c8d5cb9049cd0ac6c1a42f3ed81d749bfc9fe03eb15d721c` |
| Green log | `a7fd2c761bc40ceec218a290915d6089c4d7ed428eab426ca83ed78fc038853b` |
| Body/delta verification | `9219aaa76a348d2e3e82e18c4567f57461b94ce6ab3e1b32dc61907c6d0f391d` |
| Inventory | `31a9f5287df0760eba1745025ecaf56bf324283364efa274b8e22326c7cf01e4` |

`runner-append.txt` contains the proposed new-test include. Parent owns registration once. The unified patch does not alter any original test or runner include.

## 5. Checks Run

Estimated each focused run under two minutes. Julia 1.10.0, startup/compiled modules disabled, Julia and BLAS each measured one thread, existing Manifest/depot, subprocess timeout 110 seconds with kill/wait on expiry.

| Retained run | Actual result | Wall time |
| --- | --- | --- |
| `red-001.log`, integrated baseline | 51 pass / 13 fail / 64 | 25.00 s |
| `green-001.log`, unchanged baseline after preparation assertion | 51 pass / 13 fail / 64, exit 1 | 25.05 s |
| `green-002.log`, actual correction | New 64/64 + existing ingress 202/202 + original fitting 37/37 | 29.21 s |

Final focused total: 303/303. The original Phase 1 testset was copied byte-for-byte from the live runner into a standalone file, with only prerequisite imports added. Its existing identity assertions were preserved. The stored run JSON contains the exact command and elapsed time. A corrected source preparation was completed before the actual green launch.

The new tiny fit cases use three records and one iteration. The unchanged original fitting testset retains its existing iteration settings. No package-wide rerun, simulation, GPU, remote compute, benchmark or calibration campaign was performed.

Patch check and application on a separately retained exact baseline reproduced the tested source and new test byte-for-byte. No dependency update or resolution occurred.

## 6. Tests of the Tests

The new baseline red check exposes 13 ordinary identity/metadata-reference failures across dense, sparse, AI, Henderson and public dispatch routes. Its 31 canonical-Q/method-change checks and 12 finite/rank/precision rejection controls already pass on the integrated baseline and remain green after the correction.

Snapshots verify that y, X, Z, Q, IDs and relationship-diagonal metadata values remain unchanged. Canonicalization checks verify the computed precision and discarded cache in the new result, unchanged original inputs, and numerical agreement with an explicitly canonical reference model. A method override verifies normalized returned method and unchanged original method.

Golden Set: unchanged original 37-check Phase 1 testset, 202 ingress/result guards, 64 identity/canonicalization/method/nonmutation checks. No old assertion was weakened.

## 7a. Issue Ledger

| Item | Disposition |
| --- | --- |
| Integrated dense/sparse original-spec identity regression | Repaired in scratch; existing assertions pass |
| Neighbour AI/Henderson identity regression | Same result-boundary correction, direct tests pass |
| Canonical precision and method metadata | Preserved through validated computation/result exceptions |
| Input mutation | Values and cache untouched across all four affected routes |
| Full package freshness | Parent rerun required after independent review/application |

## 8. Consistency Audit

`evidence/change-verification.json` verifies 124 other extracted whole function bodies remain identical to the integrated base, including L1/L2 numerical helpers. Removing only the original/result reference statements from each changed fit/solve function reproduces its exact baseline computational body. There are 14 textual change groups: one new helper, doc clarification and four result-boundary changes.

The scalar AI public wrapper delegates to the corrected instrumented implementation. Multi-effect routes accept raw arrays/effect tuples and return NamedTuple metadata; they have no caller AnimalModelSpec identity object. Their function bodies are unchanged. The matrix-free wrapper already built its own validated specification before L3 and remains unchanged in its separately integrated iterative file.

Downstream results continue to carry the canonical precision when canonicalization changes it. The original reference is returned only when the effective method and converted precision agree. Full finite/rank/SPD checks still precede computation.

Memory receipt: inherited operational lane/preflight guidance; source pins, historical helper bytes and executed tests establish this correction. Graft exact callers were queried first; archived proposal copies broadened its output and the read-only graph-cache lock failed. Current src coordinates and hash were checked directly.

## 9. What Did Not Go Smoothly

The original L3 component tests had not covered the existing result-identity assertion. The parent full package check found the compatibility regression. This packet supplies those direct controls and reruns the exact original testset.

Preparation first used a nonexistent scratch working directory, then an incorrect internal AI symbol, then an incorrect docstring marker. Each failed before writing source; both failed scripts and the attempt log are retained. The first assertion failure was followed by a shell-launched run against unchanged baseline; its misleading historical filename `green-001.log` is retained with its actual exit-1 result and explicit disposition above. No false passing result is claimed.

## 10. Known Residuals

This correction does NOT cover whole-package completion, arbitrary conditioning/range, statistical calibration, broader inference approval, capability promotion, public R grammar/schema or new estimators. The original mutable specification identity has its established caller-mutation semantics. Validated buffers are local to computation; post-return mutation is no snapshot guarantee.

All previously carried likelihood and iterative numerical/inference limits remain. Parent must apply only this exact delta after independent review, then resume the package check and panel on the composed source.

## 11. Team Learning

A computational conversion can preserve numerical values while breaking an established object-reference contract. Keep validated working buffers separate from stored caller identity, and retain exact original tests alongside targeted new input checks.

## 12. Cross Product Coverage

Ordinary ML/REML dense, sparse REML, AI and Henderson result identity; public dispatches; canonical-Q exceptions; explicit method override; relationship-diagonal cache provenance; input nonmutation; malformed finite/rank/precision rejection; 202 previously integrated guards; exact original 37-check fitting contract.

Parent next action is independent review of this pinned source/patch/test packet, application of the delta and a fresh package rerun. Independent approval of this author repair remains pending.
