# After-Task Report: Fixed-Effect Marker-Scan QQ Plot Data

## Task Goal

Add deterministic QQ plot-data preparation for the direct Julia
`single_marker_scan()` utility without adding a plotting dependency, genomic
inflation/calibration claim, R syntax, bridge payload change, or mixed-model
GWAS/QTL claim.

## Active Lenses And Agents

- Florence: plot-data ergonomics.
- Fisher: p-value display semantics and no calibration overclaim.
- Curie: deterministic tests and guardrails.
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
- `docs/dev-log/after-task/2026-06-14-marker-qq-plot-data.md`

## Checks Run

- `git diff --check`: passed before and after the final ledger update.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 197 checks; Phase 5
  fixed-effect single-marker scan testset is now 91 checks; Phase 4B structured
  covariance remains 61 checks.
- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 docstrings not included in the manual,
  local deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.

## Public Claim Audit

Allowed claim: `marker_qq_data()` prepares deterministic QQ plot data from a
direct fixed-effect `single_marker_scan()` result: raw p-values, sorted observed
p-values, sorted marker IDs, expected uniform order-statistic p-values,
observed/expected `-log10` display values, sort order, and display p-value
floor.

Disallowed claims remain explicit: this is not a plotting backend, not genomic
inflation estimation, not p-value calibration, not a mixed-model marker scan,
not relatedness/population-structure correction, not LOCO, not interval mapping,
not an R `marker_scan()` formula term, not a bridge payload change, and not
comparator evidence.

## Tests Of The Tests

The deterministic tests pin:

- default scan marker IDs and raw p-values;
- stable QQ sort order and sorted marker IDs;
- expected uniform order-statistic p-values (`i / (m + 1)`);
- observed and expected `-log10` display values;
- zero-p-value display floor behavior while preserving raw p-values;
- malformed scan and invalid `p_floor` guardrails.

The validation-status tests assert that the `V5-MARKER-FIXED` row names
`marker_qq_data()` and keeps the no-calibration / no-bridge-change claim
boundary.

## Coordination Notes

No R repo files were edited. The R-facing `marker_scan()` formula term remains
planned/reserved only. No bridge payload or `result_payload()` shape changed.

## What Did Not Go Smoothly

No implementation blocker. The main care point was keeping the new QQ helper
out of calibrated-GWAS language.

## Known Limitations

- Plot-data helper only; no plotting backend.
- No genomic inflation factor, calibration, LOCO, mixed-model marker scan, or
  correlated-marker multiple-testing workflow.
- No external comparator parity.
- No R syntax or bridge activation.

## Next Actions

- Continue Phase 5 in narrow, evidence-gated slices: plotting backend only if
  paired with documented output contracts, or mixed-model marker scans only
  after the estimand and relationship-correction evidence are pinned.
- Coordinate any R-facing marker API through GitHub issues before changing the
  bridge contract.
