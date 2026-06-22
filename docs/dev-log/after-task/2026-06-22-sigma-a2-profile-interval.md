# After-task report — sigma_a2 profile-LRT interval (V1-HERIT-CI)

Date: 2026-06-22

Branch: `claude/sigma-a2-profile-interval` (HSquared.jl, isolated worktree from
`main` `38286b1`). **Not committed at time of writing.**

Active lenses: Fisher (inference/intervals), Gauss (numerics), Noether
(estimand/notation), Rose (claim-vs-evidence)

Spawned subagents: none

Current lane: Julia engine (`HSquared.jl`)

## 1. Goal

Add the genuinely-missing component-level interval: a profile-LRT confidence
interval for the additive variance component `sigma_a2` (profiling `sigma_e2` as
nuisance), the variance-component companion of the existing h² profile interval.
Stays `partial`; no promotion.

## 2. Implemented

- `variance_component_interval(fit; level = 0.95, method = :profile)` (exported) +
  helpers `_profile_reml_loglik_sigma_a2` and `_variance_component_interval_profile`
  in `src/likelihood.jl`. Reuses `sparse_reml_loglik`, `_profile_root`, and
  `_standard_normal_quantile` — parallels the h² profile exactly.
- Test added to the inference testset in `test/runtests.jl`.
- `validation_status()` (`src/validation_status.jl`) and
  `docs/design/validation-debt-register.md` V1-HERIT-CI rows updated.

## 3a. Decisions and Rejected Alternatives

- **Pivoted from the originally-listed "two-component h² interval (nuisance
  profiling)".** Reading the code showed that already exists:
  `heritability_interval(fit; method = :profile)` re-maximizes the REML objective
  over the total variance (the nuisance) at each fixed h² (`_profile_reml_loglik`)
  — i.e. it is already a proper nuisance-profiled h² interval. The AGENTS.md
  "next" note was stale. Honesty over agreement: I did not rebuild it.
- **Built the genuinely-missing piece instead:** a profile-LRT interval for the
  variance COMPONENT `sigma_a2` (not the ratio), with `sigma_e2` profiled as
  nuisance. Deterministic (no bootstrap/RNG), CPU-light, and parallels the h²
  profile.
- **Rejected (for now):** the parametric-bootstrap alternative (RNG + CPU-heavy,
  and the suite is deliberately RNG-free) and a coverage-calibration sim
  (CPU-heavy). Both remain listed in the V1-HERIT-CI "still needs".
- **Deferred the `capability-status.md` mirror edit to merge** (kept this PR to
  the authoritative surfaces: `validation_status()` code + the validation-debt
  register).

## 4. Files Touched

- `src/likelihood.jl` (helper + `_variance_component_interval_profile` + public fn)
- `src/HSquared.jl` (export `variance_component_interval`)
- `src/validation_status.jl` (V1-HERIT-CI evidence/needs row)
- `docs/design/validation-debt-register.md` (V1-HERIT-CI row)
- `test/runtests.jl` (new assertions in the inference testset)
- `docs/dev-log/after-task/2026-06-22-sigma-a2-profile-interval.md` (this file)

## 5. Checks Run

- `Pkg.instantiate()` on the worktree project: `✓ HSquared` precompiled (no syntax
  errors in the src edits).
- Full core suite **thread-capped** (`OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2`,
  `julia --project=. test/runtests.jl`): **exit 0, zero failures/errors** across
  the suite (grep for `Test Failed`/`Error`/exception: none). The new σ²a-interval
  assertions are in the mid-file inference testset and passed.

## 6. Tests of the Tests

- Mirrors the existing h² profile testset. Assertions are robust to clamp-or-not
  (the n=8 fixture has a flat REML surface): `lower ≤ σ̂²a ≤ upper`, `95% ⊇ 50%`,
  `*_clamped` are Bools.
- Pins the profile helper: `_profile_reml_loglik_sigma_a2(spec, σ̂²a)` recovers the
  fitted REML optimum (atol 1e-4) and is an upper envelope of a fixed-`sigma_e2`
  slice.
- Guards: level range, `method` value, and REML-only (via the existing `ml` fit).

## 7a. Issue Ledger

- V1-HERIT-CI extended with the σ²a profile-LRT interval. Stays `partial`. The
  "still needs" (coverage calibration, parametric bootstrap, ML information) is
  unchanged. No promotion.

## 8. Consistency Audit

- Honest about the flat-surface clamp behavior (documented in the docstring +
  test comment). No coverage-calibration claim. `validation_status()` code +
  validation-debt register kept in sync; `capability-status.md` deferred to merge.

## 9. What Did Not Go Smoothly

- The originally-scoped slice (#16) turned out to be redundant (the h² nuisance
  profile already exists). Caught by reading the code before implementing; pivoted
  to the genuinely-missing σ²a component interval.

## 10. Known Residuals

- **Not committed/pushed** at time of writing.
- `capability-status.md` V1-HERIT-CI mirror edit deferred to merge.
- Not coverage-calibrated; parametric-bootstrap + ML-information variants remain
  future work.

## 11. Team Learning

Before building a "missing" capability, verify it against the code — the engine
already had the nuisance-profiled h² interval; the AGENTS.md "next" note was
stale. The genuine gap was the component-level (`sigma_a2`) interval.
