# 2026-06-20 Matrix-free MME operator for PCG (V1-PCG extension)

- Goal: extend the PCG MME solver (#83 / V1-PCG) with a `matrix_free = true` path that
  applies `C·v` directly from the sparse `X`/`Z`/`Ainv` matvecs without ever assembling
  the coefficient matrix `C` — turning #83's "C still assembled" caveat into "optionally
  matrix-free", the real memory enabler for a future large-pedigree solver. Correctness
  only; NO performance claim.
- Lenses: Gauss + Karpinski + Noether (operator numerics); Rose (no-perf-claim gate).

## What was done

- `src/iterative_solve.jl`: refactored `_pcg_solve` to take a callable operator `applyC`
  (matrix `*` or matrix-free). Added `_mme_matvec` (applies `C·v` as `common = X·v_β +
  Z·v_u`; `top = X'·common/σe²`; `bottom = Z'·common/σe² + Ainv·v_u/σa²`) and `_mme_diag`
  (matrix-free Jacobi diagonal `diag(X'X)/σe²`, `diag(Z'Z)/σe² + diag(Ainv)/σa²`).
  `solve_animal_model_pcg(...; matrix_free = false)` gains the new path + a `matrix_free`
  field in the result.
- Tests (extend the PCG testset): the operator `C·eᵢ == C[:,i]` EXACTLY column-by-column
  vs the assembled `_sparse_mme_system` lhs (max err 0.0); matrix-free diag == `diag(C)`;
  matrix-free solve == assembled solve == direct `henderson_mme` (8- and 110-animal).
- Honest status: V1-PCG row + capability-status row updated to record the matrix-free
  path; the deferred-evidence wording sharpened to "NO benchmark recorded" (no perf claim).

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (PCG testset 31/31; matrix-free == assembled == direct; `validation_status()` 38 rows).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)**.

## Claim boundary

CORRECTNESS only — the matrix-free operator is validated to MATCH the assembled `C`
(exactly, column-by-column) and to produce the same solution as the assembled path and the
direct solve. NOT the default fit path, NOT a performance / large-pedigree scaling claim
(NO benchmark recorded), no advanced preconditioners, no fit-path/REML wiring, no external
comparator. The memory-side foundation for the future production sparse path. Nothing
promoted to covered.
