---
name: hsquared-rehydrate
description: Rehydrate the hsquared or HSquared.jl project before substantial work. Use when resuming a thread, starting a new slice, recovering after interruption, checking coordination state, or preparing edits that depend on repo, CI, roadmap, or twin-lane status.
---

# hsquared Rehydrate

## Procedure

1. Start from live repository state:

```sh
git status --short --branch
git remote -v
git log --oneline --decorate -5
```

2. Check CI when the repo is on GitHub:

```sh
gh run list --limit 5
```

3. Read the durable memory surfaces:

- `AGENTS.md`
- `ROADMAP.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- newest `docs/dev-log/after-task/*.md`
- `docs/design/01-v0.1-contract.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`

4. Report:

- active branch and cleanliness;
- current lane and owner;
- latest checks;
- current blockers;
- smallest safe next action.

## Rule

Private memory may suggest where to look. Repository state decides what is
true.
