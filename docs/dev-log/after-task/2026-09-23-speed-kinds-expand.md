# After-task: 2026-09-23 speed kinds expand (8 new cells)

## Goal

Fill HSquared.jl speed cells toward ~20 diverse kinds after #378–380.
Add 5–8 NEW kinds that actually fit (covered / experimental). Fence
projected SelectedInversion. Measure on Totoro ≤16 cores; no heavy local Julia.

## Outcome

Eight new cells banked on tip `b00a901a`, Totoro, `taskset -c 0-15`,
JULIA/OPENBLAS threads = 1. **All eight report `conv=true`.**

| cell | kind | after (s) | conv |
|---|---|---:|:---:|
| hsq-maternal-q110 | direct_maternal | 0.2111 | Y |
| hsq-genomic-greml-q200 | genomic_GREML | 0.0435 | Y |
| hsq-repeatability-sparse-q200 | repeatability | 0.0027 | Y |
| hsq-fa-t2k1-q32 | factor_analytic | 0.4605 | Y |
| hsq-multivar-us-t2-q80 | multivariate | 3.5260 | Y |
| hsq-animal-depth3-q500 | pedigree_depth | 0.0127 | Y |
| hsq-reliability-selinv-q2000 | reliability | 0.0039 | Y |
| hsq-halfsib-q5000 | animal_REML_scale | 0.0311 | Y |

Evidence: `sim/results/e2e_wall_receipts_b00a901a.tsv` (+ twin under
`docs/dev-log/evidence/2026-09-23-speed-kinds-expand/`).

Harness: `sim/e2e_wall_receipts.jl --kinds`.

Predecessor wave `fdc43845` banked absolute walls with three dense cells at
`conv=false` (iteration caps). Superseded by this tip: maternal 2k iters +
DGP initials; FA replaced t=4 (iteration-limit) with converging t=2 K=1.

Cumulative kinds toward the board (union with #378–380): prior animal_REML /
post_fit_uncertainty / multi_effect / large_pedigree / sparse_selinv(+projected
fence) plus the eight above → **~20 attested kinds**.

## Not done / skipped

- SelectedInversion wire: STOP (leave projected / fenced from #378).
- ASReml paired cell: skipped (ASReml not installed locally or on Totoro).
- FA t=4 covered-flip geometry: not banked as a wall (Nelder–Mead hit 2000-iter
  limit on gene-drop); FA kind attested via t=2 K=1.
- No public README/NEWS speed claim.
- No R twin walls.

## Checks

```sh
taskset -c 0-15 env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  HSQUARED_GIT_SHA=b00a901a \
  julia --project=. sim/e2e_wall_receipts.jl --kinds
# Wrote sim/results/e2e_wall_receipts_b00a901a.tsv  (8 cells)
```

## Rose

OK to bank absolute Totoro walls for covered/experimental routes that
converged. Do not promote projected selinv. Do not headline a Mac↔Totoro or
1.10↔1.12 ratio.
