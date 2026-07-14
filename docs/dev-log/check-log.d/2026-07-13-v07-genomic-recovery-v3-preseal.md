# Check log — v0.7 genomic recovery-v3 pure preseal replay layer

Date: 2026-07-13

- Added `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl` as a
  packet/replay/summary verifier. It contains no official RNG or writer.
- Exact source SHA-256 before commit:
  `efab8a5a6d99a6253620eca417c4d7ab73c9626ec9a9f6efe2fd9417d38aa88e`.
- The 39-key contract hard-binds the D0 receipt and exact packet diagnostics.
- Typed R/Julia parity passes for D1 (36x56 fields, R hash
  `945ab4576b534420688190f6649d83cc476d3dfb0e4b6e56b35af1b1d5cb8087`)
  and D0F (3x38 fields, R hash
  `1ee7c9c2cb42c940ef55bb003fa5c02f811201a1002713e39365d10237529795`).
- Scientific summaries use verified official R attempt runtime/RSS, not replay
  performance.
- Direct selftest with BLAS/Julia threads set to one: PASS.
- Full `Pkg.test()`: PASS.
- `git diff --check`: PASS.
- Deleted surfaces, dirty trees, forged hosts/blobs/sidecars/D0 inputs,
  malformed failures, low/zero-information summaries, altered parity fields,
  and arbitrary final receipts all turn red.
- Hopper and cross-twin Grace final verdicts: CLEAN for the pure preseal layer.
- Boundary: no official driver, preseal, phenotype, fit, corpus, adjudication,
  recovery result, activation, promotion, or count change exists.
