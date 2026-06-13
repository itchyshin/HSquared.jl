---
name: pedigree-ainv-review
description: Review pedigree validation, ID recoding, sorting, founder handling, unknown parents, and sparse Ainv construction for hsquared and HSquared.jl. Use before claiming pedigree or animal-model support.
---

# Pedigree Ainv Review

## Procedure

1. Check the target capability row in `docs/design/validation-debt-register.md`.
2. Confirm the pedigree contract:
   - required columns;
   - founder representation;
   - unknown-parent handling;
   - ID recoding;
   - topological sorting.
3. Ask Gauss and Henderson whether the sparse precision path avoids dense A.
4. Ask Curie whether tiny examples and malformed inputs are tested.
5. Record evidence in the check log.

## Hard Rule

Do not advertise animal-model support until Ainv construction and the model fit
both have validation evidence.
