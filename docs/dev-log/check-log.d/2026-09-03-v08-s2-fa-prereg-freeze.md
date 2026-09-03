# 2026-09-03 — 0.8 S2 FA recovery-gate FROZEN (not run)

**Not a covered flip.** `V4-FA` stays partial. Count stays **7**. Experimental **0.7.0**.

## What froze

- Decision: `docs/dev-log/decisions/2026-09-03-v08-s2-fa-recovery-gate-prereg.md`
- Driver: `sim/v08_fa_s2_prereg.jl`
- SHA-256: `47a1b619e83b468cec28dae57918f755064a32528f16bf775943b8b7e36b4b83`
- git blob: `370cf69773a52dc7e158a9415d389e31ddf7a8e7`
- **Freeze commit: `eff57e3d`**
- Gate DGP: `t=4 K=1`, `ledermann_slack=4`
- Pass adds `min(ψ̂) ≥ 1e-4` and `slack > 0` on top of banked G/R cuts
- S4 seed list `20260914:20260923` predeclared, **not executed**

S1 remains the classify record (`80e91d75` panel, `5f07d026` contrast). This
slice does not re-run those cells and does not launch S3/S4 `--mode=fit`.

## Wiring smoke (laptop, truth-only, one seed)

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. sim/v08_fa_s2_prereg.jl \
  --mode=truth-only --cell=d4-k1 --seeds=20260914
```

**exit 0** in ~7 s (julia 1.10.0, host `w-kw3k3y6229`). `t=4 K=1`
`ledermann_slack=4`; `loglik_truth=-1029.61156914`; class `truth_only`.
No fit. No campaign.
