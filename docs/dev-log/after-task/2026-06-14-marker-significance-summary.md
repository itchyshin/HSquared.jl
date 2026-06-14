# Marker Significance Summary Helper

## Task Goal

Add a direct Julia helper that summarizes nominal marker hits from already
computed marker-scan fields without claiming calibrated GWAS/QTL/eQTL
thresholds.

## Active Lenses And Spawned Agents

- Ada/Shannon: lane discipline and branch stacking.
- Jason: sister-package diagnostic-threshold patterns.
- Fisher: significance wording and threshold boundary.
- Curie: deterministic flag/count/top-marker tests and malformed-input guards.
- Rose: public claim audit.
- Grace: local checks and CI readiness.
- Spawned agents: none.

## Files Changed

- `src/HSquared.jl`
- `src/genomic.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `README.md`
- `ROADMAP.md`
- `docs/src/api.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/scout/2026-06-14-marker-significance-summary-scout.md`
- this report

## What Landed

- Exported `marker_significance_summary`.
- Added `marker_significance_summary(scan; alpha = 0.05)`.
- The helper validates marker IDs, raw p-values, Bonferroni-adjusted p-values,
  BH q-values, chi-square values, LOD scores, and `alpha`.
- It returns raw, Bonferroni, and BH flags/counts, marker IDs, scan indices,
  thresholds, min p/q summaries, max statistic summaries, top-marker
  provenance, and scan target metadata.
- The helper works over direct fixed, supplied-variance mixed, LOCO, and custom
  scan-like named tuples that carry the expected fields.

## Checks

- `git diff --check` - passed.
- Focused marker command:
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test(test_args=["Phase 5 fixed-effect single-marker scan"])'`
  - passed. The runner executed the suite; Phase 5 fixed-effect
  single-marker scan testset is now 415 checks.
- Full suite:
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`
  - passed.
- Root-level docs command failed locally:
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`
  failed with `IOError: cd("build/"): no such file or directory`.
- Rerun from `docs/` passed:
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("make.jl")'`.
  Known local caveats remained: 8 unrelated docstrings not included in the
  manual, local deployment skipped, VitePress default substitutions, missing
  local logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.

## Tests Of The Tests

- Deterministic tests cover raw, Bonferroni, and BH flags/counts, marker IDs,
  scan indices, thresholds, min p/q summaries, max statistics, top-marker
  provenance, and target propagation for fixed, mixed, LOCO, and custom scans.
- Guard tests cover missing marker IDs, missing p-values, malformed adjusted
  p-values, malformed BH q-values, malformed chi-square and LOD fields, and
  invalid `alpha`.
- Validation-status tests require the new helper and its claim-boundary text
  to appear in the `V5-MARKER-FIXED` row.

## Public Claim Audit

Allowed:

- `marker_significance_summary()` prepares nominal raw-p, Bonferroni, and BH
  flags/counts over the markers already returned by a direct Julia scan.

Blocked:

- calibrated p-values;
- effective marker counts;
- calibrated/correlated-marker genome-wide thresholds;
- significant QTL/eQTL claims;
- `gwas_table()` / `qtl_table()` / `eqtl_table()` activation;
- plotting or fine mapping;
- R `marker_scan()` syntax;
- bridge payload or `result_payload()` changes;
- comparator parity.

## Coordination Notes

No R repository files were edited. This is Julia-lane groundwork on top of the
stacked Phase 5 marker-scan helper branches.

## What Did Not Go Smoothly

The root-level docs invocation failed on the existing local DocumenterVitepress
`build/` cwd assumption. Running the same docs build from the `docs/`
directory passed.

## Known Limitations

- Requires already-computed scan fields.
- Does not adjust p-values beyond consuming the scan's existing Bonferroni and
  BH fields.
- Does not calibrate thresholds under LD/correlated markers.
- Does not promote QTL/GWAS/eQTL support.

## Next Actions

1. Push as a draft PR stacked on the marker-region helper.
2. Watch CI and Documenter.
3. Continue Phase 5 with either a direct Julia regional/threshold display
   refinement, R bridge planning, or comparator evidence once the branch stack
   lands.
