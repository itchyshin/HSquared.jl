# H3 seed freshness audit: remote branch supplement

Reviewer: Codex, read-only source and remote inventory. Date: 2026-10-04.

## Scope

This supplements `tools/mv_h3_rg_seed_audit.py`. It checks the live `origin`
branch inventory and reads one already-local commit object. It does not fetch,
allocate seeds, run a fit or simulation, or establish seed freshness.

## Evidence

- `git ls-remote --heads origin` completed as a read-only query after the
  sandbox denied its default-network attempt.
- A filtered query for branch names containing `h3`, `366`, `arc1`, or
  `coverage` found:
  - `cursor/09-h1-h3-harness-20260903` at
    `b0f645eebe244176114df79b837affa947b5bbb8`;
  - `feat/2026-07-03-interval-coverage` at
    `c0a33d60b8e947f42c66cf6ebaebaaacc4c690c0`.
- Commit `b0f645eebe244176114df79b837affa947b5bbb8` exists in the local Git
  database. Its retained
  after-task report says the all-campaign run was a one-replicate smoke and
  explicitly says no 2,000-replicate confirmation was run in that slice.
- Its check log records the smoke as exit 0, about 15 seconds, with
  `GATE PATH_ONLY`; every row had `claim_eligible=false`. It reports a
  non-interpretable tiny-cell `h3_ram` result and says the isolated
  `h3_ram` run on seed `20260903` formed an interval. The log records no
  48-replicate screen or confirmation.
- The same predeclaration lists a 48-replicate-per-cell directional screen,
  but the retained check log records only the one-replicate smoke. This audit
  found no evidence that the screen was executed; that is not proof that no
  unretained or external results exist.

## Decision and remaining limits

The remote inventory narrows the seed investigation: the identified remote
H3 harness branch records smoke-only execution. The H3 exclusion inventory
must still report `freshness_verified=false` and `execution_authorized=false`.
The origin query does not inspect untracked remote result stores. The sister-R
doc-34, ignored-directory inventories, and refs with missing objects also
remain unresolved. Do not allocate H3 seeds or launch the screen until those
sources are checked and the independent freshness decision is recorded.

No source code, seed files, simulator outputs, covered-status rows, or
coordination-board entries were changed by this supplement.
