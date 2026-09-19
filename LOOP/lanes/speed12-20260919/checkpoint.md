# Checkpoint: speed12-20260919

GOAL: see GOAL.md.
STATE: arc S1 done. All five leaf-S1 gates (G1.1-G1.5) PASS via
`node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --approve --timeout 1800 --cwd "$(pwd)" .unlazy/julia-speed-20260919/gates/leaf-S1.md`
(ALL MET, 5/5; run gate-check.mjs with `--cwd` set to the worktree root, not
its default -- it otherwise resolves CHECK lines relative to the gate file's
own directory and every CHECK fails with "No such file or directory").
`sim/profile_ai_reml_sections.jl` committed; no src/ changes.

SECTION-SHARE TABLE (instrumented per-section @timed measurement, method (ii);
top 3 sections by share of total instrumented wall per rung -- this is more
informative than the stdlib Profile.@profile cross-check, method (i), whose
leaf-nearest-known-function attribution puts ~75-80% of samples in "other" at
every rung, most plausibly because thin wrapper calls (`cholesky`, `\`) inline
into their caller and GC/dispatch samples have no named-function match; both
methods are in the TSV, distinguished by its `method` column):
  halfsib q=1000  fill=3.8  : cholmod_factor=88.3% mme_assembly=7.0% selinv=2.1%
  halfsib q=5000  fill=3.8  : cholmod_factor=45.9% mme_assembly=29.8% selinv=11.5%
  halfsib q=20000 fill=3.8  : cholmod_factor=45.8% mme_assembly=29.2% selinv=11.9%
  halfsib q=50000 fill=3.8  : cholmod_factor=47.9% mme_assembly=31.8% selinv=10.8%
  f0adv   q=5000  fill~74   : selinv=99.3% cholmod_factor=0.6% ai_step=0.1%
  f0adv   q=5000  fill~150  : selinv=99.3% cholmod_factor=0.6% ai_step=0.0%

G1.4 RATIO: at q=5000, target-fill 471 is NOT reachable by varying
nfounder_frac (this generator's fill saturates at ~150 once nfounder_frac hits
its floor of 4 founders; the historically banked fill=471 point is at
q=20,000 at the default nfounder_frac=0.005, not obtainable by shrinking
nfounder_frac at fixed q=5000 -- see the file's header comment and
docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md).
Measured at the closest achievable fill (150.3, nfounder_frac=0.0008):
selinv wall 5.72 s / factorization wall 0.037 s = ratio 155.5 (>= 100 -> PASS,
reported honestly as a measured finding, not tuned to hit 471).

TRUTH LIVES IN:
  - branch claude/lane-speed12-20260919 in this worktree (unpushed), commit
    8d41c2ed29096900e934ca19082c9a81bae2dba1 (parent 4c4b6d9b at run time --
    the TSV filename embeds the pre-commit short SHA, which is now one commit
    behind HEAD; this is expected, not a defect).
  - sim/profile_ai_reml_sections.jl (the harness; owns this file and the TSVs
    under sim/results/).
  - sim/results/ai_reml_sections_4c4b6d9b.tsv (full ladder: halfsib
    q=1000/5000/20000/50000, f0adv q=5000 at fill targets 75/150/471 --
    committed).
  - ledger .unlazy/julia-speed-20260919/gates/leaf-S1.md (git-ignored, all
    5 gates [x] with EVIDENCE lines recorded by gate-check.mjs).
  - vault plan copy LOOP/lanes/speed12-20260919/ultra-plan.md.

NEXT: arc S2 (bench/ SelectedInversion.jl arms; see arcs.md). Totoro arm
(q=20000 fill-471) is a STOP gate per GOAL.md and G1.4's number above.

RESUME: read LOOP/lanes/speed12-20260919/GOAL.md -> this file -> ultra-plan.md
-> repo AGENTS.md; then run arc S2.
