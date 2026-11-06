# Arc 1 reconstructed diagnostic pre-run

## 1. Goal

Integrate and independently review the source-history checker and diagnostic launcher, preserve dirty work, then execute exactly eight authorized diagnostic attempts. This finite engineering slice does not close the scientific goal.

## 2. Implemented

A separate source snapshot and finite seed-history admission were reviewed before execution. Eight attempts ran on Totoro with at most four jobs and one Julia and BLAS thread per job. All eight returned native results, both rank candidates were eligible, and all sixteen rank comparisons passed the 0.0001 reference-shortfall limit. Maximum shortfall was 5.23e-12. Per-job wall time was 27.64 to 39.78 seconds, substantially below the conservative 30 to 90 minute total estimate. No retry or replacement was performed. Report structure check passed; automatic ledger execution was unavailable because node or gate-check was missing, so that automated gate state is UNKNOWN.

## 3a. Decisions and Rejected Alternatives

Use a separately versioned Julia-only diagnostic identity. Do not inherit historical R parity or change original acceptance gates. History is finite and includes 41 unparsed inputs; it is not exhaustive. An independent enumeration of 644750 frozen allocated seeds found no collision with the eight diagnostic seeds. The best-found reference is not a proof of a global optimum.

## 4. Files Touched

New tools: tools/arc1_diagnostic_seed_history.py and sim/arc1/run_diagnostic_cells.py. New tests: test/test_arc1_diagnostic_seed_history.py and test/test_arc1_diagnostic_cells.py. New amendment: docs/dev-log/decisions/2026-10-24-arc1-source-history-rebuild.md. Separate ledger: .unlazy/arc1-rebuild-diagnostic-20261024/GATES.md. Original protected records and source were not edited. No commit, push, tag or release.

## 5. Checks Run

Parent verification: 28 diagnostic unit tests passed, exit 0. Original pilot launcher: 33 tests passed, exit 0. Actual host package-load and configuration checks passed without fitting. Exact deployed admission and source/runtime pins received independent Astra review. Planning-only admission returned eight jobs and no execution. Eight terminal native results and eight serialized artifact hashes were checked locally. Independent result review passed at diagnostic scope. Receipt SHA-256: b220d41b15e51159206828e0f4f1203419936327c5d149f2eaf00da06a7856a6. All eight datasets attempted 19 ordinary starts and 86 expanded-reference rows each. Three ordinary starts failed covariance checks and 24 reference rows were unaccepted; all remain visible. Launcher span was 72.92 seconds, maximum overlap four; no fitting processes remain.

Retained results: /private/tmp/arc1-completed-prerun-20261024/results. Compact table: /private/tmp/arc1-completed-prerun-20261024/compact-results.json. Remote root: /home/snakagaw/hsq_work/arc1-diagnostic-rebuild-20261024-34mpd77. Admission core SHA-256: bb62ef58cfedae500689cda74846ff5ae439f7b60e8c4d870bf9f6bb27b128c3.

## 6. Tests of the Tests

Adversarial cases cover seed collisions, malformed history, source drift, admission changes, retries, timeout, termination and unexpected process communication failure. Real harmless child and grandchild processes exercise cleanup. Diagnostics provide no pilot or confirmation credit even though inherited coordinates retain the pilot label.

## 7a. Issue Ledger

Original G2 through G8 remain open. R source reconstruction and live parity remain unresolved. Historical N80-null outers 2 and 14 still lack K1 reference maxima. Existing failures remain counted. No extra fits are authorized by this report.

## 8. Consistency Audit

public_covered_count remains 7; v7 remains HOLD. G0 and G1 retain historical status only. Source and seed admission are new diagnostic identities. Original GATES.md, checkpoint, coordination board, freeze and AGENTS.md were deliberately left untouched. Before-state inventory preserves 40 dirty paths; only the authorized new amendment changed among them at integration.

## 9. What Did Not Go Smoothly

Missing historical source and incomplete seed history required an explicit amendment. R reconstruction remains unfinished. The initial runtime estimate was highly conservative; measured timings now support a smaller estimate for this exact source and schedule, but eight datasets cannot characterize tail runtime or numerical failure rates.

## 10. Known Residuals

One dataset per cell cannot establish reliability, selection probabilities, coverage or calibration. No interval study ran. No full pilot or confirmation campaign was launched. The finite consumed-history search has explicit scope limits. Recovery trees under /private/tmp are vulnerable to reboot cleanup and remain in place.

Next action: prepare a measured pilot proposal with exact source and seed admission. Never restart this admission or reuse its eight seeds.

## 11. Team Learning

Luna workers owned the two disjoint tools and tests. Astra reviewed amendment design, exact source/history/runtime admission and result evidence. Parent integrated and executed. Separate diagnostic identities allow useful bounded validation without misrepresenting historical provenance.

## 12. Cross-Product Coverage

Covers complete four-trait Gaussian pedigree automatic K0/K1 diagnostic fitting at eight N/signal combinations using the full frozen reference schedule. This does NOT cover the omitted N80-null cell, pilot rates, confirmation, interval calibration, repeatability profiles, reconstructed R parity, GPU, other models, releases or public capability promotion.
