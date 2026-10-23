# After-task — 2026-09-07 release-record cleanup (Julia)

## 1. Goal

Reconcile the completed reader-documentation milestone with the historical
science roadmap, without authorizing a release or changing engine behavior.

## 2. Implemented

Added a matched public-source decision record; a bridge-compatibility note;
roadmap and coordination-board notices; a dated notice on the historical
handover; and a check-log shard.

## 3a. Decisions and Rejected Alternatives

Kept experimental **0.8.0** and public count **7**. Rejected selecting 0.9 or
0.10, treating the documentation milestone as a science-plan completion,
changing a status cell, or repeating the stale blanket claim that S5 was not
run. The record instead states its scoped PASS and held promotion.

## 4. Files Touched

- `ROADMAP.md`
- `docs/design/12-bridge-compatibility.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/handover/2026-09-07-codex-handover.md`
- `docs/dev-log/decisions/2026-09-07-documentation-milestone-release-boundary.md`
- `docs/dev-log/check-log.d/2026-09-07-release-records-cleanup.md`
- `docs/dev-log/after-task/2026-09-07-release-records-cleanup.md`

## 5. Checks Run

- `git diff --check`: **PASS**.
- `julia --project=docs docs/make.jl`: **PASS**. Documenter completed its
  checks and Vitepress render; its existing missing-docstring and local
  deployment-skip warnings are retained in the check log.
- Manual reconciliation against the capability ledger and S5 record: **PASS**;
  the 2026-09-01 tail-scale PASS remains frozen-scope evidence and promotion is
  held.
- Root release-record verifier: **PASS** — `RECORDS_VERIFIED: 14 Markdown
  files; scope, new-path privacy and local-link checks passed`.

## 6. Tests of the Tests

Negative control: before this repair, the canonical after-task validator failed
this report because all required numbered headers were absent. This revision
uses every exact protocol header; the fresh validator returned
`after-task structure check passed`.

## 7a. Issue Ledger

No issue was opened or closed. The associated R-side PR #195 and issue #186 are
parent-owned. The R bridge record keeps optional Julia PR #267 explicitly
off the critical path and not release evidence.

## 8. Consistency Audit

Walked the bridge matrix, roadmap, capability ledger, S5 debt record,
coordination board, and handover. They now consistently treat the reader
milestone as documentation-only and retain 0.8.0/count 7, H1/H3 deferral, G10
hold, and S5 promotion hold.

## 9. What Did Not Go Smoothly

The first local Documenter invocation was sandbox-blocked while creating its
standard Julia artifact-usage lock. The approved rerun passed; the incidental
generated validation-status timestamp was restored. The first report also used
informal headings and failed the canonical after-task validator.

## 10. Known Residuals

This is not a package test, engine fit, release gate, or a replacement for
deferred science. Package numbering, release authority, H1/H3, G10, S5
promotion, PR #195, and issue #186 remain unresolved.

## 11. Team Learning

This edit owner spawned no child agents. The parent lane has separately reported
a Terra producer, Luna mechanical scout, and Terra specification reviewer; they
are not participants or signatories in this report. Durable lesson: a handover
notice must identify a historic record as such while preserving its body, and
must point to public current evidence rather than silently rewriting history.

## 12. Cross-Product Coverage

The documentation-record product covers ✓ the Julia decision record, bridge
matrix note, roadmap/board notices, historical-handover notice, and audit
records. It does NOT cover ✗ Julia source/API behavior, package versioning,
tags, General registration, a capability/status-cell flip, S5 promotion,
H1/H3 science, G10 authorization, or PR #195 / issue #186 disposition.
