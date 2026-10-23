# #366 K-effect coverage: DRAC N=2000 bank receipt

Date: 2026-09-25 evening (America/Denver; filenames 2026-09-26)  
Host: **Narval** (DRAC), account `def-snakagaw_cpu`  
Jobs: 4003782 interior COMPLETED 41 s (exit 0); 4003783 main_rest
COMPLETED 1:49 (exit 0). Dedicated checkout
`~/projects/def-snakagaw/HSquared.jl-coverage-366-n2000`.  
Julia: module `julia/1.10.10` (cluster default). Same harness and
frozen seeds as the Totoro bank.

Totoro N=2000 is already banked
(`…-s5-totoro-n2000-receipt.md`). This receipt is the owner-requested
DRAC provenance copy. Direction agrees. Absolute coverages are not
bit-identical across Julia 1.12.6 (Totoro) and 1.10.10 (Narval).

## Coverage table (level 0.95)

| cell | target | n_eval | coverage | MCSE | n_refuse | refusal_rate |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| interior | Va | 1928 | 0.915 | 0.006 | 72 | 0.0360 |
| interior | Vpe | 1928 | 0.977 | 0.003 | 72 | 0.0360 |
| interior | Ve | 1928 | 0.947 | 0.005 | 72 | 0.0360 |
| interior | h2 | 1928 | 0.999 | 0.001 | 72 | 0.0360 |
| interior | t | 1928 | 0.955 | 0.005 | 72 | 0.0360 |
| low_pe | Va | 1398 | 0.882 | 0.009 | 602 | 0.3010 |
| low_pe | t | 1398 | 0.964 | 0.005 | 602 | 0.3010 |
| near_pe | Va | 1101 | 0.844 | 0.011 | 899 | 0.4495 |
| near_va | h2 | 1108 | 0.774 | 0.013 | 892 | 0.4460 |
| near_va | t | 1108 | 0.959 | 0.006 | 892 | 0.4460 |

Full rows: `…-s5-drac-n2000-combined-summary.tsv`. Claim class:
**directional-conservative-bank**. Not nominal.

Versus Totoro (same seeds, same cells): interior Va 0.903 vs 0.915;
near_pe refuse 0.446 vs 0.450; near_va h2 0.762 vs 0.774. Same
soft spots.

## Fences held

No covered flip. No version bump. Count stays 7. Experimental 0.9.0.
