---
name: formula-contract-review
description: Review hsquared formula, covariance, and relationship grammar. Use when adding or changing R syntax, Julia formula equivalents, unsupported-syntax errors, examples, docs, or the R-Julia model specification.
---

# Formula Contract Review

## Procedure

1. Identify the formula surface being changed.
2. Check `docs/design/02-formula-grammar.md`.
3. Check `docs/design/01-v0.1-contract.md` for current scope.
4. Ask Boole: is the syntax memorable, parseable, and consistent?
5. Ask Noether: do syntax, equations, and engine target describe the same
   object?
6. Ask Rose: does public wording distinguish implemented, planned, and missing?

## Required Output

- accepted syntax;
- rejected or deferred syntax;
- user-facing error wording;
- files that need synchronized updates.
