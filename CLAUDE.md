# CLAUDE.md

This project's operating doctrine is shared with the `.codex/` prep and the R
twin. The authoritative instructions live in `AGENTS.md` — read them:

@AGENTS.md

## Claude operator notes

- **Lane:** this repo is the **Julia engine lane** (`HSquared.jl`). The R lane
  (`hsquared`) is a twin sister Claude session. Coordinate at every shared-
  contract touch and at each ROADMAP phase boundary; do not edit the R repo from
  here. Durable coordination channel: GitHub issue comments on the mirrored
  ledger (Julia #5/#6/#7 ↔ R #2/#5/#6).
- **Rehydrate first:** at the start of substantial work, run the
  `hsquared-rehydrate` skill (live git/CI state + `ROADMAP.md`,
  `docs/dev-log/coordination-board.md`, `docs/dev-log/check-log.md`, newest
  after-task report, `docs/design/01-v0.1-contract.md`,
  `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`).
- **Skills** live in `.claude/skills/` (symlinks into `.agents/skills/`) — invoke
  via the Skill tool. **Review-lens subagents** live in `.claude/agents/` — spawn
  via the Agent/Task tool when a slice warrants a named lens (Ada, Shannon,
  Hopper, Henderson, Gauss, Fisher, Curie, Grace, Rose, Pat, …). Say explicitly
  when a subagent is actually running vs. used as a review perspective.
- **Definition of Done** (per `AGENTS.md`): implementation + tests + docs +
  capability-status row + validation-debt row + check-log evidence + after-task
  report + Rose audit + clean local checks (+ clean CI if pushed).
- **Local checks over CI:** run `julia --project=. -e 'using Pkg; Pkg.test()'`
  and `julia --project=docs docs/make.jl` locally before pushing.
- **Honest status:** no fitting / performance / GPU / genomics / QTL / GLLVM
  claim without the full evidence chain. Repository state — not chat — is the
  source of truth.
