# After-task — Matrix-free MME operator for PCG (V1-PCG extension)

Date: 2026-06-20. Lane: Julia engine. Branch: `julia/s52-matrixfree-pcg`. Extends the
PCG MME solver (#83 / V1-PCG).

## Summary

Added a `matrix_free = true` path to `solve_animal_model_pcg`: it applies `C·v` directly
from the sparse `X`/`Z`/`Ainv` matvecs (`common = X·v_β + Z·v_u`; `top = X'·common/σe²`;
`bottom = Z'·common/σe² + Ainv·v_u/σa²`) and uses a matrix-free Jacobi diagonal, never
assembling the coefficient matrix `C`. `_pcg_solve` was refactored to take a callable
operator. This turns #83's "C still assembled" caveat into "optionally matrix-free" — the
memory-side foundation for a future large-pedigree solver. Correctness only; no perf claim.

## Definition of Done

- implementation — `_mme_matvec` + `_mme_diag` + `matrix_free` kwarg/field in
  `src/iterative_solve.jl`; `_pcg_solve` now operator-based.
- tests — extend the PCG testset: operator `C·eᵢ == C[:,i]` exactly (column-by-column vs
  assembled), matrix-free diag == `diag(C)`, matrix-free == assembled == direct (8- and
  110-animal). PCG testset 31/31; full suite green (38 status rows).
- documentation — docstring (matrix-free section); V1-PCG row + capability-status updated.
- check-log — `docs/dev-log/check-log.d/2026-06-20-matrix-free-pcg.md`.
- after-task — this file.
- Rose audit — run before merge (no-perf-claim gate).
- clean local checks — `Pkg.test()` + `docs/make.jl` exit 0.

## Claim boundary

CORRECTNESS only — the matrix-free operator MATCHES the assembled `C` exactly
(column-by-column) and gives the same solution as the assembled path and the direct solve.
NOT the default fit path, NOT a performance / large-pedigree scaling claim (NO benchmark
recorded), no advanced preconditioners, no fit-path/REML wiring, no external comparator.
Nothing promoted to covered.

## Next (deferred)

- A recorded large-pedigree benchmark (the actual performance claim — gated by the
  evidence rule).
- Advanced preconditioners (block-diagonal / incomplete Cholesky / APY genomic).
- Wire matrix-free PCG into the fit path / REML iterations as an optional solver backend.
