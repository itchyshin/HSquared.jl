# 2026-07-20 — D1 smoke contract arity diagnosis

- **Scope:** static, read-only source comparison only. No Totoro connection, retired-root read, seed use,
  admission, panel, controller launch, or retry.
- **Finding:** named `SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH`.
  At sealed R `5325e95`, `smoke-n-ladder` interprets its argument as a worker count and emits one pair per
  distinct `n` (`4` for D1); the controller passed `16` expecting attempts, then called
  `recommend-workers`, which requires at least `16` attempt TSVs. Thus its `RC=21` branch was
  deterministic (`4 < 16`), not evidence of a seed, fitting, or compute failure.
- **Test gap:** the launcher test checked strings/mode names, not the composed
  `smoke-n-ladder -> recommend-workers` cardinality contract.
- **Boundary:** the diagnosis satisfies the named-failure prerequisite in D-68 but does not authorize a
  successor. `d1-reseal4` and `2028000000/101:148` remain permanently retired; public status and
  `public_covered_count=5` are unchanged. Full proof:
  `docs/dev-log/recovery-checkpoints/2026-07-20-d1-smoke-contract-arity-diagnosis.md`.
