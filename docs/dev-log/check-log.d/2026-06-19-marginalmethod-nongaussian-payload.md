# 2026-06-19 MarginalMethod dispatch + non-Gaussian bridge payload (#44)

- Goal: close the gap `validation_status()` itself named (the V6-LAPLACE `missing`
  field) — a `MarginalMethod` dispatch type and a `NonGaussianFit` bridge result
  shape — so the R non-Gaussian family-acceptance can fire. Value-preserving (no
  numeric change to `fit_laplace_reml`).
- Lenses: Emmy + Hopper (bridge/fitted-object shape), Gauss (value-preservation),
  Rose (claim gate). Adversarial review run as a workflow.

## What was done

- `MarginalMethod` dispatch (src/nongaussian.jl, internal): `abstract type
  MarginalMethod`; `Laplace`/`Variational`; `_marginal_method(::Symbol)` accepts
  `:laplace`/`:LA`/`:variational`/`:VA`; `_marginal_method_symbol` (canonical
  symbol) and `_marginal_method_string` (R-facing `"laplace"`/`"variational"`).
  WIRED into `fit_laplace_reml` and `laplace_reml_interval` (they now dispatch via
  the type and accept `:LA`/`:VA`), so the abstraction is genuinely used.
- `nongaussian_result_payload(fit::NonGaussianFit)` (exported): the boring bridge
  `NamedTuple` (`engine`/`target = "nongaussian_reml"`/`family`/`n_trials`/`method`/
  `variance_components`/`fixed_effects`/`breeding_values = (ids, values)`/`loglik`/
  `converged`), mirroring the `multivariate_result_payload` top-level shape.
- `NonGaussianFit` gained an `n_trials::Union{Int,Nothing}` field (Binomial trials
  denominator; `nothing` for other families) so a binomial payload is
  self-describing.
- Honesty: NO `heritability` field (family-uniform shape; h² left to the consumer).
- Rows: `validation_status` V6-LAPLACE (MarginalMethod + payload moved `missing` →
  `evidence`), capability-status Fitted-non-Gaussian row, validation-debt V6-FIT.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (new "Phase 6 MarginalMethod…(#44)" testset; re-run green after the review fixes).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)** (combined
  with #43 on the rebased branch).
- CI on PR #66 (pre-review-fix commit): Julia 1 / 1.10 / docs / deploy all **pass**.
- Adversarial 3-lens review (Emmy / Gauss / Rose): Emmy **concerns**, Gauss + Rose
  **pass_with_nits**. All in-lane findings addressed before merge:
  - Emmy (should_fix): binomial payload dropped `n_trials` → added `n_trials` field
    + payload; `MarginalMethod` was near-dead (`_marginal_method_symbol` unused,
    `:LA`/`:VA` unreachable) → wired the dispatch into the fitter so both are live;
    method string `"va"` inconsistent → use `"variational"` (matches the symbol +
    the `"laplace"` sibling).
  - Emmy/Gauss/Rose (nits): docstring "mirrors result_payload" → "mirrors the
    multivariate_result_payload top-level shape"; dropped the dangling
    `[MarginalMethod](@ref)`; reworded the heritability omission to lead with the
    family-uniform reason; copied `ids` in the payload (symmetry with `values`).
  - Rose (nit): added this check-log entry + the #44 after-task report.

## Claim boundary

Value-preserving experimental bridge-shape change. The R-facing method-string
(`"laplace"`/`"variational"`) and family-acceptance contract are PENDING R-lane
agreement (per AGENTS.md rule 2) before being treated as frozen. No external
comparator; Bernoulli single-trial variance still downward-biased. No capability
moved to covered.
