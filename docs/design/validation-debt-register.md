# Validation Debt Register

| ID | Capability | Status | Required evidence |
| --- | --- | --- | --- |
| V0-LOAD | Package loading | covered | `using HSquared` in test suite |
| V0-CTRL | Control validation | covered | default and invalid control tests |
| V0-PLACEHOLDER | Honest placeholder errors | covered | Phase 0 error tests |
| V1-DATA | HSData in-memory input container | covered | phenotype, pedigree, genotype, expression ID-map tests and failure-mode tests in `test/runtests.jl` |
| V1-PED | Pedigree validation | covered | tiny malformed and valid pedigrees in `test/runtests.jl` |
| V1-AINV | Sparse `Ainv` | covered | hand-checked tiny pedigrees and dense inverse comparison in `test/runtests.jl`; shared out-of-order calf/sire/dam fixture with expected Ainv `[1.5 0.5 -1.0; 0.5 1.5 -1.0; -1.0 -1.0 2.0]` mirrored by R head `fe7e346`; optional R-side `nadiv::Mrode9` / `nadiv::makeAinv()` comparator at R head `369d14a` |
| V1-CSC | Sparse CSC bridge marshalling | covered | zero-based R-slot, one-based Julia-slot, malformed-slot, and direct payload integration tests in `test/runtests.jl` |
| V1-SPEC | Low-level animal model spec validation | covered | dimension, ID, family, and method tests in `test/runtests.jl` |
| V1-LIK | Univariate Gaussian ML/REML likelihood | partial | hand-calculated tiny likelihood tests; still needs Mrode and comparator checks |
| V1-SPARSE-REML | Sparse REML likelihood identity | partial | `sparse_reml_loglik()` matches dense REML on tiny fixtures; still needs Mrode and comparator checks and does not estimate variance components |
| V1-OPT | Dense variance-component optimizer | partial | tiny likelihood-improvement tests; still needs Mrode and comparator checks |
| V1-DENSE-GUARD | Dense validation path size guard | covered | `max_dense_cells` failure and boundary tests for likelihood, optimizer, spec dispatch, and direct payload dispatch in `test/runtests.jl` |
| V1-MME | Supplied-variance Henderson MME solve | partial | sparse `henderson_mme()` matches deterministic MME fixture for fixed effects, EBVs, and fitted values; still needs Mrode and comparator checks |
| V1-DENSE-OUT | Dense EBV/heritability/PEV/reliability extractors | partial | hand-checked identity-relationship BLUP, variance-ratio, PEV, and reliability tests plus Henderson MME fixture; still needs textbook Mrode and comparator checks |
| V1-BRIDGE | R-to-Julia payload parity | partial | R payload builder exists in `hsquared` head `b57b48e`; Julia direct payload target has spec-dispatch, parent-index, `ids`, sparse `Z`, Julia-side `Ainv`, and sparse CSC slot tests; R head `398e019` records sparse `Z` marshalling through Julia `sparse_csc_matrix()`; still needs relationship-object marshalling beyond `Z`, public bridge return tests, and Mrode validation |
| V1-RESULT | R-Julia result shape parity | partial | R fitted-object extractor contract exists in `hsquared` head `e543cd7`; Julia `result_payload()` has matching field-name/value tests; R head `c837f2d` normalizes the Julia result into an internal `hsquared_fit`; R head `78ba5ff` adds future PEV/reliability normalization, but Julia payload fields are unchanged until lockstep tests exist; still needs public bridge return tests |
| V1-HSDATA-BRIDGE | R `hs_data()` to Julia `HSData` parity | partial | R `hs_data()` exists in `hsquared` head `644c75e`; Julia `HSData` mirror exists; still needs live bridge marshalling tests |
| V1-REML | Sparse Gaussian REML optimizer / AI-REML | planned | Mrode simple animal model and comparator check |
| V1-EBV | Production sparse EBVs/BLUPs, reliability, and PEV | planned | known fitted values, reliability, and prediction error variance against comparator |
| V3-MV | Multivariate Gaussian animal model | planned | long-format missing-record recovery |
| V4-FA | Factor-analytic G matrix | planned | simulated loading and Psi recovery |
| V5-GBLUP | Genomic and single-step models | planned | JWAS/sommer/BLUPF90 style comparator checks |
| V7-INHERIT | Non-standard inheritance | planned | relationship construction and biological interpretation checks |

Rows must be updated before public docs promote a capability.
