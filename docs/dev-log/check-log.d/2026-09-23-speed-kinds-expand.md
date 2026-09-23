# Check-log: 2026-09-23 speed kinds expand

| date | command | outcome |
|---|---|---|
| 2026-09-23 | `lane_preflight` / fresh worktree `HSquared.jl-speed-kinds-20260923` from `origin/main` @ `bb245683` (post-#380) | OK |
| 2026-09-23 | Totoro `taskset -c 0-15` `julia --project=. sim/e2e_wall_receipts.jl --kinds` pin `b00a901a` | Wrote `sim/results/e2e_wall_receipts_b00a901a.tsv` (8 cells); **8/8 conv=true** |
| 2026-09-23 | Predecessor pin `fdc43845` | 8 cells banked; 3 dense `conv=false` — superseded |
| 2026-09-23 | SelectedInversion projected cells | not run (fenced; unwired) |
| 2026-09-23 | ASReml comparator | skipped (unavailable) |
| 2026-09-23 | Local heavy Julia | none |

Julia on Totoro: 1.12.6. Threads: JULIA=1 OPENBLAS=1.
