# After-Task Report: Marker Significance Summary Helper

## Task Goal

Add a deterministic direct-Julia marker significance summary helper over
already-computed marker-scan fields, without adding calibrated GWAS/QTL/eQTL
threshold claims, p-value calibration, effective marker-count estimation,
plotting, R syntax, bridge payload changes, calibrated PVE/model R2 claims, or
comparator evidence.

## Active Lenses And Agents

- Fisher: nominal-significance-vs-calibrated-threshold boundary.
- Pat: summary ergonomics.
- Curie: flags, counts, top-marker provenance, and guard tests.
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
- `docs/dev-log/after-task/2026-06-14-marker-significance-summary.md`
- `docs/dev-log/scout/2026-06-14-marker-significance-summary-scout.md`

## Checks Run

- Focused `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test(test_args=["Phase 5 fixed-effect single-marker scan"])'`:
  passed. The test runner executed the suite; Phase 5 fixed-effect
  single-marker scan testset was 415 checks.
- Full `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 5 fixed-effect single-marker scan testset was 415 checks and
  Phase 4B structured covariance remained 61 checks.
- `git diff --check`: passed after source/docs closeout edits.
- Documenter was rebuilt with one-thread settings after clearing stale local
  generated output. Known local caveats remained: 8 unrelated docstrings not
  included in the manual, local deployment skipped, VitePress default
  substitutions, missing local logo/favicon/package.json substitutions, and
  4 npm audit advisories in generated docs dependencies.

## Public Claim Audit

Allowed claim: `marker_significance_summary()` prepares deterministic nominal
raw-p, Bonferroni, and BH flags/counts over the markers already present in a
direct Julia marker-scan result. It returns thresholds, marker IDs, original
scan indices, min/max diagnostics, and top-marker provenance by raw p-value.

Disallowed claims remain explicit: this does not define calibrated
correlated-marker genome-wide thresholds, estimate effective marker counts,
calibrate p-values, correct scan statistics, choose public GWAS/QTL/eQTL
thresholds, draw plots, activate R `marker_scan()` syntax, activate
`gwas_table()` / `qtl_table()` / `eqtl_table()`, activate `regional_plot()`,
change the bridge payload, change `result_payload()`, or add comparator
evidence.

## Tests Of The Tests

The deterministic tests pin:

- nominal raw-p, Bonferroni, and BH thresholds;
- per-marker flags and counts;
- marker ID and scan-index provenance for each summary class;
- min raw p-value, minimum adjusted p-values, max chi-square, and max LOD;
- top-marker ID, index, p-value, adjusted p-values, chi-square, and LOD;
- target propagation for fixed, supplied-variance mixed, supplied LOCO, and
  compatible scan-like inputs;
- guards for missing marker IDs, missing p-values, malformed Bonferroni/BH
  fields, malformed chi-square/LOD fields, and invalid `alpha`.

The validation-status tests assert that the `V5-MARKER-FIXED` row names
marker-significance summary evidence while keeping calibrated/correlated-marker
genome-wide thresholds, p-value calibration, bridge changes, and comparator
claims outside the covered boundary.

## Coordination Notes

No R repo files were edited. This helper remains direct-Julia only. Any
R-facing exposure through `marker_scan()`, `gwas_table()`, `qtl_table()`, or
`eqtl_table()` must be coordinated through GitHub issues before changing the
bridge contract or public formula language.

## What Did Not Go Smoothly

The first docs build hit stale local `docs/build` generated output instead of a
source failure. Removing `docs/build` and rebuilding passed. The shell's
default PATH still has no `julia`; validation used `~/.juliaup/bin/julia` with
one-thread settings.

## Known Limitations

- Summary helper only.
- Thresholds are nominal over the returned marker set.
- No calibrated/correlated-marker genome-wide thresholds, effective marker-count
  estimation, p-value calibration, statistic correction, calibrated PVE/model R2
  claim, plotting backend, external comparator parity, R syntax, bridge
  activation, or GWAS/QTL/eQTL table activation.

## Next Actions

- Coordinate any R-facing marker-significance exposure through GitHub issues
  before changing the bridge contract.
- Add calibrated threshold workflows only as separate gated slices with explicit
  statistical assumptions, comparator/simulation evidence, and public claim
  wording.
