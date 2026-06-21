# Scout — JWAS comparator setup and claim boundary

Date: 2026-06-21. Lane: Julia validation/comparator.

## Question

Can the existing JWAS.jl comparator scaffold be made runnable locally, and what
claim can HSquared.jl honestly make from the result?

## Sources Checked

- JWAS documentation home page: <https://reworkhow.github.io/JWAS.jl/latest/>
  describes JWAS as a Julia platform for univariate and multivariate Bayesian
  mixed models with pedigree random effects.
- JWAS upstream `Project.toml`:
  <https://raw.githubusercontent.com/reworkhow/JWAS.jl/master/Project.toml>
  records `uuid = "c9a035f4-d403-5e6b-8649-6be755bc4798"` and version `2.3.6`.
- Local Pkg probe: plain `Pkg.instantiate()` failed because JWAS is not
  registered in Julia General; `Pkg.add(url = "https://github.com/reworkhow/JWAS.jl")`
  succeeds and writes the git-ignored comparator manifest.

## Lesson

JWAS is useful as an opt-in independent implementation for fitted-target smoke
evidence, but it is Bayesian/MCMC while HSquared.jl's target is REML. Therefore
the honest wording is "agreement" or "cross-estimator probe", never
"same-estimand parity" or "covered validation".

## HSquared Action

- Correct the comparator `Project.toml` JWAS UUID.
- Add `comparator/setup_jwas_env.jl` so future users can reproduce the
  unregistered package setup.
- Record the 2026-06-21 local run as agreement evidence only.

## Claim Risk

Do not use this run to close the fitted-Mrode or same-estimand comparator gate.
Those still need a REML/prod-software comparator or R-lane published target with
versions, controls, tolerances, and Rose audit.
