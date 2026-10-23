## 1. Goal

Align the Julia-local formula-status test and roadmap wording with the
experimental `engine bridge` status label.

## 2. Implemented

The status test now expects only reserved and planned rows to be unavailable.
The roadmap describes the engine-bridge, reserved, and planned rows consistently.
The model-grammar page distinguishes the existing experimental validation-scale
sparse REML optimizer from broader production sparse fitting. The capability
table scopes its backend-roadmap statement and points to the separate bounded
experimental GLLVM row. No model or capability status changed.

## 3a. Decisions and Rejected Alternatives

Kept the Julia diagnostic local to the engine. The R twin owns formula parsing;
matching columns do not imply matching inventories or parser behavior.

## 4. Files Touched

- `test/runtests.jl`
- `docs/src/roadmap.md`
- `docs/src/model-spec-grammar.md`
- `docs/design/capability-status.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-09-29-julia-formula-status-contract.md`
- `docs/dev-log/after-task/2026-09-29-julia-formula-status-contract.md`

## 5. Checks Run

- Focused Julia assertions for the 20-row status table passed.
- Full Julia 1.10 `Pkg.test()` passed, ending `Testing HSquared tests passed`.
  The existing Project/Manifest mismatch warning remains; no resolve or update
  was run.
- Documenter and VitePress built successfully in an isolated temporary copy
  after the wording repairs. The generated validation-status page matched the
  candidate byte-for-byte, and the rendered grammar and roadmap pages contain
  the corrected scope. Existing warnings include 47 undocumented docstrings,
  local-build deployment skipped, and bundle size.
- Rose reviewed the exact current formula-status and adjacent wording. The two
  reported claim conflicts are resolved. This is wording review only, not full
  FA/GLLVM or source-review signoff.
- `git diff --check` passed. The memory regression self-test passed.
- The after-task structure check passed. The full closeout compiler remains
  red because the active acceptance ledger still has open gates for this larger
  goal; I did not mark those gates abandoned or complete.
- Lane preflight found one visible lane but a 16-day-old handover claiming
  Claude ownership. No additional active competing lane appeared in its census.

## 6. Tests of the Tests

The old predicate classified `engine bridge` as unavailable because it excluded
only the obsolete `parsed` label. The table explicitly pins the first row's
engine-bridge fitting status and separately checks all reserved/planned rows.
The full suite exercised the corrected assertions.

## 7a. Issue Ledger

- Fixed: stale test predicate left behind by the status-label correction.
- Fixed: roadmap summary still called the first status `parsed`.
- Fixed: grammar page said sparse animal-model fitting was wholly planned,
  obscuring the experimental validation-scale sparse REML route.
- Fixed: backend-roadmap capability row could be read as denying the separate
  bounded GLLVM route.
- Rose's exact-current review passed this wording slice after the fixes. This
  does not provide full Rose signoff for the twin programme.

## 8. Consistency Audit

Checked the Julia status table, its integrated test, README, engine contract,
capability and validation-debt wording, public-claims register, model grammar,
backend roadmap, and roadmap. The current docs distinguish the Julia diagnostic
from the R parser and separate experimental sparse and GLLVM routes from planned
broader scope. Historical changelog and archived reports retain their original
descriptions.

Rose's exact-current re-review passed the adjacent wording at these hashes:
`src/planned_terms.jl` `a47d953d72565f347db805b5d0c7bdc86d5440dedaa6454c674f6e48c9607d5c`,
`docs/src/model-spec-grammar.md`
`6320c1916e26683a6d2825955434ae74125179c57cb99efa7449cf11abf2229c`, and
`docs/design/capability-status.md`
`df599ef0566883297f79d0f9fe7b7165a4956e104afdd89f49b2e475a4829c5e`.

## 9. What Did Not Go Smoothly

The first docs build in the temporary copy lacked a valid Git origin and stopped
before rendering. Adding the candidate's configured origin allowed the build to
complete. The repository closeout generator resolved the Dropbox brain root
from this worktree and could not write there, so this report was created in the
candidate repository and checked directly. Its first check failed because the
required memory and Golden Set fields were missing; they were added before the
final check.

## 10. Known Residuals

The worktree contains broader uncommitted changes owned by the ongoing HSquared
goal. This report closes only the formula-status consistency correction. E1,
A2, V3, FA and GLLVM acceptance, and full source-review signoff remain open.
The stale-hand-over warning remains for coordination follow-up.

## 11. Team Learning

When a diagnostic changes a status vocabulary, update tests and reader-facing
summaries together. Keep public parser ownership explicit at every boundary.
Memory receipt: routed manifest identified the Julia/R boundary and acceptance
gates; lane preflight found only the candidate lane but a stale handover claiming
Claude ownership. I did not change lane ownership.

Golden Set: `memory_regression.py --selftest` passed all detectors.

## 12. Cross-Product Coverage

This does NOT cover R parsing behavior, R/Julia parser parity, FA or GLLVM
fitting acceptance, recovery calibration, GPU execution, or release readiness.
It covers only the Julia-local formula-status labels and their documentation.
