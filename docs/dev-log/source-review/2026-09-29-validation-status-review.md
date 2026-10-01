# Exact-current validation status and public-claims review

## Scope and pin

Read-only review on candidate HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.

| File | SHA-256 |
| --- | --- |
| `src/validation_status.jl` | `8778dd2513603115c43f51b4e57fb6d87495a8c8061b66195f58c00a90a4df28` |
| `docs/design/capability-status.md` | `df599ef0566883297f79d0f9fe7b7165a4956e104afdd89f49b2e475a4829c5e` |
| `test/test_212_engine_controls.jl` | `d3617990b66813a67b63d075d8d06e1988fdeb0ae7b5f46017d6dec15e21f302` |

## Verdict

Rose: **PASS WITH LIMITATIONS** for the current capability-status and claim-boundary wording.

- FA remains engine-covered only for the bounded T4/K1 cell, generic positive Ledermann slack, and interior uniqueness values. The public status text says slack is a dimension screen, not local identification proof; sparse-loading points can reduce covariance-map rank; fitted uniqueness information and inference are unassessed. `cov=fa()` remains planned and the R route is partial.
- GLLVM remains partial. The 50/50 ordinary-start replay is one balanced Poisson T3/K2 cell and supports reproducibility for that cell only. It does not support broad recovery or calibration. The claim register's "no broad recovery" statement is conservative, though it omits the one-cell replay.
- Automatic rank is outside current support and is not claimed. The separate experimental GPU row is not evidence of GPU completion in this programme.
- `test/test_212_engine_controls.jl` is a contract-only test and does not alter status. No covered count or capability row should change from this audit.

## Verification

The exact-candidate Julia package suite and status-table consistency test were already recorded as passing in the candidate ledger. This review independently ran `julia --compiled-modules=no --project=. test/test_212_engine_controls.jl`; it passed 15/15 engine-control assertions and 24/24 malformed-genomics input assertions. A normal compiled-module run was blocked because the sandbox denied writing Julia's shared compilation cache; the no-compiled-modules run exercised the source successfully.

No code, status row, public claim, or capability count changed in this review. The audit does not sign off the FA likelihood-information or broad GLLVM recovery requirements and does not close A2, E1, or V3.
