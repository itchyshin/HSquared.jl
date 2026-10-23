# #366 K-effect coverage: Totoro near-boundary triage receipt (N=500)

Date: 2026-09-24  
Host: **Totoro** (owner authorized triage; NOT 2000; NOT DRAC)  
Cores: `taskset -c 0-3` · `JULIA_NUM_THREADS=1` · `OPENBLAS_NUM_THREADS=1` · serial reps  
Ask before 2000: **still open**. STOP; do not auto-start N=2000 or DRAC.

## Command

```sh
# on Totoro after rsync → /home/snakagaw/hsq_work/HSquared-coverage-366
export K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
export JULIA_BIN=/home/snakagaw/.juliaup/bin/julia
# harness --cell=main_rest expands to low_pe,near_pe,near_va
taskset -c 0-3 env K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 JULIA_BIN="$JULIA_BIN" \
  bash sim/k366_totoro_n500_nearbound.sh
```

Log: `2026-09-24-k-effect-coverage-366-s5-totoro-n500-nearbound.log`  
Wall: 2026-09-24T11:44:10 → 11:46:16 MDT (**126 s**; Julia 1.12.6; 3×500 reps).  
Affinity at launch: `AFFINITY=taskset -c 0-3`; julia pid affinity list `0-3`.

## Predeclaration / cells

- Design: `docs/design/58-k-effect-coverage-predeclaration.md`
- Seeds: `20260924001`…`20260924500` (same frozen lock as interior)
- Route: sparse `fit_multi_effect(:auto)` only · design 15/30/200×2
- Cells this run: `low_pe` `(0.3,0.05,0.65)`, `near_pe` `(0.3,0.01,0.69)`, `near_va` `(0.01,0.3,0.69)`
- Interior already banked separately (`…-s5-totoro-n500-summary.tsv`)

## Coverage + refusal (level 0.95)

| cell | target | n_eval | coverage | MCSE | n_refuse | refusal_rate |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| low_pe | Va | 356 | 0.899 | 0.016 | 144 | 0.288 |
| low_pe | Vpe | 356 | 0.961 | 0.010 | 144 | 0.288 |
| low_pe | Ve | 356 | 0.933 | 0.013 | 144 | 0.288 |
| low_pe | h2 | 356 | 1.000 | 0.000 | 144 | 0.288 |
| low_pe | t | 356 | 0.966 | 0.010 | 144 | 0.288 |
| near_pe | Va | 271 | 0.867 | 0.021 | 229 | 0.458 |
| near_pe | Vpe | 271 | 0.956 | 0.012 | 229 | 0.458 |
| near_pe | Ve | 271 | 0.926 | 0.016 | 229 | 0.458 |
| near_pe | h2 | 271 | 1.000 | 0.000 | 229 | 0.458 |
| near_pe | t | 271 | 0.970 | 0.010 | 229 | 0.458 |
| near_va | Va | 266 | 1.000 | 0.000 | 234 | 0.468 |
| near_va | Vpe | 266 | 0.966 | 0.011 | 234 | 0.468 |
| near_va | Ve | 266 | 0.955 | 0.013 | 234 | 0.468 |
| near_va | h2 | 266 | 0.763 | 0.026 | 234 | 0.468 |
| near_va | t | 266 | 0.970 | 0.010 | 234 | 0.468 |

Claim class (predeclared): **directional-conservative-bank**. Refusal rate is a first-class
endpoint near the boundary (near_pe / near_va ≈ 0.46–0.47). near_va `h2` undercovers when an
interval forms (0.763); document, do not remove SEs. Triage N=500; not a covered flip.

## Fences held

- No version bump; `public_covered_count` stays 7; no `partial`→`covered` flip.
- No dense arm; no DRAC; **no N=2000 started**.
- S5 G2 (near-boundary refusal rates) satisfied by this bank.
