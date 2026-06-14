# After-Task Report: Marker Genomic-Inflation Diagnostic

## Task Goal

Add a deterministic diagnostic summary for marker-scan chi-square inflation over
direct Julia scan results, without calibrating p-values, correcting test
statistics, choosing genome-wide thresholds, changing R syntax, or changing the
bridge payload.

## Active Lenses And Agents

- Fisher: diagnostic-vs-calibration boundary.
- Jason: genomic-control scout and literature breadcrumb.
- Curie: deterministic median-chi-square tests.
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
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-14-marker-genomic-inflation.md`
- `docs/dev-log/scout/2026-06-14-marker-genomic-inflation-scout.md`

## Checks Run

- Preliminary `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 216 checks; Phase 5
  fixed-effect single-marker scan testset is now 175 checks; Phase 4B structured
  covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=. -e 'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; Pkg.test()'`:
  passed. Phase 0 scaffold/validation-status block is now 216 checks; Phase 5
  fixed-effect single-marker scan testset is now 175 checks; Phase 4B structured
  covariance remains 61 checks.
- Final `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 nice -n 15 ~/.juliaup/bin/julia --project=docs -e 'using LinearAlgebra; BLAS.set_num_threads(1); include("docs/make.jl")'`:
  passed. Known local caveats remained: 8 docstrings not included in the manual,
  local deployment skipped, VitePress default substitutions, missing local
  logo/favicon/package.json substitutions, and 4 npm audit advisories in
  generated docs dependencies.

## Public Claim Audit

Allowed claim: `marker_genomic_inflation()` computes a
genomic-control-style lambda diagnostic from a scan's returned chi-square
statistics. The default expected median is the committed chi-square(1) median
constant `0.454936423119572`.

Disallowed claims remain explicit: this does not calibrate p-values, correct
test statistics, estimate effective marker counts, choose genome-wide
thresholds, draw plots, activate R `marker_scan()` syntax, change the bridge
payload, change `result_payload()`, or add comparator evidence.

## Tests Of The Tests

The deterministic tests pin:

- the default chi-square(1) median constant;
- even- and odd-length median chi-square identities;
- `lambda_gc = median_chisq / expected_median`;
- target propagation for fixed, mixed, LOCO, and custom scan-like inputs;
- guards for missing `chisq`, empty `chisq`, negative/non-finite chi-square
  values, and invalid expected median.

The validation-status tests assert that the `V5-MARKER-FIXED` row names
`marker_genomic_inflation()` and keeps p-value calibration, bridge changes, and
comparator claims out of the covered boundary.

## Coordination Notes

No R repo files were edited. The R-facing `marker_scan()` formula term remains
planned/reserved only. No bridge payload or `result_payload()` shape changed.
Coordination should be posted to Julia issue #7 and R issue #9 once the draft PR
is open.

## What Did Not Go Smoothly

This branch already existed locally with a partial `marker_genomic_inflation()`
implementation. I inspected the diff, kept that name, and finished the tests,
status rows, and docs around the existing helper rather than adding a duplicate
diagnostic API.

## Known Limitations

- Diagnostic summary only.
- No p-value calibration, statistic correction, effective marker count,
  genome-wide threshold selection, plotting backend, external comparator parity,
  R syntax, or bridge activation.

## Next Actions

- Add p-value calibration or effective-marker-count logic only as a separate
  gated slice with explicit statistical assumptions and tests.
- Coordinate any R-facing marker API through GitHub issues before changing the
  bridge contract.
