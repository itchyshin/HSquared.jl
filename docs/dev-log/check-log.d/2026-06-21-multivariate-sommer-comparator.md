# 2026-06-21 Multivariate REML sommer comparator evidence (V4-MV-REML)

- Goal: reproduce the R-lane external comparator run for the deterministic
  two-trait fixture `test/fixtures/phase4_multitrait_parity/` and record the
  result in the Julia engine repo without promoting `V4-MV-REML`.
- Lenses: Ada + Shannon (handoff/coordination), Curie + Fisher + Mrode
  (validation evidence), Rose (claim boundary), Grace (checks).

## Comparator Command

Run from the read-only sibling R repo:

```sh
cd "/Users/z3437171/Dropbox/Github Local/hsquared"
Rscript data-raw/multivariate-comparator-study.R
```

Environment observed before the run:

- R version: 4.5.2 (2025-10-31)
- `sommer`: 4.4.5
- `nadiv`: installed

The sibling R repo was dirty before the run and was left untouched; the script
was used only as a read-only comparator harness.

## Result

The comparator script fits the same bivariate Gaussian animal model with
`sommer::mmer`, rebuilding the numerator relationship matrix `A` independently
with `nadiv::makeA` rather than copying the Julia `Ainv` target.

```text
=== sommer 4.4.5 vs HSquared.jl multivariate target ===
G0 (sommer):
       trait1   trait2
trait1 0.603559 0.111878
trait2 0.111878 0.270278
G0 (target):
       trait1   trait2
trait1 0.603628 0.111950
trait2 0.111950 0.270353
R0 (sommer):
       trait1   trait2
trait1 0.263118 0.000312
trait2 0.000312 0.090666
R0 (target):
       trait1   trait2
trait1 0.263112 0.000308
trait2 0.000308 0.090658
h2 (sommer): 0.696406 0.748809  (target): 0.696435 0.748877

REML loglik (NOT compared; additive-constant scale): sommer = -7.9669  engine = -121.7048  offset = 113.7379

Element-wise agreement:
  max|dG0|         7.529e-05
  max|dR0|         7.626e-06
  max|dbeta|       1.801e-06
  max|dh2|         6.821e-05
  cor_EBV_trait1   1.000e+00
  cor_EBV_trait2   1.000e+00
  max|dEBV|        4.398e-05
```

## Claim Boundary

This records one external comparator leg for the deterministic multivariate
target fixture. `V4-MV-REML` remains `partial`: the broad recovery gate was not
re-declared/passed, the evidence is one fixture/package rather than independent
multi-package parity, and there is still no R-facing multivariate model spec or
production sparse multivariate path.

## Local Repo Checks

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` — passed. Existing-style
  local-build warnings were observed for undocumented docstrings, missing local
  Vitepress logo/favicon assets, skipped deployment detection, and npm audit
  output.
- `git diff --check` — passed.
