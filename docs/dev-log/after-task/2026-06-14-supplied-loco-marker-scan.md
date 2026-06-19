# After-Task Report: Supplied LOCO Marker Scan Selection

## Task Goal

Add a direct Julia helper that selects among caller-supplied leave-one-group-out
relationship precision matrices for marker screening, without constructing LOCO
matrices automatically, estimating variance components, changing R syntax,
changing the bridge payload, or making a broad GWAS/QTL claim.

## Active Lenses And Agents

- Gauss: GLS covariance reuse and relationship-matrix selection.
- Fisher: Wald estimand and no calibration overclaim.
- Curie: deterministic tests and reduction checks.
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
- `docs/dev-log/after-task/2026-06-14-supplied-loco-marker-scan.md`

## Checks Run

- First low-core `Pkg.test()` attempt after implementation and before final
  status/docs edits passed. Phase 5 fixed-effect single-marker scan testset was
  142 checks.
- Later low-core `Pkg.test()` attempt after status/docs edits failed because
  the `V5-MARKER-LOCO` validation-status row did not include the exact asserted
  phrase `automatic LOCO relationship construction`. The row now names that
  missing capability explicitly.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 213 checks; Phase 5
  fixed-effect single-marker scan testset is now 142 checks; Phase 4B structured
  covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 docstrings not included in the manual,
  local deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.

## Public Claim Audit

Allowed claim: `loco_mixed_model_marker_scan()` is a dense validation-scale
Julia helper that selects the caller-supplied relationship precision matrix for
each marker group, then runs the same supplied-variance GLS Wald marker tests as
`mixed_model_marker_scan()`.

Disallowed claims remain explicit: this does not construct LOCO relationship
matrices from marker data, choose LOCO defaults, estimate marker-scan variance
components, run a sparse production scan, calibrate p-values, estimate genomic
inflation, draw plots, activate R `marker_scan()` syntax, change the bridge
payload, change `result_payload()`, or add comparator evidence.

## Tests Of The Tests

The deterministic tests pin:

- agreement with separate `mixed_model_marker_scan()` calls on each supplied
  group-specific relationship precision matrix;
- propagation of marker IDs, marker groups, relationship groups, variance
  components, allele-frequency metadata, Bonferroni/BH corrections, and
  LOD-equivalent scores;
- compatibility with `marker_manhattan_data()` and `marker_qq_data()`;
- guards for missing group precision matrices, marker-group length mismatches,
  invalid precision dimensions, empty relationship-precision maps, and marker
  collinearity under the selected covariance.

The validation-status tests assert that the new `V5-MARKER-LOCO` row names
`loco_mixed_model_marker_scan()`, pins the reduction to separate
`mixed_model_marker_scan()` calls, and keeps automatic LOCO construction,
defaults, bridge changes, and calibration out of the covered claim.

## Coordination Notes

No R repo files were edited. The R-facing `marker_scan()` formula term remains
planned/reserved only. No bridge payload or `result_payload()` shape changed.
Coordination should be posted to Julia issue #7 and R issue #9 once the draft PR
is open.

## What Did Not Go Smoothly

The validation-status row initially used a longer missing-capability phrase that
did not match the status test's asserted boundary. The row now says `automatic
LOCO relationship construction` directly so the gate catches future drift.

## Known Limitations

- Dense validation-scale helper only.
- Caller supplies every group-specific relationship precision matrix.
- Supplied variance components only.
- No automatic LOCO matrix construction, LOCO defaults, calibration,
  genomic-inflation diagnostics, plotting backend, external comparator parity,
  R syntax, or bridge activation.

## Next Actions

- Add automatic LOCO relationship construction only as a separate gated slice
  with explicit inputs and tests.
- Coordinate any R-facing marker API through GitHub issues before changing the
  bridge contract.
