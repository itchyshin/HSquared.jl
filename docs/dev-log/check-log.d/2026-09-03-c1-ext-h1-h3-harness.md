# 2026-09-03 — C1-ext H1/H3 interval harness scaffold

**Lane:** `cursor/09-h1-h3-harness-20260903`  
**Not a covered flip.** Count stays **7**. Version stays experimental **0.7.0**.  
No 2000-rep confirm. No `point` mapping.

## Commands

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. -e 'using Test; include("test/test_phase1_interval_coverage_ext.jl")'

env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. sim/phase1_interval_coverage_ext.jl --mode=smoke \
  --reps=1 --seed=20260903 --resume=false --out=tmp/c1ext-smoke-all.tsv

env HSQUARED_C1EXT_SMOKE=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. -e 'using Test; include("test/test_phase1_interval_coverage_ext.jl")'
```

## Outcomes (local, 2026-09-03, Julia 1.10.0)

- Thin scaffold test: **29/29 pass**, ~0.3 s.
- Full `--mode=smoke` (all five campaigns, 1 rep): **exit 0**, ~15 s.
  `diag reps=7 interval_success=6`. `GATE PATH_ONLY`.
  `claim_eligible=false` on every summary row.
- Env-gated smoke test (`h1_two,h1_multi`): **5/5 pass**, ~5 s.
- `h3_ram` tiny cell was NON-INTERPRETABLE on the all-campaign seed
  (flat/boundary REML information). Expected at this scale; confirm design
  stays the n=960 maternal gate. Isolated `--campaigns=h3_ram` on seed
  `20260903` did form an interval (path exists).
- 1-rep coverage of 1.000 on tiny H1 cells is a clamp / n=1 artefact, not a
  claim (doc-34 red flag at confirm scale).

`Pkg.test()` / `devtools::check()` / CI were **not** run (thin opt-in test;
not included from `runtests.jl`). Confirm `sbatch` is **not armed**.
