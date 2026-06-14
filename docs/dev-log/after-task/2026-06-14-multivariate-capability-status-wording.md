# After-Task Report: Multivariate Capability-Status Wording

## Task Goal

Remove a stale capability-status wording contradiction after Phase 4 and Phase
4B multivariate engine utilities landed on the PR branch.

## Active Lenses And Spawned Agents

- Active lenses: Rose, Shannon.
- Spawned subagents: none.

## Files Changed

- `docs/design/capability-status.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-14-multivariate-capability-status-wording.md`

## Checks Run

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed with known local
  Documenter/VitePress caveats.
- `git diff --check`: passed.

## Public Claim Audit

The stale row said "Multivariate G matrices" were planned with no
implementation. That was no longer honest beside the current Phase 4 and Phase
4B rows. The replacement row narrows the planned item to the public
multivariate G-matrix model-spec / syntax surface.

No capability is promoted:

- experimental Julia engine utilities remain experimental;
- public R-facing multivariate syntax remains planned;
- long-format interface remains planned;
- external comparator parity remains planned;
- bridge payload remains unchanged.

## Tests Of The Tests

No test code changed. The slice is documentation/status wording only.

## Coordination Notes

This is a Julia status-ledger cleanup. It does not require R code changes and
does not change the shared bridge contract.

## What Did Not Go Smoothly

The stale row was spotted during the PR body refresh rather than during the
first extractor edit. The fix is deliberately narrow.

## Known Limitations

The capability-status table still separates engine-internal experimental rows
from public R-facing syntax rows. That duplication is intentional for claim
discipline, but it requires continued maintenance.

## Next Actions

- Commit and push this wording cleanup.
- Record remote CI on PR #17 if pushed.
