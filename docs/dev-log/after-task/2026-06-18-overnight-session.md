# Overnight autonomous session — 2026-06-18

Running log of the autonomous overnight slices (maintainer away; push/PR/merge
deferred). Each slice: TDD, full local suite green, local checkpoint commit, no
push. The user's explicitly-requested AI-REML trace fusion + profile interval
has its own report (`2026-06-18-aireml-trace-fusion-and-profile-interval.md`);
this log accumulates the smaller hardening/follow-on slices.

## Slice 1 — multivariate covariance hardening (V4-MV)

- `genetic_correlation(C)` now guards **symmetry** (`isapprox(C, Cᵀ)`) and
  **positive-semidefiniteness** (`eigmin(Symmetric(C)) ≥ -1e-8`), in addition to
  the existing square + positive-diagonal checks. The PSD bound deliberately
  allows rank-deficient PSD inputs (e.g. low-rank `G = ΛΛ'`) while rejecting
  indefinite matrices, so the structured-covariance paths are unaffected.
- Added a deterministic `_cov_to_chol_params`/`_chol_params_to_cov` roundtrip
  regression test for t = 3 and t = 4 (catches parameter-order bugs; rtol 1e-12).
- Tests: `test/runtests.jl` "Phase 4 multivariate covariance hardening" (11
  checks: valid PD correlations in [-1,1], rank-1 PSD allowed, asymmetric /
  indefinite / non-square / non-positive-diagonal rejected, t≥3 roundtrip).
- Full suite: **1479/1479** green. Closes next-50 Julia items #4 and #7.
- Claim impact: none — defensive hardening of existing helpers.
