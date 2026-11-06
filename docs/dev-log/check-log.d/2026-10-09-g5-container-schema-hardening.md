# G5 container schema hardening check record

- Status: narrow nested-schema engineering slice passed; no G5 gate credit.
- Focused command: `JULIA_DEPOT_PATH=/private/tmp/hsquared-arc1-julia-cache:/Users/z3437171/.julia julia --project=. test/arc1_simulation_executor.jl`
- Exit: 0.
- Results: source-bound executor 326/326 in 4m34.4s; reference-admission and rank-comparison receipts 15/15; exact UTF-8 diagnostic identity 15/15.
- Covered change: explicit nested entry fields and value types for `producer_history` and `provenance_failures`, checked on write and after reader event-reference reconstruction.
- Tests of the tests: malformed nested producer and provenance entries must fail at their designated validator messages on both writer and reader paths. The suite also retains malformed core-row, unsupported sparse-index, and directory mutation cases.
- First run: failed 2 assertions and 2 test cases against source loaded before the post-reconstruction fix, and a fresh-process subprocess could not write to the default Julia cache. Preserved in session output; no evidence was counted. The final run used a disposable cache in `/private/tmp` and passed.
- `git diff --check`: passed.
- Current hashes: `sim/arc1/artifact_container.jl` `a3e5d546f0ede3898236531431d791319bee6bb848244336d4c160edc8f4c6b9`; `test/arc1_simulation_executor.jl` `83572254661f026be00cb20ac661201d08b0ae6c4676b0224d43043973854983`.
- Astra exact-source review: PASS for these final hashes; the producer-declared field sets and post-reconstruction reader check match the current source. Review limits: producer `record` payload and `source_id` internals are not validated, and provenance `value`/`tag` are preserved as arbitrary diagnostics.
- G5 remains open: other nested diagnostic schemas, the raw-diagnostic/certificate mutation matrix, current-source performance, and admission prerequisites remain unmet. No fit, seed, study attempt, legacy artifact read, or gate transition occurred.
- G1/G6/G7 retained checks remain reopened for the current inventory; do not reuse the earlier frozen-source passes as current evidence. G0 remains met.
