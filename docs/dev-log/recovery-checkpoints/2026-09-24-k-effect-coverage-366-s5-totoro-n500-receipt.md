# #366 K-effect coverage: Totoro triage receipt (N=500)

Date: 2026-09-24  
Host: **Totoro** (owner authorized triage; NOT 2000; NOT DRAC)  
Cores: `taskset -c 0-3` · `JULIA_NUM_THREADS=1` · `OPENBLAS_NUM_THREADS=1` · serial reps  
Ask before 2000: **still open**. STOP; do not auto-start N=2000 or DRAC.

## Command

```sh
# on Totoro after rsync → /home/snakagaw/hsq_work/HSquared-coverage-366
export K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
export JULIA_BIN=/home/snakagaw/.juliaup/bin/julia
taskset -c 0-3 env K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  OMP_NUM_THREADS=1 JULIA_BIN="$JULIA_BIN" bash sim/k366_totoro_n500.sh
```

Log: `2026-09-24-k-effect-coverage-366-s5-totoro-n500.log`  
Wall: 2026-09-24T11:31:07 → 11:32:08 MDT (**61 s**; Julia 1.12.6; first-rep JIT ~12 s).  
Affinity confirmed at launch: julia pid affinity list `0-3`.

## Predeclaration / SHA

- Design: `docs/design/58-k-effect-coverage-predeclaration.md`
- Branch tip at launch: `e340ac25` (S5 launch menu); banking commit follows this receipt
- Seeds: `20260924001`…`20260924500` from frozen seed lock
- Route: sparse `fit_multi_effect(:auto)` only · cell: interior `(0.3, 0.2, 0.5)` · design 15/30/200×2

## Coverage table (interior, level 0.95)

| target | n_eval | coverage | MCSE | n_refuse | refusal_rate |
| --- | ---: | ---: | ---: | ---: | ---: |
| Va | 489 | 0.922 | 0.012 | 11 | 0.022 |
| Vpe | 489 | 0.965 | 0.008 | 11 | 0.022 |
| Ve | 489 | 0.941 | 0.011 | 11 | 0.022 |
| h2 | 489 | 0.998 | 0.002 | 11 | 0.022 |
| t | 489 | 0.965 | 0.008 | 11 | 0.022 |

fit_ok=500/500; fit_converged=489/500; se_ok=489/500 (11 `fit_not_converged` → refuse).  
Claim class (predeclared): **directional-conservative-bank**. Triage N=500; not a covered flip; Va remains the softest point (~0.922) with usable MCSE.

## Fences held

- No version bump; `public_covered_count` stays 7; no `partial`→`covered` flip.
- No dense arm; no DRAC; **no N=2000 started**.
- Near-boundary cells not run in this triage (interior only).
