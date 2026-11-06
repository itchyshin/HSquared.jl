# Arc 1 retained development receipts and manifest drift

Reviewer: Codex, read-only evidence audit. Date: 2026-10-04.

## Scope

I inspected ignored local Arc 1 evidence under
`.unlazy/arc1-gaussian-reliability/evidence/development-v1-20261003/`.
No campaign fit or simulation ran in this review. No seed, source, or
capability row changed.

## Retained attempt evidence

The directory contains three admitted `fa_rank` attempts for the development
cell `N=80`, `signal=null`; each admission planned 30 attempts. The manifest
assigns unique seeds across 644,480 outer and nested rows. The three observed
seeds match outer indices 1, 2, and 3 in the current manifest.

- Attempt 1 ended with `child_error` after 7.831 seconds. Julia reported that
  `FillArraysStatisticsExt` was absent from the active `Manifest.toml`. Its
  start, result, and log digests match their retained records.
- Attempts 2 and 3 ended `ok` after 19.952 and 20.140 seconds. Both report
  eligible K0/K1 candidates and select K0. Admission, start, result, full
  result, summary, and Julia-log digests match the local files and canonical
  seed allocation.
- This is 3 of 30 planned attempts in one development cell: 2 eligible
  selections and 1 child error. It is not a pilot or confirmation result.

## Source and manifest limits

The successful receipts pin the same `src/arc1_profiles.jl` and
`src/arc1_interfaces.jl` hashes, but those hashes differ from the current
worktree. The failure receipt also pins an older `sim/arc1/execution_identity.jl`
and seed-manifest hash. These receipts describe their recorded source
snapshot. The current implementation needs its own evidence.

Running `tools.arc1_manifest.verify_manifest` on the current manifest failed:
`tracked historical seed audit paths or hashes changed`. The recorded audit
has 999 paths; the current audit has 1,000. One handover file was added, and
four tracked files changed: `docs/dev-log/check-log.md`,
`docs/dev-log/coordination-board.md`,
`docs/dev-log/phase-snapshot-archive.md`, and `test/arc1_interfaces.jl`.
The current manifest therefore needs a new source freeze and admission after
active edits settle. Do not use these receipts to claim current-source
reliability, and do not launch the campaign from this manifest.

## Decision

The retained run evidence changes the status from “no local Arc 1 attempts
found” to “three development attempts retained, two successful under older
profile/interface sources.” It does not close an acceptance gate. Keep G0 and
the reliability gates open. Next, finish the active profile-v4 review, freeze
the source and seed manifest again, rerun its full verifier, then resume the
remaining 27 development attempts under the newly admitted source identity.

## Current-source contract checks

The focused command
`JULIA_DEPOT_PATH=/private/tmp/arc1-contract-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Test; include("test/arc1_fa_v2_contracts.jl")'`
passed 23/23 profile-v4 evidence-sink contract checks and 157/157 FA-rank v2
contract checks. The Julia process took about 17 seconds, including compilation. The
default shared depot first failed to create a compiled-cache lock under the
sandbox; the temporary writable depot allowed the test to run.

Hashes at the passing run:

- `test/arc1_fa_v2_contracts.jl`:
  `64c013b0856503d6d8e26f8d349949f1a9125bbc2ae0ca0ac904a9002efdb4fe`
- `src/fa_rank_selection.jl`:
  `61eb542bf34796c0222e1a8df7550de5dfdb03f3bb855c63a43c243f6bbbeda0`
- `src/arc1_profiles.jl`:
  `9c807d4b6cad596e12230c9e5c5eb0f1f3e8cc7c868902706aa3ca05aa6d180c`

These tests establish current contract behavior. They do not resolve the
profile-v4 scientific review hold or establish campaign reliability.
