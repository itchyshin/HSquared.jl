# After-task — H2 beta-binomial (overdispersed-logit) Laplace family — 2026-06-22

## Task goal

Backlog slice **H2**: add an internal beta-binomial response family to the
non-Gaussian engine (`src/nongaussian.jl`) on the Laplace path only, with a fitted
`σ²a`-at-fixed-ρ route through `fit_laplace_reml`. Overdispersed logit-binomial:
the success probability is Beta-distributed across records (intra-class correlation
`ρ ∈ (0,1)`; `ρ → 0` is the Binomial limit). `[JL]` engine-only — no R bridge /
model-spec touched. Stays `partial` (experimental, validation-scale, internal, not
exported, not the public default, not covered).

## Active lenses / spawned agents

Review lenses applied while building: Gauss + Noether (the score/Fisher-weight
derivation and the kernel implementation), Curie + Fisher (the recovery design and
honest gating), Hopper (the `dispersion` payload-field contract delta). A real
`rose-systems-auditor` subagent audited the branch before merge (see Checks).

## What I derived (and where the spec was incomplete)

- Conditional marginal `ℓ(y|η,ρ) = lbeta(α+y, β+n−y) − lbeta(α,β) + log C(n,y)`,
  `α = p(1−ρ)/ρ`, `β = (1−p)(1−ρ)/ρ`, `p = logistic(η)`; `α+β = (1−ρ)/ρ` is
  η-constant, so its loggamma terms cancel in the score.
- **Score** `dℓ/dη = p(1−p)·s·[ψ(α+y) − ψ(β+n−y) − ψ(α) + ψ(β)]`, `s = (1−ρ)/ρ`.
  Verified the `ρ→0` limit → `y − np` (Binomial score) analytically.
- **Weight = Fisher (expected) information** `E[(dℓ/dη)²] = Σ_k score(k,η)²·P(k|η,ρ)`
  — chosen for the `E[score²]` form (information identity) because it needs **only
  digamma, no trigamma**, and is `≥ 0` by construction (`> 0` strictly: the k=0
  bracket `ψ(β)−ψ(β+n) < 0`).
- **The spec's "observed information can be negative" claim was under-specified, and
  I confirmed it true only after probing:** at small n (m=2, m=10) my probes stayed
  positive; the observed `−d²ℓ/dη²` first goes negative at **larger n** in the
  surprising tail — pinned at `m=20, ρ=0.5, y=0, η=3 → −d²ℓ/dη² ≈ −0.099`. This is
  the load-bearing reason Fisher (not observed) info must be the IRLS weight, and the
  test now hardcodes that demonstration so it can't silently regress.

## Files changed

- `src/nongaussian.jl` — new `_lbeta` + series `_digamma` helpers (reuse the existing
  `_loggamma`, no `SpecialFunctions`); `BetaBinomialResponse(n_trials, rho)` struct +
  `_betabin_params`/`_fam_loglik`/`_fam_score`/`_fam_weight`/`_check_counts` kernels;
  `:beta_binomial` branch in `_resolve_single_family` (new `rho` kwarg); wiring in
  `fit_laplace_reml` (accept family, require both `n_trials`+`rho`, reject
  `:variational`, store ρ); **`NonGaussianFit` gains a `dispersion` field** (all 3
  constructor call sites updated); `nongaussian_result_payload` carries `dispersion`.
- `test/runtests.jl` — new "Phase 6 beta-binomial … (H2)" oracle testset; bumped
  `length(validation) == 45`; `betabin_row` occursin assertions; updated the 2 other
  nongaussian-payload `propertynames` checks (+`:dispersion`, +`=== nothing` for
  non-beta-binomial) at the parity fixture and the MarginalMethod testset.
- `test/fixtures/non_gaussian_parity/generate.jl` — generator's payload-shape guard +`:dispersion`.
- `src/validation_status.jl` — +1 `partial` row `V6-BETABINOMIAL` (44 → 45, interior).
- `sim/phase6_betabinomial_recovery.jl` — NEW opt-in recovery harness (Beta via two
  Marsaglia–Tsang Gamma draws; Beta–Binomial DGP; σ²a profiled at fixed ρ).
- `docs/dev-log/recovery-checkpoints/2026-06-22-h2-betabinomial-recovery.md` — NEW.
- `docs/design/validation-debt-register.md`, `docs/design/capability-status.md` — V6-BETABINOMIAL mirrors.
- `docs/design/14-program-backlog.md` — H2 ✅.

## Checks run and exact outcomes

- Oracle testset (in `Pkg.test()`): ρ→0 reduction of loglik AND Fisher weight to
  `BinomialResponse(m)`; score == central FD (rtol 1e-5); pmf sums to 1, mean `n·p`,
  variance `n·p(1−p)(1+(n−1)ρ)`; zero-mean score; Fisher weight == E[score²];
  Fisher weight > 0 across a wide grid incl. the negative-observed regime; guards;
  independent Gauss–Hermite quadrature of the TRUE marginal within `< 0.2` of the
  Laplace value on the 3-animal fixture. **All pass.**
- Recovery harness (`sim/phase6_betabinomial_recovery.jl`, thread-capped): hard gate
  (converged ∧ interior σ̂²a ∧ EBV cor ≥ 0.5) **5/5**; σ̂²a magnitude recovered well
  (mean 0.949 vs 1.0, mean rel 0.153, **5/5** within rel ≤ 0.45, reported-not-gated),
  EBV cor 0.74–0.82. Exit 0. (Conditional on ρ supplied at truth.)
- Full `Pkg.test()` (thread-capped, `OPENBLAS/OMP=2 JULIA_NUM_THREADS=1`):
  **"Testing HSquared tests passed"** (exit 0).
- `julia --project=docs docs/make.jl` (thread-capped): initially **exit 1** — a
  vitepress dead link from an `@ref` to the internal (un-manualed)
  `BetaBinomialResponse` in the `fit_laplace_reml` docstring; fixed by dropping the
  `@ref` (plain code span, matching how the other internal `ResponseFamily` types are
  referenced), then **exit 0** (status pages regenerated; only the benign pre-existing
  warnings — no logo/favicon, docstrings-not-in-manual, local-build skip-deploy).
- Real `rose-systems-auditor` subagent over the branch: **CLEAN (merge-ready)** —
  verified all seven audit points against source/tests (the negative-observed-info
  assertion, the independent GH oracle, the reported-not-gated recovery, the
  `dispersion` contract delta incl. the `pp` payload assertion). Two non-blocking
  polish items raised (these `__PENDING__` markers; the `_resolve_single_family`
  comment) — both applied.

## Public claim audit (Rose)

- `V6-BETABINOMIAL` is `partial`; nothing promoted to `covered`. Public-default
  covered count UNCHANGED (1 = Gaussian); Julia `validation_status()` 44 → 45 (the
  new row is partial; covered count unchanged).
- The recovery σ̂²a magnitude is REPORTED (5/5 within rel ≤ 0.45), gated only on the
  reliable signal — matching the `V6-NBINOM`/`V6-BERNOULLI` precedent. The gate was
  pre-declared and NOT tightened/loosened post-hoc; the conditional-on-supplied-ρ
  caveat is recorded.
- Kernel correctness rests on the in-suite INDEPENDENT oracle (ρ→0 anchor + score-FD
  + GHQ marginal), not on the recovery run.
- Contract delta: the bridge payload gains a `dispersion` field (self-describing,
  `nothing` for all non-beta-binomial families). Engine-side only — recorded as a
  cross-lane note for the R twin (AGENTS.md rule 2); no R repo edit.

## What did not go smoothly

- My initial small-n probes (m=2, m=10) showed observed info staying positive, which
  would have made the spec's Fisher-vs-observed motivation wrong. Re-deriving the
  asymptotics and probing larger n found the genuine negative-observed point at
  m=20 — the spec's conclusion was right, its stated regime was incomplete. Recorded.
- Rose-principle miss-then-catch: I updated 2 of 3 nongaussian-payload `propertynames`
  assertions; the third used the variable `pp` (not `payload`/`pay`) and my first grep
  missed it. The first full-suite run caught it (1 failed test); fixed and re-ran green.
- A `tee` pipe masked the recovery sim's real exit on a first run with a comprehension
  ParseError (`[begin … end for …]`); fixed to an explicit loop, re-ran with captured exit.

## Known limitations

- ρ is SUPPLIED/FIXED, not estimated; joint `(σ²a, ρ)` is follow-up.
- Laplace-only (no VA kernel — the beta-binomial marginal does not factor through a
  log-partition the GH-VA kernels reuse); `:variational` is rejected.
- Scalar common denominator only (no per-record `BetaBinomialVectorResponse`).
- No `σ²a` profile-LRT interval for `:beta_binomial` (the H6 extension), no external
  comparator (MCMCglmm/aods3/glmmTMB), no latent-scale h², no R activation.

## Next actions

1. Confirm full `Pkg.test()` + `docs/make.jl` green; fill the two pending outcomes.
2. Real `rose-systems-auditor` over the branch before merge.
3. Commit, push, PR, merge on green CI (pre-authorized).
4. Then **H3** (Bernoulli probit / threshold, `V6-PROBIT`).
