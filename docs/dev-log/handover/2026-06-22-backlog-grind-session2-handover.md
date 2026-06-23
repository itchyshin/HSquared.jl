# Handover — backlog grind, session 2 (2026-06-22)

**START HERE** for the next session. Repo state is the source of truth; this is the
at-a-glance pointer. Continues the 100-slice program from
`2026-06-22-backlog-grind-handover.md`.

## TL;DR

This session merged the two green PRs the prior handover flagged, closed the prior
session's DEFERRED ledger/evidence follow-ups, and landed the first remaining slice
(L1, drawing-only). **3 PRs merged/landed; nothing promoted to covered; public-default
covered count UNCHANGED (1 = Gaussian).** The next slice is **H2 (beta-binomial)** —
the first of the correctness-critical GLMM/inference half. Spec digested below.

## What landed this session (all on `HSquared.jl`, all verified)

1. **Merged `#164` (I1 sire fixture) + `#165` (H1 negative-binomial)** — both CI-green;
   the NB2 loglik/score/weight were independently re-derived before merge, and the I1
   fixture confirmed an honest self-consistency target (not external parity).
2. **`#166` — deferred ledger/evidence close-out (C5/C10/I1/H1)** — MERGED. No new
   `src/` numerics. +3 `partial` `validation_status()` rows (`C10-LRT`, `V1-SIRE-FIT`,
   `V6-NBINOM`; count 41 → 44), the C5 genomic-σ²a `.md` mirrors + V2-GBLUP cross-ref,
   the sire comparator-manifest entry, a NEW opt-in NB recovery sim (σ²a magnitude
   honestly REPORTED-NOT-GATED — 3/5 at rel≤0.45, ~21% downward, the Bernoulli
   information effect — gated only on the reliable EBV-rank signal; no gate relaxation),
   and doc-14 ✅ marks. `Pkg.test()` + `docs/make.jl` green; real Rose audit CLEAN.
3. **`#167` — L1 HSquaredMakieExt figure kinds** — MERGED (`4d4c0f4a`). Drawing-only;
   5 new Makie `kind`s (`:manhattan`, `:qq`,
   `:rr_variance`, `:rr_surface`, `:rr_eigenfunctions`) consuming existing `*_plot_data`
   preparers. Makie stays OUT of CI (cost discipline); the stub testset is 11 assertions
   (9 `MethodError` payloads, one per kind); the LOAD-BEARING local CairoMakie draw
   passed ALL 30 checks. Florence figure-honesty CLEAN; Rose CLEAN. `validation_status()`
   rows UNCHANGED (drawing tracked in the debt register + design-doc §8, PR #121 precedent).

## Exact state

- **`HSquared.jl` main:** `4d4c0f4a` (after #167; #166 was `2e8f15da`).
- **`hsquared` (R) main:** `ce61016` — UNCHANGED this session (Julia-lane only).
- **Open PRs:** `#167` (L1) green-pending; none else.
- **Julia `validation_status()`:** 44 rows (5 covered + 3 covered_external + 35 partial
  + 1 planned). Covered count UNCHANGED this session.
- **CairoMakie scratch env:** `/tmp/hsq_makie_env` (CairoMakie 0.15.11 / Makie 0.24.x,
  dev-references the repo). May be cleared from /tmp — recreate with
  `julia --project=/tmp/hsq_makie_env -e 'using Pkg; Pkg.develop(path="."); Pkg.add(name="CairoMakie", version="0.15.11"); Pkg.precompile()'`.

## Remaining slices (the prior handover's 8, now 7)

> **Execution playbook:** `2026-06-22-remaining-slices-execution-plan.md` — the
> per-slice plan (API + correctness traps + oracle/gate + funnel impact + risk
> register + the rigid derive→oracle→Rose recipe). This section is the summary.

Order: **H2 → H3 → H6 → H7 → C2 → C6 → J1** (J1 LAST — needs a derived convention +
sign-off). Each GLMM/inference slice is one careful **derive → oracle → Rose** pass.
Full specs: `docs/design/15-backlog-wave-execution-plan.md` + `/tmp/backlog_specs.md`
(regenerate from the design-sweep workflow if gone).

### H2 — beta-binomial (NEXT), spec digested

Add `BetaBinomialResponse(n_trials::Int, rho::Float64)` to `src/nongaussian.jl`
(internal; mirrors `BinomialResponse`, scalar common-denominator). Logit link,
overdispersion `ρ ∈ (0,1)` (intra-class corr; ρ→0 = Binomial limit). Closed-form
conditional marginal: `ℓ(y|η,ρ) = lbeta(α+y, β+n−y) − lbeta(α,β) + log C(n,y)`,
`α = p(1−ρ)/ρ`, `β = (1−p)(1−ρ)/ρ`, `p = logistic(η)`.

**Reuse** the existing `_loggamma` (Lanczos, `multivariate.jl`, in scope) →
`_lbeta(a,b) = _loggamma(a)+_loggamma(b)−_loggamma(a+b)`. No `SpecialFunctions`.

**Two correctness subtleties (do NOT skip):**
1. **Weight = FISHER (expected) information `−E[d²ℓ/dη²]`, NOT the observed
   `−d²ℓ/dη²`.** Beta-binomial is not log-concave in η for all (ρ,y), so the observed
   information can be NEGATIVE and would break the `cholesky(Symmetric(H))` PD
   assumption in the IRLS Newton loop (`nongaussian.jl:227`/`:247`). The expected
   information is ≥0, keeps H PD (Fisher scoring — the standard non-canonical-link
   choice). Document this in the kernel comment (contrast: the Binomial weight IS the
   observed information because the logit binomial is canonical/log-concave).
2. **Score** is analytic via the digamma chain rule through (α,β) × `dp/dη = p(1−p)`.
   Needs a `_digamma` (a proper series, or the FD form
   `_digamma(x) = (_loggamma(x+1e-6)−_loggamma(x−1e-6))/2e-6`). The score MUST match
   central finite differences of `_fam_loglik` (the project's standard kernel gate).

**Wiring:** `fit_laplace_reml` accepts `family = :beta_binomial` requiring BOTH
`n_trials` AND a new `rho` keyword; estimate `σ²a` over the Laplace marginal at a
SUPPLIED FIXED ρ (1-param Brent, reusing the single-component branch with
`fam = BetaBinomialResponse(n_trials, rho)`); joint (σ²a, ρ) is explicit follow-up.
Reject `marginal = :variational` (no VA kernel). `NonGaussianFit`: add an explicit
`dispersion::Union{Float64,Nothing}` field — **blast radius: audit every
`NonGaussianFit(` call (currently 2 in `fit_laplace_reml`) + the `genetic_gllvm.jl`
reductions**. `nongaussian_result_payload`: `family = "beta_binomial"`, carry ρ. NOT
exported. Do NOT touch the R bridge/model-spec ([JL] engine-only).

**Oracle (the binding gates):** (a) ρ→0 reduction to `BinomialResponse(m)` (the
trusted-path anchor); (b) score == central FD; (c) Fisher weight > 0 incl. a regime
where the observed info is negative; (d) a β-fixed independent tensor Gauss–Hermite
quadrature of the TRUE beta-binomial marginal (adapt the Binomial `_binom_marginal`
oracle in the runtests testset ~lines 5908-5993) — Laplace value close on the 3-animal
fixture. Commit ONLY once the oracle passes.

**Funnel:** new `V6-BETABINOMIAL` `validation_status` row (count **44 → 45**, bump the
`@test length(validation) == 44` + insert NOT-first/NOT-last) + the `.md` mirrors. The
full row text is in `/tmp/backlog_specs.md` / doc-15. Opt-in
`sim/phase6_betabinomial_recovery.jl` (clone the binomial one; DGP draws
`p_i ~ Beta(α,β)` then `y_i ~ Binomial(m, p_i)`; fit at the same fixed ρ). This family
closes the documented binomial-overdispersion-convention gap in
`docs/dev-log/after-task/2026-06-22-binomial-mcmcglmm-comparator.md`.

### H3 / H6 / H7 / C2 / C6 — see doc-15 + /tmp/backlog_specs.md
- H3: `BernoulliProbitResponse` (probit/threshold/liability) → `V6-PROBIT`.
- H6: extend the σ²a profile-LRT interval coverage (mostly the Bernoulli leg) → updates
  `V6-FIT` in place; BLAS-heavy coverage run, pace it.
- H7: Nakagawa–Schielzeth / de Villemereuil latent- & observation-scale h² → `V6-NS-H2`.
- C2: `genetic_correlation_interval(fit, …; method = :delta | :profile)` → EXTENDS the
  V4-MV-REML row (append, do NOT change its covered status for the POINT ESTIMATE).
- C6: `bootstrap_variance_component_interval(fit)` (Gaussian REML) → extends V1-HERIT-CI.

### J1 — haplodiploid (LAST; LANDMINE)
The design spec's convention is self-contradictory (stated female rule `½(A_sire+A_dam)`
gives father→daughter = 0.5, but the canonical anchor requires 1.0 — a haploid drone
transmits his whole genome). **DERIVE the diploidized haplodiploid recursion from a
reference + get Mendel/Falconer sign-off BEFORE implementing.** Then impl + oracle +
Rose + maintainer sign-off.

## Disciplines (carry over unchanged)

Covered/partial/planned honesty; Rose claim-vs-evidence audit mandatory before any
public/repo-visibility change (spawn the real `rose-systems-auditor`); **no rushing
correctness-critical genetics/likelihood code** — derive → build an INDEPENDENT oracle
(score/weight vs FD + a limiting-case) → commit only once it passes (the design specs
accelerate but do NOT guarantee correctness; J1 proved a spec can be wrong); funnel
files (`src/validation_status.jl` + `test/runtests.jl` count + `.md` ledgers) serialize
landing — one slice at a time, bump the count assertion + insert NOT-first/NOT-last;
reuse the existing `_loggamma` (no duplicate — precompile breaks); CPU discipline —
`PATH="$HOME/.juliaup/bin:$PATH" OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2
JULIA_NUM_THREADS=1 julia --project=. ...`, one capped run at a time, pace heavy sims;
commit/push frequently; local checks over CI; repo-visible memory over chat. DoD = impl
+ tests + docs + capability-status row + validation-debt row + check-log + after-task +
Rose audit + clean local checks (+ clean CI if pushed) + maintainer sign-off for any
covered promotion.

## How to resume

1. Confirm `#167` (L1) merged; sync main.
2. Start **H2** (beta-binomial) — digested above; full text in doc-15 / `/tmp/backlog_specs.md`.
   Branch per-slice; derive → oracle → Rose → after-task → PR → merge on green.
3. Continue H3 → H6 → H7 → C2 → C6; **J1 last** (derive convention + sign-off first).
4. An untracked prior-session file
   `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`
   (a cross-lane R-twin handoff for hsquared #44 gate 1, "not yet implemented") sits in
   the working tree — left untracked, NOT part of any slice. Decide separately whether
   it belongs in the R repo.
