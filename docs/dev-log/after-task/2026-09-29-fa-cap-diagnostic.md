## 1. Goal

Record bounded ordinary-start iteration-cap diagnostics and verify an independent same-model Gaussian FA/REML comparator against the current Julia source for the existing four-trait, rank-one pedigree cell. Keep the frozen two-hundred-seed primary method unchanged.

## 2. Implemented

- Ran three fresh development seeds at the frozen five-thousand cap and reran the two nonconverged seeds at ten thousand, using the preregistered same-data diagnostic allowance. Repeated the independent Gaussian FA/REML comparison against the current Julia source hash to resolve comparator provenance.
- Recorded per-seed outcomes, runtime, source and driver hashes, updated primary-study estimate, and limits in the preregistration, GATES.md, check-log.md, and coordination board.
- Made no source, test, public API, capability-status, or primary-method changes.

## 3a. Decisions and Rejected Alternatives

- Kept the optimizer default unchanged. Six five-thousand-cap development fits recovered in three cases and did not converge in three. Same-data ten-thousand-cap diagnostics converged in all three cap-exhausted cases, but one still missed the frozen residual covariance error threshold. This is not enough evidence for a reliable ten-thousand default.
- Did not start the two-hundred-seed primary run. The updated estimate is about 8.5 hours including a two-times margin plus startup, so explicit approval is required.
- Kept near-floor uniqueness separate from convergence and covariance recovery. All three selected ten-thousand-cap diagnostic fits had uniqueness within one percent of the absolute floor.

## 4. Files Touched

- docs/dev-log/recovery-checkpoints/2026-09-28-fa-ordinary-start-prereg.md
- GATES.md
- docs/dev-log/check-log.md
- docs/dev-log/coordination-board.md
- docs/dev-log/after-task/2026-09-29-fa-cap-diagnostic.md
- docs/dev-log/scout/2026-09-27-fa-same-model-reference.md

## 5. Checks Run

- Verified the Julia source hash before and after the Totoro runs: 68f1ec986764e06417381008405f492a3bd8da9d8399bbf8511f4467f31ecc55.
- Ran development seeds 20261403, 20261404, and 20261405 at five thousand iterations. One recovered; two did not converge. Total fit time was 256.05 seconds.
- Reran seeds 20261403 and 20261405 at ten thousand iterations. Both converged; seed 20261403 met the fixed recovery criteria, while seed 20261405 had relative R error 0.25657 against the 0.25 threshold.
- Combined with prior development seeds 20261400 to 20261402, five-thousand-cap recovery was 3/6. The estimated primary runtime is 200 × 75.91 seconds × 2, plus startup, about 8.5 hours.
- Totoro process check found no Julia process after completion. tools/totoro_hygiene.sh reported zero zombies, stopped supervisors, stale watchers, or busy processes.
- The raw cap outputs and diagnostic driver remain in /private/tmp; their paths and SHA-256 values are recorded in the preregistration. The source-pinned comparator logs and harness hashes are recorded in the scout note.

## 6. Tests of the Tests

No source behavior or test assertions changed. The development-mode driver rejects any seed in the frozen primary stream. It wrote all requested development rows, including two nonconverged five-thousand-cap results and the later ten-thousand-cap diagnostics.

## 7a. Issue Ledger

- Found: a five-thousand cap can prevent convergence for some tested starts.
- Found: ten thousand iterations did not guarantee meeting the frozen covariance recovery criterion.
- Deferred: estimate population recovery and default-start reliability with the held primary campaign, after explicit approval.
- Open: uniqueness information and near-floor interpretation.

## 8. Consistency Audit

Checked the current GATES and coordination board against test/runtests.jl and the newer recorded R bridge checks. Rose's audit caught an overstatement about comparator source provenance. Reran the independent comparator on current Julia source hash 68f1ec986764e06417381008405f492a3bd8da9d8399bbf8511f4467f31ecc55, verified unchanged before and after the fit, and recorded the one-fixture result and limits. Rose's second pass caught two truncated scratch-log hashes; both now match the files. Corrected stale wording that the FA multistart test was not registered and that the earlier red bridge diagnostics contract was still current. The FA capability remains partial, and the source-review, inference, and validation gates remain open.

## 9. What Did Not Go Smoothly

The first lane-lease attempt could not write its registry outside the workspace sandbox. The exact-file lease was then claimed with the required elevated permission. The first Julia comparator launch could not write the existing Julia compilation cache; the same command succeeded after the narrowly scoped cache access was approved. The closeout generator uses the Shinichi vault as its root, so its relative path resolved outside the package worktree. The after-task structure check passed, but its acceptance-ledger check correctly reported unmet top-level FA, GLLVM, and source-review gates; this slice leaves those gates open.

## 10. Known Residuals

- The development sample is too small to estimate population recovery or justify a new default.
- The primary run is still held for approval. Its current estimate is about 8.5 hours with the required margin.
- The source-pinned same-model comparator now matches the current Julia source hash `68f1ec986764e06417381008405f492a3bd8da9d8399bbf8511f4467f31ecc55` for one truth-informed fixture. Ordinary-start equivalence, population recovery, and uniqueness information remain open.
- No hosted CI or R checks were run in this diagnostic slice.

## 11. Team Learning

Memory receipt: route.py found no LOAD-FIRST manifest for this managed worktree. The repository AGENTS.md, existing GATES.md, FA preregistration, and the local lane preflight shaped the scope. Notebook or external package research was not needed. The numerical review and R bridge control audit were read-only specialist agent work.

Golden Set: not in scope because this slice changed no model code, public API, or test behavior.

## 12. Cross-Product Coverage

Covers: Julia ordinary-start FA diagnostics for one Gaussian pedigree cell, exact source version, fixed five-thousand primary cap, ten-thousand same-data cap checks, and the current recorded R bridge status.

Does NOT cover: a population recovery rate, a new iteration default, broad FA ranks or designs, local uniqueness information, uncertainty calibration, non-Gaussian FA, missing responses, Bernoulli traits, automatic rank selection, full R package checks on this slice, the GLLVM capability, whole-wave Julia source-review signoff, GPU execution, or any release action.
