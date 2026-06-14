# After-Task Report: Marker Scan Table Helper

## Task Goal

Add a deterministic direct-Julia row-aligned marker-scan table helper over
already-computed marker-scan fields, without activating R `marker_scan()`
syntax, `gwas_table()` / `qtl_table()` / `eqtl_table()`, bridge payload
changes, calibrated p-values, calibrated PVE/model R² claims, plotting,
threshold selection, or marker-scan variance-component estimation.

## Active Lenses And Agents

- Fisher: scan-table-vs-calibrated-GWAS/QTL table boundary.
- Pat: scan-table ergonomics.
- Curie: scan-order, variance, metadata, mixed/LOCO optional-field tests.
- Shannon: R/Julia boundary.
- Grace: low-core checks and Documenter build.
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
- `docs/dev-log/after-task/2026-06-14-marker-scan-table.md`
- `docs/dev-log/scout/2026-06-14-marker-scan-table-scout.md`

## Checks Run

- Focused `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test(test_args=["Phase 5 fixed-effect single-marker scan"])'`:
  passed. The test runner executed the suite; Phase 5 fixed-effect
  single-marker scan testset was 316 checks.
- Preliminary `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block was 225 checks; Phase 5
  fixed-effect single-marker scan testset was 313 checks; Phase 4B structured
  covariance remained 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 228 checks; Phase 5
  fixed-effect single-marker scan testset is now 316 checks; Phase 4B
  structured covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 docstrings not included in the manual,
  local deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.
- `git diff --check`: passed.
- Rose boundary grep for unsupported marker/GWAS/QTL/eQTL claims: only explicit
  planned/blocked/no-claim wording matched.
- Remote CI for pushed commit `662538b`:
  <https://github.com/itchyshin/HSquared.jl/actions/runs/27512222798>
  passed.
- Remote Documenter for pushed commit `662538b`:
  <https://github.com/itchyshin/HSquared.jl/actions/runs/27512222795>
  passed.
- Both remote runs emitted the known non-failing Node.js 20 deprecation
  annotation for upstream actions forced onto Node.js 24.

## Public Claim Audit

Allowed claim: `marker_scan_table()` prepares deterministic row-aligned scan
tables from already-computed direct Julia marker-scan results. It preserves
original scan order, returns the existing scan statistics, computes allele
variances and marker-level variance contributions as `2p(1-p) * effect^2`,
optionally reports proportions when a positive finite `total_variance` is
supplied, and aligns already-validated marker metadata by exact marker ID.

Disallowed claims remain explicit: this does not estimate marker-scan variance
components, calibrate p-values, claim calibrated PVE/model R², correct test
statistics, estimate effective marker counts, choose genome-wide thresholds,
draw plots, activate R `marker_scan()` syntax, activate `gwas_table()` /
`qtl_table()` / `eqtl_table()`, change the bridge payload, change
`result_payload()`, or add comparator evidence.

## Tests Of The Tests

The deterministic tests pin:

- original scan order through `scan_indices = [1, 2]`;
- all core scan-statistic fields in the table;
- marker-variance identities from `2p(1-p) * effect^2`;
- optional total-variance proportions;
- compatibility with direct fixed-effect, supplied-variance mixed, and supplied
  LOCO marker scans;
- preservation of supplied variance components for mixed scans;
- preservation of marker groups for LOCO scans;
- metadata alignment from `HSMarkerMapSpec` / `HSData`;
- custom scan-like input with three markers;
- guards for missing fields, wrong field lengths, invalid standard errors,
  negative chi-square values, invalid allele frequencies, malformed optional
  `k`, invalid marker-group lengths, invalid total variance, non-numeric total
  variance, and missing `HSData` marker metadata.

The validation-status tests assert that the `V5-MARKER-FIXED`,
`V5-MARKER-MIXED`, and `V5-MARKER-LOCO` rows name scan-table coverage while
keeping `gwas_table()` / `qtl_table()` / `eqtl_table()` activation, p-value
calibration, calibrated PVE/model R², bridge changes, and comparator claims out
of the covered boundary.

## Coordination Notes

No R repo files were edited. This helper aligns with the R twin's planned table
vocabulary only as internal Julia groundwork. Any R-facing `marker_scan()`,
`gwas_table()`, `qtl_table()`, or `eqtl_table()` exposure must be coordinated
through GitHub issues before changing the bridge contract or public formula
language.

## What Did Not Go Smoothly

One broad docs patch missed a ROADMAP line break and was split into smaller
patches. The shell's default PATH still has no `julia`; validation used
`~/.juliaup/bin/julia` 1.10.0 with one-thread settings.

## Known Limitations

- Table helper only.
- Uses returned marker effects and allele frequencies; no model refit.
- Optional proportions are only relative to a user-supplied total variance.
- No calibrated PVE/model R², marker-scan variance-component estimation,
  statistic correction, effective marker count, genome-wide threshold
  selection, plotting backend, external comparator parity, R syntax, bridge
  activation, or `gwas_table()` / `qtl_table()` / `eqtl_table()` activation.

## Next Actions

- Coordinate any R-facing table/extractor exposure through GitHub issues before
  changing the bridge contract.
- Add calibrated GWAS/QTL tables only as separate gated slices with explicit
  statistical assumptions, comparator/simulation evidence, and public claim
  wording.
