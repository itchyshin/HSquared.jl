---
name: hsquared-team-dispatch
description: Dispatch hsquared work across coordinator, R, and Julia lanes. Use before starting a substantial slice, spawning agents, steering the Julia twin thread, touching shared docs, or deciding which named review lenses are active.
---

# hsquared Team Dispatch

## Procedure

1. Read `AGENTS.md` and `docs/dev-log/coordination-board.md`.
2. Identify the lane:
   - coordinator: shared design, memory, issues, claims;
   - R: `hsquared` code, tests, docs, S3 surface;
   - Julia: sibling `HSquared.jl` engine work.
3. Name active lenses and what each should check.
4. State whether spawned subagents or separate threads are actually running.
5. Check for file overlap before edits.
6. Update the coordination board when the lane state changes.

## Status Format

```text
Active lenses: Ada, Shannon, Rose, Grace, Pat
Spawned subagents: none
Current lane: coordinator
Next action: update public claims register
```

## Hard Rule

Do not let the R lane and Julia lane edit the same shared contract at the same
time. Shannon owns the overlap check.
