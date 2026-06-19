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
| `a4ddaba` | Phase-6 non-Gaussian family hardening (`src/nongaussian.jl`) — closes the team's `laplace_fixes_needed` | `sigma_e2>0` guard, Poisson integer-count guard, non-converged → `NaN`; suite 1510/1510 |
| `023f076` | Phase-6 Poisson marginal-value test vs Gauss–Hermite (test-only) | β-fixed tensor GH quadrature confirms VA ELBO ≤ true marginal, Laplace ≈ true; suite 1513/1513 |
| `50657f4` | Phase-6 `:diagonal` (mean-field) VA + ELBO-monotonicity | closed-form `S=diag(1/diag H_uu)`; verified `ELBO_full ≥ ELBO_diagonal`; suite 1515/1515 |
| `616651c`/`b56d6c9` | Phase-6 **fitted** non-Gaussian (`fit_laplace_reml`, Laplace/VA REML over variance components) + fitted EBVs | Gaussian recovers `fit_sparse_reml` exactly (both :laplace & :variational); Poisson estimates σ²a>0; EBVs == BLUP at fitted VCs; suite 1526/1526 |
| `3f4a97a` | Phase-6 **Poisson known-truth recovery** (`sim/phase6_poisson_recovery.jl`, opt-in) | σ̂²a recovers 5/5 seeds (rel ≤ 0.323, mild Laplace bias); breeding-value recovery cor 0.81–0.88 |
| `92cc4bf` | Phase-6 **Poisson variance-component profile interval** (`laplace_reml_interval`, `src/nongaussian.jl`); reverted a stray uncommitted `FastGaussQuadrature` entry in `Project.toml` | inverts marginal LRT `2·(ℓ̂−ℓ(σ²a))=χ²₁,level`; interior upper endpoint pinned to χ²₁ root (3.8415/2.7055), lower clamps on flat profile, nests by level; suite 1538/1538 (+12) |
| `907bf75` | Phase-6 **Bernoulli/logit family** (`BernoulliResponse`, Laplace + VA) — binary 0/1 traits | VA expected kernels via 20-node Gauss–Hermite (logistic has no closed-form Gaussian expectation); β-fixed GH gate confirms `va.elbo ≤ R` (gap 4e-4) and Laplace close (gap 0.028); finite-diff kernels; `fit_laplace_reml(:bernoulli)` converges (`:laplace`/`:variational`); suite 1553/1553 (+15) |
| `44a7dbd` | Phase-6 **Bernoulli known-truth recovery** (`sim/phase6_bernoulli_recovery.jl`, opt-in) | q=1075 half-sib, truth σ²a=1.0 (logit); 5/5 gated pass (EBV cor 0.565–0.701 ≥ 0.5, non-collapse); σ̂²a 0.36–0.81 reported-not-gated (known Laplace-for-binary downward bias) |
| `02f63f3` | Phase-3 **two-effect REML known-truth recovery** (`sim/phase3_two_effect_recovery.jl`, opt-in) | q=860, common-env groups independent of pedigree (identifiable); 5/5 recover ALL THREE components (max rel σ1 0.286, σ2 0.277, σe 0.123) — prior additive underestimation was a confounding artifact, not an estimator flaw |
| `8636339` | Phase-6 **Binomial/logit family + recovery** (`BinomialResponse(n_trials)`, `sim/phase6_binomial_recovery.jl`) | generalises Bernoulli (m=1); Laplace + VA (GH kernels ×m + binom offset); m=8 value gate (va.elbo ≤ R, Laplace gap 0.031); recovery q=345/m=20 **σ²a HARD-gated 5/5** (rel ≤ 0.175, EBV cor 0.90–0.92) — binary bias is an information effect; suite 1584/1584 (+31) |
| `25d16f1` | Phase-3 **repeatability h² identifiability study** (docs evidence; no src/test) | full-sib designs: q=315/n=1575 recovers h² 4/5 within ~0.26 (vs original 2/5) but STILL not gateable (1 seed misses at 0.58) — σ²a/σ²pe split intrinsically ill-conditioned at validation scale; honest negative result, closes the speculative gap |
| `16b2684` | **Dense-inverse conditioning caveat** (`V1-DENSE-COND`, docs) | the dense `inv(Ainv)` estimators are O(q³)/precision-limited for ill-conditioned `Ainv`; sparse/Henderson/Laplace+VA use `Ainv` directly; tracked limitation |
| _(latest)_ | Phase-3 **cytoplasmic / maternal-lineage relationship** (`maternal_lineage`, `cytoplasmic_relationship`, exported) | first non-standard-inheritance primitive; maternal-founder trace + 0/1 same-line indicator; hand-verified multi-lineage fixture; suite 1637/1637 (+53) |

The (A)/(B) commit is your explicitly-requested refactor task plus an in-flight
slice I owned and finished. Full report:
`2026-06-18-aireml-trace-fusion-and-profile-interval.md`.

## Repo state

- Branch `codex/phase5-gwas-qtl-eqtl-tables`, HEAD = this slice's local commit.
- Full local suite: **1637/1637 pass, exit 0**.
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

Done this session (moved to the slice log): Phase-3 recovery harness, Phase-6
Laplace + VA foundations, family hardening, Gauss–Hermite value gate, `:diagonal`
VA, fitted `fit_laplace_reml` + EBVs, Poisson known-truth recovery, the Poisson
profile interval (Slice 10), the Bernoulli/logit family for Laplace + VA
(Slice 11), the Bernoulli known-truth recovery harness (Slice 12), and the
two-effect REML recovery harness (Slice 13), and the Binomial/logit family +
recovery (Slice 14, which resolved the binary-bias question), and the
repeatability `h²` identifiability study (Slice 15, honest negative result), the
dense-inverse conditioning caveat (Slice 16, `V1-DENSE-COND`), and the first
non-standard-inheritance primitive — cytoplasmic / maternal-lineage relationship
(Slice 17).

**Still solo-doable (newly visible after Slice 17):** Phase 3's non-standard
inheritance scope has more relationship-construction primitives that ARE solo +
hand-verifiable — selfing-aware inbreeding, clonal (identical-genotype groups),
haplodiploid, polyploid relationship coefficients — plus a cytoplasmic-variance
estimation example feeding `fit_two_effect_reml`. These are genuine remaining
runway.

**Genuinely NOT solo (needs you / R lane / external):** external GLLVM.jl /
gllvmTMB / sommer / ASReml comparator parity; the R-facing model-spec + bridge
activation; latent genetic factors; a full fitted-object API; production sparse
fitting + large-pedigree hardening; and Phases 7–8 (GPU/HPC backends — these
cannot be honestly validated without hardware and so are out of solo scope).

Everything else on the Phase-6/Phase-7 path (a full fitted-object/extractor API,
latent genetic factors, more families, external GLLVM.jl/gllvmTMB comparators,
the R model-spec) genuinely needs the R lane, external packages, or your steer.

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

### Slice 6 — Poisson marginal-value gate vs Gauss–Hermite (closes the last team item)
- Test-only: a self-contained Golub–Welsch tensor Gauss–Hermite quadrature of the
  true β-fixed Poisson marginal, used as an INDEPENDENT reference. Confirms the
  VA `elbo` is a valid lower bound on `log p(y)` (`va.elbo ≤ R + 1e-6`) and the
  Laplace value is close (`≈ R`, atol 5e-2) — without falsely asserting the two
  approximations bound each other (they don't; both lie below the truth in
  different amounts). Exercises the β-fixed (p=0) path of both marginals.
- Full suite 1513/1513. This was the team's strongest remaining honest-coverage
  item; the only Poisson check that was missing a true-value comparator is now in.
- Remaining Phase-6 follow-ons (clearly scoped, not started): a `:diagonal` VA
  option + ELBO-monotonicity test; the Laplace `gradient_norm`-at-mode nit;
  variance-component estimation and a fitted GLLVM path; external GLLVM.jl/
  gllvmTMB comparators; the R-facing model-spec.

### Slice 7 — `:diagonal` (mean-field) VA + ELBO-monotonicity
- `variational_marginal_loglik(...; covariance = :diagonal)` adds the mean-field
  option with the closed-form `S = Diagonal(1 ./ diag H_uu)`. Verified it is a
  *looser* lower bound than full covariance (`ELBO_full ≥ ELBO_diagonal`,
  β-fixed). `:full` remains the validated (REML-exact) foundation; `:diagonal`
  is explicitly lower-bound-only (it discards pedigree relatedness). Full suite
  1515/1515.
- Remaining Phase-6 (the genuinely larger, still-unstarted work): variance-
  component estimation → a *fitted* non-Gaussian/GLLVM model, latent genetic
  factors, external GLLVM.jl/gllvmTMB comparators, and the R-facing model-spec.

### Slice 8 — fitted non-Gaussian: variance-component estimation (`fit_laplace_reml`)
- The first *fitted* non-Gaussian capability: `fit_laplace_reml` maximises the
  Laplace marginal or the VA ELBO over `(sigma_a2[, sigma_e2])` (NelderMead for
  Gaussian, Brent for Poisson).
- **Exact gate**: for the Gaussian family the objective IS the exact REML loglik,
  so both the `:laplace` and the full-covariance `:variational` fits recover
  `fit_sparse_reml` (marginal loglik rtol 1e-6, VCs rtol 1e-2, interior 8-animal
  fixture). Poisson returns a positive `sigma_a2` and converges. Full suite
  1524/1524.
- This moves Phase 6 from *marginals* into *fitting*. Still experimental: no
  intervals, no fitted-object/EBV extractors, no Poisson known-truth recovery,
  no external comparator, not exported, no R model-spec — those are the next
  steps toward a genuinely usable fitted GLLVM.

### Slice 9 — Poisson known-truth recovery (`sim/phase6_poisson_recovery.jl`)
- Opt-in (outside CI): half-sib pedigree (165 animals), `u ~ N(0, A·0.5)`,
  `yᵢ ~ Poisson(exp(1.5 + uₐ))`, fit with `fit_laplace_reml(family = :poisson)`,
  5 predeclared seeds.
- **5/5 pass**: σ̂²a recovers within rel ≤ 0.323 (mild expected Laplace downward
  bias, no boundary collapse) and breeding-value recovery correlation 0.81–0.88.
  Genuine recovery of known truth — closes the V6-FIT recovery gap.
- This rounds out the Phase-6 non-Gaussian arc: marginals → fitting → EBVs →
  known-truth recovery, all internally validated. Remaining items (a
  full fitted-object API, latent factors, external comparators, R model-spec)
  genuinely need the R lane / external packages / your steer.

### Slice 10 — Poisson variance-component profile interval (`laplace_reml_interval`)
- The first *interval* for a non-Gaussian variance component, closing the
  V6-FIT "no intervals" gap. `laplace_reml_interval(y, X, Z, Ainv;
  family = :poisson, marginal, level, initial)` fits with `fit_laplace_reml`,
  then inverts the marginal LRT `2·(ℓ̂ − ℓ(σ²a)) = χ²₁,level` for the Poisson
  `sigma_a2`, reusing the existing `_profile_root` bisection and
  `_standard_normal_quantile`. No new statistical code path — it composes the
  pieces already validated in earlier slices.
- **Gates** (8-animal count fixture, 12/12): the interval brackets the estimate;
  `dev(σ̂²a) ≈ 0` at the MLE; the interior **upper** endpoint is pinned to the
  χ²₁ root (`dev(upper) ≈ 3.8415` at 95%, `2.7055` at 90%) — the genuine LRT
  property that a wrong root-finder would fail; the **lower** endpoint clamps on
  the flat near-zero profile; higher confidence ⇒ wider interval; guards throw.
- I probed the fixture first (the estimate is near zero with a flat lower
  profile, so the lower bound is non-binding) so the test asserts the *correct*
  statistical behaviour rather than rubber-stamping output.
- Cleanup: reverted a stray *uncommitted* `FastGaussQuadrature` entry in
  `Project.toml` (added during earlier exploration, then superseded by the
  self-contained Golub–Welsch quadrature in the Gauss–Hermite test; used
  nowhere, never committed). `Project.toml` now matches HEAD; Gauss–Hermite
  testset still passes (3/3).
- Still experimental, Poisson-only, asymptotic: no Gaussian/multi-component
  intervals (needs nuisance profiling), no large-n coverage calibration. Full
  suite 1538/1538.

### Slice 11 — Bernoulli/logit family (Laplace + VA) — binary traits
- The biggest missing real-world quantitative-genetic family: BINARY 0/1 traits
  (disease, survival, reproductive success). `BernoulliResponse` (logit link)
  extends the non-Gaussian engine to **both** the Laplace marginal and the VA
  ELBO — directly the "GLLVM with Laplace as well as VA" directive.
- The genuine work is the VA path: the logistic log-partition `log(1+eη)` has no
  closed-form Gaussian expectation (unlike Poisson's log-normal MGF), so the VA
  expected loglik/score/weight kernels are computed by a load-time 20-node
  Gauss–Hermite rule. Using the **same nodes** for all three makes the expected
  score and weight *exactly* the η̄-derivatives of the expected loglik, so the VA
  Newton iteration stays consistent with the ELBO it maximises.
- **Gates** (15/15): conditional + expected score/weight match central finite
  differences; the expected kernels reduce to the conditional ones as `v→0`; a
  β-fixed independent tensor Gauss–Hermite quadrature of the true Bernoulli
  marginal confirms `va.elbo ≤ R` (valid lower bound, gap ≈4e-4) and the Laplace
  value is close (`|lap−R| ≈ 0.028`); binary guard rejects non-`{0,1}`;
  `fit_laplace_reml(...; family = :bernoulli)` converges for both `:laplace` and
  `:variational`.
- **Honest limit**: binary data is variance-uninformative at small scale, so the
  fitted `sigma_a2` is boundary-prone (the 8-animal smoke fixture runs to the
  Brent upper bound) and is NOT yet calibrated by a known-truth recovery study.
  The marginal *machinery* is trustworthy (VA-lower-bound + finite-diff gates);
  the *fitting* is flagged as uncalibrated in the new `V6-BERNOULLI` rows. Full
  suite 1553/1553. Team lenses: Gauss/Noether (kernel derivatives + quadrature
  consistency), Curie (the GH value gate as the truth oracle), Darwin/Falconer
  (binary/threshold traits are the high-value biological case), Karpinski
  (load-time GH rule, `@inbounds` reduction), Rose (uncalibrated-fit honesty).

### Slice 12 — Bernoulli known-truth recovery (`sim/phase6_bernoulli_recovery.jl`)
- Honest recovery calibration of the Slice-11 Bernoulli fit. Opt-in (outside CI):
  half-sib pedigree (25 sires / 50 dams / 1000 offspring, q=1075), `u ~ N(0,A·1)`
  on the logit scale, `yᵢ ~ Bernoulli(logistic(uₐ))` (μ=0, prevalence ≈ 0.5 — the
  most informative binary case), 5 predeclared seeds.
- **Result (RAN, exit 0):** 5/5 pass the GATED criteria — converged, interior
  (non-collapsed) `σ̂²a`, and EBV recovery correlation `cor(û,u) ∈ [0.565,
  0.701]` ≥ 0.5. The variance point estimate is REPORTED-not-gated and confirms
  the textbook **Laplace-for-binary downward bias**: `σ̂²a ∈ [0.362, 0.813]`
  (mean ≈0.65 vs truth 1.0), one persistent low-bias seed.
- This is the same honesty split as the Phase-3 `h²` case: gate the reliable
  signal (rank/EBV recovery), report the biased one (variance magnitude) without
  pretending it is calibrated. Calibrating binary `σ̂²a` needs a bias correction
  or a many-trial binomial design — recorded as remaining V6-BERNOULLI debt.
  Evidence log: `docs/dev-log/recovery-checkpoints/2026-06-18-phase6-bernoulli-recovery.log`.
  No test-suite change (opt-in). This rounds out the Bernoulli arc: kernels →
  marginals (Laplace + VA) → fitting → honest recovery characterization.

### Slice 13 — two-effect REML known-truth recovery (V3-TWOEFFECT-REML)
- Closes the V3-TWOEFFECT-REML "no committed RNG recovery harness" gap, and
  answers whether the prior additive-variance underestimation was an estimator
  flaw or a design artifact. `sim/phase3_two_effect_recovery.jl` (opt-in):
  `y = μ + u1[animal] + u2[group] + e` with `u1 ~ N(0,A·σ1²)` (additive,
  pedigree), `u2 ~ N(0,I·σ2²)` (common environment), `e ~ N(0,I·σe²)`.
- The fix vs. the old confounded one-off: the common-environment GROUPS are
  assigned INDEPENDENTLY of the pedigree, so the pedigree-structured additive
  covariance and the block-structured group covariance are separable. q=860
  half-sib (20 sires / 40 dams / 800 offspring), 80 groups, truth (1.0,0.5,1.0).
- **Result (RAN, exit 0):** 5/5 recover ALL THREE components (max rel σ1 0.286,
  σ2 0.277, σe 0.123). The earlier additive underestimation was a confounding
  artifact of the aliased design, NOT an estimator flaw — an important honest
  correction to the prior note. Evidence log:
  `docs/dev-log/recovery-checkpoints/2026-06-18-phase3-two-effect-recovery.log`.
  No test-suite change (opt-in).

### Slice 14 — Binomial/logit family + recovery (resolves the binary-bias question)
- Generalises the Bernoulli family to `BinomialResponse(n_trials)` (`y` successes
  out of a common `m`; Bernoulli is `m=1`), for BOTH Laplace and VA. Conditional
  `ℓ = yη − m·log1pexp(η) + log C(m,y)`; the VA expected kernels reuse the
  Bernoulli Gauss–Hermite kernels scaled by `m` (plus the constant binomial
  offset). `fit_laplace_reml` gains a `:binomial` branch + required `n_trials`.
- **Gates** (31/31): exact `m=1`→Bernoulli reduction; conditional + expected
  score/weight finite-diff; a β-fixed Gauss–Hermite value gate (m=8) with
  `va.elbo ≤ R` (gap ≈2e-3) and Laplace close (gap ≈0.031); guards on
  `n_trials < 1`, `y ∉ 0:m`, and missing `n_trials`.
- **Scientific payoff** (`sim/phase6_binomial_recovery.jl`, RAN exit 0, q=345,
  m=20, truth σ²a=1.0): **5/5 with `σ̂²a` HARD-gated** — rel ≤ 0.175, EBV
  correlation 0.900–0.916. Where the single-trial Bernoulli left `σ̂²a`
  downward-biased and reported-not-gated (Slice 12), 20 trials/record make the
  data informative enough to recover `σ̂²a` tightly. So the binary "bias" is an
  INFORMATION effect, not an estimator flaw — the honest resolution of the
  Slice-11/12 limitation. Suite 1584/1584. Evidence log:
  `docs/dev-log/recovery-checkpoints/2026-06-18-phase6-binomial-recovery.log`.

### Slice 15 — repeatability `h²` identifiability study (honest negative result)
- Tests the standing hypothesis that the repeatability `h²` (σ²a/σ²pe split)
  becomes reliably recoverable with a denser, relatedness-richer pedigree (the
  forward note in `sim/phase3_qg_recovery.jl`). Probed full-sib designs (shared
  sires ⇒ relatedness 0.5 within family, 0.25 across — the contrast the original
  half-sib design lacked), truth (1.0,0.6,1.4), 5 seeds.
- **Result:** the split improves with richness — small (q=156,n=624) recovers
  `h²` 2/5, large (q=315,n=1575) recovers 4/5 within ~0.26 — but it is STILL not
  reliably gateable even at n=1575 (1 seed misses at relh 0.58). The
  additive-vs-permanent-environment contrast is intrinsically ill-conditioned at
  validation scale.
- This is an honest **negative** result that closes a speculative gap: it
  replaces "needs a denser pedigree (future work)" with concrete evidence, so a
  future session won't re-litigate it. No always-failing harness committed (that
  would mean tuning a threshold to a hard problem); `t` stays the gated summary.
  Evidence: `docs/dev-log/recovery-checkpoints/2026-06-18-phase3-repeatability-h2-identifiability.md`.

### Slice 16 — dense-inverse conditioning caveat made visible
- The last queued solo item. Added `V1-DENSE-COND` (status: documented) to the
  validation-debt register: the validation-scale dense estimators that form an
  explicit `A = inv(Ainv)` (`fit_two_effect_reml`, `fit_repeatability_reml`, the
  recovery harnesses) are O(q³) and lose precision for ill-conditioned `Ainv`,
  whereas the sparse REML / Henderson / non-Gaussian Laplace+VA paths use
  `Ainv` / `cholesky(Ainv)` directly and never materialise the inverse. A known
  validation-scale limitation, not a bug; production sparse fitting is the
  remedy. Doc-only; no src/test/claim-surface change.

### Slice 17 — cytoplasmic / maternal-lineage relationship (starts Phase-3 inheritance scope)
- After re-checking the ROADMAP I corrected an under-scoping: Phase 3 ("Standard
  Quantitative-Genetic AND Inheritance Models") explicitly includes cytoplasmic
  inheritance, selfing, clonal, etc. — so non-standard inheritance has a genuine
  solo-doable foundation (relationship construction), which I had wrongly lumped
  with GPU/HPC. (Phase 7 = CPU/GPU and Phase 8 = HPC genuinely cannot be honestly
  validated solo.)
- `maternal_lineage(pedigree)` traces each individual to its maternal founder in
  one forward pass (topological order ⇒ dam index < i); `cytoplasmic_relationship`
  builds the dense 0/1 same-maternal-line indicator `C` (mitochondrial /
  cytoplasmic inheritance). Both exported with `(ids, sire, dam)` methods.
- **Gates** (53 checks): hand fixture (maternal lines A:{A,C,D,F}, B:{B,E}) with
  an exhaustive `C[i,j] == (lineage[i]==lineage[j])` check, symmetry, unit
  diagonal, founder self-labelling, `F→C→A` transitivity, all-founder→identity,
  and convenience-method agreement. Suite 1637/1637.
- **Honest scope:** construction only. `C` is the 0/1 indicator (rank = #lineages,
  singular) — the relationship for an i.i.d. cytoplasmic random effect (a grouping
  that feeds the existing `fit_two_effect_reml` second effect), NOT a matrix to
  invert. No cytoplasmic-variance fitting claim, no R model-spec. Moves the
  capability row planned→experimental, adds `V3-CYTO`, updates ROADMAP Phase 3.
  The other inheritance systems (selfing, clonal, haplodiploid, polyploid) and
  the cytoplasmic-variance estimation example remain open.
