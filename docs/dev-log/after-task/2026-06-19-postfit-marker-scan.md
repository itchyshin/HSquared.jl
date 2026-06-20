# After-task — #45 Post-fit marker-scan entry points (2026-06-19)

Overnight autonomous runway run (Ada). BT2 bridge-readiness slice.

## Goal

Deliver the #45 post-fit `(fit, markers)` marker-scan entry point routing to the
relatedness-corrected `mixed_model_marker_scan`.

## Key finding

The handover flagged "fix the `Ainv = NULL` on the returned fit". On the **Julia**
side that is a non-issue: `AnimalModelFit` carries `spec.Ainv` (and `spec.y/X/Z`
and `variance_components`). So a post-fit scan can read everything off the fit. The
`Ainv = NULL` is the **R-side** bridge payload slot (the R fit object does not
marshal the relationship back) — an R-lane item, flagged for #61. The Julia
deliverable is the convenience dispatch.

## What landed

- `src/postfit.jl` (new, included after `likelihood.jl`):
  `mixed_model_marker_scan(fit::AnimalModelFit, markers; ...)` (relatedness-corrected
  GLS, the headline) and `single_marker_scan(fit::AnimalModelFit, markers; ...)`
  (fixed-effect screen) — thin delegations pulling design/Ainv/VCs off the fit.
- Tests: the `(fit, markers)` results equal the explicit-argument scans on a
  6-animal / 3-marker fixture.
- Rows: capability-status + `V5-MARKER-MIXED` note the post-fit methods and that
  p-values stay uncalibrated (gate #48).

## Review (adversarial workflow)

Curie + Rose both **pass_with_nits**, no blocker. Curie's should_fix was the
high-value catch: the original test used `Z = I`, under which the GLS covariance is
invariant to whether `Z` is threaded — so it could not prove the headline claim.
Added a non-identity (permutation) `Z` case that (a) still reduces exactly to the
explicit call, (b) yields effects DIFFERENT from the identity-`Z` scan (proving `Z`
enters `V`), and (c) leaves `single_marker_scan` unchanged (pinning its deliberate
relatedness-blindness). This also closed an inherited engine-level gap (the core
mixed scan had only ever been tested with `Z = I`). Rose confirmed the claims are
honest and the test is genuinely red-before/green-after.

## Local checks

- `Pkg.test()` → exit 0 (post-fit testset 6/6).
- `docs/make.jl` → exit 0.

## Cross-lane (for #61)

The R-side `Ainv = NULL` payload slot must carry the relationship precision back so
the R `gwas()`/post-fit scan can use it — R-lane work, to be noted on #61.

## Claim boundary

Convenience dispatch over existing dense validation-scale scans; no new statistics;
p-values NOT genome-wide calibrated (gate #48); no sparse production scan; no R
`marker_scan()` activation. No capability moved to covered.
