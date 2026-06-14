# After-Task Report: Marker-Variance Contribution Summary Helper

## Task Goal

Add a deterministic direct-Julia marker-variance contribution summary helper
over already-computed marker-scan fields, without adding calibrated PVE/model
R2 claims, marker-scan variance-component estimation, plotting, R syntax,
bridge payload changes, threshold selection, or p-value calibration.

## Active Lenses And Agents

- Fisher: variance-contribution-vs-calibrated-PVE boundary.
- Pat: scan-summary ergonomics.
- Curie: deterministic sorting, top-N, optional proportions, metadata
  alignment, and guard tests.
- Shannon: R/Julia boundary.
- Grace: low-core local checks and Documenter build.
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
- `docs/dev-log/after-task/2026-06-14-marker-variance-summary.md`
- `docs/dev-log/scout/2026-06-14-marker-variance-summary-scout.md`

## Checks Run

- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 225 checks; Phase 5
  fixed-effect single-marker scan testset is now 270 checks; Phase 4B structured
  covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 docstrings not included in the manual,
  local deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.
- `git diff --check`: passed after source/docs closeout edits.
- Remote CI for pushed commit `67cb758`:
  <https://github.com/itchyshin/HSquared.jl/actions/runs/27511455907>
  passed.
- Remote Documenter for pushed commit `67cb758`:
  <https://github.com/itchyshin/HSquared.jl/actions/runs/27511455912>
  passed.

## Public Claim Audit

Allowed claim: `marker_variance_explained()` prepares deterministic sorted
marker-level variance contribution summaries from already-computed direct
Julia marker-scan results. The contribution is `2p(1-p) * effect^2`. When a
positive finite `total_variance` is supplied, the helper also reports
`proportion_variance_explained = marker_variance / total_variance`.

Disallowed claims remain explicit: this does not estimate marker-scan variance
components, calibrate p-values, claim calibrated PVE/model R2, correct test
statistics, estimate effective marker counts, choose genome-wide thresholds,
draw plots, activate R `marker_scan()` syntax, change the bridge payload,
change `result_payload()`, or add comparator evidence.

## Tests Of The Tests

The deterministic tests pin:

- marker-variance identities from `2p(1-p) * effect^2`;
- default marker-variance ordering and stable scan-index provenance;
- optional total-variance proportions;
- top-N selection by contribution magnitude;
- p-value sorting when scan p-values are present;
- compatibility with direct fixed-effect, supplied-variance mixed, and supplied
  LOCO marker scans;
- metadata alignment from `HSMarkerMapSpec` / `HSData`;
- custom scan-like input sorting by absolute effect;
- guards for missing fields, wrong field lengths, non-finite effects,
  invalid allele frequencies, invalid total variance, unsupported `sort_by`,
  invalid `top_n`, p-value sorting without p-values, and missing `HSData`
  marker metadata.

The validation-status tests assert that the `V5-MARKER-FIXED`,
`V5-MARKER-MIXED`, and `V5-MARKER-LOCO` rows name marker-variance summary
coverage while keeping p-value calibration, calibrated PVE/model R2, bridge
changes, and comparator claims out of the covered boundary.

## Coordination Notes

No R repo files were edited. This helper aligns with the R twin's existing
`marker_variance_explained()` output vocabulary, but remains direct-Julia only.
Any R-facing exposure must be coordinated through GitHub issues before changing
the bridge contract or public formula language.

## What Did Not Go Smoothly

The shell's default PATH had no `julia`, and the only `/Applications` Julia was
1.6.7, which is incompatible with the repo's Julia 1.10-resolved manifest. The
actual validation used `~/.juliaup/bin/julia` 1.10.0.

## Known Limitations

- Summary helper only.
- Uses the direct marker-effect and allele-frequency convention
  `2p(1-p) * effect^2`.
- Optional proportions are only relative to a user-supplied total variance.
- No calibrated PVE/model R2, marker-scan variance-component estimation,
  statistic correction, effective marker count, genome-wide threshold
  selection, plotting backend, external comparator parity, R syntax, or bridge
  activation.

## Next Actions

- Add calibrated PVE/model R2 only as a separate gated slice with explicit
  statistical assumptions and tests.
- Coordinate any R-facing marker-variance exposure through GitHub issues before
  changing the bridge contract.
