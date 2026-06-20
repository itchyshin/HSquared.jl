# 2026-06-19 FA rotation/interpretation convention — decision (doc-only)

- Goal: ratify the deferred factor-analytic / low-rank loading rotation
  convention, so #42 (lowrank/fa bridge exposure) and #55 (evolvability) have a
  settled, identifiable basis. Pairs with #37 (em_fa warm-start).
- Lenses: Fisher (identifiability) + Kirkpatrick (FA / reduced-rank G) proposed
  independently and CONVERGED; Ada ratified. Rose: claim gate.

## Decision (see `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`)

Bridge and do inference ONLY on rotation-INVARIANT functionals of `G` (the
eigenstructure — `genetic_pca`/`g_max`, already shipped in #55 — plus evolvability,
`Ψ`, `G`/correlations/`h²`, eigenvalues). NEVER bridge raw loadings `Λ`; NO SEs on
loadings or individual eigenvectors. Precedent: Kirkpatrick & Meyer (2004) /
WOMBAT / ASReml `xfa`.

## What was done

- New decision note `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`.
- Forward pointer added to the superseded `2026-06-14-loading-rotation-identifiability.md`.
- Capability-status (FA row) + validation-debt `V4-FA` updated: convention is now
  DECIDED (was "defers rotation/interpretation"); the eigenbasis bridge exposure
  is gated on R-lane ratification (#42).

## Commands / results

- Doc-only change — **no `.jl` files touched** (`git diff --name-only` shows only
  `docs/`), so `Pkg.test()` and the Documenter build (`docs/src/`) are unaffected
  and remain green on `main`. The `docs/dev-log/` + `docs/design/` markdown is not
  part of the Documenter site.

## Cross-lane

This widens the bridge contract once exposure is implemented, so per AGENTS.md
rule 2 it is gated on joint R-lane ratification (#42 ↔ R #7). Posted in the #61
coordination note. No engine change lands until the R lane acks.

## Claim boundary

A decision record only — no code, no capability change, nothing bridged yet. The
exposable invariants already exist (from #55 + the multivariate fit); the eigenbasis
bridge payload + structured-fit SEs-on-invariants are the gated follow-up.
