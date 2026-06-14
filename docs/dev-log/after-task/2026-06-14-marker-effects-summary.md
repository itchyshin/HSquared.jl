# After-Task Report: Marker-Effects Summary Helper

## Task Goal

Add a deterministic direct-Julia marker-effect summary helper over already
computed marker-scan fields, without adding a new statistical procedure,
plotting backend, R syntax, bridge payload change, threshold selection, or
p-value calibration.

## Active Lenses And Agents

- Fisher: effect-summary-vs-calibration boundary.
- Pat: scan-summary ergonomics.
- Curie: deterministic sorting, top-N, metadata-alignment, and guard tests.
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
- `docs/dev-log/after-task/2026-06-14-marker-effects-summary.md`
- `docs/dev-log/scout/2026-06-14-marker-effects-summary-scout.md`

## Checks Run

- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 220 checks; Phase 5
  fixed-effect single-marker scan testset is now 223 checks; Phase 4B structured
  covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 docstrings not included in the manual,
  local deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.

## Public Claim Audit

Allowed claim: `marker_effects()` prepares deterministic sorted marker-effect
summary data from already-computed direct Julia marker-scan results. It can
sort by p-value, Bonferroni p-value, Benjamini-Hochberg q-value, chi-square,
LOD score, signed effect, or absolute effect; it can optionally align
already-validated marker-map chromosome/position metadata by exact marker ID.

Disallowed claims remain explicit: this does not calibrate p-values, correct
test statistics, estimate effective marker counts, choose genome-wide
thresholds, draw plots, activate R `marker_scan()` syntax, change the bridge
payload, change `result_payload()`, or add comparator evidence.

## Tests Of The Tests

The deterministic tests pin:

- default p-value ordering and stable scan-index provenance;
- top-N selection by chi-square;
- effect, absolute-effect, standard-error, z-score, p-value, adjusted p-value,
  LOD-score, and denominator field propagation;
- compatibility with direct fixed-effect, supplied-variance mixed, and supplied
  LOCO marker scans;
- metadata alignment from `HSMarkerMapSpec` / `HSData`;
- custom scan-like input sorting by absolute effect and BH q-value;
- guards for missing fields, wrong field lengths, non-finite effects,
  non-positive standard errors, negative chi-square values, unsupported
  `sort_by`, invalid `top_n`, and missing `HSData` marker metadata.

The validation-status tests assert that the `V5-MARKER-FIXED`,
`V5-MARKER-MIXED`, and `V5-MARKER-LOCO` rows name marker-effect summary
coverage while keeping p-value calibration, bridge changes, and comparator
claims out of the covered boundary.

## Coordination Notes

No R repo files were edited. The scout note checked the R twin naming
discipline: R already uses `marker_effects()` as an output/extractor name for
marker effects, so the Julia helper stays direct-Julia and scan-like for now.
Coordinate any R-facing exposure through GitHub issues before changing the
bridge contract or public formula language.

## What Did Not Go Smoothly

The local branch already contained an untracked scout note and a partially
settled helper name. I kept the extractor-style `marker_effects()` name because
it aligns with the R output vocabulary, then made the evidence rows and docs use
that exact exported API name.

## Known Limitations

- Summary helper only.
- No p-value calibration, statistic correction, effective marker count,
  genome-wide threshold selection, plotting backend, external comparator parity,
  R syntax, or bridge activation.

## Next Actions

- Add p-value calibration or effective-marker-count logic only as a separate
  gated slice with explicit statistical assumptions and tests.
- Coordinate any R-facing marker-effect or marker-scan extractor exposure
  through GitHub issues before changing the bridge contract.
