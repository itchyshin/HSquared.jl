# Independent sparse-helper identity completion

## 1. Goal

PASS for the second, minimal specification-identity completion prepared by Gauss/Sol. Actual reviewer Astra high. This closes the legacy `_validated_sparse_relationship_spec` reference-contract regression on exact proposed bytes. Full package completion remains pending parent execution.

Base likelihood `1a6fa73396566ba66a785960b8df4db7201f98b0d8c9f2953b9676e68d917f9d`; proposed source `d77e6565e574ce428371fb86f8322d12edc977ead5f05093d24c4204ef85e935`; patch `4480577a431283969661f4930684cc4fef9b37cff3349d6cde971ec32dc008ef`.

## 2. Implemented

No author or live edit. Independently inspected the frozen patch, verified all50 author inventory entries, reconstructed source/test from exact base, read the legacy helper's three computational callers and all relevant existing identity assertions, then ran the focused suite in a separately owned package copy.

## 3a. Decisions and Rejected Alternatives

Keep the legacy validating return contract: original reference when effective precision and method remain equivalent; validated canonical spec for actual precision changes. The factor always belongs to the validated canonical Float64 precision. All three numerical consumers call `_likelihood_validated_spec` directly, preserving converted working buffers independently of legacy result identity. This avoids introducing raw-type computation as a side effect of restoring an API contract.

## 4. Files Touched

Only this directory's copied package, checks, logs and receipt, plus the owned final numerical-panel report. No live source, original tests, runner, driver or other lane files edited.

| Artifact | SHA256 |
| --- | --- |
| `package/src/likelihood.jl` | `d77e6565e574ce428371fb86f8322d12edc977ead5f05093d24c4204ef85e935` |
| `test/likelihood_helper_identity_regression.jl` | `1a070d94fd464275064830367088a593134ad66daed27d64c8e0a715996187d1` |
| `independent-controls.jl` | `e4d0a653e696cdeef60477f44d6ebe49ae29de6c37a831609d8ea3d45c8dd943` |
| `review.log` | `5cefaa8b0409e9d516b03e9a30c196889b4698c14dfea85da2f3d0950454d6bc` |
| `verification.json` | `44cf0ae02fc3c1700d5e682c27cf04907b287160ff855c4292274927a37ebb3e` |
| `run.jl` | `05f00dd1ce059a2a627d2c539c5c56b17c2029a383c9be8e597de2f558a81d10` |

## 5. Checks Run

694/694 PASS:670 submitted/original checks and24 independently frozen controls. Exit0,36.55s, Julia1.10.0, measured JuliaThreads1/BLASThreads1, compiled modules/startup disabled, existing project/Manifest/depot, explicit120s timeout. Estimate before launch under2min. Original bounded fitting testsets retain their original iteration settings; new fits use three records and one iteration. No new simulation, campaign, GPU, dependency update or full package run.

The entire original sparse-input file is byte-identical to live. All four extracted original testset bodies occur verbatim in the live runner; Henderson's `_solve_mme_for_test` oracle is also byte-identical. Patch application exactly reproduces submitted source/new test. Replacing only the validator-call name restores each of the three numerical bodies exactly to its base.

## 6. Tests of the Tests

Author original sparse red run failed the unchanged reference assertion. Its first expanded green attempt encountered a missing standalone Henderson prerequisite; failed log/extraction are preserved and exact prerequisite restored. No test assertion was weakened.

Independent controls were frozen before packet inspection, SHA e4d0a653e696cdeef60477f44d6ebe49ae29de6c37a831609d8ea3d45c8dd943, and executed unchanged. They check original Float32 and metadata identity, separate converted/sparse computational buffers, factor consistency, likelihood equality between legacy/computational inputs, actual precision canonicalization/cache dropping, nonmutation and invalid finite/conversion/rank/SPD refusal. All24 pass.

## 7a. Issue Ledger

- Legacy sparse helper identity: resolved at proposed bytes, original assertion passes.
- Three computational callers: direct canonical validator calls preserve prior computation exactly.
- Public and internal result identities: original constructor16/fit37/Henderson42/internalAI23, prior64 and full original sparse26 pass.
- Finite/rank/precision/output guards: prior202 and new46 helper controls pass; no bypass introduced.
- Selector/finite-difference neighbors:192+22 pass on the corrected package.
- Integrated full-suite freshness: still owed after exact application.

## 8. Consistency Audit

Exhaustive src/test search and Graft agree on three computational consumers: supplied sparse likelihood, sparse REML fit and AI implementation. They no longer consume the legacy return. Source review of the five textual change groups finds no objective, optimizer, starts, covariance, uncertainty or iterative change. The prior result selector is unchanged. Original stored/cached reference semantics remain caller-mutable; validation is not a concurrent mutation guarantee.

Predicted source-root aggregate after this sole delta on the current2ae tree is `11f6319f4fcc9f69b98d0291676d5fe44bd5252485b09853d2e5553225abd773`. Parent must verify actual application.

## 9. What Did Not Go Smoothly

The preceding identity correction missed the separately tested helper contract; the full suite exposed it after the public fit assertions passed. This review now checks constructor, fit, helper, internal/public AI and cache contracts together. No independent execution failure occurred. Graft reported56220estimated tokens saved; exact source/tests controlled the review.

## 10. Known Residuals

No whole-package success, calibration, arbitrary conditioning/range or immutable-input guarantee follows. The legacy helper may return original Float32 or other supported arrays alongside a Float64 canonical factor; numerical consumers use the separate converted helper. All existing inference and public-scope limits remain.

## 11. Team Learning

Reference identity can be a separate contract at each helper, result and cache boundary. Restore the specific boundary and make numerical consumers explicit; retain every original assertion during compatibility repair.

## 12. Cross-Product Coverage

Covers legacy validator identity, canonical precision/factor/cache behavior, converted working arrays, all three numerical consumers, original constructor/public/internal result identities and the listed regression neighbors. This does NOT cover final package/bridge/docs completion, new fitting capabilities, statistical calibration, GPU or release. Apply only the exact delta and register the new regression once before the final package rerun.
