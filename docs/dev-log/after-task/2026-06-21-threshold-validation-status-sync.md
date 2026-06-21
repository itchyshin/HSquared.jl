# After-Task Report: Threshold Validation-Status Sync

## Live Phase Snapshot

As of this report, the slice starts from Julia `main` `f9fbbb1` after the #45
marker-scan payload fixture merge. The R lane has merged hsquared PR #77
(`e2758a1`) to sync the parent validation-canon issue body and hsquared PR #78
(`7e10c43`) to sync the PEV/reliability closeout. Covered public status is
unchanged: v0.1 univariate Gaussian animal-model support only. This slice does
not promote any validation row to covered.

## 1. Goal

Reconcile the human-facing validation-status page with the existing
`validation_status()` source row for `V5-MARKER-THRESHOLD`.

## 2. Implemented

- Added the missing `V5-MARKER-THRESHOLD` row to
  `docs/src/validation-status.md`.
- Added a coordination-board entry documenting the #48 status-sync scope.
- Retargeted the live #48 issue body so it lists the existing deterministic
  threshold machinery and fixed-panel mini-smoke while keeping the issue open.
- Added this after-task report and a per-slice check-log note.

## 3a. Decisions and Rejected Alternatives

- Did not change threshold code or tests; the source row and threshold
  machinery already existed.
- Did not close #48. The realistic-LD/design calibration, external comparator,
  and R-facing significance wording gates remain open.
- Kept the validation-status row concise, pointing to the current partial
  state rather than duplicating the long source-ledger evidence text.

## 4. Files Touched

- `docs/src/validation-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-threshold-validation-status-sync.md`
- `docs/dev-log/after-task/2026-06-21-threshold-validation-status-sync.md`

## 5. Checks Run

- `git diff --check` — passed.
- `julia --project=docs docs/make.jl` — passed with existing local warnings for
  skipped deployment detection, substituted Vitepress defaults, missing
  logo/favicon, and npm audit output.
- `gh issue edit 48 --body ...` — passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-threshold-validation-status-sync.md`
  — passed.

## 6. Tests of the Tests

This is a source-documentation sync only. The guard is that
`src/validation_status.jl`, `docs/design/capability-status.md`, and
`docs/design/validation-debt-register.md` already contain the threshold row and
evidence; this slice restores the missing rendered-doc source row.

## 7a. Issue Ledger

- #48 remains open. This branch repairs a validation-status page omission and
  retargets the live issue body to current partial evidence.
- R lane: no R files were touched. R can continue to hold `gwas()`
  significance wording until realistic-LD/design calibration evidence lands.

## 8. Consistency Audit

- Checked `src/validation_status.jl` for the source `V5-MARKER-THRESHOLD` row.
- Checked capability status, validation debt, API docs, and threshold after-task
  reports for existing threshold evidence and boundaries.
- Kept `V5-MARKER-THRESHOLD` partial.

## 9. What Did Not Go Smoothly

The rendered-doc source table had drifted behind the typed source row. The
implementation and ledgers were ahead of the human-facing page.

## 10. Known Residuals

- No realistic-LD/design calibration evidence.
- No external PLINK/GenABEL/qvalue comparator.
- No threshold columns wired into public marker-scan outputs.
- No R `gwas()` significance wording activation.
- No covered-status promotion.

## 11. Team Learning

Manual validation-status tables need a lightweight sync habit after adding
typed rows. Otherwise the source API is more current than the page humans read.
