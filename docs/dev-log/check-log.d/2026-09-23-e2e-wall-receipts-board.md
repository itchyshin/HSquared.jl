## 2026-09-23: e2e wall receipts for board H² `needs_run` `[JL]`

### Goal

≥5 e2e fit / post-fit walls on post-#371 tip `e05fcf0e` matching board cell_ids
`hsq-animal-fit-q500|q2000|q10000`, `hsq-pev-reliability-q500`, plus multi-effect
and large-pedigree diversity cells.

### Commands

```sh
export LANE_ID='cursor:HSquared.jl-speed12:e2e-1790164253'
~/shinichi-brain/tools/lane_lease.sh --claim HSquared.jl \
  --paths 'sim/,bench/,docs/dev-log/,LOOP/' --ttl 6 \
  --note 'e2e wall receipts post-#371 board needs_run'
# GRANTED

env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  ~/.juliaup/bin/julia --project=. sim/e2e_wall_receipts.jl --core
# Wrote sim/results/e2e_wall_receipts_e05fcf0e.tsv  (6 cells)
```

Host: `w-kw3k3y6229.psych.ualberta.ca` (Mac; Totoro flag N).
Julia 1.10.0; BLAS.set_num_threads(1).

### Results (median-of-3 unless noted)

| cell | after_s | note |
|---|---:|---|
| hsq-animal-fit-q500 | 0.004912 | gene-drop; conv; 8 iters |
| hsq-animal-fit-q2000 | 0.009821 | gene-drop; conv; 9 iters |
| hsq-pev-reliability-q500 | 0.000311 | selinv; dense before = banked 0.0125s |
| hsq-multi-effect-K2-q500 | 0.003635 | sparse AI; dense NelderMead 2.55s (1 timed) |
| hsq-animal-fit-q10000 | 0.031218 | gene-drop; conv; 7 iters |
| hsq-animal-fit-q20000-large | 0.040177 | gene-drop; conv; 4 iters |

### Claim boundary

Not CI. Not a public speed claim. June hist walls are different DGP (soft
context). Live dense PEV skipped (OpenBLAS hang). Board file flip owed outside
this repo (no GLLVM edit).
