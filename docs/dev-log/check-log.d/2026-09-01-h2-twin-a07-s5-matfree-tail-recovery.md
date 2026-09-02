# check-log — 2026-09-01 h2-twin A07 S5 matfree tail recovery

**Arc:** A07 (B2)  
**Lane:** `claude/lane-h2-twin-20260901` @ `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`  
**Goal:** Frozen S5 gate at q=25,000 on Totoro (owner-approved 2026-09-01)

## Commands

```sh
# Port verification (local worktree)
git log --oneline -3
# a0ffb86a chore(H2): port frozen S5 ...
# f261165e fix(H2): port fit_matrix_free_reml ...

# Totoro (ControlMaster ssh totoro; julia 1.10.10)
export PATH=~/hsq_work/julia-1.10.10/bin:$PATH
export OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1
cd ~/hsq_work/h2-a07-s5-20260901
julia --project=. sim/phase_s5_matfree_tail_recovery_gate.jl a07_s5_recovery.tsv
# exit 0; OVERALL GATE: PASS
```

## Results

| Check | Outcome |
|-------|---------|
| Port `a0ffb86a` | S5 script + predeclaration on campaign branch |
| Engine `f261165e` | `fit_matrix_free_reml` reachable (required for gate) |
| A3_MAX_CAP_EXHAUSTED | 4 (matches A08 decision) |
| Leg A A3 | 0/48 cap-exhausted (≤ 4/48) PASS |
| Overall gate | PASS (Leg A + Leg X) |
| Wall time | ~44m 39s (2026-09-01T17:42:28 → 18:27:07 -06:00) |
| Receipt | `~/local-scratch/h2-a07-s5-receipt.md` |

## Claim boundary

- Validation evidence only; no capability promotion; no push from this slice.
