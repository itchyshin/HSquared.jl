# After-Task Report: Structured Covariance Status Sync

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `07a3c63` after the #48
threshold validation-status sync. The R lane has already merged hsquared PR #74
(`b4b4da5`), retargeting R issue #22 so diagonal structured covariance is
described as banked while lowrank/fa remains open. Covered public status is
unchanged: v0.1 univariate Gaussian animal-model support only. This slice does
not promote any validation row to covered.

## 1. Goal

Reconcile the Julia human-facing structured-covariance docs with the current
engine/bridge state: `:diagonal`/`:unstructured` payloads are banked, while
lowrank/fa loading exposure remains blocked.

## 2. Implemented

- Updated `docs/src/validation-status.md` for `V4-FA`.
- Updated `docs/design/capability-status.md`.
- Updated `docs/design/06-public-claims-register.md`.
- Retargeted live issue #42 so it records the banked diagonal/unstructured
  payload and keeps lowrank/fa bridge exposure open.
- Added a coordination-board entry, check-log note, and this after-task report.

## 3a. Decisions and Rejected Alternatives

- Did not change `src/validation_status.jl`; it already had the right
  diagonal-vs-lowrank/fa boundary.
- Did not touch `multivariate_result_payload()` or fixtures; this is a status
  sync only.
- Did not close #42. The lowrank/fa bridge exposure and R activation remain
  open gates.

## 4. Files Touched

- `docs/src/validation-status.md`
- `docs/design/capability-status.md`
- `docs/design/06-public-claims-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-structured-covariance-status-sync.md`
- `docs/dev-log/after-task/2026-06-21-structured-covariance-status-sync.md`

## 5. Checks Run

- `git diff --check` — passed.
- `julia --project=docs docs/make.jl` — passed with existing local warnings for
  skipped deployment detection, substituted Vitepress defaults, missing
  logo/favicon, and npm audit output.
- `gh issue edit 42 --body ...` — passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-structured-covariance-status-sync.md`
  — passed.

## 6. Tests of the Tests

This is a source-documentation sync only. Existing CI tests already cover
`multivariate_result_payload()` for `:diagonal`/`:unstructured`, reject
`:lowrank`/`:factor_analytic`, and verify
`test/fixtures/structured_covariance_parity/`.

## 7a. Issue Ledger

- #42 remains open. The live issue body now records that diagonal/unstructured
  payloads are banked; lowrank/fa loading exposure, external comparator parity,
  and R-facing covariance syntax remain open.
- R lane: no R files were touched. R issue #22 was already retargeted in
  hsquared PR #74.

## 8. Consistency Audit

- Checked `src/validation_status.jl`, `docs/design/validation-debt-register.md`,
  `docs/design/12-bridge-compatibility.md`, and
  `test/fixtures/structured_covariance_parity/README.md`.
- Kept `V4-FA` and `V4-BRIDGE` partial.
- Preserved the raw-loading/rotation-identifiability boundary.

## 9. What Did Not Go Smoothly

The typed source row had already been updated, but the human-facing status page
and public claims register had not followed it.

## 10. Known Residuals

- No lowrank/fa bridge payload.
- No R covariance-structure syntax activation.
- No external comparator parity against the structured targets.
- No passing broad calibration claim.
- No covered-status promotion.

## 11. Team Learning

When a partial bridge lands for one safe subset, claim surfaces need to say
which subset is banked and which subset is still blocked. A blanket "no bridge
payload" phrase becomes stale quickly.
