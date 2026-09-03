# 2026-09-03 — 0.8 S3 FA uniqueness-interior bound (not a flip)

**Not a covered flip.** `V4-FA` stays partial. Count stays **7**. Experimental **0.7.0**.

## What landed

- Engine: `ψ_i = FA_UNIQUENESS_FLOOR + exp(θ_i)`, floor `1e-4`
- Refuse path: `ledermann_slack` / `fa_covered_flip_cell` /
  `require_fa_covered_flip_cell` (slack ≤ 0 is not a covered-flip cell)
- Tests: `test/test_fa_uniqueness_interior.jl`
- S2 freeze `eff57e3d` / driver blob `370cf697` **untouched**

## Focused tests (laptop)

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. -e 'using Test; include("test/test_fa_uniqueness_interior.jl")'
```

**exit 0.** `27 / 27` pass in 3.9 s (julia 1.10, host `w-kw3k3y6229`).

Existing Phase 4B FA path (`t=2 K=1`, uniqueness start 0.4): still
converged; `min(ψ̂) ≈ 1.002e-4` (on the floor; slack = −2). No S4 campaign.
