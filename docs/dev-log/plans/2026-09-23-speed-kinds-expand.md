# Plan / receipt bank: speed kinds expand (toward 20)

Date: 2026-09-23
Lane: `cursor/speed-kinds-expand-20260923` @ `fdc43845` (+ receipts tip)
Script: `sim/e2e_wall_receipts.jl --kinds`
TSV: `sim/results/e2e_wall_receipts_fdc43845.tsv`
Host: Totoro (EPYC), `taskset -c 0-15`, Julia 1.12.6, BLAS threads 1

## Goal

After #378–380 (12 board/speed12 cells), add 5–8 NEW kinds that actually
fit under covered / experimental rows. Leave projected SelectedInversion fenced.

## New cells (8)

| cell | kind | after (s) | Totoro | status row |
|---|---|---:|:---:|---|
| hsq-maternal-q80 | direct_maternal | 0.0392 | Y | V3 direct–maternal covered experimental |
| hsq-genomic-greml-q200 | genomic_GREML | 0.0565 | Y | V2-GREML covered |
| hsq-repeatability-sparse-q200 | repeatability | 0.0033 | Y | sparse animal+PE (repeatability route) |
| hsq-fa-t4k1-q48 | factor_analytic | 0.9104 | Y | FA t=4 K=1 covered experimental |
| hsq-multivar-us-t2-q80 | multivariate | 1.7585 | Y | unstructured multi-trait covered experimental |
| hsq-animal-depth3-q500 | pedigree_depth | 0.0108 | Y | 3-gen window-mated animal REML |
| hsq-reliability-selinv-q2000 | reliability | 0.0041 | Y | reliability(:selinv) post-fit |
| hsq-halfsib-q5000 | animal_REML_scale | 0.0410 | Y | larger halfsib animal REML |

All `pair = measured_now` (absolute walls). Not public speed claims.

## Honesty fences

- Projected SelectedInversion (`*_projected` in #378 TSV) remains unwired; not
  re-run here.
- Dense maternal / FA / unstructured multi-trait are validation-scale walls,
  not production sparse claims.
- Totoro Julia was 1.12.6 (host default); prior #380 large walls used 1.10.12.
  Absolute walls only — no cross-version speedup column.
- No R twin parallel harness.

## Run

```sh
taskset -c 0-15 env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  HSQUARED_GIT_SHA=fdc43845 \
  julia --project=. sim/e2e_wall_receipts.jl --kinds
```
