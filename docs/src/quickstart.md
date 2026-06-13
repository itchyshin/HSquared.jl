# Get Started

`HSquared.jl` currently exposes engine utilities, not a full model-fitting
workflow.

## Normalize A Pedigree

```@example quickstart
using HSquared

ped = normalize_pedigree(
    ["offspring", "parent_a", "parent_b"],
    ["parent_a", "0", "0"],
    ["parent_b", "0", "0"],
)
```

The returned pedigree is sorted so known parents precede offspring.

```@example quickstart
ped.ids
```

Unknown parents are encoded as `0` in the normalized parent-index vectors.

```@example quickstart
ped.sire, ped.dam
```

## Build A Sparse `Ainv`

```@example quickstart
Ainv = pedigree_inverse(ped)
Matrix(Ainv)
```

This matrix is the sparse inverse additive relationship matrix used by later
animal-model fitting code.

## What Does Not Work Yet

The high-level fitting functions are placeholders.

```@example quickstart
try
    fit_animal_model(nothing)
catch err
    sprint(showerror, err)
end
```

REML/ML fitting, EBVs, heritability, and R bridge execution remain Phase 1
targets.

## R Syntax Parity Target

The planned bridge target is that R users write the public `hsquared` syntax and
select the Julia engine from R:

```r
hsquared(
  y ~ sex + age + animal(1 | id, pedigree = ped),
  data = dat,
  family = gaussian(),
  engine = "julia"
)
```

That is not executable yet. The current Julia utilities are the engine pieces
needed underneath that bridge.
