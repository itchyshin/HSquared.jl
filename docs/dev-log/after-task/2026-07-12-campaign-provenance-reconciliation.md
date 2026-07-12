# 2026-07-12 — doc-34 campaign provenance reconciliation

## 1. Goal

Reconcile the handoff claim that four doc-34 campaigns had not run against repository truth and live
DRAC evidence, preventing duplicate compute and unsupported capability promotion.

## 2. Implemented

- Swept `main`, branches, worktrees, stashes, the R twin, and the multi-project brain index before launch.
- Found the committed R-twin result checkpoint (`hsquared` `3221039`, corrected by `b90d4c3`).
- Verified the cited Fir job IDs, array outcomes, raw remote result trees, row/seed counts, selected
  checksums, and machine-readable GATE lines over SSH.
- Withheld every planned submission: the campaigns already ran, so no seed was duplicated.
- Independently audited driver/pre-registration alignment and recorded the exact claim boundaries below.

## 3a. Decisions and Rejected Alternatives

Rejected blindly rerunning four expensive campaigns from the newer merged drivers: a durable checkpoint
plus live raw artifacts outrank a stale handoff sentence. Rejected status changes because the evidence has
known tier/scope boundaries and no new Rose/G10 promotion chain was run here. Kept raw outputs on DRAC
`/project`; did not bulk-copy or commit simulation artifacts.

## 4. Files Touched

- `docs/dev-log/after-task/2026-07-12-campaign-provenance-reconciliation.md`

No source, driver, capability-status, validation-status, or R-twin file changed.

## 5. Checks Run

- Ultra-plan Phase 0.25: `git status -sb`, `git log --oneline -20`, `git branch -a`,
  `git worktree list`, `git stash list`, staged/unstaged diffs — local `main` clean at `a6955220`.
- Brain MCP `search_notes(..., search_all_projects=true)` — recovered doc 34 and the already-banked results.
- `bash -n` on all five sbatch scripts — PASS (independent driver audit).
- Julia `Meta.parseall` on all four drivers — PASS (independent driver audit).
- Live `ssh fir sacct` — cited arrays exist; C1/C8/supplied-K screens completed; repeatability confirm
  first array timed out and the recorded resume completed.
- Live raw checks:
  - C1: 20 summary + 20 detail TSVs; 3,520 summary rows; 352,000 detail rows.
  - C8: 16 GATE lines; every cell converged 500/500; `base_inside` passed; only
    `rg_090_rec1` and `rg_095_rec1` failed.
  - supplied-K screen: 3/3 PASS at 48/48; confirm: 2,000 rows and 2,000 unique seeds in each of
    `arbK`, `identity`, and `pedA`, all PASS.
  - repeatability confirm: 40 task TSVs, 2,000 rows/seeds; pooled GATE FAIL at 1,999/2,000 converged,
    bias −0.00120, MCSE 0.00057, `|bias|/MCSE=2.10`.
- Selected SHA-256 anchors on Fir: C1 task-1 summary `db98f4a…c60`; C8 base-inside
  `909c011a…c58`; supplied-K arbK confirm `f05836f4…10a`; repeatability pooled `f064582f…eba`.

## 6. Tests of the Tests

The prior-work gate produced the required negative control: the proposed launch was stopped when the
cross-project search found evidence contradicting the handoff. SLURM `COMPLETED` was not accepted alone;
raw row counts, unique seeds, GATE lines, and checksums were checked. The repeatability TIMEOUT→resume
history also proves why parent-state greenness alone is insufficient.

## 7a. Issue Ledger

- **Fixed operationally:** stale “drivers have NOT been run” handoff claim; duplicate-run risk.
- **Confirmed evidence:** C1 coverage characterization; C8 500-seed breadth; supplied-K 2,000-seed
  confirm; repeatability 2,000-seed banked negative.
- **Carried:** C1 `h2=0.1` interior-vs-boundary classification mismatch; C8 500 vs doc-34 2,000 confirm;
  C8 driver lacks an explicit 0.90 convergence gate (all realized cells were 500/500); confirm output
  retains `screening_only=true`; supplied marker `Q` is not covered by the K gate.
- **No promotion:** `public_covered_count` remains 5.

## 8. Consistency Audit

Compared the R-twin checkpoint, governing doc 34, four Julia drivers, five sbatch scripts, live Fir
accounting, and live raw artifacts. Three independent lenses reviewed driver mechanics, statistical
scope, and launch readiness. The results checkpoint is substantively supported, but its shorthand
“supplied-K / Q” heading must not be read as Q evidence, and C8 remains characterization-tier.

## 9. What Did Not Go Smoothly

The incoming handoff was newer than the driver merge but stale relative to evidence already committed in
the R twin. The first route command was run from the Julia repo with a relative hub path and failed; the
absolute hub router then returned the correct manifest. The hub closeout helper wrote relative to the hub,
so this report was created directly in the active repo instead.

## 10. Known Residuals

The raw evidence remains on Fir under
`/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/`, not copied into git.
C1 claim-tier ratification still needs
the h²=0.1 classification resolved plus Rose/maintainer review. supplied-K still owes its comparator,
n-ladder/true-null, R wiring, maintainer IN/OUT decision, Rose, and G10. Repeatability remains partial after
its banked negative. No automatic capability reconciliation was attempted.

## 11. Team Learning

Memory receipt: loaded the HSquared route manifest, doc 34, cross-repo guards, `$ultra-plan`, and
`$validation-harness`; Phase 0.25 plus `search_all_projects=true` directly prevented redundant compute.

Golden Set: the relevant existence-vs-evidence and recall-before-scouting guards fired. The live negative
control was stronger: repository + cluster evidence overruled the handoff without trusting either alone.

## 12. Cross-Product Coverage

Covers: provenance and terminal-state verification for C1, C8 breadth, supplied-K recovery, and
repeatability recovery; exact local/DRAC evidence boundaries; the decision not to rerun.

Does NOT cover: marker Q; C8 2,000-seed confirm; repeatability interval coverage; supplied-K comparator,
R surface, or promotion chain; C1 maintainer ratification; any capability/status/public-count move.
