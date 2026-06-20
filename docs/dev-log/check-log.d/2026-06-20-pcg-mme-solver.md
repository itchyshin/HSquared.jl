# 2026-06-20 Iterative (PCG) MME solver (V1-PCG)

- Goal: land the iterative-solver primitive the "production sparse path" keeps waiting
  on — a preconditioned conjugate-gradient solve of the animal-model MME, validated by
  CORRECTNESS (matches the direct `henderson_mme`), no performance claim.
- Lenses: Gauss + Karpinski + Noether (numerics/CG); Rose (claim gate).

## What was done

- `src/iterative_solve.jl` (new, included after `likelihood.jl`; exported
  `solve_animal_model_pcg`): `solve_animal_model_pcg(spec, σ²a, σ²e; tol, maxiter,
  preconditioner = :jacobi | :none)` assembles the SAME sparse SPD system as
  `henderson_mme` via `_sparse_mme_system` and solves `C·[β; u] = rhs` by PCG (internal
  `_pcg_solve`), splitting the solution into β + EBVs. Jacobi preconditioner `M⁻¹ =
  1/diag(C)`; non-positive-curvature guard.
- Deterministic testset "Phase 1 PCG MME solver (iterative == direct, V1-PCG)": PCG β/EBVs
  equal `henderson_mme` to atol 1e-8 (Mrode9-shaped 8-animal + tiny 3-animal); plain CG
  reaches the same solution; Jacobi iters ≤ plain-CG iters; relative residual ≤ tol;
  starved `maxiter` ⇒ `converged = false`; σ/tol/maxiter/preconditioner guards.
- Honest status: `V1-PCG` (`partial`) in `validation_status()` (37 → 38);
  capability-status "Iterative (PCG) MME solver" row; api.md.

## Commands / results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (PCG testset green; jacobi converged in 10 iters, relres ~1.5e-14, β/EBVs == direct;
  `validation_status()` 38 rows).
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **passed (exit 0)** (new api.md
  entry resolves).

## Claim boundary

CORRECTNESS primitive only — PCG is validated to MATCH the direct solve. NOT the default
fit path, NOT a performance / large-pedigree scaling claim (`_sparse_mme_system` still
assembles `C` explicitly, so it is not yet matrix-free), no advanced preconditioners, no
REML/fit-path wiring, no external comparator. The iterative-solver foundation for the
future production sparse path. `σ²a`/`σ²e` supplied. Nothing promoted to covered.
