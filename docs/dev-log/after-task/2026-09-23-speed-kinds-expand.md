# After-task: 2026-09-23 speed kinds expand (8 new cells)

## Goal

Fill HSquared.jl speed cells toward ~20 diverse kinds after #378–380.
Add 5–8 NEW kinds that actually fit (covered / experimental). Fence
projected SelectedInversion. Measure on Totoro ≤16 cores; no heavy local Julia.

## Outcome

Eight new cells banked on tip `fdc43845` (harness) / receipts SHA pin
`fdc43845`, Totoro, `taskset -c 0-15`, JULIA/OPENBLAS threads = 1.

| cell | kind | after (s) |
|---|---|---:|
| hsq-maternal-q80 | direct_maternal | 0.0392 |
| hsq-genomic-greml-q200 | genomic_GREML | 0.0565 |
| hsq-repeatability-sparse-q200 | repeatability | 0.0033 |
| hsq-fa-t4k1-q48 | factor_analytic | 0.9104 |
| hsq-multivar-us-t2-q80 | multivariate | 1.7585 |
| hsq-animal-depth3-q500 | pedigree_depth | 0.0108 |
| hsq-reliability-selinv-q2000 | reliability | 0.0041 |
| hsq-halfsib-q5000 | animal_REML_scale | 0.0410 |

Evidence: `sim/results/e2e_wall_receipts_fdc43845.tsv` (+ twin under
`docs/dev-log/evidence/2026-09-23-speed-kinds-expand/`).

Harness: `sim/e2e_wall_receipts.jl --kinds`.

Cumulative kinds toward the board (union with #378–380): prior animal_REML /
post_fit_uncertainty / multi_effect / large_pedigree / sparse_selinv(+projected
fence) plus the eight above.

## Not done / skipped

- SelectedInversion wire: STOP (leave projected / fenced from #378).
- ASReml paired cell: skipped (ASReml not installed locally or on Totoro).
- No public README/NEWS speed claim.
- No R twin walls.
- Diversity-plan IDs at exact q=500/2k/10k not retimed; these eight cover the
  empty kinds (maternal, genomic, repeatability, FA, multivar, pedigree depth,
  reliability/PEV, halfsib control) toward the ~20 aim (12 floor + 8 = 20).

## Checks

```sh
taskset -c 0-15 env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  HSQUARED_GIT_SHA=fdc43845 \
  julia --project=. sim/e2e_wall_receipts.jl --kinds
# Wrote sim/results/e2e_wall_receipts_fdc43845.tsv  (8 cells)
```

## Rose

OK to bank absolute Totoro walls for covered/experimental routes. Do not
promote projected selinv. Do not headline a Mac↔Totoro or 1.10↔1.12 ratio.
