# After-Task Report: Marker-Scan Payload Fixture

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `7466b2d` after the
PEV/reliability payload ledger closeout. The R lane has merged hsquared PR #75
at `e9633c0`, syncing the marker-scan issue body around the already-banked
post-fit `gwas(fit, markers)` surface, and hsquared PR #76 at `9e94137`,
syncing the multivariate validation issue body. Covered public status is
unchanged: v0.1 univariate Gaussian animal-model support only. This slice does
not promote any validation row to covered.

## 1. Goal

Complete the Julia-owned #45 payload handoff by adding a stable
`marker_scan_result_payload(scan)` bridge shape and a deterministic
`test/fixtures/marker_scan_parity/` target that the R lane can consume without
live Julia.

## 2. Implemented

- Exported `marker_scan_result_payload(scan)` from `HSquared`.
- Added a compact row-aligned payload for marker IDs, effects, SEs, Wald
  statistics, nominal p-values, Bonferroni/BH values, LOD-equivalent scores,
  denominators, allele frequencies, VanRaden scale, optional supplied variance
  components, and optional LOCO group metadata.
- Added `test/fixtures/marker_scan_parity/` with reproducible source data,
  expected payload CSV, metadata CSV, README, and `generate.jl`.
- Added tests for payload shape, payload values, fixture reconstruction, and a
  corrupted-effect negative check.
- Updated validation-status evidence, public claims, capability/debt ledgers,
  bridge compatibility, API docs, genomic docs, roadmap docs, coordination
  board, and this check-log/after-task evidence.

## 3a. Decisions and Rejected Alternatives

- Kept the payload as a plain `NamedTuple` instead of introducing a new result
  type, matching the existing engine result style and R bridge needs.
- Serialized the fixture as CSV plus metadata rather than Julia-only objects so
  R can validate the target without starting JuliaCall.
- Did not include calibrated thresholds in the payload. Calibration remains the
  separate #48 evidence gate.
- Did not activate map-annotated GWAS/QTL/eQTL table workflows; those remain
  reserved beyond this bridge fixture.

## 4. Files Touched

- `ROADMAP.md`
- `src/HSquared.jl`
- `src/genomic.jl`
- `src/validation_status.jl`
- `test/runtests.jl`
- `test/fixtures/marker_scan_parity/README.md`
- `test/fixtures/marker_scan_parity/generate.jl`
- `test/fixtures/marker_scan_parity/expected_marker_scan_payload.csv`
- `test/fixtures/marker_scan_parity/expected_metadata.csv`
- `test/fixtures/marker_scan_parity/markers.csv`
- `test/fixtures/marker_scan_parity/pedigree.csv`
- `test/fixtures/marker_scan_parity/phenotypes.csv`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/12-bridge-compatibility.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/src/api.md`
- `docs/src/genomics-qtl-gpu-hpc.md`
- `docs/src/roadmap.md`
- `docs/src/validation-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-marker-scan-payload-fixture.md`
- `docs/dev-log/after-task/2026-06-21-marker-scan-payload-fixture.md`

## 5. Checks Run

- `julia --project=. test/fixtures/marker_scan_parity/generate.jl` — passed.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
- `julia --project=docs docs/make.jl` — passed with existing local warnings for
  skipped deployment detection, substituted Vitepress defaults, missing
  logo/favicon, and npm audit output.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-marker-scan-payload-fixture.md`
  — passed.
- `git diff --check` — passed.

## 6. Tests of the Tests

The fixture test reconstructs the pedigree, supplied variance components, fit,
and marker matrix from CSV files before recomputing the payload. It compares
all serialized numeric columns at `1e-12` tolerance and then perturbs the first
effect estimate to prove the parity check fails on value drift.

## 7a. Issue Ledger

- #45: this branch completes the Julia-side post-fit marker-scan bridge payload
  and deterministic fixture requested for the R handoff.
- #48: remains open for calibrated genome-wide threshold evidence and any
  activation beyond nominal marker-scan output.
- R lane: no R files were touched. The R twin has already synced the R issue
  body in hsquared PR #75 (`e9633c0`), and can now consume
  `test/fixtures/marker_scan_parity/` as a Julia-free parity target.

## 8. Consistency Audit

- Updated both source-of-truth ledgers and Documenter pages that mention the
  marker-scan bridge state.
- Kept `V5-MARKER-MIXED` partial, with no covered-status promotion.
- Kept the direct Julia utilities separate from formula-level
  `marker_scan()` / `qtl_scan()` grammar and map-annotated output tables.

## 9. What Did Not Go Smoothly

The first local test run caught a syntax error in the new negative fixture
check. After fixing the `isapprox(...; atol = 1e-12)` call, the full package
suite passed.

## 10. Known Residuals

- No calibrated genome-wide threshold activation (#48).
- No map-annotated `gwas_table()` / `qtl_table()` / `eqtl_table()` /
  `lod_scores()` workflow.
- No public R formula `marker_scan()` activation.
- No sparse production scan, marker-scan variance-component estimation, or
  external comparator evidence.
- No validation-row or public-claim promotion.

## 11. Team Learning

For bridge work, the serialized fixture is as important as the live Julia
function: it gives the R lane something stable to test against even when
JuliaCall is not available or is locally unstable.
