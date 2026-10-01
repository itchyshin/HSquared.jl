# 2026-09-29 Wave 4 genomic boundary classifier follow-up

Estimated before execution: focused tests under one minute; full `Pkg.test()` about five minutes based on the previous exact run. No simulation, fit campaign, or GPU work was run.

- First focused attempt could not load HSquared because Julia tried writing its compiled cache under the protected default depot. Rerun with `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia` succeeded.
- TDD red run: the deterministic near-zero strict-interior fixture returned `boundary_lower` instead of `boundary_unresolved`. A second red run reproduced `TypeError: non-boolean (Missing) used in boolean context`. The numerical-guard test failed with `UndefVarError` before the guard existed.
- Final focused `test/wave4_genomic_boundary_near_endpoint.jl`: **19/19 passed**.
- Final full Julia 1.10.0 `Pkg.test()`: passed; output ended `Testing HSquared tests passed`. The existing project/manifest mismatch warning appeared. No `Pkg.resolve()` or update was run.
- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: passed at 11,024/14,000 bytes, one snapshot entry.
- `python3 /Users/z3437171/shinichi-brain/tools/memory_regression.py --selftest`: passed, all detectors discriminated.
- After-task structure check passed. Its integrated acceptance-ledger check still has five open programme gates: `.unlazy/hsq-fa-closeout/GATES.md`, `.unlazy/hsq-gllvm-foundation/GATES.md`, `.unlazy/hsq-w105/GATES.md`, `.unlazy/hsq-wave2-bridge-GATES.md`, and root `GATES.md`. They remain open; this bounded source repair does not abandon them.
- No docs build or hosted CI was run. The checked-in design amendment and status wording are not deployment evidence.
- Scoped reviews: Gauss/Astra and Noether/Sol approved the math and exception boundary; Rose passed the claim/status wording after the historical-candidate clarification.
- Exact implementation, evidence boundary, hashes, and open findings: `docs/dev-log/source-review/2026-09-29-wave4-boundary-followup.md`.

This repairs one Wave 4 source-contract subfinding only. E1 remains open, along with A2 and V3. No capability status or covered count changed, and no release, registry, GPU, merge, or tag action occurred.
