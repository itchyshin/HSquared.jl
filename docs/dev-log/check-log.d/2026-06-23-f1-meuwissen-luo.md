# Check log — F1 (B3) Meuwissen–Luo O(n) inbreeding

**2026-06-23 · branch `claude/wave-f-foundation-gpu-plan` · Wave F / Track A.**

## Change

- `src/pedigree.jl`: new `_meuwissen_luo_inbreeding(pedigree)` (Meuwissen & Luo
  1992) + a minimal inline max-heap (`_ml_heappush!`/`_ml_heappop_max!`).
  `inbreeding_coefficients` now delegates to it (no longer builds the dense
  `_numerator_relationship` just to read its diagonal). `max_relationship_cache`
  kept for signature compat (no longer bounds the inbreeding path; still governs
  the dense `_numerator_relationship` used by `additive_relationship`/A₂₂ and as
  the oracle).
- `test/runtests.jl`: new `@testset "F1 Meuwissen-Luo inbreeding (O(n), no dense
  cap)"` (10 assertions); fixed the now-obsolete `@test_throws` at the former
  line 1045 (the dense-cap throw is intentionally gone).
- `docs/design/capability-status.md` (Sparse `Ainv` row) +
  `docs/design/validation-debt-register.md` (V1-AINV) updated.

## Evidence

- **Correctness (exact oracle):** M–L `F` matches the dense
  `_numerator_relationship` diagonal EXACTLY (`maxdiff = 0.0`) on calf/sire/dam,
  an inbred half-sib pedigree (F=0.25), a 3-generation selfing chain
  (F=0.875), and a random 300-animal inbred pedigree (local check), and `≈` on a
  deterministic q=2000 inbred pedigree (in-suite).
- **Scaling unblock:** q=12000 runs in `test/runtests.jl` (was capped at 1e4);
  q=30000 confirmed on DRAC (previously threw); q≤300000 in the opt-in scale
  benchmark (`docs/dev-log/recovery-checkpoints/2026-06-23-f0-scale-baseline.md`)
  — Ainv build now O(n) (0.337 s at q=300k vs dense 0.412 s at q=10⁴).
- **Local checks:** `Pkg.test()` green on the Mac (`JULIA_EXIT=0`; F1 testset
  10/10; `Testing HSquared tests passed`), single-thread, julia 1.10.10.
- `docs/make.jl`: not re-run for this slice (no docstring page wiring beyond the
  existing API docs; to confirm before merge if Documenter touches `pedigree.jl`).

## Boundaries / honesty

- Claim is **inbreeding/Ainv build is O(n) and scales**, validated EXACT vs the
  dense oracle. NOT a production-fitting or competitive-performance claim.
- The scale run shows `fit_ai_reml` (factorization + convergence) is the NEXT
  bottleneck (super-linear; non-converged at q=300k) — that is F2/F3, untouched
  by F1.
- Timings are opt-in single-machine measurements (fir, DRAC), not a CI gate.
