## 2026-09-23: speed kinds expand (8 new e2e walls) `[JL]`

### Goal

Add maternal / genomic GREML / FA / repeatability / multi-trait / pedigree-depth
/ reliability / larger-halfsib walls after #378–380. Totoro ≤16 cores. Projected
SelectedInversion stays fenced.

### Commands

```sh
# worktree cursor/speed-kinds-expand-20260923 @ fdc43845
# Totoro path: /home/snakagaw/hsq_work/speed-kinds-expand-20260923
taskset -c 0-15 env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  HSQUARED_GIT_SHA=fdc43845 \
  /home/snakagaw/.juliaup/bin/julia --project=. sim/e2e_wall_receipts.jl --kinds
# Wrote sim/results/e2e_wall_receipts_fdc43845.tsv  (8 cells)
```

Host: `totoro` (EPYC). Julia 1.12.6. BLAS threads 1. Cores capped 0-15.

### Results (median-of-3)

| cell | kind | after_s |
|---|---|---:|
| hsq-maternal-q80 | direct_maternal | 0.0392 |
| hsq-genomic-greml-q200 | genomic_GREML | 0.0565 |
| hsq-repeatability-sparse-q200 | repeatability | 0.0033 |
| hsq-fa-t4k1-q48 | factor_analytic | 0.9104 |
| hsq-multivar-us-t2-q80 | multivariate | 1.7585 |
| hsq-animal-depth3-q500 | pedigree_depth | 0.0108 |
| hsq-reliability-selinv-q2000 | reliability | 0.0041 |
| hsq-halfsib-q5000 | animal_REML_scale | 0.0410 |

### Claim boundary

Not CI. Not a public speed claim. Absolute after only. No projected-selinv cells.
