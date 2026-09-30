# Sparse validating-helper identity completion

## 1. Goal

Complete the inherited specification-identity repair after the fourth original package run failed at `test/test_sparse_aireml_input_contracts.jl:59`: `first(_validated_sparse_relationship_spec(exact_spec)) === exact_spec`. Preserve original assertions and canonical computational buffers.

Exact integrated base `src/likelihood.jl`: `1a6fa73396566ba66a785960b8df4db7201f98b0d8c9f2953b9676e68d917f9d`. Parent identified the live tree as the frozen 2ae source tree. Work is isolated under `/private/tmp/hsq-likelihood-helper-identity-fix-20260930/`; independent review and parent application remain pending.

## 2. Implemented

The legacy `_validated_sparse_relationship_spec` validates through `_likelihood_validated_spec`, then returns `_likelihood_result_spec(original, validated)` with the canonical factor. It preserves the caller's original reference when effective method and converted precision are unchanged. An actual precision canonicalization returns the canonical spec and drops stale relationship-diagonal metadata.

All three computational callers now use `_likelihood_validated_spec` directly: supplied sparse likelihood, sparse REML fitting and the AI implementation. Their working arrays therefore remain converted Float64/sparse and use one canonical precision. Dense evaluation/fitting and Henderson already use that computational helper directly and are unchanged.

This separates the legacy validating return contract from computational working buffers. Original/converted finite checks, dimensions, sparse fixed-rank checks, canonical symmetry/SPD checks, ID checks, factors and finite output checks are unchanged.

## 3a. Decisions and Rejected Alternatives

The original helper was an internal validation API with an explicit reference-retention test. Reconstructing every valid specification had changed that API. Public result selection alone did not restore the helper test, so this correction closes the actual helper boundary.

The three numerical consumers continue to receive canonical Float64 working arrays. Their bodies change only the called validator name. Returning raw original arrays to these consumers was unnecessary and could weaken the intended computational contract.

The original reference retains established mutable-input semantics. No immutable snapshot or concurrent mutation guarantee is added. Method override and canonical-Q exceptions from the prior independently reviewed correction remain unchanged.

## 4. Files Touched

Only owned scratch files: copied project/source execution snapshot, exact baseline, new `test/likelihood_helper_identity_regression.jl`, copied original/focused tests, original testset extractions, evidence logs, source/new-test patch, runner proposal, inventory and this receipt. No live source, test, runner, Git state, driver or other lane was edited.

| Artifact | SHA256 |
| --- | --- |
| Prepared source | `d77e6565e574ce428371fb86f8322d12edc977ead5f05093d24c4204ef85e935` |
| Unified patch | `4480577a431283969661f4930684cc4fef9b37cff3349d6cde971ec32dc008ef` |
| New helper regression | `1a070d94fd464275064830367088a593134ad66daed27d64c8e0a715996187d1` |
| Final green log | `6bf77bb8b2493da7adc79743efd5a487deea1ee61d1e4b7936fb928813f8fb88` |
| Identity/caller sweep | `151972b21b0e3abb9012d6acfae835c30179e36c49e10dce3d18e188e8d15b5b` |
| Body verification | `40dc8370341bc8f1d9c071b7aa730126b9e93b64122caabab4fe3d82bf7cf06b` |
| Inventory | `2f1c51a0da67c3b66196e77714cf45592dc6329246e823ed519d5edb08241379` |

`runner-append.txt` proposes one include for the new file. Existing files/includes stay as registered. Parent must apply the delta after independent review and add that include once.

## 5. Checks Run

Estimated each focused invocation under two minutes. Julia 1.10.0 with startup/compiled modules disabled, Julia/BLAS measured one thread each, existing project/Manifest/depot, Python timeout 110 seconds with child kill/wait on expiry.

| Run | Actual result | Wall time |
| --- | --- | --- |
| Original sparse file on base, `red-001.log` | 12 pass / 1 fail before later testsets | 20.55 s |
| First corrected-source run, `green-001.log` | Preceding checks passed; standalone Henderson extraction missing prerequisite | 31.56 s |
| Final corrected-source run, `green-002.log` | 670/670 | 35.32 s |

Final passing checks:

| Scope | Checks |
| --- | ---: |
| Entire original sparse AI input file | 26 |
| New legacy-helper/computational-buffer checks | 46 |
| Prior result identity regression | 64 |
| Prior finite/rank/precision/result guards | 202 |
| Exact original specification-constructor testset | 16 |
| Exact original dense/sparse fit testset | 37 |
| Exact original Henderson fixture | 42 |
| Exact original internal/public AI identity testset | 23 |
| Existing uncertainty/selector checks | 192 |
| Existing derived-step checks | 22 |
| Total | 670 |

New tiny fit controls have three records and one iteration. Original testsets retain their original bounded settings. No new simulation, campaign, GPU, remote run, package-wide rerun or dependency update occurred. Command, timeout, elapsed time and exit code are preserved in run JSON files.

The unified patch passes application checks against a separate exact baseline and reproduces the tested source and new regression bytes. Source/runner in the live candidate remain unchanged by this child.

## 6. Tests of the Tests

The entire original sparse-input file was copied byte-for-byte; its old reference assertion first failed on the integrated baseline and passes after this repair. The final run also executes all its later iteration/parameter checks.

All four selected original runner testset bodies are byte-identical to the live original bodies. Standalone prerequisite imports/helper definitions were added outside those bodies. The existing 64 identity, 202 ingress and selector test files were copied without alteration.

Fresh Float32 controls verify legacy reference retention and metadata identity while the computational helper returns separate Float64 sparse buffers. They check nonmutation, equivalent likelihoods, sparse/AI result identity, cache-return identity, canonical-Q/cache changes and malformed original/converted response/design/precision rejection.

Golden Set: original constructor/fit/Henderson/internal-AI/helper identity assertions, full original sparse-input controls, 64/202 prior regressions, 214 selector/step checks and 46 fresh helper/buffer checks. No original assertion was weakened.

## 7a. Issue Ledger

| Item | Disposition |
| --- | --- |
| Legacy sparse helper original-reference regression | Repaired in scratch; original test passes |
| Computational canonical-buffer contract | Preserved through direct helper use in all three callers |
| Public dense/sparse/AI/Henderson identity | Preserved; prior and original checks pass |
| Canonical Q and stale diagonal metadata | Preserved; original and new controls pass |
| Full package freshness | Parent rerun required after application |

## 8. Consistency Audit

Graft callers locate supplied sparse likelihood, sparse fitting, AI implementation and the original helper test. An exhaustive current src/test sweep records 51 identity/helper/caller matches. Production callers now use the computational validator directly; the legacy validator remains available for its reference-retaining API.

Every relevant original identity assumption was classified:

- Constructor y/X/Z/Q reference assertions: exact original 16-check testset replayed.
- Dense and sparse fit-spec references: exact original 37-check testset replayed, with prior 64-check regression.
- Supplied Henderson reference: exact original 42-check fixture replayed.
- Internal/public AI fit-spec reference: exact original 23-check testset replayed.
- Sparse validating-helper reference: entire original 26-check file replayed.
- Relationship-diagonal cache reference and absent cache: source contract reattested; fresh tiny Float32/cache checks exercise the same identity path. The original 1+F file had already passed before the parent's current full-run stop; its larger seeded fixture was not rerun here.
- FA uniqueness `=== nothing` and unrelated metadata `nothing` conditions: separate source contracts, untouched by this delta.

`change-verification.json` verifies 125 other extracted whole function bodies remain byte-identical, including the result selector, canonical/finite validator, Henderson and all L1/L2 helpers. Replacing only the called validator name restores the exact original body of each of the three numerical consumers. Five textual change groups comprise three call replacements and the legacy helper/comment changes.

Memory receipt: inherited operating guidance for shared lane preservation; exact current source/tests establish numerical truth. Graft was consulted first and its live-only graph returned precise current callers. Its reported token-saving estimate for the two queries was 57,062.

## 9. What Did Not Go Smoothly

The first identity correction audited public fit result references but missed the separate legacy helper assertion. The parent full-suite run found this additional concrete boundary. The expanded sweep now covers all relevant original identity assertions and exact current callers.

The first expanded scratch invocation omitted `_solve_mme_for_test`, a prerequisite of the extracted Henderson fixture. All preceding corrected controls passed; that extraction then errored before later assertions. The exact original helper was added outside the unchanged testset body. Failed extraction/log and preparation note are retained. No proposal source change was required for this standalone test repair.

## 10. Known Residuals

This correction does NOT cover full-package completion, statistical calibration, arbitrary range/conditioning, immutable/concurrent input semantics, capability promotion, public R grammar/schema or new estimators. Existing likelihood and iterative inference/numerical limits remain unchanged.

The legacy helper can retain Float32 or other original array types after successful converted validation. Its factor belongs to the canonical Float64 precision. Numerical consumers use the separate converted helper and do not rely on raw legacy return types.

## 11. Team Learning

An internal helper can have an independently tested reference contract even when public numerical outputs are unchanged. Audit result references, helper references, constructor aliases and cache references together. Keep converted working arrays on an explicit computational route while preserving the original validating API.

## 12. Cross Product Coverage

Full original sparse-input file; constructor and public/internal fit identities; supplied Henderson; Float32 p=0/p=1 legacy/helper computational buffers; canonical precision and cache provenance; finite conversion/rank/precision refusal; prior 64/202 regressions; uncertainty selection/step contracts.

Parent next action is independent Astra review of the frozen packet, application of this exact delta and resumption of the package run/panel. Independent approval and full-suite completion remain pending.
