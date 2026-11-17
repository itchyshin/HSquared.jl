# SE information switch: `information = :ai | :observed`

Date: 2026-11-09. Lane: Julia, assigned to the hsquared session by Szymek for
this slice. Branch `claude/se-information-switch` from `main` `15e932f2`.

## Why

On the great tit animal + permanent-environment model, hsquared's SEs were 2-7%
wider than ASReml-R's. The cause is the matrix inverted, not a bug.
`multi_effect_variance_component_covariance` inverts the finite-difference
OBSERVED information. ASReml inverts the AVERAGE information (AI). The univariate
animal model here already used AI, so the engine mixed conventions across routes.
Evidence (independent base-R reference, ASReml, MCMCglmm, timing):
hsquared `dev-test/se-investigation/RESULTS.md` on branch
`claude/se-asreml-mcmcglmm-investigation`.

## Change (`src/likelihood.jl`)

- `_validate_information`: accepts `:ai` / `:observed`.
- `_multi_reml_ai_information!`: K-effect AI matrix at the estimate,
  `1/2 wᵢ'P wⱼ` with the fitter's working variates, one factorisation + K+1
  re-solves on the shared `_MultiREMLWorkspace`.
- `_univariate_observed_information`: FD observed information for
  `(σ²_a, σ²_e)`, reusing the validated spec / Ainv / log|Ainv|; refuses a
  near-boundary component instead of stepping it negative.
- Keyword `information` on `variance_component_covariance`,
  `variance_component_standard_errors`, `heritability_standard_error`,
  `heritability_interval` (delta), `variance_component_uncertainty` (default
  `:ai`, unchanged behaviour) and on
  `multi_effect_variance_component_covariance`,
  `multi_effect_variance_component_standard_errors`,
  `multi_effect_ratio_standard_errors`, `multi_effect_sum_ratio_interval`,
  `multi_effect_uncertainty` (default `:observed`, unchanged behaviour).
- `_require_identified_information` message says "information matrix" (it now
  guards both).

No default changes on the Julia side. hsquared requests `:ai` explicitly.

## Tests

`test/test_se_information_switch.jl` (19): against a dense computation from the
definitions with V formed explicitly, the AI matrices match
`1/2 y'P Vi P Vj P y` to rtol 1e-8 (K = 2 and univariate). The FD observed
information matches `2 AI - 1/2 tr(P Vi P Vj)` to rtol 1e-3. Defaults are
bitwise unchanged, every public product honours the keyword, and bad symbols
throw. Full `Pkg.test()` passes.

## Boundary

Asymptotic SEs, not coverage-calibrated under either matrix. No validation_status
row, capability, or public claim changes. Not threaded: two-effect,
direct-maternal, multivariate, and dense ratio-interval paths (observed FD).
