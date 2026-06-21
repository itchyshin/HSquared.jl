# After-task — Sparse AI-REML / selinv boundary hardening (#6)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/sparse-boundary-hardening`. Issue: #6.

## Summary

Added a committed deterministic testset `"Phase 1 sparse AI-REML / selinv boundary
hardening (#6)"` to `test/runtests.jl`, placed immediately after the existing "Phase 1
large-pedigree sparse AI-REML fit + selinv PEV hardening (#6)" testset. Three boundary /
stress cases, all RNG-free, all CORRECTNESS ONLY — no timing or performance is asserted.

**Pedigree:** two founders (f1, f2, unrelated) + a 3-generation selfing chain from f1
(s1, s2, s3, built via `normalize_pedigree(...; allow_selfing = true)`) + three offspring
that cross back to f2 or the other founder. Inbreeding coefficients in the same pedigree:
F ∈ {0, 0.5, 0.75, 0.875}. Total: 8 animals.

**Case 1 — highly-inbred pedigree:**
- `any(F .>= 0.5)` and `any(F .>= 0.875)`: the selfing chain reaches deep inbreeding.
- `pedigree_inverse == inv(additive_relationship)` (atol 1e-8): Henderson's direct Ainv
  rule stays exact under high inbreeding.
- `fit_ai_reml` converges on a structured deterministic y ([1.0, 3.5, 1.5, 1.2, 1.0,
  3.2, 3.8, 2.5]) providing an interior REML optimum; VCs positive.
- `henderson_mme` at the fitted VCs reproduces β (atol 1e-8) and EBVs (atol 1e-7)
  exactly: self-consistency holds at the inbred boundary.

**Case 2 — near-boundary low-h² optimum:**
- y near-constant ([3.01, 2.99, 3.00, …]) drives σ²a toward zero.
- Fit returns finite positive VCs without NaN (observed: σ²a ≈ 5.6e-5 or similar).
- `converged` is **not** asserted — the boundary optimum legitimately yields
  `converged = false`, which is correct behavior. The test asserts `isfinite` and
  positivity only (honest reporting, not forced convergence).
- Self-consistency still holds at whatever VCs are returned.

**Case 3 — selinv exact at the boundary:**
- On the inbred pedigree fit (Case 1): `prediction_error_variance(:selinv) ≈ :dense`
  (atol 1e-8) and `reliability(:selinv) ≈ :dense` (atol 1e-8).
- The Takahashi selected-inverse recursion stays numerically exact under high inbreeding.

Total: 16 test assertions, all passing.

## Definition of Done

- implementation — no src changes; the boundary correctness derives from existing
  `fit_ai_reml` / `pedigree_inverse` / `henderson_mme` / `prediction_error_variance`
  paths tested in a new configuration.
- tests — "Phase 1 sparse AI-REML / selinv boundary hardening (#6)": 16 assertions, all
  green, `test/runtests.jl`.
- documentation — no new public API; no docstring change needed.
- check-log — `docs/dev-log/check-log.d/2026-06-20-sparse-boundary-hardening.md`.
- after-task — this file.
- capability-status row — "Sparse production fitting / AI-REML" and "Production sparse
  reliability / PEV" rows in `docs/design/capability-status.md` extended to note boundary
  hardening.
- validation-debt row — `V1-REML` and `V1-SELINV-PEV` rows in
  `docs/design/validation-debt-register.md` extended; `V1-AI-REML` and `V1-SELINV-PEV`
  evidence strings in `src/validation_status.jl` extended.
- `validation_status()` row count — **41 rows unchanged** (no new row added).
- Rose audit — see below.
- clean local checks — `Pkg.test()` GREEN + `docs/make.jl` builds.
- clean CI — gated on the PR.

## Rose audit (claim-vs-evidence)

Rose lens review (perspective, not a spawned subagent):

**Pass — no blockers.** Every load-bearing claim in the testset is backed by an
assertion:

1. High inbreeding is not just stated — `any(F .>= 0.5)` and `any(F .>= 0.875)` are
   committed test gates; the F values are deterministic from the pedigree structure.
2. `pedigree_inverse == inv(A)` is asserted at atol 1e-8, not assumed.
3. Self-consistency (β/EBV match) is asserted at atol 1e-8/1e-7 in BOTH the inbred
   convergence case and the near-zero-σ²a boundary case — there is no path that
   "passes" by skipping the check when convergence is false.
4. The low-h² case does NOT assert `low_fit.converged` either true or false; the
   comment is explicit: "converged may be false — that is correct behavior and is NOT
   asserted either way". This is the correct honest position.
5. Selinv-at-boundary (Case 3) is asserted at atol 1e-8, matching the existing
   large-pedigree standard.
6. No performance or timing claim is present anywhere in the testset or in the
   updated doc rows.
7. `validation_status()` was verified to return 41 rows before and after the edit.
8. No capability was promoted to covered; all affected rows stay `partial` or
   `covered` (V1-AI-REML was already `covered`; the boundary hardening note is
   additive evidence, not a status change).

**One honest note:** the near-boundary case (Case 2) exercises a degenerate optimum
that the AI-REML optimizer reports as `converged = false`. This is engine behaviour
under a near-zero h² design, not a bug. The self-consistency gate still confirms the
engine returns usable (finite, positive, self-consistent) VCs even in this regime.

## Claim boundary

CORRECTNESS-AT-BOUNDARY only. Three deterministic boundary/stress cases for existing
`fit_ai_reml` + `pedigree_inverse` + selinv PEV paths. No new algorithm, no new
capability, no performance/timing claim, nothing promoted to covered.
