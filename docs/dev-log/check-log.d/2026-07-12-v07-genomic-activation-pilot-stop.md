# 2026-07-12 — v0.7 genomic activation pilot STOP

- Ran a 432-seed diagnostic pilot over the preregistered cells with the pre-repair Julia-only
  harness on Totoro, 16 processes, threads/BLAS = 1; raw outputs
  stayed local and no GitHub Actions artifact was created.
- Three cells failed the 95% observed convergence gate: `n120_m600_r020` (36/48),
  `n120_m600_r080` (40/48), and `n300_m1000_r020` (42/48).
- Two more cells exceeded the 2,000-replicate precision cap after independent base-R recomputation
  with the frozen upper-SD rule: `n120_m600_r050` (2,015) and `n300_m1000_r080` (2,278).
- Independent R recomputation deliberately went RED against the initial Julia summary because the
  latter used raw pilot SD. Confirmation was not launched. The compact checkpoint records the
  corrected decision and immutable local checksums.
- Activation is held, nothing is promoted, and `public_covered_count` remains 5.

Evidence: `docs/dev-log/recovery-checkpoints/2026-07-12-v07-genomic-activation-pilot-stop.md`.
