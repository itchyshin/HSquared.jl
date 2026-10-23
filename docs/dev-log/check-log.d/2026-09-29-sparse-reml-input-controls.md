# 2026-09-29 sparse REML input controls

Focused regression tests pass 26/26. They reject asymmetric, indefinite, singular, and non-finite relationship precision; compare direct sparse REML for tolerated roundoff asymmetry with the explicitly averaged precision; verify canonical inputs retain the original spec; reject invalid iteration counts; and reject non-finite or unrepresentable starting variances.

The full Julia 1.10 `Pkg.test()` run ended with `Testing HSquared tests passed`. It included the direct sparse REML tests and all existing FA, GLLVM, bridge, and package testsets. Julia warned that Project dependencies or compat requirements differ from Manifest; no resolve or update was run. `git diff --check` passed for the changed source and regression test files.

Gauss and Noether reviewed the exact source and test hashes and passed the scoped numerical and contract review. Source hashes: `src/likelihood.jl` `67fbbc2e0682ca4893549489a8ea95d02e0123f69a10eb3a284385acea7b06cb`; `src/iterative_solve.jl` `265cfc8d6ba9ca33475b85c56c4701cdd0359b90db9b0cdcae47c6740f4d8a34`; `test/test_sparse_aireml_input_contracts.jl` `a8de2200cf633be1635124b2de8a233516a2441916efd5bd1d7bb9b1bb8ce2da`.

The after-task structure validator passes. Acceptance-ledger status remains open: root gates A2, E1, and V3; W105 G4; and Wave 2 bridge G4 are unmet. The GLLVM foundation ledger has two runnable checks not yet executed.

This closes only direct sparse REML relationship-precision and optimizer-control validation. It changes no capability row, validation-debt status, public claim, or covered count. A2, E1, and V3 remain open. No simulation, GPU run, R bridge change, release submission, registry submission, merge, or tag occurred.
