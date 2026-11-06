# G2 outer10 K1 reference-status interpretation

Date: 2026-10-08  
Reviewer: Astra, independent read-only review  
Verdict: PASS for interpretation of the retained K1 status records only.

## Scope

Determine why the expanded-reference `best_by_rank[1]` row is `finite_unaccepted` while the current ordinary selector has an eligible K1 result with a matching likelihood. No fits, code edits, policy changes, or G2 credit were authorized or performed.

## Evidence

- Expanded-reference case: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-only-v5/output/run-20261007T213821Z-70db5b9c/outer0010.json`, SHA-256 `09da833de62ce18dc94db6b81d56652feb4739b43a8bf80cc83723f310fd6f9e`.
- Current selector case: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v1/output/run-20261008T024259Z-2015b815/outer0010.toml`, SHA-256 `66070cb30a67fb288363d1b540ec0c6da40c9a527ca3154e7ab69dc1443b7ac4`.
- Current reference source: `sim/arc1/reference.jl`, SHA-256 `3fa05682b1dda61be259f21a8275a113337f39a3db007c41a69995bfe573b080`.
- Frozen output projection: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-reference-only-v5/expanded_reference.jl`, SHA-256 `14eec9906c909c7086dca83e6ebbd3d59b07eb1d21bbca628ba38899f079562d`.

## Finding

For K1 start `amplitude_0.025_sign_ppmp`, schedule index 3, the Nelder-Mead row first recorded likelihood `-447.7326852042336` as `finite_unaccepted` because that optimizer did not converge. The final BFGS row later recorded the exact same parameter vector and likelihood as `admissible`; it converged, was accepted, had successful line search, and passed the analytic and two-scale numerical gradient checks. The ordinary selector's eligible K1 result was `-447.73268520423966`, a shortfall of `6.08225e-12`.

The reference tracker retains the earliest observation when likelihood and schedule index tie (`arc1_reference_prefer_global`, `sim/arc1/reference.jl:123-130`). The output projection looks up that retained stage and copies its status (`expanded_reference.jl:155-163`). Therefore `best_by_rank[1]` preserves the earlier Nelder-Mead status even though the same point has a later admissible witness. The K1 status concern is resolved as a projection and tie-provenance effect; the later admissible witness remains valid.

This finding does not resolve outer10 K0. Its ordinary/reference shortfall remains `0.16953374156236123`, above the frozen `0.0001` tolerance. The reference K0 point is not an acceptance witness for the ordinary candidate. G2 remains open and this review grants zero G2 credit.
