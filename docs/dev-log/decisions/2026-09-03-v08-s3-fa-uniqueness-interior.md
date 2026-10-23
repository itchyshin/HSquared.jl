# 2026-09-03 — 0.8 S3 FA uniqueness-interior bound (engine change)

**Status: LANDED · NOT a covered flip · S2 DGP untouched.**  
Lane: `cursor/08-fa-20260903` (WT `~/local-scratch/lanes/HSquared.jl-08-fa-20260903`).  
S2 remains FROZEN at `eff57e3d` / PR head was `45bb3219` before this slice.

`public_covered_count` stays **7**. `V4-FA` stays **partial / experimental**.
No 0.8.0. No 1.0 / CRAN. Rose CLEAN is **not** written.

## What S3 is

A fitter change, not a campaign and not an EM warm-start:

1. Fitted uniqueness is parameterized as
   `ψ_i = FA_UNIQUENESS_FLOOR + exp(θ_i)` with `FA_UNIQUENESS_FLOOR = 1e-4`,
   so `min(ψ̂) ≥ 1e-4` by construction.
2. Ledermann-saturated cells (`ledermann_slack(t, K) ≤ 0`) remain *fittable*
   for diagnosis. `fa_covered_flip_cell` is false and
   `require_fa_covered_flip_cell` throws — the honest refuse path for a
   covered-flip cell. S1 `t=3 K=1` (slack 0) is that disclosure cell.

`factor_analytic_covariance` still accepts any positive Ψ (truth DGPs).
The bound is on the *fitted* FA path only.

## Explicit non-changes

- `sim/v08_fa_s2_prereg.jl` not edited (S2 freeze).
- No S4 10-seed campaign.
- No `rel_g` / `rel_r` retune.
- No EM warm-start.
- No capability-status edit (other-lane lease).
- No `V4-FA` covered flip.

## S4

S4 may now run the frozen driver
`sim/v08_fa_s2_prereg.jl --cell=d4-k1 --mode=fit` on Totoro first
(1 thread / 1 BLAS thread). Pass bar remains 8/10 `ok_recovery` under the
S2 definition. This note does not launch that run.
