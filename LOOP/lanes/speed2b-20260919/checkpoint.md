# S2b checkpoint (2026-09-19)

## STATE

DONE. All 4 auto-checkable gates (G2b.1, G2b.2, G2b.3, G2b.5) PASS via
`gate-check.mjs --approve`. G2b.4 is the ledger's manual gate (no CHECK
line) -- the numbers below are handed to the orchestrator to record it.

Worktree: `<lane worktree>`
Branch: `claude/lane-speed2b-20260919` (based on `origin/main` b9f30a64)
Commits (newest first): 6e7e814d (measurements), d6a55667 (header-line fix),
b1a18896 (GIT_SHAS.txt), ff019def (git-shas cache mechanism), 49d63c49
(threads/install-weight fixes), e21857b6 (harness rewrite).
Not pushed, not merged. `src/` untouched throughout (`git diff --name-only
b9f30a64 -- src/` is empty).

## PER-FIXTURE TABLE (threads=1, Mac unless noted)

| fixture | achieved fill | is_super | T_fact | T_a_trace | T_a_diag | T_c_trace | T_c_diag | S_c_trace | S_c_diag | R_c_trace | err_c |
|---|---|---|---|---|---|---|---|---|---|---|---|
| f0adv_q20000_fill150 | 213.653 | true | 0.172 | 74.586 | 73.469 | 0.4574 | 0.4131 | 163.06 | 177.84 | 2.660 | 1.644e-14 |
| f0adv_q20000_fill150_forced_simplicial | 179.085 | false | 2.046 | 61.829 | 62.886 | 75.554 | 71.856 | 0.82 | 0.88 | 36.93 | 1.328e-14 |
| f0adv_q20000_fill75 | 44.058 | true | 0.019 | 0.6384 | 0.6167 | 0.04530 | 0.04469 | 14.09 | 13.80 | 2.377 | 4.445e-14 |
| f0adv_q50000_fill75 | 83.347 | true | 0.177 | 54.160 | 51.183 | 0.4040 | 0.3954 | 134.06 | 129.45 | 2.276 | 1.139e-13 |
| f0scale_q20000 | 3.880 | false | 0.001 | 0.00084 | 0.00075 | 2.186 | 0.00413 | 0.00 | 0.18 | 1483.5 | 7.975e-14 |
| boundary_q2000 | 3.879 | false | 0.000151 | 0.000096 | 0.000092 | 0.02126 | 0.000329 | 0.00 | 0.28 | 140.35 | 1.281e-14 |
| dense_pin_n50 (supernodal) | 13.745 | true | 0.000022 | 0.000029 | 0.000014 | 0.000015 | 0.000013 | 1.98 | 1.12 | 0.669 | 3.062e-16 |
| dense_pin_n500 (simplicial) | 61.172 | false | 0.001056 | 0.003280 | 0.003093 | 0.020241 | 0.014530 | 0.16 | 0.21 | 19.16 | 6.144e-16 |
| **Totoro** f0adv_q20000_fill474 | 473.937 | true | 0.758 | **547.44** | 558.80 | 1.906 | 1.909 | **287.29** | 292.65 | 2.515 | 1.671e-14 |

(Full 10-row Mac table: `bench/results/selinv_arms_d6a55667_t1.tsv`; dense_pin_n50
simplicial and dense_pin_n500 supernodal omitted above for space, both clean:
err_c 4.593e-16 and 7.004e-15 respectively.)

## BIT-IDENTITY vs OLD KERNEL

Raw trace/diag values are not stored in either TSV (only aggregate stats),
so the check is indirect: `err_c` (arm c vs arm a) is a deterministic
function of arm a's trace/diag given arm c unchanged. Compared
`bench/results/selinv_arms_9be11566_t1.tsv` (OLD kernel) against
`selinv_arms_d6a55667_t1.tsv` (NEW kernel) fixture-by-fixture: **err_c
matches to the printed precision on all 10/10 rows** (e.g. fill150:
1.644e-14 both; fill75: 4.445e-14 both; q50000fill75: 1.139e-13 both;
forced_simplicial: 1.328e-14 both; dense pins: 3.062e-16/4.593e-16/
7.004e-15/6.144e-16 all match). Strong corroboration of Szymek's
bit-identical claim; not a literal byte-diff of trace/diag arrays.

## SPEEDUP FINDING (unplanned, load-bearing for D-271 context)

The new kernel's speedup over the old one is **fixture/fill-dependent, and
much smaller than the file-header's 6.65x-9.97x claim** at the two highest-
fill points measured: at Mac fill213.7, combined a_trace+a_diag went
236.9s (old) -> 148.1s (new) = **1.65x**. At Totoro fill473.9 (the D-271
banked point), combined went ~1219s (old, median of reps) -> ~1106s
(new) = **~1.10x**. AGENT-INFERRED explanation (not verified against
Szymek's own benchmarks): the dense-clique optimization's benefit likely
shrinks as clique width grows relative to `DEFAULT_SELINV_BLOCK_CAP=2000`
or as per-pair-lookup cost is already amortized at extreme fill. This does
NOT change the D-271 verdict here (SelectedInversion remains ~287x faster
than our kernel regardless), but matters if Szymek's claim is cited
elsewhere as a blanket number.

## D-271 VERDICT

```
S_c_trace (Totoro, fill474) = 287.29   threshold >= 10   PASS
err_c (max, Mac grid + Totoro) = 1.139e-13   threshold <= 1e-10   PASS
packages_added = 1 (SelectedInversion)   threshold <= 2   PASS
new_jll = 0   threshold == 0   PASS
G_fit (AGENT-INFERRED, Amdahl, share=0.993) = 95.63   threshold >= 2   PASS
```
**tier = "optional extension"** (printed by `--gate verdict`, never typed by hand).

## INSTALL WEIGHT (G2b.3, measured on a COPY of the PACKAGE env, not bench/)

`packages_added=1 (SelectedInversion)`, `new_jll=0`, `precompile_seconds=0.62`.
PrecompileTools (SelectedInversion's only non-stdlib dep) was already pulled
in transitively via Optim's own tree -- corrects the S9-flagged
Manifest-vs-Project error from S2 (bench Manifest shows "55 added" because
it resolves Optim's ~57 transitive deps; that is NOT the package-env
install weight).

## GATES

G2b.1 PASS, G2b.2 PASS, G2b.3 PASS, G2b.5 PASS (all via
`gate-check.mjs --approve`, evidence written into
`.unlazy/julia-speed-20260919/gates/leaf-S2b.md`). G2b.4 PENDING (manual;
orchestrator fills from the Totoro numbers above).

## TOTORO WALL

Launched 12:45 MDT via `~/hsq_work/speed2b-20260919/run_totoro_arm.sh`
(ControlMaster socket, nohup, pidfile), attached via
`~/hsq_work/speed2b-20260919/check_totoro_arm.sh` polled every 60s.
Finished 13:43 MDT: **~58 minutes wall**, under the 60-minute kill ceiling
but close to it -- almost entirely a_trace+a_diag (each ~550s x 3 calls =
warm-up + 2 timed reps). Within Shinichi's 09:36 approval of the Totoro arm.

## TRUTH LIVES IN

- `bench/selinv_arms.jl` (rewritten harness, commit 6e7e814d and its parents)
- `bench/results/selinv_arms_d6a55667_t1.tsv` (Mac grid, threads=1)
- `bench/results/selinv_arms_ff019def_totoro_q20000_fill474.tsv` (Totoro)
- `bench/results/install_weight_b9f30a64.txt` (install weight)
- `.unlazy/julia-speed-20260919/gates/leaf-S2b.md` (gate evidence)
- `bench/results/selinv_arms_9be11566_t1.tsv`, `selinv_arms_b68bde5a_totoro_q20000_fill471.tsv` (old-kernel comparison copies, carried over from speed12)

## NEXT

- Orchestrator: fill G2b.4 (manual) from the Totoro numbers above.
- Orchestrator/Shinichi: close #353 per D-271's "optional extension" tier,
  or route to whoever owns turning this into an actual weak-dependency
  extension PR (out of scope for this leaf -- measurement only, no src/
  or Project.toml edit was made here).
- Consider flagging the smaller-than-claimed speedup-at-high-fill finding
  back to Szymek/S9 if the 6.65x-9.97x figure is being relied on elsewhere
  as a general claim rather than fixture-specific.
- threads=4 was not run (the threads=1 grid's two reduced-reps fixtures
  alone made the full grid long enough that doubling it risked the 30-min-
  campaign guidance without a fresh estimate/approval); can be added later
  if wanted.
