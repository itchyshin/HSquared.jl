# 2026-06-19 PEV/reliability into the standard result payload (#43)

- Goal: deliver the engine half of the locked #61 / hsquared#21 decision — make
  `prediction_error_variance` and `reliability` standard fields of the univariate
  bridge payload `result_payload(::AnimalModelFit)`, computed through the
  production-direction Takahashi selected inverse (`:selinv`), so the R twin can
  make its PEV/reliability enrichment unconditional and close hsquared#21.
- Lenses: Hopper + Boole + Emmy (bridge/result-payload contract), Gauss + Noether
  (selinv numerics), Rose (claim gate). Adversarial review run as a workflow.

## What was done

- `result_payload(fit::AnimalModelFit)` (src/likelihood.jl): now computes
  `pev = prediction_error_variance(fit; method = :selinv)` and
  `rel = reliability(fit; method = :selinv)` and adds two standard fields,
  `prediction_error_variance = (ids, values)` and `reliability = (ids, values)`,
  placed after `predictions` and before `diagnostics`. Docstring updated.
- Shape matches the R unpack: the R twin (`../hsquared/R/julia-bridge.R`) reads
  top-level `raw$prediction_error_variance` / `raw$reliability`, each `(ids,
  values)`, via `hs_julia_id_values()` (hsquared#21). No try/catch — boundary
  behaviour is identical to calling the extractors directly (interior REML/Henderson
  fits are PD; the locked decision is "unconditional for those targets").
- Tests (`test/runtests.jl`, "Phase 1 dense fit extractors"): extended the strict
  `propertynames(payload)` tuple to include the two new fields, and pinned
  `payload.prediction_error_variance.values` ≈ both `:selinv` and `:dense`
  extractor values, and `payload.reliability.values` ≈ `:selinv` reliability.
- Rows: capability-status "R result payload shape" (the "deliberately keeps
  PEV/reliability out of base payload" wording replaced with the `:selinv` landing
  + machine-precision + hsquared#21 note); validation-debt `V1-RESULT` and
  `V1-SELINV-PEV` updated.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (baseline green before the change; green after the widened payload tuple +
  PEV/reliability value parity; re-run green after the review fixes added the
  8-animal Mrode9-shaped non-trivial fixture and the `reliability` PEV-dedup).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (DOCS_EXIT=0)**.
- Adversarial 3-lens review workflow (Hopper / Gauss / Rose) → all **pass_with_nits**
  (no blockers). Findings addressed in-lane:
  - Gauss (dedup): `result_payload` now computes the `:selinv` PEV once and passes
    it to `reliability` via a new optional `pev` kwarg (no second Cholesky).
  - Gauss/Rose (wording): scoped "machine precision" to well-conditioned
    validation-scale fits; softened "production-direction" → "`O(nnz(L))`
    (sparse-scalable)"; documented that the `reliability` denominator still forms
    the dense `inv(Ainv)`.
  - Rose (evidence): added an 8-animal Mrode9-shaped, `nfixed = 2` fixture pinning
    `:selinv` PEV/reliability == `:dense` and the payload values, so the
    V1-SELINV-PEV "8-animal" wording is now actually backed; filled these
    docs-build + review-outcome lines.
  - Hopper (R-lane, flagged on #61, NOT edited here): the R bridge's opportunistic
    `merge()` (`../hsquared/R/julia-bridge.R:51-58`) is last-wins and would overwrite
    the payload's `:selinv` fields with the standalone extractors' `:dense` default
    (numerically identical today); R-lane should drop it so the `:selinv` payload
    passes through, then close hsquared#21 on the de-duplicated path. Also: #21 is
    now unconditional only on the `AnimalModelFit`/REML route — the Henderson-MME R
    route still rides opportunistic enrichment (separate slice).

## Follow-ups (noted, not in this slice)

- Production-direction reliability denominator: compute `diag(A)` via a selected
  inverse of `Ainv` (`O(nnz)`) instead of the dense `inv(Ainv)`, to make the
  payload reliability fully sparse-scalable.
- R-lane: drop the opportunistic `merge()`; decide whether #21 needs an
  always-present guarantee on the Henderson target too.

## Claim boundary

A validation-scale bridge-shape change only. `:selinv` matches the dense MME
inverse diagonal to machine precision for well-conditioned validation-scale fits
(`V1-SELINV-PEV`); this is NOT a production large-pedigree reliability claim (the
`reliability` denominator still densifies `inv(Ainv)`), and there is no external
fitted-model comparator for PEV/reliability. No capability moved to covered.
