# GWAS/QTL/eQTL Table Wrappers

Date: 2026-06-16

## Task Goal

Add direct Julia `gwas_table()`, `qtl_table()`, and `eqtl_table()` helpers over
existing marker-scan table data without activating formula-driven marker scans,
R syntax, expression-wide eQTL workflows, calibrated thresholds, plotting, or
bridge payload changes.

## Active Lenses And Agents

- Ada/Shannon: stacked Phase 5 lane discipline.
- Fisher: p-value, LOD, and table-claim boundaries.
- Curie: deterministic tests and malformed-input guards.
- Pat/Boole: simple table names and metadata ergonomics.
- Rose: claim-vs-evidence audit.
- Grace: local tests and docs build.
- Jason: local sister-package scout.
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
- `docs/src/validation-status.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/scout/2026-06-16-gwas-qtl-eqtl-table-wrappers-scout.md`
- this report

## What Landed

- Exported `gwas_table()`, `qtl_table()`, and `eqtl_table()`.
- Each helper wraps `marker_scan_table()` output and preserves existing scan
  fields.
- `gwas_table()` and `qtl_table()` optionally carry non-empty scalar `trait`
  metadata.
- `eqtl_table()` optionally carries non-empty scalar `feature` metadata for an
  expression feature, gene, or transcript.
- All three support direct scan results with optional `HSMarkerMapSpec` or
  `HSData` marker metadata alignment.

## Checks Run

- `git diff --check`: passed.
- Focused/low-core command:

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test(test_args=["Phase 5 fixed-effect single-marker scan"])'
```

Result: passed. The test runner executed the package suite; the Phase 5
fixed-effect single-marker scan testset is now 443 checks.

- Full low-core command:

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'
```

Result: passed. Phase 5 fixed-effect single-marker scan testset remains 443
checks; Phase 4B structured covariance remains 61 checks.

- Docs command:

```sh
rm -rf docs/build && env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'
```

Result: passed. Known local caveats remain: 8 unrelated docstrings not included
in the manual, local deployment skipped outside CI, VitePress default
substitutions, missing local logo/favicon/package.json substitutions, and 4 npm
audit advisories in generated docs dependencies.

## Tests Of The Tests

The deterministic tests pin:

- `analysis = :gwas | :qtl | :eqtl`;
- optional `trait` / `feature` metadata normalization;
- marker-map-backed chromosome and position alignment;
- preservation of scan `target`, marker IDs, LOD scores, marker groups, and
  variance-proportion fields;
- errors for blank trait/feature metadata;
- errors when wrappers receive malformed scan fields or `HSData` without
  marker metadata.

## Public Claim Audit

Allowed:

- `gwas_table()`, `qtl_table()`, and `eqtl_table()` label already-computed
  direct marker-scan tables.
- The helpers are direct Julia table-preparation utilities.

Blocked / not claimed:

- no formula-driven GWAS/QTL/eQTL workflow;
- no R `marker_scan()` / `qtl_scan()` activation;
- no expression-wide eQTL scan;
- no cis/trans classification;
- no interval mapping or mixed-model LOD workflow;
- no calibrated p-values, calibrated PVE/model R2, or calibrated genome-wide
  thresholds;
- no plotting backend, `regional_plot()`, or fine mapping;
- no bridge payload or `result_payload()` change;
- no external comparator evidence.

## What Did Not Go Smoothly

- A couple of local file reads over docs files were slow / appeared to hang in
  the Dropbox-backed checkout; they completed or were interrupted without
  modifying files.
- One grep command used shell backticks in a pattern and printed harmless
  `command not found` messages before being stopped. No files were changed by
  that command.

## Known Limitations

- The wrappers do not compute scan statistics.
- They inherit the current direct marker-scan limitations: validation-scale
  helpers, approximate Wald summaries, no calibrated genome-wide thresholds, no
  external comparator parity, and no R-facing formula activation.

## Next Actions

1. Push this stacked branch and open a draft PR after the existing Phase 5
   marker recovery head.
2. When the Phase 5 stack is ready, reconcile/open issue comments for the
   direct table wrappers.
3. Later slices can add R-side planned extractors only after bridge and syntax
   contracts are explicitly updated.
