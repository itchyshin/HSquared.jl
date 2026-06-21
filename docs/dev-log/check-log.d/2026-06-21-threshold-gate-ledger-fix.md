# 2026-06-21 Threshold gate ledger fix (#48)

- **Goal:** restore the #48 GitHub issue state to match the repo-visible
  evidence ledger after #134 landed.
- **Lenses:** Ada/Shannon (issue-ledger coordination), Rose (claim boundary),
  Grace (check evidence).
- **Spawned subagents:** none.

## Commands

- `gh issue view 48 --json number,title,state,closedAt,url,labels,body` —
  showed #48 was `CLOSED` at `2026-06-21T18:43:25Z`, despite the #134
  after-task report saying the threshold gate must remain open.
- `gh issue reopen 48` — passed; reopened
  <https://github.com/itchyshin/HSquared.jl/issues/48>.
- `git diff --check` — passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-threshold-gate-ledger-fix.md`
  — passed.

## Boundary

Issue-ledger hygiene only. This does not add threshold evidence, does not wire
calibrated thresholds into marker-scan outputs, does not activate R `gwas()`
significance wording, does not satisfy the realistic-LD/external-comparator
gate, and does not promote any capability to covered.
