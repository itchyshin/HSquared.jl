# After-task: #366 S5 Totoro N=2000 banked

Date: 2026-09-25 evening (America/Denver)  
Lane: `cursor/366-n2000-drac-20260926` @
`~/local-scratch/lanes/HSquared.jl-coverage-366-n2000`  
Issue: #366

## What landed

- Totoro N=2000 sparse coverage for the same four cells the N=500 bank
  already covered: interior plus `main_rest`
  (`low_pe`, `near_pe`, `near_va`)
- Safety gate `K366_S5_GO=1`; Julia 1.12.6; serial; OPENBLAS=1
- Wall after instantiate: interior 22 s; main_rest 62 s
- Combined TSV, replicates, logs, and a receipt under
  `docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-totoro-n2000*`
- DRAC Narval jobs 4003782 / 4003783 completed the same evening on
  `~/projects/def-snakagaw/HSquared.jl-coverage-366-n2000` (interior
  41 s, main_rest 1:49). Receipts
  `2026-09-26-k-effect-coverage-366-s5-drac-n2000*`

## Coverage (claim class directional-conservative-bank)

Interior n_eval=1931, refuse 0.0345: Va 0.903, Vpe 0.968, Ve 0.940,
h2 0.998, t 0.954. Near_pe refuse 0.446; near_va refuse 0.464;
near_va h2 0.762 when formed. Direction matches the N=500 precursor.
DRAC interior Va 0.915; near_va h2 0.774. Same soft spots.

## Fences held

No covered flip. No version bump. `public_covered_count` stays 7.
Experimental 0.9.0. Not nominal calibration. Local-scratch worktree
only. Campaigns on Totoro / DRAC only.

## STOP

Do not flip V1-HERIT-CI or the K-effect capability row. Do not start
0.10 / FA/SS public work from this receipt.
