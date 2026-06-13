---
name: bridge-contract-review
description: Review the future bridge from hsquared R calls to HSquared.jl. Use for marshalling, JuliaCall or other bridge choices, result-shape parity, engine controls, and R placeholder/error wording.
---

# Bridge Contract Review

## Procedure

1. Read the v0.1 and engine contracts.
2. Identify the R model specification that will cross to Julia.
3. Confirm that unsupported syntax errors before marshalling.
4. Keep Julia engine controls under an engine-specific surface.
5. Ensure result fields map to documented R extractors.
6. Record bridge gaps in the validation debt register.

## Lenses

- Hopper: R-Julia translation.
- Lovelace: eventual `engine = "julia"` user ergonomics.
- Emmy: R object shape.
- Rose: public claim audit.
