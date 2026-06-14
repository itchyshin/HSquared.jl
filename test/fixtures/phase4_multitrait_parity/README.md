# Phase 4 Multi-Trait Parity Fixture

This directory stores a deterministic two-trait animal-model fixture for future
R-lane sommer/ASReml/BLUPF90 parity checks.

It is not a published external comparator and does not promote any validation
row to covered status. The expected values are Julia REML targets from
`fit_multivariate_reml` on this fixture, recorded so another engine can compare
against the same data.

Files:

- `pedigree.csv`: animal, sire, and dam IDs. Unknown parents are `0`.
- `phenotypes.csv`: record-level data with animal ID, shared fixed covariate
  `x`, and two traits.
- `expected_genetic_covariance.csv`: Julia REML target `G0`.
- `expected_residual_covariance.csv`: Julia REML target `R0`.
- `expected_beta.csv`: fixed effects at the target covariances.
- `expected_heritability.csv`: per-trait `diag(G0)/(diag(G0)+diag(R0))`.
- `expected_ebv.csv`: breeding values at the target covariances.
- `expected_metadata.csv`: log-likelihood and diagnostic summaries.

The package test suite reads these files and checks fast self-consistency at the
stored target covariances. It does not re-run the dense optimizer in CI.

## Model To Fit

The intended comparator target is a two-trait Gaussian animal model:

```text
trait_k ~ intercept_k + beta_x,k * x + animal_k + residual_k
```

where the two trait columns are modelled jointly. The animal effects follow the
pedigree numerator relationship from `pedigree.csv`:

```text
vec(animal effects) ~ Normal(0, A x G0)
```

and residuals are independent across records but correlated across traits:

```text
vec(record residuals) ~ Normal(0, I_record x R0)
```

The fixed-effect design is shared across traits and contains an intercept plus
the numeric `x` covariate from `phenotypes.csv`. There are no missing trait
records in this fixture.

## Comparator Protocol

The R lane should use this fixture as an input/target bundle, not as external
evidence by itself.

1. Rebuild `A` or `Ainv` from `pedigree.csv`; do not copy Julia's in-memory
   relationship matrix.
2. Fit the same bivariate Gaussian animal model by REML.
3. Record the comparator package, version, optimizer controls, convergence
   status, and platform.
4. Compare estimated `G0`, `R0`, fixed effects, EBVs, heritability, and
   log-likelihood against the `expected_*.csv` files.
5. Treat log-likelihood carefully: the Julia target in `expected_metadata.csv`
   is the full REML log-likelihood including the constant on the HSquared.jl
   package scale. Comparator packages may report a shifted likelihood.
6. Post the command, package versions, raw comparator output, alignment rules,
   and chosen tolerance to the coordination issue before any validation row is
   promoted.

No tolerance is committed here for external comparator parity. A tolerance
belongs to the R-lane comparator run that records the package, estimator,
optimizer settings, and likelihood scale.

## Claim Boundary

This fixture is a deterministic Julia target for future comparator work. It is
not sommer, ASReml, BLUPF90, JWAS, DMU, or WOMBAT evidence until one of those
tools is actually run and the evidence chain is recorded.

Using this fixture must not imply R-facing multivariate syntax, a bridge payload
change, production sparse multivariate fitting, covariance standard errors,
likelihood-ratio tests, multi-seed calibration, or a covered validation row.
