# Check receipt: single-block coefcov error wording

- Candidate: `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Exact-current hashes: `src/bridge_payload_v2.jl` `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0`; `test/runtests.jl` `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691`.
- Boole exact-hash review: PASS for matching docstring/runtime wording and the bounded parser/dispatch/error contract.
- Focused bridge regression: passed after the repair; full Julia 1.10 `Pkg.test()` on the candidate passed, including the 66/66 integrated parser group.
- Disposition: correct the message only. `coefcov` fitting stays unwired, schema ratification remains pending, and whole E1, A2, and V3 remain open. No status or count changed.
