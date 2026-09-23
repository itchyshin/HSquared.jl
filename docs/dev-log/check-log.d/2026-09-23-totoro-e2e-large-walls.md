## 2026-09-23: Totoro e2e large walls q10k+q20k `[JL]`

### Goal

Totoro re-time of `hsq-animal-fit-q10000` and `hsq-animal-fit-q20000-large`
on post-#379 tip `101aa483`. Projected SelectedInversion stays fenced.

### Commands

```sh
# worktree from origin/main @ 101aa483
# Totoro path: /home/snakagaw/hsq_work/totoro-e2e-large-20260923
taskset -c 0-15 env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  ~/.julia/juliaup/julia-1.10.12+0.x64.linux.gnu/bin/julia --project=. \
  sim/e2e_wall_receipts.jl --large
# Wrote sim/results/e2e_wall_receipts_101aa483.tsv  (2 cells)
```

Host: `totoro` (EPYC). Julia 1.10.12. BLAS threads 1. Cores capped 0-15.

### Results (median-of-3)

| cell | after_s | min_s | conv | iters | nnzA |
|---|---:|---:|:---:|---:|---:|
| hsq-animal-fit-q10000 | 0.034537 | 0.0335 | true | 7 | 46800 |
| hsq-animal-fit-q20000-large | 0.047683 | 0.0472 | true | 4 | 92000 |

Mac #379 absolutes for context only: 0.0312 s / 0.0402 s (not a speedup pair).

### Claim boundary

Not CI. Not a public speed claim. Absolute after only. No projected-selinv
cells. Soft June hist from #379 unchanged.
