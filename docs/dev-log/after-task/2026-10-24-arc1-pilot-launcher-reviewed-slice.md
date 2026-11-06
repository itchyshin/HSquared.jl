# Arc 1 pilot launcher reviewed slice

## 1. Goal

Implement and review a one-thread-per-job launcher/admission for the eight unrun FA-rank pilot cells. Do not start fits.

## 2. Implemented

The candidate launcher requires a hash-pinned consumed-attempt history and matching review receipt before admitting a batch. It checks new seeds against consumed history and across pilot cells, revalidates the history on plan resume, checks root listing scope and path containment, and compares each parsed attempt record with its history identity using the same bytes whose hash was verified. It also hashes and parses the measured pre-run receipt from one byte snapshot. The launcher still requires a separate measured pre-run receipt and owner authorization before execution.

## 3a. Decisions and Rejected Alternatives

No pilot execution, seed allocation, or change to scientific thresholds was made. No claim of complete historical seed discovery is made from self-attested inventory fields.

## 4. Files Touched

- `sim/arc1/run_pilot_cells.py` (new candidate launcher)
- `test/test_arc1_pilot_cells.py` (new synthetic contract tests)
- `docs/dev-log/after-task/2026-10-24-arc1-pilot-launcher-reviewed-slice.md` (this report)

All files are in the Codex worktree. No Dropbox checkout, recovery tree, isolated R tree, protected checkpoint, freeze, gates file, or coordination board was edited.

## 5. Checks Run

- `python3 test/test_arc1_pilot_cells.py`: **33 tests passed**.
- Focused source-record identity mismatch test before the implementation fix: **failed as expected** because the plan was incorrectly accepted.
- Same focused test after the fix: **passed** as part of the 33-test suite.
- Receipt read-race test before the implementation fix: **failed as expected** when a simulated second read raised an error; after the fix, the hash-verified bytes authorize correctly.
- Retained candidate batch, plan-only mode: exit code **2**, `launcher_rejected`, with no plan or other output written because reviewed consumed-attempt history is missing.
- `git diff --check -- sim/arc1/run_pilot_cells.py test/test_arc1_pilot_cells.py`: **passed**.
- Exact file preflight reported no missing branch work for `sim/arc1/run_pilot_cells.py`; overall census still reports other live lanes, so this report claims only this authorized slice.
- No Julia process, fit, consumed seed, reference grid, SSH session, commit, push, tag, or release was started.

## 6. Tests of the Tests

Synthetic tests check rejection of missing history, invalid root claims, listing hash mismatch, incomplete listings, unlisted attempt records, source-to-history identity mismatch, and entries outside their declared root. The identity mismatch test was observed failing before its implementation fix and passing afterward. These tests establish checker behavior for the tested contracts; they do not establish that real retained roots were exhaustively searched.

## 7a. Issue Ledger

The launcher candidate remains **not eligible for execution**. The retained pilot batch lacks the required reviewed complete consumed-attempt history. Hashes bind supplied artifacts but cannot prove reviewer identity or that every historical store was enumerated. No pilot gate credit is earned.

## 8. Consistency Audit

The candidate follows the bounded eight-cell, one-thread-per-job scope. It leaves the separate measured pre-run and owner-authorization gates in place. Arc 1 gate status, `public_covered_count=7`, and v7 HOLD were not changed. This slice does not establish G2 or any pilot/confirmation result.

## 9. What Did Not Go Smoothly

Independent review found that earlier code pinned source-file hashes without checking that the source contents matched the attempt identity. A targeted test reproduced the acceptance error. The check was added and then reviewed again.

## 10. Known Residuals

Independent review confirms the identity and containment fixes and identified the receipt read-race, which is now fixed. The remaining material limit is external: the launcher cannot prove the independent reviewer actually searched every retained store or authenticated the reviewer. The root inventory must be separately controlled and reviewed before a measured pre-run can be considered. The existing retained candidate is therefore still refused.

## 11. Team Learning

Hash consistency alone does not bind a historical attempt claim to the contents of its source record. Validate identity fields from the exact bytes whose digest was checked, and keep completeness as an explicit external evidence obligation.

## 12. Cross-Product Coverage

This launcher-only slice does NOT cover the R interface, Julia scientific engine, capability-status row, public grammar, or cross-product contract. It covers only local pilot batch admission and plan validation in the candidate launcher. The R lane and all protected project state remain untouched.

## Next Actions

1. Obtain a separately controlled and independently reviewed inventory covering the retained attempt stores and lineages.
2. Regenerate the eight-cell batch against that evidence and rerun plan-only admission.
3. Measure a bounded pre-run and report its results before requesting separate execution authorization.

The worktree has other pre-existing dirty changes. This slice was not committed. The shared check log and coordination board were not edited because their current dirty/protected ownership was not clear in this worktree.
