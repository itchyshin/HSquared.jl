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

## Reserved Planned Genomic/QTL Vocabulary

R head `3c82c9a` reserves these planned formula markers:

```r
genomic(1 | id, Ginv = Ginv)
single_step(1 | id, Hinv = Hinv)
markers(M, model = "random")
marker_scan(M, map = marker_map)
qtl_scan(position, genotype_probs = probs)
```

The R parser rejects them with planned-not-implemented wording before ordinary
model-frame construction. This prevents undefined marker objects from being
evaluated and prevents planned genomics/QTL terms from being silently treated
as fixed effects.

Julia mirrors the same names as planned vocabulary reservations:

```julia
planned_model_terms()
genomic()
single_step()
markers()
marker_scan()
qtl_scan()
```

These Julia functions intentionally throw planned-not-implemented errors. They
do not construct model specs, validate marker matrices, run GBLUP/single-step,
or perform marker/QTL/eQTL scans.

## Reserved Planned Standard Quantitative-Genetic Vocabulary

R head `10e8fd7` reserves these planned formula markers:

```r
permanent(1 | id)
common_env(1 | litter)
maternal_genetic(1 | dam, pedigree = ped)
maternal_env(1 | dam)
paternal_genetic(1 | sire, pedigree = ped)
paternal_env(1 | sire)
cytoplasmic(1 | maternal_line)
imprinting(1 | id, pedigree = ped, parent = "maternal")
dominance(1 | id, pedigree = ped, Dinv = Dinv)
epistasis(1 | id, pedigree = ped, Einv = Einv)
relmat(1 | id, K = K)
precision(1 | id, Q = Q)
```

Julia mirrors the same names as planned vocabulary reservations:

```julia
planned_quantgen_terms()
permanent()
common_env()
maternal_genetic()
maternal_env()
paternal_genetic()
paternal_env()
cytoplasmic()
imprinting()
dominance()
epistasis()
relmat()
HSquared.precision()
```

These functions intentionally throw planned-not-implemented errors. They do not
construct model specs, validate relationship or precision matrices, or fit
Phase 2+ quantitative-genetic effects.

Julia note: `Base` already exports a `precision` function, so direct Julia code
should refer to the planned custom precision-kernel marker as
`HSquared.precision()`. The reserved term name remains `:precision`, matching
the R formula marker and future bridge payload vocabulary.

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
- R and Julia both expose grammar status diagnostics that separate parsed,
  reserved, and planned formula rows without enabling fitting.
- Julia validates the low-level `AnimalModelSpec`.
- Julia can evaluate and experimentally optimize the dense Gaussian objective
  for a validated spec.
- Julia can accept the direct `y`, `X`, `Z`, `Ainv` payload once `Ainv` is built
  in Julia.
- R head `9eabf0d` exposes the opt-in experimental path through
  `hs_control(engine = "julia")` and normalizes the returned
  `result_payload()` into an internal `hsquared_fit`.
- R head `398e019` consumes Julia `sparse_csc_matrix()` for sparse `Z`
  marshalling.
- Relationship-object marshalling beyond `Z`, stable production engine
  controls, and Mrode validation are still planned.

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
- genomic prediction, single-step fitting, marker-effect estimation, marker
  scans, and QTL/eQTL scans;
- permanent environment, common environment, maternal/paternal effects,
  cytoplasmic inheritance, imprinting, dominance, epistasis, and custom
  relationship/precision kernels;
- GLLVM-style response matrices;
- GPU backend selection from the user API;
- non-standard inheritance wrappers.

Unsupported terms should be rejected by the R package before Julia fitting is
requested.
