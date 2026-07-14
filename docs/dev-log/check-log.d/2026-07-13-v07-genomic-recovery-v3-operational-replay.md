# Check log — v0.7 genomic recovery-v3 operational Julia replay

Date: 2026-07-13

- Repaired D0F source admission to use the hash-pinned 432-row D0 diagnostics
  corpus rather than an obsolete campaign-seal/pilot-packet layout that is not
  present in the adjudicated D0 evidence root.
- Added operational `replay`, quiescent `verify-replay`, and `summarize` gates.
  Each replay binds the official R attempt, packet, manifest, preseal, corpus
  lock, Julia tool bytes, and Julia commit.
- Direct non-selftest entry now rejects GitHub Actions, generic CI, DRAC login
  nodes, malformed job IDs, and unadmitted hosts before reading a stage root.
- Kept official R runtime/RSS as the scientific summary source. Julia replay
  performance remains diagnostic only.
- Fixed a parallel-worker race found by independent Grace review. A worker now
  validates immutable inputs plus only its own create-once output pair. Exact
  mutable-subtree validation occurs only after fan-out is quiescent.
- Fixed a cross-twin seal mismatch found by Fisher review: Julia now verifies
  the deployed operational `v07_genomic_recovery_v3_recompute.R`, not the pure
  preseal helper, against `r_recomputer_commit` and `r_recomputer_sha256`.
  The single `d0_recomputer_sha256` key likewise now verifies the same R D0
  recomputer bound by the R preseal, rather than an unrelated Julia helper.
- Mutation controls prove that an unrelated in-flight worker does not fail a
  valid row, while quiescent verification rejects an in-flight primary,
  unexpected member, empty directory, corrupted packet, changed D0 fingerprint,
  or incomplete replay denominator.
- Direct-execution mutations prove Totoro and a numeric-job DRAC allocation are
  admitted while login-node, malformed-job, GitHub Actions, and generic-CI
  contexts are rejected.
- Clean Totoro deployment exposed R 4.5.3 versus local R 4.6.0 raw D0F fixture
  hash drift. A direct diff localized it to last-bit bootstrap quantile/SD
  serialization (maximum far below `1e-10`); all schemas and typed fields agree.
  Generated fixture hashes are now descriptive, while presealed R tool hashes
  and typed exact/`1e-10` parity remain mandatory.
- `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 ~/.juliaup/bin/julia --project=. --startup-file=no sim/phase2_v07_genomic_recovery_v3_stage_replay.jl --mode=selftest`:
  PASS; no official RNG or seed consumed.
- `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 ~/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'`:
  PASS.
- `git diff --check`: PASS.
- Independent Grace re-review after the concurrency repair: `CLEAN`.
- Final tool SHA-256 before commit:
  `c8b4d2ceb4c01f807efa610002763fc1f5416c35a666427975a7f7972a3b0826`.
- Boundary: no official phenotype, fit, replay row, summary, adjudication,
  recovery claim, activation, capability move, or count change was produced.
