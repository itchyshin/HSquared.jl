# Validation Debt Register

| ID | Capability | Status | Required evidence |
| --- | --- | --- | --- |
| V0-LOAD | Package loading | covered | `using HSquared` in test suite |
| V0-CTRL | Control validation | covered | default and invalid control tests |
| V0-PLACEHOLDER | Honest placeholder errors | covered | Phase 0 error tests |
| V1-PED | Pedigree validation | planned | tiny malformed and valid pedigrees |
| V1-AINV | Sparse `Ainv` | planned | hand-checked tiny pedigrees and reference values |
| V1-REML | Univariate Gaussian REML | planned | Mrode simple animal model and comparator check |
| V1-EBV | EBVs/BLUPs | planned | known fitted values against comparator |
| V3-MV | Multivariate Gaussian animal model | planned | long-format missing-record recovery |
| V4-FA | Factor-analytic G matrix | planned | simulated loading and Psi recovery |
| V5-GBLUP | Genomic and single-step models | planned | JWAS/sommer/BLUPF90 style comparator checks |
| V7-INHERIT | Non-standard inheritance | planned | relationship construction and biological interpretation checks |

Rows must be updated before public docs promote a capability.
