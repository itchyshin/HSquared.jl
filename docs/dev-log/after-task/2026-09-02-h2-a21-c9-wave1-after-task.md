# After-task / substitution — A21 C9 wave-1 (JL-7 / JL-8)

**Date:** 2026-09-02
**Lane:** Julia (`HSquared.jl`) — campaign worktree
`~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`, branch
`claude/lane-h2-twin-20260901`.
**Active lenses:** Ada, Shannon, Rose (perspectives)
**Spawned subagents:** none
**Current lane:** coordinator / ledger only

Panel: `~/local-scratch/h2-a21-estimand-claim-panel-2026-09-02.md` §5.3 / §6
item **C9**, applied to the Julia half of wave-1 (Rose pass-3 findings
**JL-7** and **JL-8**). Not a new design number and not a covered flip.

**Fence held:** `public_covered_count` **5** · `V4-MV-REML` **covered**
(unchanged) · draft PR **#277** · no G10 · no Darwin ink · no Registrator ·
no merge · no capability-status count edit.

---

## Goal

Record what wave-1 landed on this lane after JL-7 and JL-8, and close A21
C9 without inventing a contemporaneous after-task for those two commits.

## Substitution note

Neither JL-7 nor JL-8 wrote an after-task or check-log shard at commit
time. A21 C9 asked for a consolidated report plus a recorded substitution,
not reconstructed reflection. Block 1 overnight debt already has Option B
(`docs/dev-log/decisions/2026-09-02-block1-check-log-substitution.md`).
This file is the **wave-1** substitute for JL-7/JL-8: index the SHAs and
the Rose finding they close; do not invent "what did not go smoothly"
after the fact.

R-lane wave-1 (C5/C6) is recorded in the twin
`hsquared` report of the same name. C6 already has its own after-task.

No new `docs/design/NN-` ID. No new decision file (lease is after-task +
optional board line).

---

## What wave-1 landed (Julia)

| Item | SHA | What it did |
| --- | --- | --- |
| **JL-7** | `ca4b4fcf9d64d25a0d09a67823bb71b4abaf06b3` | README + `docs/src/validation-status.md`: `public_covered_count` is a claims-register ledger total, not a callable `public_covered_count()`. Authority remains `docs/design/06-public-claims-register.md`. |
| **JL-8** | `c0f53e0ddaf57d002100a55ee5798c5051e87095` | Matfree fence `src/` scan is recursive (`walkdir` plus a nested-file pin). A top-level `readdir` would miss a future `src/` subdirectory. |

Both SHAs are on `origin/claude/lane-h2-twin-20260901` and are ancestors
of draft PR [#277](https://github.com/itchyshin/HSquared.jl/pull/277)
(head at C9 write time: `c0f53e0d`).

Twin wave-1 (R lane; recorded in the sibling C9 report):

- C5 `529a5a2b76cda71bf786ae2a64c9f342fd108cfe` — Willham citation lock
  for `h2_T`, `m2`, `r_am`.
- C6 `0c96fd34dd92fcf5b81cf9786088e7dabdae0889` — two `m2` denominators
  + `r_am` identity (R tests).
- Draft PR [#141](https://github.com/itchyshin/hsquared/pull/141).

## Files changed (this C9 slice)

- this report
- one short prepended coordination-board note (existing Block 1 section
  left untouched)

## Checks

Ledger only. No `Pkg.test()`, Documenter rebuild, or capability-status
recount were run for C9. JL-7 is prose. JL-8 is a fence-scan change
already on the pushed PR head.

## Public-claim audit

No status word moved. `public_covered_count` stays **5**. JL-7 makes the
count harder to misread as a function; it does not change the number.
JL-8 does not widen the matfree claim.

## Tests of the tests

None new here. JL-8's nested-file pin is the test-of-the-test for the
recursive walk; it lives in `test/runtests.jl` at the JL-8 commit.

## Coordination

- PLATFORM: cursor | ON BRANCH: `claude/lane-h2-twin-20260901` | LANE: A21 C9
  wave-1 ledger. OTHER LANES:
  `codex/2026-07-13-v07-performance-localization` — not touched.
- Foreign-lane preflight flagged the Claude twin branch as expected; this
  slice stays inside `docs/dev-log/after-task/` plus one board line.
- Draft PRs stay draft. No merge.

## What did not go smoothly

JL-7 and JL-8 landed without after-task reports. Reconstructing
session-level reflection would be weaker than naming the gap. This index
is the substitute.

## Known limitations

- Julia-lane `r_am` identity test still owed (A21 C4).
- Rose pass-3 leftovers still open: JL-2 (partial), JL-4, JL-5.
- Darwin ink, G10, and Registrator remain owner-gated.

## Next actions

Keep the fence. Do not flip, merge, or register. Remaining A21 leisure
items are other leases.
