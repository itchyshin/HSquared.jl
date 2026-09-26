# After-task: #366 N=2000 Rose claim-vs-evidence (no flip)

Date: 2026-09-26  
Lane: `cursor/366-n2000-rose-20260926` @
`~/local-scratch/lanes/HSquared.jl-coverage-366-n2000`  
Bank PR: #396 merged `be25772a` (tip `0b73aeed`)  
Issue: #366

## Verdict

HOLD. Totoro and DRAC N=2000 repeat the N=500 map. Interior Va stays
the soft interior cell (Totoro 0.903, DRAC 0.915, N=500 0.922).
Near_va h2 stays collapsed when formed (0.762 / 0.774 / 0.763).
Near-boundary refuse stays first-class (near_pe 0.446 / 0.450 / 0.458;
near_va 0.464 / 0.446 / 0.468). Host pair agrees on the same soft
spots. Julia 1.12.6 vs 1.10.10 is not bit-identical and does not
change the claim class. N=2000 did not put interior Va on 0.95.

Claim class stays directional-conservative-bank. No covered flip.
`public_covered_count` stays 7. Version stays 0.9.0.

## Pair vs N=500

| cell / target | N=500 Totoro | N=2000 Totoro | N=2000 DRAC |
| --- | ---: | ---: | ---: |
| interior Va | 0.922 | 0.903 | 0.915 |
| interior t | 0.965 | 0.954 | 0.955 |
| interior refuse | 0.022 | 0.0345 | 0.036 |
| near_va h2 | 0.763 | 0.762 | 0.774 |
| near_pe refuse | 0.458 | 0.446 | 0.450 |

Sources: combined TSVs under
`docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n500-combined-summary.tsv`,
`…-s5-totoro-n2000-combined-summary.tsv`,
`…-s5-drac-n2000-combined-summary.tsv`.

## Fences held

No capability-status edit. No `Project.toml` edit. No validation-debt
flip. Local-scratch worktree only.

## STOP

Do not flip `V1-HERIT-CI` or the K-effect row from this read.
