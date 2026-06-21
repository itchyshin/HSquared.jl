# Multivariate REML sommer comparator checkpoint — 2026-06-21

## Question

`V4-MV-REML` had Julia-internal deterministic checks, a serialized two-trait
target fixture, and recovery characterization, but it still lacked external
comparator evidence. The R lane prepared a `sommer` comparator against
`test/fixtures/phase4_multitrait_parity/`. This checkpoint records the reproduced
run and the claim boundary in the Julia engine repo.

## Setup

- Fixture: `test/fixtures/phase4_multitrait_parity/`.
- External comparator harness:
  `/Users/z3437171/Dropbox/Github Local/hsquared/data-raw/multivariate-comparator-study.R`
  (read-only sibling repo reference).
- Comparator package: `sommer` 4.4.5.
- Independent pedigree relationship rebuild: `nadiv::makeA`.
- Model: bivariate Gaussian animal model by REML with the same fixed effect,
  animal random effect, unstructured genetic covariance, and unstructured
  residual covariance as the Julia target.

Reproduce:

```sh
cd "/Users/z3437171/Dropbox/Github Local/hsquared"
Rscript data-raw/multivariate-comparator-study.R
```

## Result

`sommer` and the stored Julia target agree tightly on variance components,
heritabilities, fixed effects, and EBVs:

| quantity | max difference / agreement |
| --- | --- |
| G0 | max abs(dG0) = 7.529e-05 |
| R0 | max abs(dR0) = 7.626e-06 |
| beta | max abs(dbeta) = 1.801e-06 |
| h2 | max abs(dh2) = 6.821e-05 |
| EBV correlation, trait 1 | 1.000 |
| EBV correlation, trait 2 | 1.000 |
| EBV values | max abs(dEBV) = 4.398e-05 |

The REML log-likelihood values were deliberately not used as a parity metric:
`sommer` and HSquared.jl report different additive-constant scales for this
model (`sommer = -7.9669`, engine = `-121.7048`, offset = `113.7379` in the
run).

## Conclusion

This is a clean external comparator leg for the deterministic multivariate
target fixture. It confirms that the Julia dense multivariate REML target is
consistent with `sommer` on this fixture when the relationship matrix is rebuilt
independently in R.

## Status Implication

`V4-MV-REML` stays `partial`, not `covered`. This run removes the stale "no
external comparator" wording for the serialized target, but it is still one
fixture/package. Remaining blockers include:

- a passing or revised broad recovery gate;
- a published Mrode-style multi-trait estimate or equivalent textbook target;
- additional independent comparator parity (ASReml, BLUPF90, JWAS, or
  equivalent);
- an R-facing multivariate model spec;
- production sparse multivariate fitting.
