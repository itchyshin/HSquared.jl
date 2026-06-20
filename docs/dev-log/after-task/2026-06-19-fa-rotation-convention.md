# After-task — FA rotation/interpretation convention decision (2026-06-19)

Overnight autonomous runway run (Ada). The science-decision item that unblocks
#42 (lowrank/fa bridge exposure) and pairs with #37 / #55.

## Goal

Ratify the convention (deferred since 2026-06-14) for handling rotation-
nonidentified factor-analytic / low-rank genetic loadings, so structured-fit
quantities can be bridged in an identifiable, reproducible way.

## Process (team)

A two-lens proposal workflow (Fisher — inference/identifiability; Kirkpatrick —
factor-analytic / reduced-rank G) ran in parallel; the two **converged**
independently on the same answer, which Ada ratified.

## Decision

Bridge and do inference ONLY on **rotation-invariant functionals of `G`**: the
eigenstructure (`genetic_pca`/`g_max`, already shipped in #55), evolvability
(#55), `Ψ`, `G`/correlations/`h²`, eigenvalues. **Never bridge raw loadings `Λ`**;
**no SEs on loadings or individual eigenvectors** (the latter especially under
near-degenerate eigenvalues). Precedent: Kirkpatrick & Meyer (2004) reduced-rank /
principal-component estimation of `G` (WOMBAT; ASReml `xfa`).

## What landed (doc-only)

- `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md` (the decision).
- Forward pointer from the superseded 2026-06-14 note.
- Capability-status (FA row) + validation-debt `V4-FA`: convention DECIDED;
  eigenbasis bridge exposure gated on R-lane ratification (#42).

## Local checks

No `.jl` files touched — `Pkg.test()` and the Documenter build (`docs/src/`) are
unaffected and remain green on `main`.

## Cross-lane

Gated on joint R-lane ratification (#42 ↔ R #7) before any structured-fit field is
bridged (AGENTS.md rule 2). Posted in the #61 coordination note.

## Claim boundary

Decision record only — no code, no capability change, nothing bridged yet. The
exposable invariants already exist; the eigenbasis bridge payload + SEs-on-invariants
are the gated follow-up.
