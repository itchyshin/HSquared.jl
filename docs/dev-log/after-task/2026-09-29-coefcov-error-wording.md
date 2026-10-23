# After-task: single-block coefcov error wording

## 1. Goal

Make the payload-v2 error describe the actual unsupported `coefcov` route, then preserve exact-current reviewer and test evidence.

## 2. Implemented

The fit error and public docstring now consistently state that no `coefcov` payload fitting route is wired. The regression checks parsing, the typed `Phase0NotImplementedError`, and matching runtime/doc wording.

## 3a. Decisions and Rejected Alternatives

Kept the frozen parser syntax intact. The parser can recognize the block while the estimator remains unavailable; broadening or deleting the grammar would change the contract beyond the defect.

## 4. Files Touched

- `src/bridge_payload_v2.jl`
- `test/runtests.jl`
- `GATES.md`
- `docs/dev-log/source-review/2026-09-29-coefcov-error-wording.md`
- `docs/dev-log/check-log.d/2026-09-29-coefcov-error-wording.md`
- `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- This report

## 5. Checks Run

- Targeted bridge regression: red before the wording repair, green after it.
- Exact-current Boole review: PASS on the source and test hashes recorded in the receipt.
- Julia 1.10 `Pkg.test()`: exit 0 on the candidate; integrated payload-parser test group 66/66.
- `git diff --check`: run again after this report is written.

## 6. Tests of the Tests

Before the repair, the focused assertion detected the inaccurate multi-block wording. Afterward, it checks the unsupported runtime exception and that the public docstring uses the same bounded phrase.

## 7a. Issue Ledger

- Fixed: error text incorrectly suggested only multi-block `coefcov` was unsupported.
- Deferred: `coefcov` fitting remains unwired; payload schema ratification and whole E1 source review remain open.
- A2 (FA information and recovery) and V3 (twin validation) remain open.

## 8. Consistency Audit

The parser can accept the frozen syntax, while the fit call fails with a typed unavailable-route error. The updated help and runtime error agree. No capability status or public covered count changed.

## 9. What Did Not Go Smoothly

The first local lease attempt could not persist outside the workspace. An escalated call then acquired the required scoped lease. The shared central check log has divergent content on 15 refs, so this slice uses its standalone check-log shard and does not append to that conflicted file.

## 10. Known Residuals

The repair is limited to the wording contract. It does not validate the full bridge contract, `coefcov` estimation, FA/GLLVM R parity, or whole E1/A2/V3 acceptance. No GPU run, release submission, registry action, merge, or tag occurred.

## 11. Team Learning

When syntax is recognized but estimation is deliberately unavailable, name the unavailable fitting route in both runtime errors and public help; avoid describing only one rejected subcase.

## 12. Cross-Product Coverage

This slice covers the Julia payload-v2 parser help, runtime error, and integrated test. It does NOT cover the R emitter, the full bilateral bridge, estimation for `coefcov`, or other result-payload routes.
