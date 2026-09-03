# 2026-09-03 — 0.8 S2 FA recovery-gate PREDECLARATION

**Status: FROZEN · NOT RUN.**  
Decision: `docs/dev-log/decisions/2026-09-03-v08-s2-fa-recovery-gate-prereg.md`  
Driver: `sim/v08_fa_s2_prereg.jl`  
Driver SHA-256: `47a1b619e83b468cec28dae57918f755064a32528f16bf775943b8b7e36b4b83`  
Driver git blob: `370cf69773a52dc7e158a9415d389e31ddf7a8e7`

S1 closed (Totoro): 8/10 old-gate `ok_recovery`, 2 Heywood, 0 optimizer_miss,
`heywood_flag` 7/10, `ledermann_slack=0`. Start-sensitivity REFUTED.

## Locked before any S4 fit

- Gate DGP: `t=4 K=1`, `ledermann_slack=4` (`--cell=d4-k1`).
- Not chosen: `t=5 K=2` (slack 2, but changes rank).
- Pass: converged AND `rel_g ≤ 0.45` AND `rel_r ≤ 0.25` AND `min(ψ̂) ≥ 1e-4`
  AND `ledermann_slack > 0`.
- Old G/R gates accept collapsed uniqueness — recorded as
  `heywood_accepted_by_old_gr` when that happens.
- S4 seeds: `20260914:20260923`. Bar: 8/10 `ok_recovery` under this definition.
- S3 first: uniqueness bound / Ledermann guard. Not EM warm-start.

Not a covered flip. Count stays 7. Rose CLEAN not written.
