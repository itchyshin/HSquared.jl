# Team And Memory Operating System

`HSquared.jl` uses repo-visible coordination rather than private memory alone.

## Coordination Model

The project has two package lanes:

- R lane: `hsquared`, the user-facing package.
- Julia lane: `HSquared.jl`, the computational engine.

Ada coordinates. Shannon checks lane overlap. Named team members are review
lenses unless actual subagents are explicitly spawned.

## Status Update Template

Use:

```text
Ada active. Lenses engaged: Boole, Henderson, Hopper, Rose. No spawned
subagents running.
```

If a real subagent is running, name it separately.

## Repo-Visible Memory

Keep durable memory in:

- `AGENTS.md`
- `ROADMAP.md`
- `docs/design/`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/`
- `docs/dev-log/recovery-checkpoints/`
- `docs/dev-log/decisions/`
- `docs/dev-log/scout/`

Chat memory can suggest where to look. Repository state decides what is true.

## Shared File Rule

Before editing shared files, check for overlap:

- `AGENTS.md`
- `ROADMAP.md`
- capability status
- validation debt
- R-Julia contract
- public syntax docs

Do not let two agents edit the same shared contract at once.
