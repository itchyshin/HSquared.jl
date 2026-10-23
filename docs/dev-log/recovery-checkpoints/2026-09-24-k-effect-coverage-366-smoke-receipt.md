# #366 K-effect coverage — Totoro smoke receipt (N=50)

Date: 2026-09-24  
Host choice: **Totoro** (Ada G0; ≤16-core budget; used `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`)  
Ask before heavy: **not yet** — this receipt is smoke only; STOP before N=500/2000 or DRAC.

## Command

```sh
# on Totoro after rsync of worktree → /home/snakagaw/hsq_work/HSquared-coverage-366
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  /home/snakagaw/.juliaup/bin/julia --project=. sim/phase3_k_effect_coverage.jl \
  --mode=smoke --host=Totoro --reps=50 --resume=false \
  --out=docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-smoke-replicates.tsv \
  --summary=docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-smoke-summary.tsv
```

Wrapper: `~/hsq_work/run_k366_smoke.sh` · log: `2026-09-24-k-effect-coverage-366-smoke.log`  
Wall: 2026-09-24T10:58:34 → 10:59:56 MDT (incl. ~40s precompile on Julia 1.12.6).

## Predeclaration / SHA

- Design: `docs/design/58-k-effect-coverage-predeclaration.md`
- Commit: `f046c2283c4eef2165adb0228d74cc7b1b27c009`
- Seeds: `20260924001`…`20260924050` from frozen seed lock
- Route: sparse `fit_multi_effect(:auto)` only · cell: interior `(0.3, 0.2, 0.5)` · design 15/30/200×2

## Smoke table (interior, level 0.95)

| target | n_eval | coverage | MCSE | n_refuse | refusal_rate |
| --- | ---: | ---: | ---: | ---: | ---: |
| Va | 49 | 0.878 | 0.047 | 1 | 0.02 |
| Vpe | 49 | 0.980 | 0.020 | 1 | 0.02 |
| Ve | 49 | 0.959 | 0.028 | 1 | 0.02 |
| h2 | 49 | 1.000 | 0.000 | 1 | 0.02 |
| t | 49 | 0.959 | 0.028 | 1 | 0.02 |

fit_ok=50/50; fit_converged=49/50; se_ok=49/50 (one `fit_not_converged` → refuse).  
Claim class (predeclared): **directional-conservative-bank** — smoke is not claim-grade; Va point estimate under 0.95 with wide MCSE.

## Fences held

- No version bump; `public_covered_count` stays 7; no `partial`→`covered` flip.
- No dense arm; no DRAC / N=500/2000 started.
