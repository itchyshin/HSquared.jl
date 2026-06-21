# After-Task Report: Threshold gate ledger fix (#48)

## Live Phase Snapshot

As of this report, Julia `main` before the slice was `beca371` after the
fixed-panel threshold-calibration smoke (#134), with post-merge CI, Documenter,
and Pages green. Covered public status is unchanged: v0.1 univariate Gaussian
animal-model support only; Phase 5 marker threshold work remains
`partial` / `experimental`.

## 1. Goal

Restore the #48 issue state to match the repo-visible evidence ledger: the
fixed-panel calibration smoke advanced #48, but did not close the threshold
gate.

## 2. Implemented

- Reopened <https://github.com/itchyshin/HSquared.jl/issues/48> after confirming
  it had been closed when #134 merged.
- Added a coordination-board entry making the reopened state explicit.
- Added a per-slice check-log note documenting the issue-state mismatch and the
  no-promotion boundary.

## 3a. Decisions and Rejected Alternatives

- Chose to reopen #48 rather than create a new issue because the original issue
  text still names the remaining work: realistic-LD/design calibration,
  effective-number/FDR workflow, output wiring, and Rose audit.
- Did not add a GitHub issue comment. The repository record is enough for this
  narrow hygiene fix, and outward issue comments should remain deliberate.
- Did not edit threshold code, tests, or status rows. The problem was ledger
  state, not the #134 implementation.

## 4. Files Touched

- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-threshold-gate-ledger-fix.md`
- `docs/dev-log/after-task/2026-06-21-threshold-gate-ledger-fix.md`

## 5. Checks Run

- `gh issue view 48 --json number,title,state,closedAt,url,labels,body` —
  confirmed the issue was closed at `2026-06-21T18:43:25Z`.
- `gh issue reopen 48` — passed.
- `git diff --check` — passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-threshold-gate-ledger-fix.md`
  — passed.

## 6. Tests of the Tests

This slice has no source-code test because it changes issue state and repo
ledger files only. The guard is the before/after GitHub issue query plus the
after-task validator, which would fail if the required Rose sections were
missing.

## 7a. Issue Ledger

- Reopened #48. It remains the active gate for calibrated genome-wide
  significance thresholds.
- #48 is not satisfied by the #134 fixed-panel smoke. Remaining blockers:
  realistic-LD/design type-I control, effective-number/FDR workflow if chosen,
  threshold output wiring, external comparator or accepted calibration canon,
  and Rose audit before any public significance claim.

## 8. Consistency Audit

- Checked the #134 after-task report and check-log entry; both already state
  that #48 should remain open.
- Confirmed no R-lane files were edited.
- Kept the change in `check-log.d/` rather than the frozen historical
  `check-log.md`.

## 9. What Did Not Go Smoothly

The issue was closed by GitHub linkage despite the repo report saying the gate
remained open. That is exactly the kind of ledger drift this patch corrects.

## 10. Known Residuals

- No new threshold calibration evidence.
- No realistic-LD or external-comparator evidence.
- No `marker_scan_table()` threshold columns.
- No R `gwas()` significance wording activation.
- No covered-status promotion.

## 11. Team Learning

When a PR advances but does not satisfy an issue, avoid closing keywords or
reopen the issue immediately after merge. Validation gates should be driven by
the evidence ledger, not by incidental PR linkage.
