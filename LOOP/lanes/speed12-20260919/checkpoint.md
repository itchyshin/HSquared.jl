# Checkpoint: speed12-20260919

GOAL: see GOAL.md.
STATE: arc S1 done+repaired (see prior entry, kept below); arc S2 done. All
five automated leaf-S2 gates (G2.1-G2.5) PASS under
`node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --approve --root "$PWD" --cwd "$PWD" --timeout 1800 .unlazy/julia-speed-20260919/gates/leaf-S2.md`
run from the worktree root (cwd = repo root, "$PWD" resolved to
`/Users/z3437171/local-scratch/lanes/HSquared.jl-speed12-20260919`); overall
tool exit=1 because G2.6 (Totoro arm) is the one remaining UNMET gate, by
design ("Manual gate... leave it pending" -- not a failure of anything else).

HEADLINE FINDING: arm (c) (SelectedInversion.jl v0.2.1) is ~280x faster than
the current kernel at the highest-fill Mac fixture (f0adv q=20000, fill~150,
supernodal): T_a=236.9s, T_c=0.833s, S_c=284.4. Far past D-271's >=10x
threshold -- but ONLY at large, high-fill, SUPERNODAL scale. The advantage
inverts at small/simplicial scale (see table).

BUDGET OVERRUN, STATED PLAINLY: the coordinator's own budget probe instruction
caught this -- ONE arm-a pass at f0adv q=20000/fill150 measured at ~237s (not
the "a few seconds" implicitly assumed by the original reps=3/threads={1,4}
grid design). Honouring "whole step under 30 min of compute" required cutting
much further than the coordinator's own fallback (threads=1 + 2 repeats for
q=20000 rungs): the three expensive F0-adversarial high-fill rungs
(q=20000 fill75/150, q=50000 fill75) ran with reps=1, no warm-up, and arm (b)
INFERRED rather than independently re-measured (justified: arm (b)'s own
`refresh_L!` provably falls back to arm (a)'s exact computation when
is_super=true, so T_b=T_a is not a guess there, it is the code path actually
taken); threads=4 was dropped entirely, not just for the expensive rungs.
G2.1/G2.2/G2.5's correctness/precondition checks use small/cheap stand-in
fixtures of the SAME generator/algorithm instead of re-paying the ~237s cost
per check (agreement is a scale-independent property of the math). The
run_grid() invocation itself still took ~23 minutes wall (measured, see
bench/results/); combined with the two budget-probe invocations before it,
this arc's total Julia compute is well over the 30-minute target -- reported
as the finding it is, not hidden. bench/Project.toml's own instantiate+
precompile (~2-6s each run, deps already cached from the package env's own
Pkg.instantiate()) is NOT compute time per the goal's own rule and is
excluded from that estimate.

PER-FIXTURE TABLE (threads=1; full table in
bench/results/selinv_arms_9be11566_t1.tsv):
fixture                        | is_super | T_fact(s) | T_a(s)   | T_b(s)   | T_c(s)  | S_b  | S_c    | R_c    | err_c
f0adv_q20000_fill150           | true     | 0.1788    | 236.894  | 236.894* | 0.8330  | 1.00 | 284.39 | 4.659  | 1.6e-14
f0adv_q20000_fill75            | true     | 0.0177    | 10.600   | 10.600*  | 0.0828  | 1.00 | 128.00 | 4.679  | 4.4e-14
f0adv_q50000_fill75            | true     | 0.1690    | 199.473  | 199.473* | 0.8325  | 1.00 | 239.60 | 4.927  | 1.1e-13
f0adv_q20000_fill150_forced_simplicial | false | 1.9476 | 209.241 | 213.340 | 145.777 | 0.98 | 1.44 | 74.85 | 1.3e-14
boundary_q2000                 | false    | 0.00015   | 0.000176 | 0.000117 | 0.02145 | 1.50 | 0.01   | 141.68 | 1.3e-14
f0scale_q20000 (benign)        | false    | 0.00149   | 0.001935 | 0.001327 | 2.2053  | 1.46 | 0.00087| 1479.0 | 8.0e-14
dense_pin_n50 (supernodal)     | true     | 2.2e-5    | 7.4e-5   | 6.9e-5   | 2.5e-5  | 1.06 | 2.89   | 1.135  | 3.1e-16
dense_pin_n50 (simplicial)     | false    | 1.9e-5    | 7.4e-5   | 6.5e-5   | 1.2e-4  | 1.13 | 0.60   | 6.656  | 4.6e-16
dense_pin_n500 (supernodal)    | true     | 3.8e-4    | 0.03258  | 0.03351  | 0.00151 | 0.97 | 21.61  | 3.986  | 7.0e-15
dense_pin_n500 (simplicial)    | false    | 1.0e-3    | 0.02691  | 0.02823  | 0.03161 | 0.95 | 0.85   | 30.48  | 6.1e-16
(* = arm b INFERRED = arm a, not independently re-measured; see budget note
above and `b_inferred` column in the TSV.)

WHY THE SIGN FLIPS: SelectedInversion's speed comes specifically from its
supernodal-block decode (`SupernodalMatrix`); the "forced_simplicial" row at
the SAME q=20000/fill150 fixture shows S_c collapsing from 284 to 1.44 the
moment is_super is forced false. At small scale (boundary_q2000, dense
pins n<=500) or on a large but BENIGN/simplicial fixture (f0scale_q20000),
arm (c) has fixed overhead that makes it SLOWER than arm (a) -- up to
~1479x slower on the benign q=20000 case. D-271's rule should therefore be
read as scoped to "large, high-fill, supernodal" specifically, not a
package-wide always-win.

ARM (b) FINDING: bitwise-identical to arm (a) on every row measured
(`bitwise_b=true` throughout the TSV). The dependency-free half-step's own
structural-hoist savings (S_b) are real but small (up to ~1.5x) and, per
`refresh_L!`'s own logic, provide NO savings at all for supernodal factors
via public CHOLMOD APIs alone (S_b~1.00 on every supernodal row) -- the
raw-pointer nzval-refresh shortcut only exists for simplicial factors
(confirmed: S_b=1.46-1.50 on the two simplicial/benign rows).

TRUTH LIVES IN:
  - branch claude/lane-speed12-20260919 in this worktree (unpushed), HEAD
    5ac80d48.
  - bench/Project.toml, bench/Manifest.toml (SelectedInversion pinned
    `=0.2.1`; HSquared developed from `..`; package Project.toml/Manifest.toml
    untouched, G2.3 confirms), bench/selinv_arms.jl (the harness, commit
    9be11566 -- its own last-commit sha, used to name the TSV; unaffected by
    later commits that do not touch this file, same lesson as S1's harness).
  - bench/results/selinv_arms_9be11566_t1.tsv (10 rows; renamed from the
    "uncommitted"-named file the ~23-minute run actually produced, after
    committing the harness -- see that commit's message for why re-running
    was not worth it purely to rename the file).
  - ledger .unlazy/julia-speed-20260919/gates/leaf-S2.md (git-ignored; G2.1-
    G2.5 [x] with EVIDENCE keyed to
    cwd=/Users/z3437171/local-scratch/lanes/HSquared.jl-speed12-20260919;
    G2.6 left pending, manual, Totoro).
  - S1's own TRUTH LIVES IN (sim/profile_ai_reml_sections.jl at c8cf8e05,
    sim/results/ai_reml_sections_c8cf8e05.tsv) is unchanged by this arc.

NEXT: the Totoro arm (G2.6) is a STOP gate -- do not launch it without
Shinichi's yes, with this checkpoint's numbers shown (S_c up to 284x at
q=20000/fill150, ~240x at q=50000/fill75; both far past D-271's 10x bar in
the supernodal regime). Per D-271, SelectedInversion.jl can only ever enter
HSquared.jl as an optional weak-dependency extension behind the existing
fallback (never a hard dependency, never in the package Project.toml) --
this arc's numbers are the measured basis for that decision, not a
recommendation to add it yet. Before trusting any future leaf-S2
`--reverify`, use the SAME `--root "$PWD" --cwd "$PWD"` pair (not just
`--cwd`) -- this is what made every G2.x approval reusable across this
arc's separate `--approve` and gate-record invocations.

RESUME: read LOOP/lanes/speed12-20260919/GOAL.md -> this file -> ultra-plan.md
-> repo AGENTS.md; then await Shinichi's decision on the Totoro arm (G2.6).

---
Prior entry (arc S1, kept for continuity):

STATE: arc S1 done, REPAIRED. A coordinator-side verifier found the first
committed TSV held only the halfsib q=1000 rung (`--gate tsv`'s own smoke run
was overwriting the same path the full ladder wrote to). Fixed and
re-verified in a repair loop; all five leaf-S1 gates (G1.1-G1.5) PASS under
both `--approve` and `--reverify` (exit 0 both times) with
cwd=/Users/z3437171/local-scratch/lanes/HSquared.jl-speed12-20260919,
path=.unlazy/julia-speed-20260919/gates/leaf-S1.md. Root cause: `--gate tsv`
and the full ladder shared one output path; fixed to verify-not-overwrite,
name by the harness's own commit (not HEAD), dedupe f0adv target-fill rungs,
and reduce GC/timing noise (GC.gc() before the timed loop; median-of-3 in
gate_prerun). Final state: sim/profile_ai_reml_sections.jl at commit
c8cf8e05; sim/results/ai_reml_sections_c8cf8e05.tsv (6 rungs, 405 rows).
G1.4 ratio ~150-160x (selinv/factor) at the closest achievable fill (150.3)
for target-fill 471 at q=5000 (471 itself is not reachable at that q; the
banked point is q=20,000).
