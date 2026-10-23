# FA exact-current ordinary-start replay

## Estimate

Estimated about two minutes from the existing 42–97 second per-fit receipts plus Julia startup. One development seed only; no primary campaign.

## Run

`HSQUARED_RUN_FA_ORDINARY_START=1 OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-review-depot:/Users/z3437171/.julia JULIA_PKG_OFFLINE=true julia --project=. --startup-file=no sim/fa_ordinary_start_recovery_20260928.jl --mode=development --seeds=20261406 --out=/private/tmp/hsquared-fa-exact-current-seed-20261406.tsv`

Result: Julia 1.10.0, four Julia threads, one BLAS thread, CPU only; 94.169 seconds. Both default and balanced starts converged; balanced selected. Relative G/R errors 0.3767708/0.2093658, fit-minus-truth objective 8.3251536, minimum uniqueness 0.1476362, 2,606 selected iterations. The frozen one-cell diagnostic criteria passed.

## Exact provenance

- Source-tree SHA-256: `ba890556104f44f8d6b7c54d90c0962beb0816b90753de9a9f01ec4ab25f00d1`
- Driver SHA-256: `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`
- Retained output SHA-256: `20e8229e9e03577b1be2e2e0d25ba0ab7d222c3be4a1b0769c1352f075c09dc4`
- Retained row: `docs/dev-log/recovery-checkpoints/2026-09-29-fa-exact-current-replay.tsv`

This establishes exact-current execution and one development-seed start behavior only. It is not a recovery-rate estimate or broad reliability evidence. The 200-seed primary is still unstarted; the conservative estimate remains about 8.1 hours and requires Shinichi's approval before launch.
