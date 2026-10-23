# After-task: 0.9 Gate-B Julia exact-head candidate

## 1. Goal

Create a fresh, isolated Julia 0.9.0 candidate from PR #322's exact head and
prepare evidence without changing the ratified A3/A4 public contract or taking
any release action.

## 2. Implemented

The candidate has 0.9.0 candidate metadata, an unreleased citation fence, and
current-facing documentation reconciled to the 0.9.0 candidate/count 7. Its
generated status documentation calls the non-Gaussian GLLVM objective the
Laplace marginal likelihood. The historical function name is retained; exact
REML is stated only for the Gaussian reduction. Codex held the narrow Julia
lease; no subagents were used.

## 3a. Decisions and Rejected Alternatives

The candidate began at `99a1af2eb765d7dd7d8aea1eb642909c9af718e7` (PR #322).
The older 0.9 candidate was divergent and could not be replayed wholesale
without losing its newer A3/A4 changes. The rejected alternative was wholesale
replay; only metadata and honesty corrections were reconciled.

## 4. Files Touched

`Project.toml`, `CITATION.cff`, `README.md`, the capability/backlog status
notes, the generated validation-status page, `src/validation_status.jl`, and
its assertions in `test/runtests.jl`.

## 5. Checks Run

- focused `validation_status()` contract: pass;
- `julia --project=docs docs/make.jl`: pass, with pre-existing undocumented
  docstring warnings and local deployment intentionally skipped;
- `julia --project=. -e 'using Pkg; Pkg.test()'`: pass;
- Unlazy `J0`–`J5`: all pass;
- `git diff --check`: pass.

## 7a. Issue Ledger

- `JL-GATEB-ENV-01` resolved: `Optim` was absent from the local depot; the
  declared dependencies were materialized without source changes.
- `JL-GATEB-TERMS-01` resolved: the status row used a non-Gaussian REML label
  despite a Laplace marginal objective.
- `JL-GATEB-DOCSYNC-01` resolved: reader-facing 0.8.0/count-6 wording was
  stale against the candidate and is now corrected or explicitly historical.
- `JL-GATEB-RELEASE-01` deferred: remote CI, independent audit, merge, tag,
  registry action, and release remain outside this candidate.

## 8. Consistency Audit

The candidate labels 0.9.0 as experimental and unreleased, leaves
`public_covered_count` at 7, preserves opt-in routes, and does not promote any
capability. It corrects the non-Gaussian GLLVM terminology: its objective is a
Laplace marginal likelihood, not REML; exact REML is only the Gaussian
reduction.

## 6. Tests of the Tests

The status-row test asserts the row ID and decisive wording. The generated
Documenter page was rebuilt and checked for the renamed row. The full package
suite passed, including A3 and A4 tests.

## 9. What Did Not Go Smoothly

The exact-head environment initially lacked `Optim`; `Pkg.instantiate()` and
precompilation materialized only recorded dependencies and left the worktree
clean. The desktop command relay detached verbose gate jobs, so the final
Unlazy run used short, bounded gate output and completed normally.

## 10. Known Residuals

This is local/macOS evidence only. No fresh GitHub CI run, external registry
check, tag, merge, release, or independent Gate-B panel has occurred. The
version metadata is a candidate marker, not a release assertion.

## 11. Team Learning

When an older candidate diverges from a newer science branch, replay only the
minimal metadata/claim corrections after comparing both histories; do not use
the older candidate as a destructive integration base.

## 12. Cross-Product Coverage

The terminology correction covers the Julia status accessor, generated
documentation, candidate README wording, and source assertions. It does NOT
cover an estimator change, non-Gaussian calibration, external comparators, R
bridge/public API work, CI on other platforms, capability promotion, or release.
The 0.9.0 candidate metadata does NOT cover a tag, registry entry, CRAN
submission, GitHub release, merge, or public availability.

## Next actions

Commit this isolated candidate, run the independent final audit and paired
R–Julia evidence reconciliation, then only open replacement PRs if those
gates pass. Gate B remains unexecuted.
