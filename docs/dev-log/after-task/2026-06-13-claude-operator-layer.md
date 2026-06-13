# Claude Operator Layer

Active lenses: Ada, Shannon, Grace, Rose, Pat.
Spawned subagents: none.

## Goal

Mirror the `.codex/` agent preparation on the Claude side so this Julia-lane
thread operates with the same review-lens roster, skills, and doctrine as the
Codex prep. Operator configuration only — no engine or contract change.

## Files Changed

- `CLAUDE.md` (new)
- `.claude/agents/*.md` (new; 21 review-lens subagents)
- `.claude/skills/*` (new; 11 relative symlinks into `.agents/skills/`)

## Implementation

- Converted each `.codex/agents/<stem>.toml` to `.claude/agents/<stem>.md` with
  a deterministic Julia `TOML`-stdlib script: frontmatter `name` = file stem,
  `description` preserved, `model_reasoning_effort = "high"` → `model: opus`
  (else inherit), `developer_instructions` → markdown body. 11 high-effort
  lenses map to opus (ada, boole, fisher, gauss, henderson, hopper, jason,
  karpinski, kirkpatrick, noether, rose); 10 medium lenses inherit.
- Added `CLAUDE.md` that imports `AGENTS.md` via `@AGENTS.md` (single source of
  truth) plus Claude operator notes: lane boundary, rehydrate → overlap-check →
  after-task loop, Definition of Done, local-checks-over-CI, honest status.
- Added `.claude/skills/<name>` as relative symlinks to `../../.agents/skills/<name>`
  for all 11 skills, sharing the canonical `SKILL.md` with the `.codex`/OpenAI
  bindings (matches the user's global `~/.claude → ~/.agents` pattern).

## Checks

- 21 agent files written and listed; sample frontmatter verified valid —
  `rose-systems-auditor` carries `model: opus`, `curie-validation-tester`
  inherits (no `model` line). Both bodies carry the lens persona.
- All 11 skill symlinks resolve to a readable `SKILL.md` (checked with
  `test -f`/`readlink`).
- No Julia source or docs were touched, so the engine and the green test state
  (515 checks at `a723da2`) are unaffected. The full `Pkg.test()` runs with the
  Phase B engine slice before pushing.

## Public Claim Audit

Allowed wording:

- The Julia lane has a Claude operator layer (`.claude/agents`, `.claude/skills`,
  `CLAUDE.md`) mirroring the `.codex/` prep.
- It is operator configuration only.

Blocked wording:

- any new engine, bridge, payload, capability, fitting, or performance change;
- any claim that the agents change package behavior.

## Tests Of The Tests

Not applicable — no package tests were added. Verification was structural:
file count, frontmatter validity, and symlink resolution.

## Coordination Notes

R lane = running Claude session `hsqaured`. Coordination cadence: contract +
phase stops, via GitHub issue comments (Julia #5/#6/#7 ↔ R #2/#5/#6). Direct
`send_message` is blocked in the current unsupervised mode; the durable channel
is GitHub issues. This slice is Julia-lane-internal operator config; no R-lane
action required. Note: during this slice the repo advanced `a723da2 → 270e7b2`
("Add sparse REML validation optimizer"); detected via repo state, so this
operator layer was kept distinct and the engine slice was not duplicated.

## What Did Not Go Smoothly

- Direct session-to-session messaging (`send_message`) is unavailable in
  unsupervised mode; fell back to GitHub issue comments as the coordination
  channel.
- Whether the freshly written `.claude/agents` resolve as `agentType` in the
  current session's registry is unverified; the Phase B review workflow will
  embed each lens persona inline as a fallback so the review does not depend on
  in-session registry refresh.

## Known Limitations

- `.claude/agents` are committed but in-session `agentType` resolution is not
  yet confirmed.
- `CLAUDE.md` `@AGENTS.md` import takes effect on the next session load.
- Committed symlinks are macOS/Linux-friendly; Windows collaborators would need
  copies instead.

## Next Actions

1. The Phase B sparse REML optimizer (`fit_sparse_reml`, `target = :sparse_reml`)
   already landed on `main` at `270e7b2` (Julia lane; CI `27466629703` +
   Documenter `27466629704` + Pages green; local suite 543 checks pass). This
   operator-layer slice does not re-implement it.
2. Run the ultracode review fan-out (Gauss · Karpinski · Curie · Fisher) + Rose
   audit on the landed `270e7b2` slice to independently verify it.
3. Continue the Phase 1 frontier: fitted Mrode output validation + external
   comparators (the recurring `V1-*` validation gap).
