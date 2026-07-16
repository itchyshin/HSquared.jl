# Retry-7 exact-head local gate — 2026-07-16

Scope: source-safe, pre-RNG verification of Julia
`976814393043d3a4af5ce343d8ac4b05c43eac41` with R adjudication head
`b190a0cebbefa9af195b0722a5ab77be72474a71`. No official Retry-7 seed was
invoked.

## Julia package gate

- Julia 1.10 `OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test()'`:
  PASS.
- `julia --project=docs docs/make.jl`: PASS. Existing docstring/assets and
  local no-deployment warnings remain; no documentation deployment occurred.
- `julia --project=. sim/phase2_v07_genomic_recovery_v3_stage_replay.jl
  --mode=selftest`: PASS, explicitly synthetic-only with no official RNG.
- `tools/preamble_cap.sh`: PASS (one live snapshot).
- Replay tool sidecar equality: both SHA-256 values are
  `fb5d5dff6be807ccda1673618a360d708dd7447aab4dad2cde7d04cb42820c37`.
- `git diff --check`: PASS; only the declared carried-over Retry-5 drafts,
  quarantined scaffold, and new documentation evidence are outside clean HEAD.

## Cross-twin synthetic lifecycle binding

The R-owned full-cardinality synthetic lifecycle bound this exact Julia replay
tool SHA-256 and returned D0F `PASS/COMPLETE` and D1 `PASS/ELIGIBLE=12`:

- Root: `/private/tmp/hsq-retry7-synthetic-exacthead-local-b190a0c-97681439`.
- D0F receipt / lineage SHA-256:
  `3f34d389025ecddd842c84af4a5dad00b80cc427f37231981f7b3448f5ce32d2` /
  `fc45ab55c0a40c57f100a668138ea21ff23e5237726f579f2bbe9c6480c0168d`.
- D1 receipt / lineage SHA-256:
  `ae99bee82bfd6e5239b8d0551b6c64f71e4fbdf13243582a4b20eae9b711b0f3` /
  `46f7d7d41af538981ec2e926ac6da20ff6a8a0a32f2c9c3261173e7dc00569f6`.

This is architecture rehearsal only. The exact-head CI, reviewer batches,
clean Totoro deployment, preseal, and independent chronology audit remain
required before either reserved space may reach RNG.
