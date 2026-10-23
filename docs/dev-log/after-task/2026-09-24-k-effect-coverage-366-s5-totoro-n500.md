# After-task: #366 S5 Totoro N=500 triage banked

Date: 2026-09-24  
Lane: `cursor/coverage-366-20260924` @ `~/local-scratch/lanes/HSquared.jl-coverage-366`  
PR: #388 (draft; do not merge)

## What landed

- Totoro N=500 sparse interior coverage run (owner go; `K366_S5_GO=1`)
- Core limits held: `taskset -c 0-3`, `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, serial
- Wall **61 s** (11:31:07 → 11:32:08 MDT); Julia 1.12.6
- Summary TSV + replicates + receipt + check-log entry banked
- Refusal rate **0.022** (11/500 `fit_not_converged`); claim class `directional-conservative-bank`

## Coverage (n_eval=489)

| target | coverage | MCSE |
| --- | ---: | ---: |
| Va | 0.922 | 0.012 |
| Vpe | 0.965 | 0.008 |
| Ve | 0.941 | 0.011 |
| h2 | 0.998 | 0.002 |
| t | 0.965 | 0.008 |

## Fences held

No N=2000 · no DRAC · no merge of #388 · no covered flip · no version bump ·
`public_covered_count` stays 7. Near-boundary cells still owed for full S5 G2.

## STOP

Do not auto-start Totoro N=2000 or any DRAC array from this receipt.
