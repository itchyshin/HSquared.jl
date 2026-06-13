---
name: rose-pre-public-audit
description: Audit hsquared public claims before making repos public, updating README/DESCRIPTION, opening issues, adding badges, or publishing docs. Use to separate implemented, partial, planned, blocked, and missing capabilities.
---

# Rose Pre-Public Audit

## Procedure

1. Read:
   - README.md
   - DESCRIPTION
   - ROADMAP.md
   - `docs/design/06-public-claims-register.md`
   - `docs/design/capability-status.md`
   - `docs/design/validation-debt-register.md`
2. Search for overclaims:

```sh
rg "fits|estimates|fast|ASReml-level|implemented|supports|Julia speed" README.md DESCRIPTION ROADMAP.md docs
```

3. Check each claim against evidence.
4. Rewrite unsupported claims as planned, target, roadmap, or scaffold.
5. Record the verdict in the check log or after-task report.

## Output

Return clean, blocked, or clean-with-limitations.
