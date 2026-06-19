# 2026-06-14 Multi-Trait Comparator Protocol

## Decision

The Phase 4 multi-trait parity fixture is a Julia target bundle for R-lane
comparator work. It is not external comparator evidence by itself.

The fixture lives at:

```text
test/fixtures/phase4_multitrait_parity/
```

The R lane should use the CSV files to fit the same bivariate Gaussian animal
model by REML in sommer, ASReml, BLUPF90, JWAS, DMU, WOMBAT, or another named
comparator, then report the command, package versions, convergence status,
alignment rules, and tolerance before any validation row is promoted.

## Estimator Target

Fit the bivariate Gaussian animal model:

```text
trait_k ~ intercept_k + beta_x,k * x + animal_k + residual_k
```

with:

- a shared fixed-effect design across traits: intercept and numeric `x`;
- additive animal effects with covariance `A x G0`, where `A` is rebuilt from
  `pedigree.csv`;
- residual effects independent across records and correlated across traits with
  covariance `R0`;
- REML estimation of `G0` and `R0`;
- no missing trait records in this fixture.

Expected Julia targets are recorded in the `expected_*.csv` files:

- `expected_genetic_covariance.csv`;
- `expected_residual_covariance.csv`;
- `expected_beta.csv`;
- `expected_ebv.csv`;
- `expected_heritability.csv`;
- `expected_metadata.csv`.

## Likelihood Scale

The Julia target log-likelihood in `expected_metadata.csv` is the full REML
log-likelihood on the HSquared.jl package scale, including the constant term.

Comparator packages may omit constants or use a different sign/scale. The R
lane must record the scale before comparing log-likelihoods. If the likelihood
scale cannot be aligned, compare covariance, fixed-effect, EBV, and
heritability outputs first and record the likelihood as not directly
comparable.

## Tolerance Policy

No external-comparator tolerance is committed by this decision.

A tolerance becomes evidence only when the R-lane comparator issue records:

- comparator package and version;
- command or script;
- optimizer settings and convergence status;
- exact target quantities compared;
- ID/trait ordering and any sign/alignment transformations;
- likelihood scale decision;
- observed differences;
- proposed committed tolerance.

The committed tolerance must be cited in status rows and public docs, not the
best observed difference alone.

## Claim Boundary

Allowed wording today:

- a deterministic Julia target fixture exists for future R-lane multi-trait
  comparator work;
- the fixture README and this decision note define the intended comparator
  protocol;
- `V4-MV-REML` remains partial.

Blocked wording today:

- sommer, ASReml, BLUPF90, JWAS, DMU, or WOMBAT parity is achieved;
- external multi-trait comparator evidence exists;
- the R package has public multivariate syntax;
- the bridge payload or `result_payload()` includes multivariate outputs;
- covariance standard errors, likelihood-ratio tests, multi-seed calibration,
  production sparse multivariate fitting, or GPU execution is covered.
