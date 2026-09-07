# Codex handover: progress toward 0.9 and 0.10

Date: 2026-09-07. From Codex to a fresh Codex task.

## Critical Context

You are Codex, picking up the paired HSquared.jl / hsquared programme.
The user wants to progress toward 0.9 and 0.10 before the broad DRM-style
adversarial testing campaign. They will obtain Grok bot scripts and receipts later.
This defers that campaign, NOT ordinary tests, scientific evidence required for
a claim, or CI. Version stays 0.8.0 and public covered count stays 7 until an
explicit release/promotion decision. Do not invent capabilities to fill a version.

## Goals and Plans

Help applied scientists install, choose, fit, diagnose, and report. First prepare
a repo-grounded ultra-plan separating earned work from remaining 0.9/0.10 scope.
Use three economical independent workers plus coordinator when useful; fresh
briefs, explicit models/efforts, ownership, dependencies and elapsed estimates.
Routine work Terra, mechanical reconnaissance Luna, claims review Sol.
Use unlazy gates for approved execution. No new large campaign is authorized.

## What Was Accomplished

Paired reader websites, honesty documentation and release-record cleanup landed.
See the paired 2026-09-07 release-records-cleanup after-task reports and
2026-09-07-documentation-milestone-release-boundary decisions for details.
R #198/#199/#200 and Julia #319/#320 were completed in the prior lane.
R #195 was closed unmerged with its branch preserved; R #186 was closed.
Fresh gh verification during this handover confirms R #200 and Julia #320 MERGED.

## Current Working State and Mission Control

| Repository | Recorded merged main | Verification | Next leverage |
| --- | --- | --- | --- |
| hsquared | 79835ca55d75c25fac53cd87da6624755af8a039 (#200) | Merge freshly verified; previous lane recorded R check and pkgdown green | Reconcile remaining public workflow and milestone scope |
| HSquared.jl | 6987871b3b8c257cdb23100246d768f8a6fd5397 (#320) | Merge freshly verified; previous lane recorded Julia 1.10/1 and Documenter green | Reconcile engine scope against R promises |

Current CI must be refreshed before action; the prior green receipts are dated
evidence, not a claim about a future head. No test campaign is running from this task.

## Key Decisions and Rationale

- Broad bot testing follows the milestone work at the user's request.
- Normal tests and CI continue at every slice; necessary evidence cannot be postponed.
- Version bumps, tags, scientific promotions, S5 reruns and heavy compute remain gated.
- Historical 0.9 scientific plans are not evidence that those capabilities shipped.
- H1/H3 remain deferred, not cancelled; G10 promotion remains held.
- Do not repeat historical S5-never-run wording: inspect current dated evidence.
- R FA/low-rank fitting remains distinct from narrow Julia engine coverage.

## Landing State

The pre-handover gate passed on the clean, landed release-record worktree.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| R release records | yes | yes | #200 merged | LANDED |
| Julia release records | yes | yes | #320 merged | LANDED |
| codex/handover-0910-20260907, these four handover/pointer files | commit and publication follow this document | verify origin branch | documentation PR only, no auto-merge | CARRIED-OVER pending human merge |
| Dirty original Dropbox checkouts and unrelated branches | mixed historic state | do not assume | outside this handover | PROTECTED |

Handover branch is carried over because the handover skill forbids auto-merge.
Resume: fetch origin, inspect origin/codex/handover-0910-20260907 and this document;
use the new isolated task for planning, not the dirty original checkouts.
FINDINGS-OF-RECORD: none

## Files Created / Modified

This handover-only branch changes exactly:

- AGENTS.md (replace the single snapshot with a current coordination pointer).
- docs/dev-log/phase-snapshot-archive.md (archive previous snapshot verbatim).
- docs/dev-log/coordination-board.md (add current continuation, retain older lanes).
- docs/dev-log/handover/2026-09-07-codex-0910-handover.md (this document).

Earlier implementation file lists remain in the paired after-task reports.

## Next Immediate Steps

1. Rehydrate AGENTS.md, brain routing, lane preflight and current coordination board.
2. Refresh gh state and main in both twins. Classify old instructions as DONE,
   OWED, RETRACTED or PROTECTED; do not redo completed documentation.
3. Read current ROADMAP.md, capability-status and the paired release-boundary
   decision. Identify exactly what 0.9 and 0.10 would mean.
4. Present a concise recommended milestone sequence, parallel routing, estimates
   and only consequential user choices before new scientific implementation.
5. After scope approval, execute bounded slices with evidence gates; reserve the
   broad adversarial campaign for the later agreed checkpoint.

## Blockers / Open Questions

The milestone scope and release labels require reconciliation; the user has not
approved arbitrary scientific additions. Bot scripts are unavailable for now,
but this does not block planning or ordinary regression tests.

## Gotchas and Failed Approaches

The original 2026-09-07 handover and older scratch notes contain superseded PR
states. Original Dropbox checkouts are dirty: preserve them and their branches.
Unrelated R #185 and Julia #265/#267 were not documentation milestone blockers.
The DRM dashboard at http://127.0.0.1:8823/p/drmTMB/test reports about 129 issue
references across an effort, not 129 independent overnight bugs. Its final quiet
overnight loop reports no new URLs; summary counters conflict with the table.
Do not treat paired issues or different approximation methods as distinct bugs
without reproduction. Do not contact or restart the bots on this authority.

## How to Resume

Rehydrate from docs/dev-log/handover/2026-09-07-codex-0910-handover.md + the
AGENTS.md snapshot, then continue with the Next Immediate Steps.

Read the coordination board and linked other lanes, then the current paired
release-boundary decisions, roadmap and capability ledger. Codex owns the live
toolchain after approval; no compilation or fits are needed merely to plan.
For later checks, cap launch threads: OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4.
Verify installed tools and project paths rather than importing stale PATH values.
Standard Julia checks: julia --project=. -e 'using Pkg; Pkg.test()',
julia --project=docs docs/make.jl, and bash tools/preamble_cap.sh.
Use isolated R and Julia worktrees and exported workflows; do not stage unrelated
configuration, private scratch files, credentials, or original checkout edits.
