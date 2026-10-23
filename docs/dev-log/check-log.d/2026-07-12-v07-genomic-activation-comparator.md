# 2026-07-12 — v0.7 genomic activation construction and comparator gate

- Regenerated the genomic BLUPF90 packet with the frozen sample-frequency VanRaden1 construction,
  ridge `0.01`, exact `Q_lambda`, and a matching `u ~ N(0, sigma_g2 K_lambda)` DGP.
- Ran `blupf90+` 2.60 from neutral starts. It converged to the HSquared.jl REML optimum within the
  five-significant-figure BLUPF90 printout floor: component absolute differences `4.16e-06` and
  `2.33e-06`; genomic-ratio difference `2.88e-07`.
- Banked the marker, kernel, precision, emitted-input, executable, log, and solutions SHA256 values
  in `docs/dev-log/recovery-checkpoints/2026-07-12-v07-genomic-activation-blupf90.md`.
- Raw comparator packets and logs remain local and git-ignored. Nothing ran on GitHub Actions.
- This is same-precision point-estimate evidence only. Nothing is promoted and public counts remain
  unchanged; the nine-cell preregistered recovery campaign remains the activation gate.

