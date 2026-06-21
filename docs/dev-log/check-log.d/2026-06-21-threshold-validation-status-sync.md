# 2026-06-21 Threshold Validation-Status Sync (#48)

- Goal: reconcile the human-facing `docs/src/validation-status.md` table with
  the source `validation_status()` row for `V5-MARKER-THRESHOLD`.
- Active lenses: Ada, Shannon, Fisher, Curie, Grace, Rose.
- Starting point: `main` at `f9fbbb1` after the #45 marker-scan payload fixture
  merge. R-lane context: hsquared PR #77 synced the parent validation-canon
  issue body and hsquared PR #78 synced the PEV/reliability closeout; neither is
  threshold evidence.
- Evidence checked:
  - `src/validation_status.jl` already contains `V5-MARKER-THRESHOLD`.
  - `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
    `docs/src/api.md`, and threshold after-task/check-log files already record
    the deterministic threshold machinery plus fixed-panel mini-smoke.
  - `docs/src/validation-status.md` skipped the `V5-MARKER-THRESHOLD` table row,
    so the rendered status page underreported the current partial evidence.
- Changes:
  - Added the missing `V5-MARKER-THRESHOLD` row to
    `docs/src/validation-status.md`.
  - Added a coordination-board entry so the narrow status-sync scope is visible.
  - Retargeted live issue #48 so it lists the banked deterministic threshold
    machinery and fixed-panel mini-smoke while keeping realistic-LD/comparator
    evidence and R significance wording open.
- Commands run:
  - `julia --project=docs docs/make.jl` — passed with existing local
    Documenter/Vitepress warnings for skipped deployment detection, substituted
    Vitepress defaults, missing logo/favicon, and npm audit output.
  - `gh issue edit 48 --body ...` — passed; #48 remains open.
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-threshold-validation-status-sync.md`
    — passed.
  - `git diff --check` — passed.
- Rose verdict: clean with limitations. This is a docs/status sync only: no new
  threshold calibration, no realistic-LD evidence, no external comparator, no
  R-facing `gwas()` significance wording, and no status promotion.
