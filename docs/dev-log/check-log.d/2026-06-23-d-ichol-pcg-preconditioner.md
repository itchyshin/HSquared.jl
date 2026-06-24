# Check log — D: incomplete-Cholesky IC(0) preconditioner for the PCG path

**2026-06-23 · NotebookLM scout lead (D).** `[JL]` engine; experimental; extends `V1-PCG`;
no `covered` promotion.

## What landed

A new `preconditioner = :ichol` option for `solve_animal_model_pcg` — an incomplete-Cholesky
IC(0) preconditioner, the cleanest remaining real scout lead (Jacobi → IC(0) is the standard
"stronger, still-sparse" upgrade).

- `src/iterative_solve.jl`:
  - `_ichol0_factor(A)` (NEW): right-looking IC(0) — the lower factor `L` with the SAME sparsity
    pattern as `tril(A)`, dropping all fill outside that pattern; returns `nothing` on a
    non-positive pivot (breakdown). ~25 lines, CSC, a per-column row→position map for the
    pattern-restricted rank-1 update.
  - `_pcg_solve` generalized: the preconditioner is now a solve function `applyMinv` (was a
    Jacobi vector) — `identity` (`:none`), `r ↦ Minv .* r` (`:jacobi`), or the IC(0) back/forward
    triangular solve (`:ichol`). The `:jacobi`/`:none` math is unchanged.
  - `solve_animal_model_pcg`: `:ichol` builds the IC(0) factor of the assembled `C` (with a
    Manteuffel diagonal-shift fallback `IC(0)(C + s·I)` on breakdown — still a valid SPD
    preconditioner for `C`), applies `M⁻¹ = (L Lᵀ)⁻¹` via two sparse triangular solves; requires
    `matrix_free = false` (it factorizes the assembled `C`). Guards added.
- Funnel (NO new validation_status row — extended `V1-PCG`; count stays 48): capability-status
  PCG row + `validation_status()` `V1-PCG` evidence/owed updated (IC(0) moves from "deferred
  advanced preconditioner" to delivered).

## Checks run and exact outcomes

- **Correctness (the gate):** PCG `:ichol` recovers the direct `henderson_mme` solution (β + EBVs)
  to atol 1e-8 on the 8-animal Mrode9 fixture and 1e-7 on the 110-animal 4-gen fixture — i.e. a
  bug in IC(0) would make PCG miss the solution; it doesn't.
- **Iteration win (measured, exploratory):** on a 310-animal half-sib fixture, plain CG 21 iters →
  Jacobi 19 → **IC(0) 16**, all to the same solution. CI asserts the robust inequality
  `:ichol ≤ :none` (not exact counts — platform-stable).
- **Full `Pkg.test()` green** (julia 1.10.0, "Testing HSquared tests passed"); Phase 1 PCG testset
  **42/42**; Phase 0 scaffold 363/363 (count 48 unchanged). `docs/make.jl` green.
- Real `rose-systems-auditor`: **CLEAN**. Ran the gate (IC(0) matches the direct `henderson_mme`
  solve to ~1e-15; `L·Lᵀ−C` = 9e-16 on the `tril(C)` pattern), confirmed `:jacobi`/`:none` math
  unchanged (no `:none` aliasing bug), forced the breakdown→diagonal-shift path and verified it
  never alters the system PCG solves, checked the `matrix_free`+`:ichol` guard, and confirmed no
  overclaim (correctness primitive; iteration win is a dev-log measurement only; `:ichol ≤ :none`
  the sole CI inequality; count 48; nothing `covered`). Non-blocking note: on small fixtures IC(0)
  ≈ exact (negligible fill), so the real advantage is fill-heavy large pedigrees — honestly not claimed.

## Boundary / honesty

A CORRECTNESS primitive: IC(0) is validated to reach the SAME direct solution (iterative ==
direct) and to take ≤ plain-CG iterations — NO production-scale performance/benchmark claim
(none recorded). Not the default fit path; nothing `covered`. Breakdown handled by the
diagonal shift (the preconditioner can be IC(0) of `C + s·I` without changing the system PCG solves).
