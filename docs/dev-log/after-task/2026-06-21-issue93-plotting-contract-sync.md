# After-Task Report: #93 plotting contract sync

## Live Phase Snapshot

As of this report, Julia `main` before the slice was `a815097` after the #48
issue-ledger fix (#135). Covered public status is unchanged: v0.1 univariate
Gaussian animal-model support only. Plotting remains experimental: the
plot-data contract is resolved, while Makie drawing is still locally attested
rather than CI-gated.

## 1. Goal

Reconcile the Julia plotting ledger with the later R-lane evidence and make
#93 ready to close as a plot-data contract issue.

## 2. Implemented

- Replaced the stale `docs/design/13-plotting-layer.md` #93 proposal text with
  a resolved-contract summary.
- Recorded that the R lane consumes all seven landed engine `*_plot_data`
  preparers with parity guards, and that R PR #35 attaches available payloads
  at fit time.
- Updated wording that still described `HSquaredMakieExt` as planned in
  plotting status/debt rows.
- Added a coordination-board entry and per-slice check-log evidence.

## 3a. Decisions and Rejected Alternatives

- Chose a docs/status sync rather than code changes because the Julia preparers,
  R consumers, and fit-time R payload attachment had already landed.
- Kept `rr_genetic_variance_plot_data.genetic_variance` unchanged. R is
  rename-robust and accepts either `value` or `genetic_variance`, so a field
  rename would create churn without closing a live gap.
- Did not promote plotting to covered. #93 closure means the payload contract is
  consumed, not that every future plotting kind or CI-rendered Makie check exists.

## 4. Files Touched

- `docs/design/13-plotting-layer.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-issue93-plotting-contract-sync.md`
- `docs/dev-log/after-task/2026-06-21-issue93-plotting-contract-sync.md`

## 5. Checks Run

- `gh issue view 93 --comments --json number,title,state,closedAt,url,body,comments`
  — confirmed #93 was open and contained R-lane completion evidence.
- `gh pr view 35 --repo itchyshin/hsquared --json number,title,state,mergedAt,url,headRefName,mergeCommit,statusCheckRollup`
  — confirmed R PR #35 merged at `2026-06-21T12:15:14Z`, merge commit
  `6098839`, with R-CMD-check success.
- `git diff --check` — passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-issue93-plotting-contract-sync.md`
  — passed.
- `julia --project=docs docs/make.jl` — passed with existing local warnings for
  omitted internal docstrings, skipped deployment detection, default Vitepress
  assets, missing logo/favicon, and npm audit output.

## 6. Tests of the Tests

This slice has no source-code test because it reconciles documentation and issue
state only. The relevant test evidence is pre-existing and recorded in the
issue/R PR: R live parity guards for all seven preparers and Julia
`test/runtests.jl` coverage for the preparer shapes and Makie stub boundary.
The after-task validator confirms the local closeout report is complete.

## 7a. Issue Ledger

- #93 is ready to close after this PR lands: the plot-data contract is ratified,
  consumed, parity-guarded, and fit-time attachment exists in the R lane.
- Remaining plotting debt is outside #93: CI-gated Makie drawing or reproducible
  docs-render evidence, future Makie Manhattan/QQ/RR kinds, and any future
  public-plotting claim language.

## 8. Consistency Audit

- Checked `docs/design/13-plotting-layer.md`, `capability-status.md`, and
  `validation-debt-register.md` for stale #93/planned-Makie wording.
- Verified `hsquared` local `main` is clean aside from two pre-existing
  untracked handover files.
- Confirmed no R files were edited from this Julia lane.

## 9. What Did Not Go Smoothly

The #93 issue was already functionally resolved by later R and Julia work, but
the original design section still preserved the earlier proposal state. This
patch closes that ledger gap.

## 10. Known Residuals

- Makie drawing methods remain local-only evidence, with the base stub covered
  by CI.
- Not every figure kind has a Julia Makie implementation.
- Marker-scan p-values remain nominal and uncalibrated until #48 advances.
- No statistical capability is promoted to covered.

## 11. Team Learning

When a cross-lane issue is answered through several later PRs, update the
original design section once the last consumer lands. Otherwise the old proposal
text becomes a false blocker even after the contract is real.
