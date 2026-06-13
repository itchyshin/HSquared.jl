# Validation Status

`validation_status()` exposes the current validation ladder as typed Julia
rows. It is a diagnostic table, not a comparator runner and not a fitting
helper.

```@example validation_status
using HSquared

status = validation_status()
length(status)
```

```@example validation_status
[row.id => row.status for row in status]
```

## Current Rows

| id | capability | phase | status | claim boundary |
| :--- | :--- | :--- | :--- | :--- |
| `V0-LOAD` | package loading | Phase 0 | covered | Package loads; this is not modelling evidence. |
| `V1-PED` | pedigree normalization | Phase 1 | covered | Pedigree validation utility only; no fitting claim. |
| `V1-AINV-TINY` | sparse Ainv tiny checks | Phase 1 | covered | Direct sparse Ainv utility; not a fitted animal model. |
| `V1-AINV-MRODE9` | Mrode9 pedigree inverse comparator | Phase 1 | covered_external | Pedigree inverse agreement only; not fitted Mrode output validation. |
| `V1-LIK` | Gaussian likelihood tiny checks | Phase 1 | partial | Dense validation evaluator only; not production sparse fitting. |
| `V1-SPARSE-REML` | sparse REML identity | Phase 1 | partial | Supplied-variance REML objective only; no variance-component estimation. |
| `V1-MME` | Henderson MME supplied-variance solve | Phase 1 | partial | Supplied variance components only. |
| `V1-DENSE-OUT` | dense output extractors | Phase 1 | partial | Experimental dense low-level outputs only. |
| `V1-MRODE-FIT` | fitted Mrode animal-model outputs | Phase 1 | planned | Fitted Mrode validation is not covered. |
| `V1-COMPARATORS` | external fitted-model comparators | Phase 1 | planned | No fitted comparator parity claim. |
| `V5-GENOMIC-QTL` | genomic, marker, QTL, and eQTL validation | Phase 5 | planned | No genomic prediction, marker scan, QTL, or eQTL support. |

## Boundary

`covered_external` means the evidence is recorded in the R twin or another
external validation path and is not independently bundled as Julia test data.
For example, the Mrode9 row records the R twin's optional `nadiv::Mrode9` /
`nadiv::makeAinv()` comparison against Julia `pedigree_inverse()`.

That evidence covers pedigree inverse agreement only. It does not cover fitted
Mrode variance components, EBVs, heritability, reliability, PEV, or external
ASReml/BLUPF90/DMU/WOMBAT/sommer/MCMCglmm fitted-model parity.
