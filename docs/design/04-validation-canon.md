# Validation Canon

Validation is a first-class engine requirement. Public capability claims need
evidence in tests, docs, and the check log.

## Validation Hierarchy

1. Tiny deterministic hand checks.
2. Pedigree and sparse `Ainv` known examples.
3. Simple Mrode-style examples.
4. Comparator model outputs where available: ASReml, BLUPF90, DMU, WOMBAT,
   sommer, or MCMCglmm.
5. XSim simulation truth for later genomic and selection examples.

## V0.1 Validation Targets

`validation_status()` exposes the current validation ladder as a typed Julia
diagnostic. It does not run comparator packages, fit models, or promote planned
capabilities.

- ID recoding preserves animal labels.
- Pedigree sorting handles founders and unknown parents.
- Sparse `Ainv` matches tiny hand-computed examples.
- Gaussian animal-model likelihood recovers known tiny solutions.
- EBVs/BLUPs and heritability match the R-facing contract.
- Dense validation-path outputs agree with Henderson mixed-model equations at
  supplied variance components.
- Sparse supplied-variance Henderson MME solves agree with deterministic MME
  fixtures before being used inside production fitting.
- The shared R/Julia supplied-variance Henderson MME fixture pins a five-animal
  pedigree, `Ainv`, fixed effects, EBVs, fitted values, and `h2 = 0.6` at
  `sigma_a2 = 1.2` and `sigma_e2 = 0.8`. R head `ca8bce1` records an
  independent R MME reference and a live Julia comparison when the sibling
  checkout is available.
- A Julia-native Mrode9-shaped supplied-variance fixture uses the 12-animal
  `nadiv::Mrode9` pedigree structure and pins `Ainv`, ML/REML likelihood
  values, fixed effects, EBVs, fitted values, PEV, reliability, derived
  accuracy, and `h2` at supplied variance components. This is equation and
  extractor validation only.
- Pedigree inverse construction has optional external comparator coverage
  through the R twin's `nadiv::Mrode9` / `nadiv::makeAinv()` live test.

Still missing from the Mrode lane:

- fitted Mrode animal-model response data;
- estimator target;
- expected variance components;
- EBVs/BLUPs;
- heritability;
- comparator versions and tolerances for fitted outputs.

The supplied-variance Henderson and Mrode9-shaped fixtures are not fitted Mrode
models and do not estimate variance components.

## Status Words

- `planned`
- `partial`
- `covered`
- `covered_external`
- `blocked`
- `deprecated`

Only `covered` capabilities may be described as working in public docs.
`covered_external` may be described only with its external-evidence boundary,
such as pedigree inverse agreement in the R twin, not as bundled Julia
coverage or fitted-model support.
