# PR 498 preserve base records

## 1. Goal

Keep main-branch records available through the Arc 1 merge trial and remove
machine-specific hook paths without reconstructing unavailable evidence.

## 2. Implemented

Restored four `LOOP/` records byte for byte and saved the previous root
`GATES.md` as a separate dated snapshot. The root index now distinguishes
the tracked FA ledger snapshot from unavailable ignored ledgers. Cursor hook
commands use the project-relative script path.

## 3a. Decisions and Rejected Alternatives

The base records were restored without editing their contents. The older
pinned archive remains untouched because it is a different snapshot. The
missing Arc 1 ledger was not reconstructed. The restored LOOP files describe
historical work; the root index labels them accordingly. Assumption: preserving
the original tracked locations is preferable to moving them in this draft.

## 4. Files Touched

`LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/ultra-plan.md`,
`GATES.md`, `.cursor/hooks.json`,
`docs/dev-log/acceptance-archive/2026-11-04-pr498-base-gates.md`, this report,
and `docs/dev-log/check-log.d/2026-11-04-pr498-preserve-base.md`.

## 5. Checks Run

`git hash-object` matched each restored file to base commit
`62ab7c8d1527d98210934d862f2cb7fd003afcb2`. The static JSON/path check
verified all three hook commands and both available/unavailable ledger paths;
`node --check .cursor/hooks/graft-hooks.cjs`, the whitespace check on edited
index, hook and new receipts, and `bash tools/preamble_cap.sh` passed. The
full staged whitespace check reports two pre-existing whitespace lines in
the byte-identical historical `LOOP/arcs.md`; they were retained intentionally.
The scoped command was `git diff --check HEAD^ HEAD -- .cursor/hooks.json
GATES.md docs/dev-log/acceptance-archive/2026-11-04-pr498-base-gates.md
docs/dev-log/after-task/2026-11-04-pr498-preserve-base.md
docs/dev-log/check-log.d/2026-11-04-pr498-preserve-base.md`. `gate-check.mjs --status` exits 2 because the root index contains zero live
gates; it does not certify acceptance. Full package and hosted CI are not yet
run on this new head. No fits or seeds were run.

## 6. Tests of the Tests

Each byte comparison uses the source commit's Git blob ID independently of the
working file. The hook check asserts the complete command, event and target
file; it does not invoke the hooks or prove native Cursor execution.

## 7a. Issue Ledger

PR #498 lost tracked base records and had a machine-specific hook path. The
missing ignored Arc 1 ledger and seed-admission issues remain unresolved.

## 8. Consistency Audit

Inspected the original root index and tracked automatic FA ledger snapshot.
Routed project guidance, preflight and a scoped lease were used. The current
root index states that source-specific historic evidence is not a present
acceptance claim. No hub guard was added; the Golden Set was not run.

## 9. What Did Not Go Smoothly

The initial hash command used zsh's special `path` loop variable, changing PATH
inside that one short-lived shell; hash checks were rerun successfully in a
fresh shell with a task-specific variable. No source bytes were affected.

## 10. Known Residuals

The original ignored ledgers are missing; historic receipts retain their
original identities. This does not resolve the seed guards, complete the Arc 1
handover, establish package CI, or make PR #498 merge-ready. Native Cursor and
Windows hook execution remain unverified.

## 11. Team Learning

An older archive with a related title need not contain the latest main-branch
bytes. Compare blob IDs and retain each version separately.

## 12. Cross-Product Coverage

This covers five tracked historical blobs and static hook command resolution.
It does NOT cover scientific gates, R–Julia bridge execution, release status,
or operation of Cursor hooks on Windows.
