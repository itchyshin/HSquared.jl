# After-task: Arc 1 N80/null bootstrap refusal (#478)

## 1. Goal

Record the explicit `insufficient_usable_bootstrap` refusal for N80/null in
the Arc 1 feasibility note and close that diagnostic. Binding source:
Decision (Shinichi, 25 Oct 2026) on #478. G4 stays open.

## 2. Implemented

Docs-only. Added
`docs/dev-log/arc-program/2026-10-30-arc1-n80-null-feasibility.md` with the
retained outer-2 and outer-14 counts, the off-repo evidence path, the
outer-14 SHA-256, and the linked #476 no-jitter finding. No source, test,
freeze, seed, or `GATES.md` change.

Active lenses: Rose (claim vs evidence, docs-only). No subagent was spawned.

## 3. Decisions and rejected alternatives

Accepted the #478 decision: stop trying to improve selector reliability for
this cell and retain the refusal. Accepted the #476 decision: no covariance
jitter on K1 starts. Rejected rewriting `GATES.md` or treating the
diagnostic as calibrated coverage.

## 4. Files touched

- `docs/dev-log/arc-program/2026-10-30-arc1-n80-null-feasibility.md`
- `docs/dev-log/check-log.d/2026-10-30-arc1-n80-null-bootstrap-refusal.md`
- `docs/dev-log/after-task/2026-10-30-arc1-n80-null-bootstrap-refusal.md`

No `src/`, `test/`, `GATES.md`, coordination-board, capability-status, or
validation-debt edit.

## 5. Checks run

- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: green.
- `bash tools/build_check_log.sh --check`: expected to pass on this shard
  shape (dated filename, ATX heading, body).
- No package tests or docs build: no code or public docs page changed.

## 6. Tests of the tests

None. This slice adds no test.

## 7. Issue ledger

#478 is the diagnostic this note is meant to close on merge (`Closes #478`).
#476 remains a separate not-planned repair (no jitter); its finding is
copied into the note so the unresolved K1 result is durable. G4 stays open.
G2-G8 remain open. `public_covered_count` remains 7.

## 8. Public claim audit (Rose perspective)

The note states formation failure only. It names the frozen 198-usable bar,
the two shortfalls (196 cap; 184/199), the refusal token, and the SHA of
the retained outer-14 result. It does not claim coverage, selector
improvement, gate credit, or a capability promotion.

## 9. What did not go smoothly

The retained bootstrap bodies live under `LOOP/lanes/...` off this
repository. The note cites that path and the published SHA; it does not
copy the LOOP tree into the repo.

## 10. Known residuals

G4 remains open. No current-source G6/G7 freeze (#475). No complete
source-bound nine-cell G2/G3 bundle (#474). Totoro thread sweep (#364)
still needs the owner machine.

## 11. Next actions

Merge this record when hosted docs/CI on the PR are green. Close #478 only
from that merge (or with the note on `main`). Do not rerun consumed seeds.
Do not edit `GATES.md` from this finding.

## 12. Cross-product coverage

Julia-lane documentation only. It does not change `hsquared`, the bridge,
or any fitted route.
