# After-task: CI push trigger for main/master (#367)

Date: 2026-09-24
Lane: Julia `cursor/post366-t7-ci-push-367` (overnight T7)
Fence: experimental 0.9.0 / `public_covered_count` 7; no covered flip; no
science / reml / loglik edits

## What landed

`.github/workflows/CI.yml` now triggers on `push` to `main` and `master` as
well as `pull_request` and `workflow_dispatch`. Direct pushes therefore run the
four-leg test matrix without a manual `gh workflow run`.

Also added a `concurrency` block with
`cancel-in-progress: ${{ github.event_name == 'pull_request' }}` so rapid
merges to main cannot cancel each other's CI evidence. PR re-pushes still
cancel the superseded PR run.

`workflow_dispatch` input `run_plotting` stays dispatch-only.

## Checks

YAML parse of `CI.yml` (see `docs/dev-log/check-log.d/2026-09-24-ci-push-trigger-367.md`).
No `Pkg.test()` required: workflow-only change.

## Not done / out of scope

- Stacked-PR `pull_request` branch-filter gap (#367 comment): still needs a
  separate Grace decision (drop `branches:` vs document retarget-to-main).
- `Documenter.yml` still has unconditional `cancel-in-progress: true`; not
  this lane's file; left for a follow-up.

## Rose

No public capability claim, version, or covered-count change. Docs note only
records the trigger gap close.
