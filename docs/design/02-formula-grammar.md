# Formula Grammar

The public formula grammar belongs to the R package `hsquared`. `HSquared.jl`
must not expose or imply more model syntax than the R-Julia contract can
support.

Parity target: the user-facing R syntax and any future Julia formula-like
surface should be as close as the languages allow. Small Julia discrepancies
are acceptable only when they are deliberate, documented, tested, and translated
cleanly by the R bridge.

## V0.1 R Grammar Target

```r
hsquared(
  y ~ sex + age + animal(1 | id, pedigree = ped),
  data = dat,
  family = gaussian(),
  REML = TRUE
)
```

R head `b57b48e` now covers this narrow grammar with an inert `animal()` marker,
`hs_build_model_spec()`, and an internal `hs_bridge_payload`. Unsupported
trait, covariance, and non-v0.1 animal terms should be rejected in R before
Julia is asked to fit anything.

## Julia Interpretation Target

The R formula should normalize to a Julia engine specification with:

- numeric response vector `y`;
- fixed-effect design `X`;
- animal random-effect design `Z`;
- sparse pedigree precision `Ainv`;
- method `:REML` or `:ML`;
- Gaussian family only;
- ID map and minimal metadata.

Current parity state:

- R parses and validates the narrow formula/data/pedigree contract.
- R builds a bridge-shaped payload with numeric `y`, dense `X`, sparse `Z`,
  normalized IDs, parent indices, pedigree metadata, method, and family.
- Julia validates the low-level `AnimalModelSpec`.
- Julia can evaluate and experimentally optimize the dense Gaussian objective
  for a validated spec.
- Julia can accept the direct `y`, `X`, `Z`, `Ainv` payload once `Ainv` is built
  in Julia.
- R head `9eabf0d` exposes the opt-in experimental path through
  `hs_control(engine = "julia")` and normalizes the returned
  `result_payload()` into an internal `hsquared_fit`.
- R-side sparse marshalling and stable production engine controls are still
  planned.

The experimental bridge target is:

```r
hsquared(..., control = hs_control(engine = "julia"))
```

on the R side, translating into the same Julia engine payload that a direct
Julia call would use. The R package remains responsible for formula capture,
R-style errors, and S3 output shape. Julia remains responsible for the numeric
engine and sparse computations.

## Future Julia Surface Target

If `HSquared.jl` later exposes a formula-like surface directly, it should follow
the R spelling closely:

```julia
hsquared(
    @formula(y ~ sex + age + animal(1 | id, pedigree = ped));
    data = dat,
    family = Gaussian(),
    REML = true,
)
```

This is a design target, not implemented behavior. Until it exists, documented
Julia examples should use the lower-level engine utilities.

## Unsupported In Phase 1

- multivariate trait syntax;
- factor-analytic covariance structures;
- genomic or single-step models;
- GLLVM-style response matrices;
- GPU backend selection from the user API;
- non-standard inheritance wrappers.

Unsupported terms should be rejected by the R package before Julia fitting is
requested.
