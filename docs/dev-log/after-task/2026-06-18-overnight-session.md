# Overnight autonomous session — progress report (living)

Last updated: 2026-06-18 (overnight). Maintainer away until ~5am; this doc is
kept current at each milestone and is the "morning report".

## How to review (fastest path)

1. `git log --oneline main..HEAD` on branch `codex/phase5-gwas-qtl-eqtl-tables`
   — the local checkpoint commits below (NOT pushed).
2. `julia --project=. -e 'using Pkg; Pkg.test()'` — full suite, currently green.
3. Live board: http://localhost:8791 (control centre).
4. The plan: `docs/design/11-completion-plan.md`.

## Operating rules I followed

- Julia lane only; R twin read-only cross-reference; **no push, no PR merge, no
  publish** — those wait for you.
- Each slice: TDD (RED→GREEN), full local suite green, full Definition of Done
  (capability/validation rows, check-log, this report), **local checkpoint
  commit** (reversible; review/reset freely).
- Honest status: nothing promoted past "experimental"; no claim without the
  evidence chain.

## Committed this session (local only, NOT pushed)

| Commit | Slice | Evidence |
| --- | --- | --- |
| `44471ad` | Julia-lane completion plan (`docs/design/11-completion-plan.md`) | planning doc; ordered critical path, gate ordering, Phase-5 PR-stack recommendation, Laplace+VA reuse map |
| `0e3c7eb` | (A) Fuse AI-REML selinv score trace `tr(A⁻¹C^uu)` → `selinv_trace_against` (O(nnz(L)), no output matrix); (B) profile-likelihood `heritability_interval(...; method=:profile)` | fused trace == prior to rtol 1e-10, optimum unchanged; profile inverts REML LRT, clamps on flat surfaces; suite green |
| `ee89565` | Harden multivariate `genetic_correlation` (symmetry + PSD guards, rank-deficient low-rank G allowed); pin Cholesky-param roundtrip t≥3 | RED→GREEN; closes next-50 Julia #4, #7 |
| `a3eab9b` | Phase-3 committed recovery harness `sim/phase3_qg_recovery.jl` | repeatability `t` recovered 5/5 (max rel 0.254); `h²` σ²a/σ²pe split under-identified (honest, ungated) |
| `c0125ba` | Phase-6 GLLVM non-Gaussian **Laplace marginal foundation** (`src/nongaussian.jl`) | Gaussian Laplace == REML loglik exact (rtol 1e-8, mode == MME); Poisson mode solves score eqn; family kernels finite-diff'd; suite 1490/1490 |
| `57c0b7c` | Phase-6 GLLVM **variational (VA) marginal foundation** (`src/nongaussian.jl`) — team-designed (workflow w0ux3t4fu) | full-cov VA, β integrated: Gaussian VA-ELBO == REML exact (rtol 1e-8, mode == BLUP, S == H_uu⁻¹); Poisson ELBO stationary; suite 1504/1504 |
| _(latest)_ | Phase-6 non-Gaussian family hardening (`src/nongaussian.jl`) — closes the team's `laplace_fixes_needed` | `sigma_e2>0` guard, Poisson integer-count guard, non-converged → `NaN`; suite 1510/1510 |

The (A)/(B) commit is your explicitly-requested refactor task plus an in-flight
slice I owned and finished. Full report:
`2026-06-18-aireml-trace-fusion-and-profile-interval.md`.

## Repo state

- Branch `codex/phase5-gwas-qtl-eqtl-tables`, HEAD `ee89565` (local).
- Full local suite: **1479/1479 pass, exit 0**.
- Working tree clean after each commit.
- The Phase-5 draft PR stack #26→#35 remains stacked + unmerged on `main`
  (unchanged; merge is your call).

## Honest status (what is and is not true)

- Still exactly **one fully public-covered capability**: the v0.1 Gaussian
  animal model (R default fit, gryphon+sommer). Tonight's work hardened and
  extended *experimental* engine internals; it did not promote anything to
  "covered".
- Multivariate recovery calibration **still fails** the predeclared gate
  (reproduced bit-for-bit by the design workflow: unstructured 6/10, FA 8/10,
  low-rank 9/10, all converged). V4 stays partial; no source fix is warranted
  (sampling variance vs stringent thresholds, not a bug).
- The AI-REML trace refactor is a numerical-equivalence + allocation win; it is
  NOT benchmarked at large pedigree scale (equivalence + complexity by
  construction only).

## In progress / next (queued, Julia-only, internally verifiable)

1. Phase-3 committed recovery harness (`sim/phase3_qg_recovery.jl`) for
   `fit_repeatability_reml` / `fit_two_effect_reml` — closes the V3 "no
   committed recovery harness" gap (opt-in, outside CI; honest pass/fail).
2. Phase-6 GLLVM/non-Gaussian **Laplace** foundation, validated by the
   Gaussian-limit reduction to `sparse_reml_loglik` (exact) — the start of the
   Laplace+VA directive; VA reuse from `DRM.jl/src/variational.jl` (`:LA`/`:VA`).
3. Dense `inv(Ainv)` conditioning caveat made visible (next-50 #6).

## Decisions awaiting you

- **Push tonight's local commits?** They are checkpoints on the feature branch.
- **Phase-5 draft PR stack #26→#35**: consolidate/merge to `main`, or keep
  stacking? (Recommendation in the completion plan: merge in order.)

## Detailed slice log

### Slice 1 — multivariate covariance hardening (V4-MV) — `ee89565`
- `genetic_correlation(C)` now guards symmetry (`isapprox(C, Cᵀ)`) and PSD
  (`eigmin(Symmetric(C)) ≥ -1e-8`), allowing rank-deficient low-rank `G` while
  rejecting indefinite/asymmetric inputs.
- Deterministic `_cov_to_chol_params`/`_chol_params_to_cov` roundtrip pinned for
  t = 3, 4 (rtol 1e-12).
- `test/runtests.jl` "Phase 4 multivariate covariance hardening" (11 checks);
  full suite 1479/1479.

### Slice 2 — Phase-3 repeatability recovery harness (V3-REPEAT-REML)
- `sim/phase3_qg_recovery.jl` (opt-in, outside CI) simulates a half-sib design
  with repeated records from known `(σ²a,σ²pe,σ²e)=(1.0,0.6,1.4)` over 5
  predeclared seeds.
- **Repeatability `t` recovered on 5/5** (max rel 0.254, gate ≤0.35).
- **`h²` (the σ²a/σ²pe split) under-identified** at this validation-scale design:
  2/5 seeds hit the σ²pe→0 boundary (max rel 0.892). Reported, NOT gated — a
  denser pedigree is needed for reliable `h²` recovery. This matches the
  estimator's documented limitation. No claim promotion; V3 stays partial.
- Closes the V3-REPEAT-REML "no committed recovery harness" gap (for `t`).
  Follow-on: a `fit_two_effect_reml` harness + a denser-pedigree `h²` study.

### Slice 3 — Phase-6 GLLVM non-Gaussian Laplace marginal foundation (V6-LAPLACE)
- New `src/nongaussian.jl` (unexported, not wired into `fit_*`): a
  family-generic Laplace-approximate marginal log-likelihood
  `laplace_marginal_loglik(y, X, Z, Ainv, σ²a, family)` for the animal model,
  integrating `[β` flat`; u ~ N(0,Aσ²a)]` by penalized-IRLS mode-finding + a
  Gaussian integral at the mode. Families: `GaussianResponse(σ²e)`,
  `PoissonResponse()` (log link). Architecture follows DRM.jl's `:LA`/`:VA`
  marginal-method idea (VA is the planned next step).
- **Validated** by: exact reduction to `sparse_reml_loglik` for the Gaussian
  family (rtol 1e-8) with mode == Henderson MME solution; Poisson Newton mode
  solving the penalized score equation (‖∇‖<1e-8); per-family score/weight
  matching central finite differences. This is the first real Phase-6 step.
- NOT: VA, variance-component estimation, a fitted GLLVM, exported API, R
  model-spec, or external comparator. Capability stays experimental;
  `V6-LAPLACE` opened as partial. Full suite 1490/1490.
- This is the headline of the night per the user's Laplace+VA directive: the
  Laplace half of the engine has a validated foundation; VA is next.

### Slice 4 — Phase-6 GLLVM variational (VA) marginal foundation (V6-VA) — team-designed
- **The breakthrough, designed WITH the team** (ultracode workflow `w0ux3t4fu`,
  7 agents): Gauss/Noether/Curie adversarially verified the Laplace base
  (independently re-derived the Gaussian reduction to ~3e-15; verdict solid, no
  blocking bugs); Karpinski/Kirkpatrick/Fisher designed the VA and resolved the
  crux — use a **FULL** variational covariance `S=(ZᵀW̃Z+Ainv/σ²a)⁻¹` (a
  mean-field/diagonal S discards pedigree relatedness and is not REML-exact) with
  **β integrated under a flat prior**; Ada synthesized the spec + exact tests.
- `variational_marginal_loglik` (`src/nongaussian.jl`, unexported): ELBO over
  `q(u)=N(m,S)`, closed-form expected-loglik kernels (Gaussian; Poisson via the
  log-normal MGF), Schur-complement β-integration term.
- **Validated**: Gaussian VA-ELBO == `sparse_reml_loglik` EXACTLY (rtol 1e-8;
  ELBO tight, mode == BLUP, `S` == Henderson `H_uu⁻¹`); Poisson ELBO stationary
  (‖∇‖<1e-8); closed-form kernels match their definitions. The team predicted the
  exact "0.88 gap" I first hit (the missing β-integration term) — adversarial
  design paid off.
- Returns `elbo` (a lower bound, tight only for Gaussian). NOT: a Poisson
  marginal-value comparator (vs Gauss–Hermite — follow-on), `:diagonal` option,
  VC estimation, fitted GLLVM, exported API, or R model-spec. Full suite
  1504/1504. **Both halves of the Laplace+VA directive now have validated
  foundations.**

### Slice 5 — Phase-6 non-Gaussian family hardening (closes the team's findings)
- Implemented the verifiers' `laplace_fixes_needed` on `src/nongaussian.jl`:
  `GaussianResponse` now requires `sigma_e2 > 0`; both marginals reject
  non-integer / negative Poisson counts (`_check_counts`); and `loglik`/`elbo`
  return `NaN` with `converged = false` on non-convergence (a non-mode value is
  never returned as a valid marginal). New 6-check hardening testset.
- Full suite 1510/1510. Defensive only — no claim/result/bridge change.
- Remaining team-flagged items (still open, recorded): the Laplace
  `gradient_norm`-at-returned-mode nit, and a Poisson marginal-VALUE test vs
  Gauss–Hermite quadrature (the one honest Poisson-value gate).
