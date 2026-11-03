# H3 screen preflight contract check

- Source: `sim/mv_h3_rg_screen_20261004.jl` (`7aedf158ff736807459fede3c52bde434f380105420b7f54a6a8e38ae6756f7c`)
- Tests: `test/test_mv_h3_rg_screen_contract.jl` (`6e9f70b0ec751876a747d64b198be204674082874d0488d5293f5989988cc35f`)
- CHECK: `JULIA_DEPOT_PATH=/private/tmp/h3-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_mv_h3_rg_screen_contract.jl`
- EXPECT: `Test Summary: H3 rg screen contract | 565 passed | 565 total`
- Exit: 0
- Independent source review: Astra ADMIT for source-only, non-executing preflight at the exact hashes above.
- Retained limits: no seed allocation, fit, simulation, timing, screen execution, runtime closure proof, or freshness proof. Admission remains HOLD.
