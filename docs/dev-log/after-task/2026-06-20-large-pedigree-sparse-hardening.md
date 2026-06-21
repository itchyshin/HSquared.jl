# After-task — Large-pedigree sparse AI-REML fit + selinv PEV hardening (#6)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/large-pedigree-sparse-hardening`. A bounded first slice of #6 (production sparse
fitting + large-pedigree hardening), built in parallel with two worktree agents.

## Summary

The sparse AI-REML path (`fit_ai_reml` → `_sparse_mme_system` + sparse CHOLMOD Cholesky
+ Takahashi selected inverse) was only exercised on tiny fixtures (≤110 animals for
selinv; ≤8 for the fit). Added a committed **deterministic 420-animal half-sib pedigree**
test that hardens the sparse path at a larger scale (CORRECTNESS-at-scale — NO timing /
performance asserted):

- `fit_ai_reml` converges (interior `σ²a, σ²e > 0`).
- **Self-consistency at scale:** `henderson_mme` at the fitted variance components
  reproduces the fit's β (atol 1e-8) and EBVs (atol 1e-7) EXACTLY.
- **selinv at scale:** the `O(nnz(L))` Takahashi selected-inverse PEV/reliability matches
  the dense MME-inverse diagonal (atol 1e-8) at 420 animals — extending `V1-SELINV-PEV`
  from the prior 110-animal fixture.

Deterministic (no RNG), in CI, fast (~0.1s warm).

## Definition of Done

- implementation — no engine code change (the sparse path already exists); a new
  committed test `Phase 1 large-pedigree sparse AI-REML fit + selinv PEV hardening (#6)`
  in `test/runtests.jl` (placed near the AI-REML / selinv tests).
- tests — 7 assertions; full `Pkg.test()` green.
- documentation — honest-status rows EXTENDED (no new row; `validation_status()` stays
  41): capability-status `Sparse production fitting / AI-REML` + `Production sparse
  reliability / PEV`; validation-debt `V1-REML`; `validation_status()` `V1-AI-REML`
  (covered, evidence strengthened) + `V1-SELINV-PEV`. "still needs" trimmed to drop
  large-pedigree hardening.
- check-log — `docs/dev-log/check-log.d/2026-06-20-large-pedigree-sparse-hardening.md`.
- after-task — this file.
- Rose audit — inline: CLEAN. The test asserts only correctness (self-consistency +
  selinv-vs-dense parity) at 420 animals; it explicitly asserts NO timing and the docs
  say "correctness-at-scale, NO performance claim" (no benchmark recorded — GPU/perf
  stays parked). `V1-AI-REML` was already `covered` (external bridge evidence); this only
  strengthens Julia-native hardening. Nothing newly promoted.
- clean local checks — `Pkg.test()` green; `validation_status()` = 41 rows.

## Claim boundary

Correctness-at-scale only — `fit_ai_reml` + selinv PEV are correct at 420 animals. NO
performance/benchmark claim (forbidden without evidence; GPU parked). Still needs
Julia-native known-truth recovery/fitted fixtures, boundary hardening, and
>2-component generalization.

## Next

A Julia-native large-pedigree known-truth recovery sim (opt-in); boundary hardening
(ill-conditioned / inbred extremes); a recorded benchmark (only when a perf claim is
actually wanted) → the CPU baseline before any GPU work.
