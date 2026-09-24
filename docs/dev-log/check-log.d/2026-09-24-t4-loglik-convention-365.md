# 2026-09-24 — T4 loglik convention metadata (#365)

## Commands

```sh
cd ~/local-scratch/lanes/HSquared.jl-post366-t4
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. -e 'using Test, LinearAlgebra, SparseArrays, HSquared; include("test/test_365_loglik_convention.jl")'
```

## Outcome

- `HSquared.jl #365 loglik convention metadata` — **21 pass / 0 fail**
- No covered flip; `public_covered_count` untouched; version stays 0.9.0
- Absolute dense loglik values **unchanged** (optima invariant); convention is
  self-describing via `loglik_convention`, `loglik_full_constant_offset`,
  `loglik_comparable_across_routes`, plus `comparable_loglik(fit)`

## Scope

Honesty / metadata for dense vs sparse REML loglik (#365). Not a numeric
identity rewrite of `_multi_effect_dense` / `_two_effect_dense`.
