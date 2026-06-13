# Formula Grammar

The public formula grammar belongs to the R package `hsquared`. `HSquared.jl`
must not expose or imply more model syntax than the R-Julia contract can
support.

## V0.1 R Grammar Target

```r
hsquared(
  y ~ sex + age + animal(1 | id, pedigree = ped),
  data = dat,
  family = gaussian(),
  REML = TRUE
)
```

## Julia Interpretation Target

The R formula should normalize to a Julia engine specification with:

- numeric response vector `y`;
- fixed-effect design `X`;
- animal random-effect design `Z`;
- sparse pedigree precision `Ainv`;
- method `:REML` or `:ML`;
- Gaussian family only;
- ID map and minimal metadata.

## Unsupported In Phase 1

- multivariate trait syntax;
- factor-analytic covariance structures;
- genomic or single-step models;
- GLLVM-style response matrices;
- GPU backend selection from the user API;
- non-standard inheritance wrappers.

Unsupported terms should be rejected by the R package before Julia fitting is
requested.
