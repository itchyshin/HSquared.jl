# 2026-09-03 — 0.8 S1 FA diagnose scaffold + single-step S0 probe

**Lane:** `cursor/08-fa-20260903`  
**Not a covered flip.** `V4-FA` and `V2-SSHINV` stay partial. Count stays **7**.  
Version stays experimental **0.7.0**.

## Commands

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. sim/v08_fa_s1_diagnose.jl --mode=truth-only --cell=d3-contrast
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. sim/v08_ss_s0_construction_probe.jl
```

## Outcomes (local, 2026-09-03, Julia 1.10.0, host `w-kw3k3y6229`)

- truth-only d3-contrast: **exit 0**. Finite truth logliks:
  `20260616` −813.65620851; `20260619` −800.61218180; `20260614` −789.31033632.
  `ledermann_slack=0`. No fit claimed.
- SS construction probe: **exit 0**. `G=A22` reduction `max|Hinv−Ainv|=0`;
  `G=A22+0.05I` shift `1.051e-01`.

`--mode=fit` is Totoro-first and is **not** claimed from this check-log entry
until a run log exists. WOMBAT: not on laptop PATH; not on Totoro PATH.
