# Issue #503: `information` kwarg validation and plot data switch

Date: 2026-11-12. Lane: Julia bounded test-and-fix sweep (Shinichi-approved).
Branch `cursor/se-information-kwarg-validation-c560`, draft PR #502.

## Goal

Close the regression gap after #500: String `information` values from bridges
must not surface as `TypeError`, and `variance_components_plot_data` must honour
the same `information` / `fd_step` choice as the standalone SE helpers.

## Lenses (review perspective only; no subagents spawned)

Gauss, Karpinski, Hopper (bridge-facing errors), Grace (CI hygiene).

## Files changed

- `src/likelihood.jl`: `_validate_information` rejects non-Symbols; untyped
  `information` keywords; `variance_components_plot_data` forwarding.
- `test/test_issue_503_information_kwarg.jl`: regression for #503.
- `test/runtests.jl`: include.
- `docs/src/changelog.md`: Unreleased bullet.
- `docs/dev-log/check-log.md`: receipt.

## Checks

Julia 1.10.13, `OPENBLAS_NUM_THREADS=1`:

| Check | Outcome |
|-------|---------|
| `include("test/test_issue_503_information_kwarg.jl")` | 12/12 |
| `include("test/test_se_information_switch.jl")` | 19/19 |
| `bash tools/preamble_cap.sh` | OK |

Hosted CI on pushed head: pending (standard four-leg matrix + docs).

## Public claim audit (Rose lens, read-only)

Bugfix only: defaults unchanged; no new fitted capability; changelog states no
string coercion. No `capability-status.md` or validation-debt edit.

## Tests of the tests

On `main` (`a4b7894a`), the type-validation testset fails 6/7 (`TypeError` /
`MethodError` vs `ArgumentError`); the plot-data testset fails on missing
`information` kwarg. With the fix, 12/12.

## Coordination

Issue filed as #503. No R-lane or parity change in this PR.

## Limitations / next

Full `Pkg.test()` not re-run on this slice after the rename/commit; rely on
focused regression + CI. String coercion deliberately out of scope per owner.

## Issue ledger

Closes #503 when PR #502 merges.
