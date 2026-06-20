# 2026-06-19 Post-fit marker-scan entry points (#45)

- Goal: deliver the #45 post-fit `(fit, markers)` marker-scan entry point so a
  caller can run a relatedness-corrected scan directly on a fitted animal model
  without re-supplying the design / relationship precision / variance components.
- Investigation result: the Julia `AnimalModelFit` ALREADY carries `spec.Ainv`
  (and `spec.y`/`X`/`Z` + `variance_components`), so the "Ainv = NULL on the
  returned fit" flagged in the handover is the R-side bridge payload slot, NOT a
  Julia gap. The Julia deliverable is the convenience dispatch.
- Lenses: Gauss + Henderson (engine), Curie + Fisher (scan validity), Rose (claim
  gate).

## What was done

- New `src/postfit.jl` (included after `likelihood.jl` so it can see both the
  `genomic.jl` scan functions and `AnimalModelFit`):
  - `mixed_model_marker_scan(fit::AnimalModelFit, markers; allele_frequencies,
    marker_ids)` → delegates to the explicit-argument `mixed_model_marker_scan`
    using `fit.spec.y/X/Z/Ainv` and `fit.variance_components.(sigma_a2, sigma_e2)`
    (the relatedness-corrected GLS scan, the headline).
  - `single_marker_scan(fit::AnimalModelFit, markers; ...)` → the fixed-effect
    screen using the fit's `y`/`X` and fitted `σ²e`.
- No new exports (both base names are already exported; these add methods).
- Tests (`test/runtests.jl`, "Phase 5 post-fit marker scan (#45)"): the
  `(fit, markers)` results equal (`==`) the explicit-argument scans on a 6-animal
  pedigree + 3-marker fixture; `target == :mixed_model_marker_scan`; marker IDs /
  effect length pinned.
- Rows: capability-status (mixed-model marker scan row) + validation-debt
  `V5-MARKER-MIXED` note the post-fit entry points and that p-values stay
  UNcalibrated (gate #48). No new `validation_status()` row (count unchanged at 34).

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → (recorded after run).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → (recorded after run).
- Adversarial review → (recorded in after-task).

## Claim boundary

A convenience dispatch over the existing dense validation-scale scans — pure
delegation, no new statistics. The returned Wald p-values are NOT genome-wide
calibrated (gate #48); no sparse production scan; no R `marker_scan()` activation;
no bridge payload change. No capability moved to covered.
