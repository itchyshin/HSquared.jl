# Check log — v0.7 genomic boundary-performance holdout

- Local Julia holdout-v2 self-test: PASS.
- R oracle focused suite: 98 expectations, 0 failures/errors/warnings.
- R engine-free suite: 1,999 expectations, 0 failures/errors/warnings; 68
  expected live-engine skips.
- Cross-twin seal keys, 26 oracle columns, and exchange-schema digest: exact.
- Independent holdout-contract audit: CLEAN.
- Totoro exact-checkout self-test: PASS.
- Discovery-v4 validator before sealing: PASS.
- Fresh holdout: `BOUNDARY_HOLDOUT_PASS` and resume recomputation PASS.
- Attempt/packet/oracle denominators: 240/240/240; fit arms with
  `error_class = none`: 480/480.
- Scientific gate: 40 wins, 0 losses, Clopper-Pearson lower 0.9278424755;
  no unresolved, invalid, or unchanged-interior error.
- Runtime gate: all five cells <= 3x; maximum observed ratio 1.37035.
- Capability/status/public count: unchanged; default R route remains held.

Evidence details and immutable hashes are in
`docs/dev-log/recovery-checkpoints/2026-07-13-v07-genomic-boundary-performance-holdout.md`.
