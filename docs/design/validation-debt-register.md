# Validation Debt Register

| ID | Capability | Status | Required evidence |
| --- | --- | --- | --- |
| V0-LOAD | Package loading | covered | `using HSquared` in test suite |
| V0-CTRL | Control validation | covered | default and invalid control tests |
| V0-PLACEHOLDER | Honest placeholder errors | covered | Phase 0 error tests |
| V1-PED | Pedigree validation | covered | tiny malformed and valid pedigrees in `test/runtests.jl` |
| V1-AINV | Sparse `Ainv` | covered | hand-checked tiny pedigrees and dense inverse comparison in `test/runtests.jl` |
| V1-SPEC | Low-level animal model spec validation | covered | dimension, ID, family, and method tests in `test/runtests.jl` |
| V1-LIK | Univariate Gaussian ML/REML likelihood | partial | hand-calculated tiny likelihood tests; still needs Mrode and comparator checks |
| V1-OPT | Dense variance-component optimizer | partial | tiny likelihood-improvement tests; still needs Mrode and comparator checks |
| V1-BRIDGE | R-to-Julia payload parity | partial | R parser exists in `hsquared` head `d85f356`; still needs parity tests for `y`, `X`, `Z`, encoded IDs, pedigree metadata, family, method, Julia-side `Ainv`, and fit-target dispatch |
| V1-REML | Sparse Gaussian REML optimizer / AI-REML | planned | Mrode simple animal model and comparator check |
| V1-EBV | EBVs/BLUPs | planned | known fitted values against comparator |
| V3-MV | Multivariate Gaussian animal model | planned | long-format missing-record recovery |
| V4-FA | Factor-analytic G matrix | planned | simulated loading and Psi recovery |
| V5-GBLUP | Genomic and single-step models | planned | JWAS/sommer/BLUPF90 style comparator checks |
| V7-INHERIT | Non-standard inheritance | planned | relationship construction and biological interpretation checks |

Rows must be updated before public docs promote a capability.
