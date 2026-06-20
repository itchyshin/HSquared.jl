# After-task — Iterative (PCG) MME solver (V1-PCG)

Date: 2026-06-20. Lane: Julia engine. Branch: `julia/s52-pcg-mme`. Innovation-backlog
adjacent (the production sparse-path foundation).

## Summary

Added `solve_animal_model_pcg`: a preconditioned conjugate-gradient solve of the
supplied-variance animal-model MME, solving the IDENTICAL sparse SPD system the direct
`henderson_mme` factorizes (`_sparse_mme_system`) without forming a Cholesky factor.
Validated by correctness — it recovers the direct solve's β and EBVs to atol 1e-8 — with
no performance claim. This is the iterative-solver primitive the "production sparse
fitting / large pedigree" gap keeps deferring to.

## Definition of Done

- implementation — `src/iterative_solve.jl` (`solve_animal_model_pcg` + internal
  `_pcg_solve`); exported; included after `likelihood.jl`.
- tests — "Phase 1 PCG MME solver (iterative == direct, V1-PCG)": iterative==direct on
  two pedigrees, plain-vs-Jacobi CG equality + iteration bound, residual ≤ tol,
  non-convergence flag, full guard set. Full suite green (38 status rows).
- documentation — docstring; api.md; capability-status "Iterative (PCG) MME solver" row.
- validation-debt — `V1-PCG` (`partial`) in `validation_status()`.
- check-log — `docs/dev-log/check-log.d/2026-06-20-pcg-mme-solver.md`.
- after-task — this file.
- Rose audit — run before merge.
- clean local checks — `Pkg.test()` + `docs/make.jl` exit 0.

## Claim boundary

Correctness primitive — PCG MATCHES the direct solve. NOT the default fit path, NOT a
performance / large-pedigree scaling claim (`C` is still assembled, so not yet
matrix-free), no advanced preconditioners, no fit-path/REML wiring, no external
comparator. Nothing promoted to covered.

## Next (deferred)

- Matrix-free MME operator (apply `C·v` without assembling `C`) — the actual large-scale
  enabler; then a genuine large-pedigree benchmark (a performance claim, gated).
- Better preconditioners (block-diagonal / incomplete Cholesky / the APY genomic path).
- Wire PCG into the fit path / REML iterations as an optional solver backend.
