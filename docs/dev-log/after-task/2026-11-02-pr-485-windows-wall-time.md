# After-task: PR 485 Windows #415 wall-time flake

## 1. Goal

Restore a green hosted matrix on PR #485 after the 2 Nov `origin/main`
merge (`62ab7c8d` via `d3bd5067`). Do not force-push. Do not merge.

## 2. Implemented

Widened the imported `#415` sparse `:two_effect` n = 2000 wall-time guard
from 10.0 s to 15.0 s. Hosted Julia 1.13 Windows recorded 10.207 s on
job 125392634656. The dense route remains ~1900 s, so the guard still
catches a scale_method regression.

Active lenses: Grace (CI flake), Rose (no claim change). No subagent
was spawned.

## 3. Decisions and rejected alternatives

Rejected skipping the guard on Windows: the check still has value if it
has slack for runner jitter. Rejected lowering n or changing
`scale_method` defaults. Rejected editing `GATES.md` or capability
status.

## 4. Files touched

- `test/test_issue_415_two_effect_sparse_route.jl`
- `docs/dev-log/check-log.d/2026-11-02-pr-485-windows-wall-time.md`
- `docs/dev-log/after-task/2026-11-02-pr-485-windows-wall-time.md`

No `src/`, changelog, capability-status, validation-debt, or
coordination-board edit.

## 5. Checks run

- Hosted pre-fix: Julia 1.10 ubuntu/windows success, Julia 1 ubuntu
  success, docs success, Julia 1 windows-latest failure at 10.207 s.
- Focused #415 file and `git diff --check` on this head.
- `bash tools/preamble_cap.sh` and `bash tools/build_check_log.sh --check`.
- Hosted matrix on the new head is owed before a new Ready comment.

## 6. Tests of the tests

The widened bound still fails a ~1900 s dense path. Convergence of the
sparse route is unchanged.

## 7. Issue ledger

- Advanced: #485 CI only. #408 stays open (JIT, R bridge, lazy PEV,
  near-boundary NaN SEs, FD-vs-AI).
- #415 stays open. This does not land the sparse route as covered.

## 8. Public claim audit (Rose perspective)

No public timing, capability, or coverage wording. Test comment cites
one hosted job, not a benchmark.

## 9. What did not go smoothly

Someone merged current main into #485 after the earlier Ready comment.
The imported #415 guard then failed on Julia 1 Windows only.

## 10. Known residuals

Hosted CI on this head is owed before "Ready for Shinichi's merge OK".
#408 remains open. The same 10.0 s bound is still on `main` and on
PR #488 until those heads pick up this change.

## 11. Next actions

Push, wait for the hosted matrix, then comment Ready with the new
run evidence. Do not merge. Do not push `main`.

## 12. Cross-product coverage

Julia test-only. Does not cover the R lane or a #415 close.
