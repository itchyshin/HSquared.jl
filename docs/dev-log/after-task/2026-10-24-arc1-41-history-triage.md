# Arc 1 unparsed-history triage

## 1. Goal

Classify the 41 retained history inputs that the diagnostic seed scan could not parse, and test whether their exact bytes contain any of the 240 proposed pilot seeds. No fits were authorized or run for this check.

## 2. Implemented

Ran a read-only scan of the exact 41 hash-identified files from the retained Totoro history directory through the existing ControlMaster. Retrieved only those 41 files to `/private/tmp`, verified each hash, and parsed the retained raw payloads. Compared their byte streams with the 240 distinct outer seeds in the retained eight-cell pilot candidate. The classification artifact is `docs/dev-log/after-task/2026-10-24-arc1-41-history-classification.json` (SHA-256 `e4526518d3cbd4b439df3e895289a3515e04b0953435e719fed2d714b8c7a2bd`); the initial path/hash scan remains in `docs/dev-log/after-task/2026-10-24-arc1-41-history-triage.json` (SHA-256 `48d9cf139c3d61a8b6f479aad34124372ba9b82cdadefbbabb7fac8533db6877`).

All 41 raw files now match their retained hashes. Thirty-nine are valid JSON/TOML; the remaining two are a Markdown note and a TSV source-hash list. None contains a recognized consumed-seed field or a complete attempt-identity tuple, and there are 0 literal matches to the candidate seeds. Eighteen files have other key names containing `seed`, chiefly metadata or path lists. These results classify the 41 files for this bounded scan; the candidate batch still lacks the required `consumed_attempt_history` bundle.

## 3a. Decisions and Rejected Alternatives

- Treated zero literal matches as bounded collision-screening evidence only. They do not establish complete seed history or exclude derived, encoded, or indirect references.
- Classified the 41 files' structures and required attempt fields, but did not treat them as a complete history root inventory or create a consumed-history receipt.
- Did not create a complete-history receipt, alter the candidate batch, or launch pilot fits.
- Assumptions made without asking: none.

## 4. Files Touched

- Added `docs/dev-log/after-task/2026-10-24-arc1-41-history-triage.json`.
- Added `docs/dev-log/after-task/2026-10-24-arc1-41-history-classification.json`.
- Added this report.
- No source, admission, protected ledger, recovery-tree, isolated R, or Dropbox file was changed.

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s test -p test_arc1_diagnostic_seed_history.py`: 15 tests passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s test -p test_arc1_diagnostic_cells.py`: 13 tests passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s test -p test_arc1_pilot_cells.py`: 33 tests passed.
- Existing Totoro ControlMaster read exactly the 41 named files. The scan found zero literal matches among 240 distinct candidate seeds. No SSH master was opened and no fit ran.
- All 41 retrieved payloads rehashed to their retained inventory entries. Local classification found 39 valid structured files, zero recognized consumed-seed fields, zero complete attempt tuples, and zero candidate-seed literal matches.
- Independent accounting review matched the triage’s 41 `(basename, bytes, SHA-256)` tuples to the 41 unparsed records in the retained history report. The reviewer could not repeat the content scan because those raw files were not available in the local evidence tree.
- The source history report declares 10,728 extracted seeds, 41 unparsed inputs, and `exhaustive=false`; it still requires independent review.

## 6. Tests of the Tests

No tests were changed. The seed-history and pilot-launcher suites include malformed-history, seed-collision, missing-review, source-drift, and refusal cases. The passing results verify those existing tests still run; they do not validate the completeness of retained historical sources.

## 7a. Issue Ledger

- Open: the eight-cell pilot batch lacks a hash-pinned consumed-attempt history, complete root inventory, and independent review receipt.
- Open: the 41 files lack recognized consumed-seed fields and attempt identity tuples, but no approved complete-root inventory assigns them a metadata role or proves that all attempt stores were enumerated.
- No external issue was opened.

## 8. Consistency Audit

The retained candidate contains eight cells and 240 unique outer seeds. The triage covers the 41 exact inputs named by the diagnostic history report, not every possible retained attempt store. `public_covered_count` remains 7 and v7 remains HOLD. Original Arc 1 gates remain open.

## 9. What Did Not Go Smoothly

The `closeout.py new` helper resolved the Git root to the protected Dropbox checkout and its write was denied. No Dropbox file changed. The report was created directly in the authorized Codex worktree. The Unlazy status command could not run because Node is unavailable in this shell, so that ledger status remains unknown.

## 10. Known Residuals

The raw 41-file copy is retained in `/private/tmp/arc1-41-history-raw-20261024` and remains vulnerable to temporary-storage cleanup. The project now retains the path/hash scan and structural classification summaries. The independent accounting reviewer did not have the raw payloads when reviewing the first scan; the follow-up classification review is pending. No complete all-root consumed-attempt inventory or independent history review exists. This report provides no pilot, confirmation, G2, or other original Arc 1 gate credit. The paired R source remains incomplete; G6 and G7 remain open.

Next action: have an independent reviewer verify this raw-payload classification, then enumerate and review all retained attempt roots before building the complete consumed-attempt inventory required for pilot admission.

## 11. Team Learning

Treat parser failures as unresolved until each raw payload is classified. A zero-match scan over those files is useful screening evidence but does not certify completeness.

Memory receipt: `route.py` found no LOAD-FIRST manifest for this worktree. I used the supplied repository instructions and retained Arc 1 records to guide the audit; no additional routed memory note was available. The Graft executable was unavailable.

Golden Set: not run because this audit changed no implementation or tests.

## 12. Cross-Product Coverage

Covers: a read-only seed-literal screen over the 41 hash-identified diagnostic history inputs and the 240 proposed FA-rank pilot seeds.

does NOT cover: complete retained history, pilot admission, pilot or confirmation fitting, selection-rate validation, uncertainty calibration, repeatability intervals, live R-Julia parity acceptance, G6/G7 completion, GPU, releases, or capability promotion.
