# After-task — D: incomplete-Cholesky IC(0) preconditioner for PCG — 2026-06-23

## Task goal

The NotebookLM scout's "D" lead: add an incomplete-Cholesky preconditioner to the PCG path
(currently Jacobi/none) — the cleanest remaining REAL lead (contrast B, which was reverted).
`[JL]` engine; experimental; extends `V1-PCG`; no `covered` promotion.

## What landed

`src/iterative_solve.jl`: `_ichol0_factor` (right-looking IC(0), pattern of `tril(A)`, drops
out-of-pattern fill, `nothing` on non-positive pivot); `_pcg_solve` generalized to a
preconditioner solve-function `applyMinv` (`:jacobi`/`:none` math unchanged); `:ichol` in
`solve_animal_model_pcg` (IC(0) of the assembled `C` + Manteuffel diagonal-shift fallback on
breakdown, applied via two sparse triangular solves; `matrix_free = false` only). Tests added to
the `V1-PCG` testset; capability-status + `validation_status()` `V1-PCG` rows updated (count 48).

## Honest result

- ✅ **Correct:** PCG `:ichol` reaches the SAME direct solution as `henderson_mme` (β + EBVs,
  atol 1e-8 at 8 animals / 1e-7 at 110) — the correctness gate that would have caught a bad IC(0)
  (the same discipline that flagged B).
- ✅ **A real preconditioner:** measured 21 (none) → 19 (Jacobi) → **16 (IC(0))** iterations on a
  310-animal fixture, same solution. CI asserts `:ichol ≤ :none` (robust inequality, not pinned counts).
- **Correctness primitive only** — NO performance/large-pedigree claim (none benchmarked); not the
  default fit path; nothing `covered`. Breakdown is handled (diagonal shift).

## Checks run and exact outcomes

- Full `Pkg.test()` green ("Testing HSquared tests passed"); Phase 1 PCG **42/42**; Phase 0 363/363
  (count 48). `docs/make.jl` green. Detail + numbers: the check-log entry.
- Real `rose-systems-auditor`: **CLEAN** (ran the gate: IC(0) ≈ direct to ~1e-15, `L·Lᵀ−C`=9e-16;
  Jacobi/none unchanged; breakdown/shift + guards correct; no overclaim, count 48, nothing covered).

## Next actions

1. ✅ Rose CLEAN; commit + push + PR (CI gates suite + docs).
2. D done. Remaining (recorded): R-twin parity (expose `em_warmup` via the hsquared bridge); G1
   Float32 / device-resident G; G2–G5 GPU; Track-A deep-pedigree; a recorded PCG benchmark (F6).
