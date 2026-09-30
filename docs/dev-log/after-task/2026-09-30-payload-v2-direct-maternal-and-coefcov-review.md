## 1. Goal

Review the Julia payload-v2 result and parser contracts against the R extractor and schema while completing the approved twin programme.

## 2. Implemented

No code changed. A read-only review found a direct-maternal result-shape mismatch between Julia and R and a `coefcov` parser-validation gap. It confirmed the inspected ordered-block and pedigree-ID mappings and preserved the Julia-only fence on multivariate-repeatability output.

## 3a. Decisions and Rejected Alternatives

Kept the slice read-only because lane preflight found changes on several refs and an active sibling R lease. The schema currently agrees with Julia's paired direct-maternal record, while the R extractor expects two records; the owner lane must reconcile the public contract before edits. Did not treat parser acceptance as fitted `coefcov` support.

## 4. Files Touched

Evidence only: `docs/dev-log/source-review/2026-09-30-payload-v2-direct-maternal-and-coefcov-review.md`, `docs/dev-log/check-log.d/2026-09-30-payload-v2-direct-maternal-and-coefcov-review.md`, `GATES.md`, and this report.

## 5. Checks Run

The reviewer pinned exact Julia and R source, schema, and test hashes and ran no tests. Lane preflight was run in both twins. The project-local preflight script and LOAD-FIRST manifest are absent from the Julia worktree; the canonical brain tool reported four refs with changes to `src/bridge_payload_v2.jl` and one to the schema. The R preflight reported 20 refs with changes to `R/julia-bridge.R`, an active Codex lease on FA/GLLVM tests, and a Cursor handover. Check-log generation and `--check`, `preamble_cap.sh`, `git diff --check`, and prose checks passed. The after-task structural checker passes; its acceptance phase correctly returns unmet because `GATES.md` and three scoped ledgers still have open programme gates.

## 6. Tests of the Tests

The existing direct-maternal test checks parameter count and metadata but not exact `random_effects` fields or R extraction. Existing schema and code make the shape mismatch directly observable. The frozen `coefcov` field set is not asserted at parser level; an invalid partial block can pass dispatch then fail later as unimplemented.

## 7a. Issue Ledger

- Open P1: settle paired-vs-two-record direct-maternal shape across schema, Julia output, R extraction, and parity regression.
- Open P2: validate the frozen `coefcov` metadata fields or reject such input at parsing with the schema's precise contract.
- Open: whole bridge and E1 review; no broad result mapping established.

## 8. Consistency Audit

The evidence distinguishes payload parsing from fitting. No capability or release state changed. The Julia-only multivariate-repeatability fence remains in place. GATES.md records these as carried bridge findings rather than a completed bridge gate.

## 9. What Did Not Go Smoothly

The code paths live in two twins with many refs carrying edits. The shared R checkout's latest handover names Cursor, so a local contract change would risk landing against the wrong lineage. This review records the mismatch for resolution by the owning lane.

## 10. Known Residuals

This review does NOT cover all payload fields, all R extractors, full S3 normalization, GLLVM/FA parity, other families, deployed docs, whole-source E1, or final V3 integration. Neither the direct-maternal mismatch nor the `coefcov` parser gap was fixed here.

## 11. Team Learning

Bridge parity requires a producer-to-extractor test of concrete nested field names and record counts; matching schema prose alone is insufficient. Unsupported blocks also need a parser-level negative test so malformed metadata does not travel to an unrelated later failure.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new fixture was added.

## 12. Cross-Product Coverage

This slice compared Julia engine output, R bridge/extractor source, schema, and selected Julia tests. It does NOT cover a live JuliaCall fit, R S3 result validation, other payload fields, whole E1, or final twin validation.
