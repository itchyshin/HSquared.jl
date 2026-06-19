# After-Task Report: LOCO Relationship Precision Construction

## Task Goal

Add a direct Julia helper that constructs dense leave-one-group-out relationship
precision matrices from marker data and marker groups, so the existing supplied
LOCO marker-scan helper no longer requires callers to build every precision
matrix by hand. Keep the slice Julia-only, validation-scale, and outside the R
bridge contract.

## Active Lenses And Agents

- Gauss: VanRaden construction and regularized inverse reuse.
- Fisher: marker-scan estimand and no calibration overclaim.
- Curie: deterministic reduction and identity tests.
- Grace: low-core local checks and Documenter build.
- Shannon: R/Julia boundary.
- Rose: claim-vs-evidence gate.
- Spawned subagents: none.

## Files Changed

- `src/HSquared.jl`
- `src/genomic.jl`
- `src/validation_status.jl`
- `test/runtests.jl`
- `README.md`
- `ROADMAP.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-14-loco-relationship-precisions.md`

## Checks Run

- Preliminary `Pkg.test()` after implementation/status edits and before final
  ledger/docs edits passed. Phase 0 scaffold/validation-status block is now 215
  checks; Phase 5 fixed-effect single-marker scan testset is now 154 checks;
  Phase 4B structured covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 215 checks; Phase 5
  fixed-effect single-marker scan testset is now 157 checks; Phase 4B structured
  covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 docstrings not included in the manual,
  local deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.

## Public Claim Audit

Allowed claim: `loco_relationship_precisions()` is a dense validation-scale
Julia helper that constructs one relationship precision per marker group by
dropping that group's markers, building a VanRaden relationship matrix from the
remaining markers, and applying the existing ridge-regularized inverse.
`loco_mixed_model_marker_scan()` can consume those matrices or externally
supplied matrices.

Disallowed claims remain explicit: this does not choose public LOCO defaults,
estimate marker-scan variance components, run a sparse production scan,
calibrate p-values, estimate genomic inflation, draw plots, activate R
`marker_scan()` syntax, change the bridge payload, change `result_payload()`, or
add comparator evidence.

## Tests Of The Tests

The deterministic tests pin:

- exact equality to explicit
  `genomic_relationship_inverse(genomic_relationship_matrix(markers_without_group))`
  constructions at a committed ridge;
- scan results from constructed LOCO precisions against separate
  `mixed_model_marker_scan()` calls for each marker group;
- propagation through the existing LOCO scan result fields and Manhattan/QQ
  plot-data compatibility from the previous slice;
- guards for marker-group length mismatch, empty group labels, one-group LOCO
  construction, invalid ridge, allele-frequency length mismatch, missing
  precision matrices, invalid precision dimensions, and marker collinearity.

The validation-status tests assert that the `V5-MARKER-LOCO` row names
`loco_relationship_precisions()`, names leave-one-group-out VanRaden evidence,
and keeps public defaults, calibration, bridge changes, and comparator claims
out of the covered boundary.

## Coordination Notes

No R repo files were edited. The R-facing `marker_scan()` formula term remains
planned/reserved only. No bridge payload or `result_payload()` shape changed.
Coordination should be posted to Julia issue #7 and R issue #9 once the draft PR
is open.

## What Did Not Go Smoothly

No code-level failure in this slice. The only friction was documentation churn:
several long status-table rows and repeated roadmap summaries needed careful
sync so the old "automatic LOCO construction missing" wording did not remain on
active public pages.

## Known Limitations

- Dense validation-scale helper only.
- VanRaden-plus-ridge construction only.
- Caller still controls marker grouping, ridge, variance components, fixed
  effects, and scan invocation.
- No public LOCO defaults, sparse production scan, p-value calibration,
  genomic-inflation diagnostics, plotting backend, external comparator parity,
  R syntax, or bridge activation.

## Next Actions

- Add public LOCO workflow defaults only as a separate gated slice with an
  explicit estimand and bridge contract.
- Coordinate any R-facing marker API through GitHub issues before changing the
  bridge contract.
