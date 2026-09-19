# Checkpoint: speed12-20260919

GOAL: see GOAL.md.
STATE: arc S1 done, REPAIRED. A coordinator-side verifier found the first
committed TSV held only the halfsib q=1000 rung (`--gate tsv`'s own smoke run
was overwriting the same path the full ladder wrote to). Fixed and
re-verified in this repair loop; see commits below. All five leaf-S1 gates
(G1.1-G1.5) PASS under BOTH
`--approve --timeout 1800 --cwd <worktree root> .unlazy/julia-speed-20260919/gates/leaf-S1.md`
(exit 0) and, immediately after,
`--reverify --timeout 1800 --cwd <worktree root> .unlazy/julia-speed-20260919/gates/leaf-S1.md`
(exit 0, "ALL MET (5 met, reran: 5, previously met reverified: 5)").
EXACT cwd + ledger path used (approvals are bound to this pair -- a
differently-formed path, e.g. no `--cwd`, resolves CHECK lines relative to
the gate file's own directory and every CHECK fails):
  cwd:  /Users/z3437171/local-scratch/lanes/HSquared.jl-speed12-20260919
  path: .unlazy/julia-speed-20260919/gates/leaf-S1.md

WHAT WAS WRONG AND WHAT CHANGED (commits 1fce83a6, 2dc5f8f7, c8cf8e05):
  - `--gate tsv` ran only halfsib q=1000 and wrote it to the SAME path
    `run_ladder()` uses for the full 6-rung deliverable -- any `--gate tsv`
    invocation (including a bare `--reverify`) silently clobbered the ladder
    TSV with a 1-rung stub, and G1.3 still PASSed on structure alone. Fixed:
    `gate_tsv()` now only VERIFIES an existing ladder TSV in place (six
    required rungs, one row per (fixture,q,fill,iteration,section), no
    duplicate keys, per-iteration section-sum within 5% of iteration_total,
    no NaN/Inf); it runs the full ladder only when no TSV exists yet, and
    never overwrites one that is already on disk. Ad-hoc single-rung smoke
    runs now write to a separate `..._smoke.tsv` path instead.
  - The output filename is now keyed to `git log -1 -- <harness file>` (the
    harness's own last commit), not `git rev-parse HEAD` -- HEAD drifts on
    every unrelated commit (e.g. a checkpoint.md update), which is exactly
    what let the wrong filename go unnoticed the first time.
  - Two different `--target-fill` values (150 and 471) resolve to the
    identical achieved fill at q=5000 (see G1.4 note below), so
    `run_ladder()` was running that fixture twice and writing duplicate
    (fixture,q,fill,iteration,section) rows -- a literal G1.3 violation.
    `run_ladder()` now dedupes by achieved fill; the verifier now also
    rejects any duplicate row key outright.
  - A live `--reverify` then exposed two measurement-noise flakes (real
    physical variance, not logic bugs): a 5.6% section-sum mismatch on one
    halfsib q=20000 iteration (plausibly a GC sweep landing inside iteration
    1), and a G1.4 ratio that dipped to 82.3 (< 100) driven by t_factor
    jitter (0.037s vs 0.071s between runs) swamping a ratio whose numerator
    barely moves. Fixed: `instrumented_ai_reml()` now calls `GC.gc()` once
    before its timed loop (same precaution `sim/drac/f0_adversarial_fill.jl`
    already takes); `gate_prerun()` now takes the median of 3 repeated
    factor/selinv timings (same technique `sim/cpu_fit_benchmark.jl` and the
    vault `w4-speed-gen-fit.jl` already use). Neither change alters what is
    measured, only how many samples each estimate draws from.

SECTION-SHARE TABLE (instrumented per-section @timed measurement, method
(ii); top 3 sections by share of total instrumented wall per rung -- more
informative than the stdlib Profile.@profile cross-check, method (i), whose
leaf-nearest-known-function attribution puts ~75-80% of samples in "other" at
every rung, most plausibly because thin wrapper calls (`cholesky`, `\`)
inline into their caller and GC/dispatch samples have no named-function
match; both methods are in the TSV, distinguished by its `method` column):
  halfsib q=1000  fill=3.8  : cholmod_factor~9-10% mme_assembly~6-9% (other dominates, small-q dispatch overhead)
  halfsib q=5000  fill=3.8  : cholmod_factor~46%   mme_assembly~30%  selinv~11%
  halfsib q=20000 fill=3.8  : cholmod_factor~46%   mme_assembly~29%  selinv~12%
  halfsib q=50000 fill=3.8  : cholmod_factor~48%   mme_assembly~32%  selinv~11%
  f0adv   q=5000  fill~74   : selinv~99%           cholmod_factor~0.6%
  f0adv   q=5000  fill~150  : selinv~99%           cholmod_factor~0.6%
(exact per-run percentages vary by a point or two run-to-run; ranges above
span the values observed across this repair's several regenerations.)

G1.4 RATIO: at q=5000, target-fill 471 is NOT reachable by varying
nfounder_frac (this generator's fill saturates at ~150 once nfounder_frac
hits its floor of 4 founders; the historically banked fill=471 point is at
q=20,000 at the default nfounder_frac=0.005 -- see the file's header comment
and docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md).
Measured at the closest achievable fill (150.3, nfounder_frac=0.0008), median
of 3 repeated timings: selinv wall ~5.5-5.8 s / factorization wall ~0.036 s =
ratio ~150-160 (>= 100 -> PASS across every re-run in this repair loop,
including the final --reverify's 151.3).

TRUTH LIVES IN:
  - branch claude/lane-speed12-20260919 in this worktree (unpushed), HEAD
    2c466ae4 (harness fixed at c8cf8e05; the TSV filename is keyed to that
    commit, not to whatever HEAD happens to be later).
  - sim/profile_ai_reml_sections.jl (the harness).
  - sim/results/ai_reml_sections_c8cf8e05.tsv (the current, verified,
    6-rung, 405-row ladder TSV -- CURRENT banked file; two earlier,
    incorrectly-named/incomplete/duplicated attempts
    (ai_reml_sections_4c4b6d9b.tsv, ai_reml_sections_2dc5f8f7.tsv) were
    generated and removed during this repair; do not resurrect them).
  - ledger .unlazy/julia-speed-20260919/gates/leaf-S1.md (git-ignored, all
    5 gates [x] with EVIDENCE keyed to
    cwd=/Users/z3437171/local-scratch/lanes/HSquared.jl-speed12-20260919).
  - vault plan copy LOOP/lanes/speed12-20260919/ultra-plan.md.

NEXT: arc S2 (bench/ SelectedInversion.jl arms; see arcs.md). Totoro arm
(q=20000 fill-471) is a STOP gate per GOAL.md and G1.4's number above. Before
trusting any future leaf-S2 gate-check run, always pass the SAME
`--cwd <worktree root>` explicitly -- the tool's own default CHECK directory
is the gate file's directory, not the process's shell cwd, and a mismatched
cwd produces an unrelated approval that a later `--reverify` cannot reuse
(exactly the G1.5 issue hit and fixed in this repair loop).

RESUME: read LOOP/lanes/speed12-20260919/GOAL.md -> this file -> ultra-plan.md
-> repo AGENTS.md; then run arc S2.
