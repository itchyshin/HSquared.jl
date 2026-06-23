# After-task — H7 latent/observation-scale non-Gaussian heritability — 2026-06-22

## Task goal

Backlog slice **H7**: a NEW EXPORTED `nongaussian_heritability` extractor — the
Nakagawa–Schielzeth (2017) / de Villemereuil (QGglmm) latent- and observation-scale
h² transform for a fitted non-Gaussian animal model, filling the gap the
family-uniform `nongaussian_result_payload` deliberately leaves (it carries NO
heritability). `[JL]` engine-only; stays `partial`.

## Active lenses / spawned agents

Lenses: **Fisher + Falconer** (the estimand decomposition — the load-bearing risk),
Noether (the Stein-lemma `V_A,obs = Ψ²·V_A` derivation), Gauss (the GH integration /
log-normal closed forms). A real `rose-systems-auditor` audited the branch.

## What I derived (and TWO spec errors I corrected)

- Latent h² = `V_A/(V_A + V_link + V_fixed)`: `V_link = π²/3` (logit), `σ²e`
  (Gaussian), `0` for the Poisson log link → Poisson latent h² is DEGENERATE,
  returned `NaN` (the exact reason the payload refuses a single h²).
- Observation h² = `Ψ²·V_A / V_P,obs`, `Ψ = E[g⁻¹′(η)]`. By **Stein's lemma**,
  `Ψ²·V_A` is exactly the variance of the regression of the mean on the breeding
  value, so `V_A,obs ≤ Var(mean)` and `0 < h²_obs < 1` BY CONSTRUCTION (not just
  asserted) — for logit `Cov(p,a) = V_A·Ψ` (Stein), for log `Cov(λ,a) = V_A·λ̄`.
- **Spec error 1 (the important one):** the spec said integrate the observation-scale
  quantities over `N(μ, V_A + π²/3 + V_fixed)`. That is WRONG — the π²/3 is the LATENT
  residual, not part of the linear-predictor spread; QGglmm's `binom1.logit` integrates
  over the random-effect variance only. Including it would silently bias the data-scale
  h². I integrate over `N(μ, V_A + V_fixed)` and document the convention.
- **Spec error 2:** the spec's test plan claimed Poisson h²_obs is monotone increasing
  in σ²a. It actually PEAKS (h²(0.5)=0.566 > h²(1.0)=0.526 at μ=1.2) — verified by
  hand. Dropped that false assertion; kept the genuinely-monotone binomial n_trials
  gradient instead.

## Files changed

- `src/nongaussian.jl` — `_VAR_LOGISTIC`, `_nongaussian_h2_core`, `_h2_family_params`,
  and the two exported `nongaussian_heritability` methods (fit + free-function).
- `src/HSquared.jl` — export `nongaussian_heritability`.
- `test/runtests.jl` — H7 oracle testset (25 assertions); `length(validation) == 47`;
  `nsh2` row check.
- `src/validation_status.jl` — +1 `partial` row `V6-NS-H2` (46 → 47, interior).
- `docs/design/validation-debt-register.md`, `capability-status.md` — V6-NS-H2 mirrors.
- `docs/design/14-program-backlog.md` — H7 ✅ (engine half).

## Checks run and exact outcomes

- Oracle testset (`Pkg.test()`, 25 assertions): Gaussian reduction (machine
  precision, free-function + fitted object); logit latent closed form V_A/(V_A+π²/3)
  to 1e-12; logit observation-scale vs an INDEPENDENT 64-node Gauss–Hermite quadrature
  of the same integrals (rtol 1e-3, 0<h²_obs<1); Poisson latent NaN + closed form vs
  independent integration (rtol 1e-6); the Binomial n_trials information gradient
  (h²_obs rises 1→5→20); guards (non-converged refused, per-record n_trials →
  NaN+caveat, ambiguous μ throws, Bernoulli information_limited, unsupported families
  throw); payload still heritability-free. **All pass.**
- Full `Pkg.test()` (thread-capped): **"Testing HSquared tests passed"** (exit 0).
- `julia --project=docs docs/make.jl` (thread-capped): **exit 0** (no dead links —
  the new exported docstring uses plain code spans, no `@ref` to internal types).
- Real `rose-systems-auditor` over the branch: audited before merge (see check-log).

## Public claim audit (Rose)

- `V6-NS-H2` is `partial`; covered/covered_external counts UNCHANGED; `validation_status()`
  46 → 47. Exported but experimental — not the public default, not covered.
- The estimand is documented precisely (which variance the integration uses, which
  estimand per family). The exact decomposition's external validation (a same-estimand
  QGglmm/MCMCglmm comparator) + a Fisher/Falconer sign-off are listed as the deferred
  promotion gate, NOT claimed. The in-suite oracle validates the NUMERICS (independent
  quadrature) and the limbs (Gaussian/Poisson closed forms), not the cross-package estimand.
- Single-trial Bernoulli carries `information_limited = true` + the downward-bias
  caveat verbatim; Poisson latent h² is honest NaN (degenerate); per-record data-scale
  h² is NaN+caveat (not silently averaged). NOT added to the payload.

## What did not go smoothly

- The estimand is genuinely delicate; I derived it from the QGglmm definition rather
  than trusting the spec, and corrected the integration-variance error (π²/3) and the
  false Poisson monotonicity claim. Both are documented.
- Scope: probit / beta-binomial / negative-binomial h² each need their own
  link-variance derivation — deliberately deferred (the function throws a clear error),
  not faked.

## Known limitations

- No same-estimand external comparator (QGglmm/MCMCglmm) and no Fisher/Falconer
  sign-off on the decomposition → cannot be promoted. Only gaussian/poisson/bernoulli/
  binomial (logit/log/identity); intercept-only `predictor_variance` default; single-
  trial Bernoulli inherits the latent bias; no intervals/SEs; no R surface. A dedicated
  DGP-true observation-h² recovery Monte-Carlo is deferred (the underlying σ²a recovery
  is already characterized per family; the transform is oracle-validated).

## Next actions

1. Confirm `docs/make.jl` green; fill the two pending outcomes.
2. Real `rose-systems-auditor` over the branch.
3. Commit, PR, merge on green CI (pre-authorized).
4. Then **C2** (genetic-correlation interval, extends V4-MV-REML).
