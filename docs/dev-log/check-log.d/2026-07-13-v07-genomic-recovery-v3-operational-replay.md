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
- The first live D0F Julia replay exposed a fixed-panel projection bug: the
  576-row phenotype manifest contains eight rows per fixed panel, but the
  validator called `only()` after filtering only on design and panel. The
  validator now requires exactly the unique phenotype ranks `1:8`, verifies
  every panel-level field and fingerprint is common across the eight rows, and
  selects rank 1 only as the canonical 72-row comparison representative.
- The failed D0F root remains hash-locked, retired, and unadjudicated. The fresh retry uses
  the newly frozen Julia phenotype-seed base `2032000000`; Julia contains no
  bootstrap-seed generator and consumes the R-presealed bootstrap-index
  manifest, whose fresh R base is `2033000000`. The cross-twin synthetic
  bootstrap-manifest hash is correspondingly pinned to
  `609db9dbb3ba023728249645e14e13e579d7dd9cc1917a9241bcf9f3c1d60c4c`.
- New tests exercise the actual 576-row phenotype-manifest to 72-row
  fixed-panel validator. A valid projection passes; a changed fixed-panel
  precision hash, duplicate/missing phenotype rank, and changed precision hash
  on phenotype rank 8 each turn the gate red. The positive test would fail at
  the original `only()` call before reaching content validation.
- Fisher's exact-commit review found that D1 was only described as conditional:
  its tooling could still prepare or preseal before D0F had a final admissible
  decision. The stage-preseal contract is now schema version 2. D1 must bind an
  external canonical D0F adjudication root and exact receipt hash, and the
  receipt must be an ordered `v07-genomic-recovery-v3-adjudication-1` record
  with `stage=d0f`, `verdict=PASS`, `stage_decision=COMPLETE`, parity maxima no
  greater than `1e-10`, complete provenance, and canonical post-run reviews.
  D0F records the new predecessor fields as `NA`.
- Mutation controls make the D1 gate red for a non-COMPLETE predecessor,
  changed receipt hash, nested predecessor root, or the known hash-locked retired
  D0F root. A valid synthetic predecessor passes.
- A second Rose/Fisher/Noether review found that receipt syntax was still
  insufficient: a forged receipt-only root passed. The Julia preseal now calls
  the sibling operational R exact final-tree validator for every D1 worker. A
  forged receipt-only root is a direct red mutation; no caller-controlled
  attestation shortcut is accepted.
- `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 ~/.juliaup/bin/julia --project=. --startup-file=no sim/phase2_v07_genomic_recovery_v3_stage_replay.jl --mode=selftest`:
  PASS; no official RNG or seed consumed.
- `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 ~/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'`:
  PASS.
- `(cd sim && sha256sum -c phase2_v07_genomic_recovery_v3_stage_replay.jl.sha256)`:
  PASS.
- `python3 ~/shinichi-brain/tools/closeout.py check <operational-replay-after-task>`:
  PASS.
- `git diff --check`: PASS.
- Independent Grace re-review after the concurrency repair: `CLEAN`.
- The earlier Fisher/Noether/Hopper receipts were invalidated by the schema-2
  repair; five fresh reviews are required on the new exact commits.
- Current pre-commit tool SHA-256:
  `8aac6c50775fcb0f5ebcd15235b2d2979bc2ac50a7b7006165342f8208d9d7de`.
- Boundary: this repair consumed no seed. The failed root contains official R
  D0F output but no admitted Julia replay or adjudication; it remains hash-locked,
  retired, and unadjudicated. No recovery claim, activation, capability move, or count
  change was produced.
