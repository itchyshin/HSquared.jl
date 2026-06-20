# After-task — #44 MarginalMethod dispatch + non-Gaussian bridge payload (2026-06-19)

Overnight autonomous runway run (Ada). Second BT2 bridge-readiness slice.

## Goal

Close the gap `validation_status()` itself named in the V6-LAPLACE `missing`
field: a `MarginalMethod` dispatch type (mirroring DRM.jl `:LA`/`:VA`) and a
`NonGaussianFit` bridge result shape, so the R non-Gaussian family-acceptance can
fire. Value-preserving — no numeric change to the fitter.

## What landed

- `MarginalMethod`/`Laplace`/`Variational` dispatch (internal) + `_marginal_method`
  / `_marginal_method_symbol` / `_marginal_method_string`, wired into
  `fit_laplace_reml` and `laplace_reml_interval` (now accept `:LA`/`:VA`, store the
  canonical symbol — value-preserving for existing `:laplace`/`:variational`).
- `nongaussian_result_payload(fit::NonGaussianFit)` (exported), mirroring the
  `multivariate_result_payload` top-level shape; carries `n_trials` (binomial
  self-describing) and deliberately no `heritability` (family-uniform shape).
- `NonGaussianFit` gained `n_trials::Union{Int,Nothing}`.
- Rows updated: `validation_status` V6-LAPLACE, capability-status, validation-debt
  V6-FIT.

## Review (3-lens adversarial workflow)

Emmy **concerns** / Gauss **pass_with_nits** / Rose **pass_with_nits**. Emmy's
three should_fixes were the high-value catches and were all addressed before merge:
(1) the binomial payload silently dropped `n_trials` → added the field + payload key
so a binomial fit is self-describing; (2) `MarginalMethod` was a near-dead
abstraction (`_marginal_method_symbol` had zero callers, `:LA`/`:VA` unreachable) →
wired the dispatch into the fitter so it is genuinely used; (3) the `"va"` method
token was inconsistent with the `:variational` symbol and the `"laplace"` sibling →
switched to `"variational"`. Nits (docstring "mirrors" overclaim, dangling `@ref`,
heritability wording, aliased `ids`) all fixed.

## Local checks

- `Pkg.test()` → exit 0 (suite + new 30+ assertion testset, green after fixes).
- `docs/make.jl` → exit 0.

## Cross-lane (pending, flagged on #61)

The R-facing `method` token (`"laplace"`/`"variational"`) and the family-acceptance
shape must be agreed with the R twin (AGENTS.md rule 2) before this payload is a
frozen contract. To be posted to #61 alongside the #43 coordination note.

## Claim boundary

Experimental, value-preserving bridge-shape change. No external comparator; the
Bernoulli single-trial variance remains downward-biased (information effect). No
capability moved to covered.
