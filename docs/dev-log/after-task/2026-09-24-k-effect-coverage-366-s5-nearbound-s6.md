# After-task: #366 S5 near-boundary Totoro N=500 banked (+ S6 claim-class note)

Date: 2026-09-24  
Lane: `cursor/coverage-366-20260924` @ `~/local-scratch/lanes/HSquared.jl-coverage-366`  
PR: #388 (draft; do not merge)

## What landed

- Totoro N=500 sparse **main_rest** coverage run (`low_pe`, `near_pe`, `near_va`)
- Harness multi-cell `--cell` aliases: `near_boundary`, `main_rest`, `main` (comma lists allowed)
- Launcher: `sim/k366_totoro_n500_nearbound.sh`
- Core limits held: `taskset -c 0-3`, `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, serial
- Wall **126 s** (11:44:10 → 11:46:16 MDT); Julia 1.12.6
- Summary TSV + replicates + receipt + check-log + combined table banked
- Claim class `directional-conservative-bank`; `public_covered_count` stays **7**

## Near-boundary refusal rates (S5 G2)

| cell | refusal_rate | note |
| --- | ---: | --- |
| near_pe | 0.458 | expect refusals (predeclaration) |
| near_va | 0.468 | expect refusals; h2 coverage 0.763 when formed |
| low_pe | 0.288 | main cell; elevated vs interior 0.022 |

## Combined coverage snapshot (t / Va)

| cell | t cov (MCSE) | Va cov (MCSE) | refuse |
| --- | ---: | ---: | ---: |
| interior | 0.965 (0.008) | 0.922 (0.012) | 0.022 |
| low_pe | 0.966 (0.010) | 0.899 (0.016) | 0.288 |
| near_pe | 0.970 (0.010) | 0.867 (0.021) | 0.458 |
| near_va | 0.970 (0.010) | 1.000 (0.000) | 0.468 |

## S6 (docs / board; no flip)

- Capability-status K-effect row: still **experimental**; text now points at banked
  #366 triage + directional-conservative claim class (NOT nominal calibration).
- No status flip · no version bump · count stays 7.
- Rose perspective: CLEAN for claim fence. Study banks evidence only; no covered claim.

## Fences held

No N=2000 · no DRAC · no merge of #388 · no covered flip · no version bump ·
`public_covered_count` stays 7.

## STOP

Do not auto-start Totoro N=2000 or any DRAC array from this receipt.
GOAL can complete as a **banked study** without a covered flip.
