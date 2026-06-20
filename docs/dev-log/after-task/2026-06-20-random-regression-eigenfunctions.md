# After-task — Random-regression eigen-function decomposition (#54, slice 4)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/s54-rr-eigenfunctions`. Slice 4 of the random-regression / reaction-norm
capability (slice 1 = descriptors, 2 = supplied-covariance MME, 3 = REML).

## Summary

Added `rr_eigenfunctions(K_g, ts)` (exported): the Kirkpatrick (Lofsvold & Bulmer
1990) covariance-function eigen-decomposition of a SUPPLIED random-regression
coefficient genetic covariance `K_g`. Eigen-decomposes `K_g = Σ_j λ_j v_j v_jᵀ`
via `genetic_pca` (descending `λ_j`, sign-canonicalized Legendre-coefficient
eigenvectors) and evaluates the eigenfunctions `ψ_j(t) = φ(t)ᵀ v_j` over the
Legendre design at `ts`, returning `(covariate, eigenvalues, eigen_coefficients,
eigenfunctions, variance_explained)`. Reuses `genetic_pca` (evolvability.jl),
`_check_kg`, and `_rr_design`/`legendre_design` — ~25 LOC. Descriptive,
supplied-covariance, rotation-invariant; no estimation, no fitting/perf claim.

## Definition of Done

- implementation — `rr_eigenfunctions` in `src/random_regression.jl`; exported in
  `src/HSquared.jl`; slice-tracking header comment updated (slice 4 landed).
- tests — "Phase 3 random-regression eigen-function decomposition (#54 slice 4)"
  (17 assertions): `genetic_pca` equivalence + descending; eigenfunctions `= Φ·V`;
  spectral reconstruction `ΦK_gΦᵀ = Ψ·diag(λ)·Ψᵀ` (atol 1e-10); variance-explained
  identities; eigenfunction orthonormality on `[-1,1]` (trapezoid, atol 1e-3);
  diagonal-`K_g` + rank-1 reductions; PSD/shape/`|t|>1` guards.
- documentation — docstring (incl. the span-ambiguity caveat under repeated `λ_j`);
  `docs/src/api.md` `@docs` block; `docs/make.jl` exit 0.
- example / not-public note — EXPERIMENTAL caveats throughout; no R model-spec.
- check-log — `docs/dev-log/check-log.d/2026-06-20-rr-eigenfunctions.md`.
- after-task — this file.
- capability-status row — `V3-RR-DESC` extended (eigen-function moved deferred→landed).
- validation-debt row — `V3-RR-DESC` extended (same). In-code `validation_status()`
  unchanged at 38 rows (descriptors fold into the register, as for slices 1/2).
- Rose audit — ran (actual subagent). Verdict **MERGE**; no must-fix/should-fix; one
  optional doc nit (span-ambiguity caveat) — **applied**.
- clean local checks — `Pkg.test()` passed (new testset 17/17; whole suite green) +
  `docs/make.jl` exit 0.
- clean CI — gated on the PR (authoritative on a clean checkout).

## Review (Rose claim-vs-evidence, actual subagent)

Verdict **MERGE**. Rose reproduced every deterministic gate in Julia: spectral
reconstruction max error **1.3e-15** (row claims 1e-10 — conservative), eigenfunction
orthonormality **2.3e-8** (test atol 1e-3 — conservative), `genetic_pca` equivalence,
the diagonal/rank-1/zero-matrix reductions, and the exact 17-assertion count.
Confirmed: every status-row claim is backed; the FA rotation convention is honored
(only rotation-invariant quantities — eigenvalues + sign-canonicalized axes — are
exposed, never raw loadings, no eigenvector SEs); no estimation/fitting/perf/covered
creep; no surviving "eigen-function … deferred" text anywhere; in-code
`validation_status()` consistent with slices 1–3. Optional nit (restate the
repeated-eigenvalue span-ambiguity) applied to the docstring.

## Claim boundary

Descriptive, supplied-covariance, rotation-invariant; `K_g` is SUPPLIED, not
estimated. NOT included: curve-valued EBV-trajectory PEV/reliability, a known-truth
`K_g` recovery harness, the R-facing `rr()` model-spec / bridge payload, and any
WOMBAT/ASReml/JWAS comparator. Nothing promoted to covered.

## Live Phase Snapshot delta

Random regression is now slices 1–4 complete (descriptors → supplied-covariance MME
→ REML → eigen-functions). The remaining RR work (permanent-environment term,
curve-valued EBV PEV, `K_g` recovery harness, R `rr()` spec, comparator) stays
deferred. `validation_status()` stays at 38 rows; nothing covered-promoted.

## Next

Genetic GLLVM (#50) remains gated behind #44 + #37/#42 + the cross-team Q1/Q2
answers (design note posted to #50; scope doc landed via #87). Other unblocked solo
engine candidates: the RR permanent-environment term / curve-valued EBV PEV; the
metafounder `henderson_mme` wiring; a matrix-free-PCG large-pedigree benchmark
(a performance claim — gated on a recorded measurement). Cross-lane comparator runs
remain the highest-leverage non-solo work.
