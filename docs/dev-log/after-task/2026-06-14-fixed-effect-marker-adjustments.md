# 2026-06-14 Fixed-Effect Marker-Scan Multiple-Testing Adjustments

## Task Goal

Add deterministic Bonferroni and Benjamini-Hochberg summaries to the direct
Julia fixed-effect marker scan while preserving the twin-lane boundary: no R
code edits, no public `marker_scan()` formula activation, and no mixed-model or
calibrated GWAS/QTL claim.

## Active Lenses And Spawned Agents

- Fisher: p-value adjustment interpretation.
- Curie: deterministic tests and invalid-input guardrails.
- Grace: throttled local checks.
- Shannon: R/Julia bridge boundary and coordination surface.
- Rose: claim-vs-evidence audit.
- Spawned agents: none.

## Files Changed

- `src/genomic.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `README.md`
- `ROADMAP.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/changelog.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- this report

## What Landed

`single_marker_scan()` now returns two additional arrays:

- `bonferroni_p_values`;
- `bh_q_values`.

Both are deterministic adjustments over the marker set returned by the direct
fixed-effect scan. The implementation adds checked private helpers for finite
`[0, 1]` p-values, Bonferroni adjustment, and Benjamini-Hochberg adjustment.
No new package dependency was added.

Tests now pin:

- Bonferroni and BH values for the two-marker hand fixture;
- Bonferroni and BH values for an unordered four-p-value vector;
- consistency between covariate-adjusted scan output and the helpers;
- output ranges for raw, Bonferroni, and BH values;
- empty, out-of-range, and non-finite p-value guardrails.

## Public Claim Audit

Allowed:

- `single_marker_scan()` reports approximate two-sided Gaussian/Wald p-values
  plus Bonferroni and Benjamini-Hochberg adjustments over the returned marker
  set;
- `V5-MARKER-FIXED` remains partial/experimental direct Julia engine evidence.

Blocked:

- no mixed-model GWAS/QTL/eQTL claim;
- no relationship or population-structure correction;
- no LOCO path;
- no LOD scores;
- no calibrated mixed-model p-values;
- no correlated-marker or genome-wide calibration claim;
- no external comparator parity;
- no R `marker_scan()` formula activation;
- no bridge payload or `result_payload()` change.

## Checks

- `git diff --check`: passed.
- Throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`: passed.
  - Phase 5 fixed-effect single-marker scan testset is now 39 checks.
  - Phase 4B structured covariance remains 61 checks.
- Throttled `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.
