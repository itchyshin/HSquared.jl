---
name: validation-canon-review
description: Review hsquared validation evidence, benchmarks, simulation studies, Mrode examples, comparator runs, and validation debt rows. Use before moving a capability from planned or partial to covered.
---

# Validation Canon Review

## Procedure

1. Read `docs/design/04-validation-canon.md`.
2. Read `docs/design/validation-debt-register.md`.
3. Confirm the estimator, model, and scale match the comparator.
4. Prefer tiny deterministic checks before broad simulations.
5. Record seeds, versions, commands, and outcomes in the check log.
6. Move capability status only when evidence supports it.

## Lenses

- Curie: test and simulation fidelity.
- Fisher: inference and estimator target.
- Mrode: textbook animal-model canon.
- Rose: claim-vs-evidence audit.
