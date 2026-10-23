# Check receipt: exact-current validation-status review

- Candidate: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Reviewer: Rose, current status-table and public-claim audit, PASS WITH LIMITATIONS.
- Source hashes: `src/validation_status.jl` `8778dd2513603115c43f51b4e57fb6d87495a8c8061b66195f58c00a90a4df28`; `docs/design/capability-status.md` `df599ef0566883297f79d0f9fe7b7165a4956e104afdd89f49b2e475a4829c5e`; `test/test_212_engine_controls.jl` `d3617990b66813a67b63d075d8d06e1988fdeb0ae7b5f46017d6dec15e21f302`.
- Command: `julia --compiled-modules=no --project=. test/test_212_engine_controls.jl` from the Julia candidate; exit 0. Engine-control tests 15/15; malformed-genomics input tests 24/24.
- A regular compiled-module invocation could not open Julia's cache pidfile due sandbox EPERM. Disabling compiled modules allowed the test file to run against source without changing the environment.
- Disposition: no capability/status/count change. FA likelihood information, broad GLLVM recovery, automatic-rank validation, and the programme gates remain open.
