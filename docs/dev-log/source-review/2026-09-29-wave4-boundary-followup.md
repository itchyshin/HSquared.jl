# Wave 4 genomic boundary classifier follow-up

## Scope and pinned source

- Baseline commit: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Original `src/likelihood.jl` SHA-256: `8c60feea113e703e156561ae39a1af1131d356d7c457b1c1d23451d627e47058`.
- Final `src/likelihood.jl` SHA-256: `bb81d2fae7e1418b806bc771270df6f620e86ed33de8a4590b8d73d739b4e283`.
- Final focused test SHA-256: `26702d54ebbd7253312cc240747dff170493d5f6136155b382b8d26abd3ee020`.
- Reviewed regions: genomic boundary provenance precheck, profile context/objective, endpoint score/classifier, and `_fit_ai_reml_genomic_boundary` numerical wrapper; regression in `test/wave4_genomic_boundary_near_endpoint.jl`.

## Findings and disposition

1. **False lower endpoint.** A deterministic SPD fixture with `n=3`, `X=e3`, `Z=I`, `K=diag(1+1e8, 1/2, 1)` has a strict interior maximum at approximately `r=2e-8`. The frozen `delta=1e-6` secant has the opposite sign, and replacing the refined near-endpoint candidate with its coarse-grid value could classify the result as `boundary_lower`. The candidate now computes the exact profiled REML score at both endpoints and retains the refined likelihood for endpoint comparison. The score keeps design 46's lower and upper KKT signs. Because the maximum lies inside the strict-interior epsilon, this fixture returns `boundary_unresolved` rather than an endpoint or a strict-interior fit.
2. **Malformed provenance.** Missing or non-string relationship source and fingerprint fields could throw during Boolean comparisons. The precheck now validates these fields before membership/equality checks and returns an unresolved result.
3. **Numerical exceptions.** The resolver now converts `PosDefException`, `SingularException`, `LAPACKException`, and sparse `ZeroPivotException` to an unresolved result. Other errors, including `ArgumentError`, are rethrown.

## Contract amendment

Frozen design 46 is unchanged. The current candidate deliberately differs from its fixed-step endpoint finite-difference algorithm by using the analytic derivative and retaining endpoint-adjacent refined likelihoods. The amendment is recorded in `docs/design/59-v07-genomic-boundary-score-amendment.md`; the historical July holdout does not validate this algorithm. Rose confirmed the capability-status wording now distinguishes the frozen July candidate from this amended experimental resolver. Capability rows and `public_covered_count` are unchanged.

## Verification

- TDD reproduced the false `boundary_lower` result before implementation.
- Focused registered test passed 19/19, including the near-zero sign reversal, score checks at both endpoints with two fixed-effect columns, all four malformed provenance fields, typed numerical failure conversion, and programming-error pass-through.
- Full Julia 1.10.0 `Pkg.test()` passed, ending `Testing HSquared tests passed`. The existing Project/Manifest mismatch warning remained; no resolve or update was run.
- `git diff --check` passed; `bash tools/preamble_cap.sh` passed at 11,024/14,000 bytes with one snapshot entry.
- `memory_regression.py --selftest` passed.

## Review and remaining limits

- Noether independently checked the derivative algebra, score normalization, endpoint signs, and near-endpoint comparison. Gauss independently checked the score and the typed catch boundary. Both reviews are scoped to these functions.
- Rose found an ambiguous historical capability-status phrase; it now names the frozen July candidate and links design 59. Rose's follow-up audit passed.
- The historical 240-seed receipt is not transferred to this amendment. No matched R-oracle run, broad endpoint calibration, upper-endpoint near-threshold recovery, whole-file Wave 4 signoff, or E1 completion is claimed. E1, A2, and V3 remain open.
- No campaign, GPU execution, release submission, registry submission, merge, or tag occurred.
