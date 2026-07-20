# RETRACTED — Claude-lane D1 post-draw "findings" (2026-07-20). Do not use.

**This file is a retraction. Its original contents were wrong and were never committed.**
The authoritative record of the D1 reseal4 post-draw terminal failure is the **coordination board**
(`docs/dev-log/coordination-board.md`, "Current v0.7 recovery status — 2026-07-20") and the main-lane
commits `14b36e30` (all-GREEN pre-draw panel), `4953ddd2` (root retired), `bb7a9f76` (owner directive:
**D1 lane PAUSED — diagnose the harness before attempt five**).

## Three false leads — withdrawn, do NOT chase them in the attempt-five diagnosis

1. **"No GREEN adversarial pre-draw panel ran before the draw."** — **FALSE.** The panel ran and was
   documented all-GREEN (`14b36e30`); it simply was not visible to the Claude lane from Totoro logs. There
   is no governance irregularity here.
2. **"Only 1 attempt artifact exists where 16 were required."** — **FALSE, a miscount.** `d1-reseal4/attempts/`
   contains a `d1` *subdirectory*; `ls | wc -l` counted the directory, not the attempts. The board's figure —
   **4 completed official smoke attempts** — is correct.
3. **"Totoro was idle, so this was not a capacity failure."** — **UNSOUND.** The load reading
   (`load 0.07`, 414 GB free) was taken ~1.5 h *after* the run terminated, so it describes post-failure
   idleness and says nothing about conditions during 08:36–10:48 UTC. Resource exhaustion is neither
   supported nor excluded by it; treat capacity as an **open** hypothesis, not a closed one.

## What from the Claude lane does stand

The three pre-draw blockers found and fixed remain valid and are recorded elsewhere: `recompute.R:278`
(→ re-seal `0f5fbb54`), the `marker_ratio` float-precision drift in Julia `_validate_manifest`
(→ `8f214eb3`), and the stale `.sha256` integrity-pin sidecar on `stage_replay.jl` (→ `512d7ca7`). The
subsequent **`preflight: PASS`** on real D1 inputs (2026-07-20 08:25 UTC, zero-seed) vindicates the
`marker_ratio` fix end-to-end. See `docs/dev-log/2026-07-19-d1-blocker-2-marker-ratio-precision.md`.

*Left in place only because deletion was not permitted in the authoring session; safe to delete.*
