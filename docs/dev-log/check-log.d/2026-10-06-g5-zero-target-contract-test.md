# G5 v4 zero-target reduced-model contract regression

- Source: current worktree `codex/arc1-gaussian-reliability-20261002`.
- Test: `test/arc1_profiles_v4.jl`, `v4 zero-target reduced models preserve Va and Vpe boundaries`.
- Command: `JULIA_DEPOT_PATH=/private/tmp/arc1-g4-bootstrap-boundary-depot-20261006:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --startup-file=no --project=. test/arc1_profiles_v4.jl`.
- Final v2 result: exit 0; Julia 1.10.0; 30/30 engine-path tests and 231/231 bounded-control tests passed; elapsed 26.467 s.
- Final raw stdout: `2026-10-06-g5-zero-target-contract-test-v2.log`, SHA-256 `6d19d3f898a28448e34f14e9c24b6234760a58f12b5ba59c3e8e6c9850aeabaf`.
- Intermediate v1 result: 257/257 tests; preserved separately in `2026-10-06-g5-zero-target-contract-test.log`, SHA-256 `d1c9f1aca770c9b8b00e04a44e0a327ddd3d3a9266405c4ab21ba4d33ceea206`.
- Scope: controlled callback contract for Va=0 and Vpe=0; exact-zero nuisance faces keep target and held-zero coordinates; production profile path returns finite status for positive residual variance and refuses a singular residual-zero proposal.
- Limit: no fitted intervals, calibration, simulation, R parity, or acceptance-gate transition. G5 remains unmet.
- Other checks are rerun after this evidence correction: `git diff --check`, report style scan, and structural after-task check. The slice changes no gate status: G2-G5 and G8 remain open; the current checkpoint/ledger record G0, G1, G6, and G7 as verified.
- Receipt: `docs/dev-log/after-task/2026-10-06-g5-zero-target-contract-test.md`.
