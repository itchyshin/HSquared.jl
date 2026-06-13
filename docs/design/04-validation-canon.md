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

- ID recoding preserves animal labels.
- Pedigree sorting handles founders and unknown parents.
- Sparse `Ainv` matches tiny hand-computed examples.
- Gaussian animal-model likelihood recovers known tiny solutions.
- EBVs/BLUPs and heritability match the R-facing contract.

## Status Words

- `planned`
- `partial`
- `covered`
- `blocked`
- `deprecated`

Only `covered` capabilities may be described as working in public docs.
