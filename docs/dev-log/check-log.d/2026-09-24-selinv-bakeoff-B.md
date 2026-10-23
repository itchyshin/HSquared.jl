# Check-log: B SelectedInversion bake-off CLOSE (KEEP-OURS)

Date: 2026-09-24  
Lane: `cursor:HSquared-selinv-B`  
Tip: `d1eb566b` · kernel `c9eac468` (#363)

## Commands run

```sh
LANE_ID=cursor:HSquared-selinv-B ~/shinichi-brain/tools/lane_preflight.sh \
  "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
# worktree already at tip d1eb566b (cursor/selinv-bakeoff-B-20260924)
rg SelectedInversion Project.toml   # empty
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=bench bench/selinv_arms.jl --gate agree
# → GATE G2b.2 PASS (/tmp/selinv-agree-B.log)
# Wall + identity on fill≈474 cell (Mac Studio, 1 BLAS thread):
# receipt: bench/results/selinv_arms_c9eac468_mac_q20000_fill474_t1.tsv
# S_c_trace=4.59  S_c_diag=5.19  err_c=1.657e-14
```

## Outcomes

| check | result |
| --- | --- |
| Package `Project.toml` clean of SelectedInversion | PASS |
| Identity `err_c` <= 1e-10 | PASS (1.657e-14) |
| `S_c_trace` >= 10 (D-271 weakdeps bar @ 1 BLAS thread) | FAIL (4.59) |
| Verdict | **KEEP-OURS** |
| Production default flipped | NO |
| DRM/GLLVM port / #463 | NOT this lane |

## Deliberately not run

- Totoro `--totoro-arm` (optional; Mac decides KEEP-OURS).
- Any `[weakdeps]` / `ext/` / hard `[deps]`.
- CliqueTrees contingency.
