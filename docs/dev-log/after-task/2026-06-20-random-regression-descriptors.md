# After-task — Random-regression covariance-function descriptors (#54, slice 1) — 2026-06-20

Overnight autonomous run (Ada), continued past the committed runway. First
innovation-backlog capability beyond the planned BT2/BT3 runway.

## Goal

Start the planned #54 (random regression / reaction norms) with a bounded,
descriptive, supplied-covariance first slice.

## Process (team)

A parallel design workflow (Henderson MME · Falconer interpretation · Curie tests)
scoped it; the designs converged on supplied-covariance-first sequencing. Falconer's
descriptive layer is slice 1; Henderson's MME is slice 2 (recorded in the roadmap
note). Falconer supplied hand-checked fixture numbers, which the tests reproduce —
confirming the Legendre normalization matches ASReml/WOMBAT.

## What landed

- `src/random_regression.jl` (exported): `legendre_basis`, `standardize_covariate`,
  and the supplied-`K_g` descriptors (`rr_genetic_variance`,
  `rr_genetic_covariance_surface`, `rr_genetic_correlation_surface`,
  `rr_heritability`).
- 31-assertion deterministic testset (closed forms, orthonormality, fixture-number
  convention lock, surface/correlation identities, guards).
- api.md + capability-status + validation-debt `V3-RR-DESC` + roadmap design note.

## Local checks

- `Pkg.test()` → exit 0 (RR testset 31/31). `docs/make.jl` → exit 0.
- CI on a clean checkout is the authoritative gate (Dropbox caveat).

## Claim boundary

Descriptive, supplied-covariance only; `K_g` not estimated; no MME, no selection-
response claim, no R model-spec/bridge. RR MME (slice 2), REML (slice 3),
eigen-functions, and comparator parity are deferred (roadmap note). No capability
moved to covered.
