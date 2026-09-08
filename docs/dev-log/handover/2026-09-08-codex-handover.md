# Handover to Codex — h² three-scale naming per de Villemereuil et al. 2016

**Date:** 2026-09-08 · **Author:** Claude Code · **Branch:** `claude/h2-three-scale-naming-20260908` (from `origin/main`)
**Status:** SPECIFICATION ONLY — no source file has been modified. Implementation is yours.

You are Codex, picking this up cold. You never saw the conversation that produced it, so
everything you need is here. **This is a maintainer-approved contract change**, not a
proposal: Shinichi read the paper during the session and said *"use paper naming, all three
scales"*, then *"please liaise with codex — they are running H2 projects"* and *"this
pertains to other projects"*.

---

## Critical context — what is wrong today

`src/nongaussian.jl` (on `origin/main`) computes a **`h2_latent`** that means two different
things depending on family, and refuses to compute it at all for one of them:

| line (main) | family | what it does |
|---|---|---|
| `1196-1197` | `:poisson` (log) | **`h2_latent = NaN`**, caveat *"latent h² is degenerate (no latent residual)"* |
| `1204`, `1213` | `:bernoulli` / `:binomial` (logit) | `latent_total = V_A + _VAR_LOGISTIC + V_fixed`; `h2_latent = V_A / latent_total` |

**Two defects, and the second is the bigger one.**

1. **The Poisson `NaN` rests on a false premise.** *"No latent residual"* is not true — the
   latent residual is the **overdispersion** term, which in this function's own
   parameterisation is `sigma_e2`. It is already in scope.
2. **The Bernoulli branch is mislabelled.** Adding `π²/3` does **not** give the latent scale.
   It gives the **liability** scale. So one function currently exports one field name for two
   different quantities.

---

## The authority — de Villemereuil, Schielzeth, Nakagawa & Morrissey (2016)

*General Methods for Evolutionary Quantitative Genetic Inference from Generalized Mixed
Models*, **Genetics 204:1281–1294**, doi:10.1534/genetics.115.186536. Open access.
**Shinichi is an author** — this is the house authority, and its terminology is what users
will look up.

The framework has **three scales** (its Figure 1; Eqs 3a–3c):

    ℓ = μ + Xb + Z_a a + … + o        (3a)  LATENT scale.  `o` = overdispersion, variance V_O
    η = g⁻¹(ℓ)                        (3b)  EXPECTED DATA scale
    z ~ D(η, θ)                       (3c)  OBSERVED DATA scale

### The equations to implement

**Eq 4 — latent scale. No distribution variance, no link variance. Defined for EVERY family.**

    h²_lat = V_A,ℓ / (V_A,ℓ + V_RE + V_O)

**Eq 24 — liability scale (binomial/threshold families ONLY).** Adds the *link* variance `V_L`:

    h²_liab = V_A,ℓ / (V_A,ℓ + V_RE + V_O + V_L)          V_L = 1 (probit), π²/3 (logit)

> The paper is explicit, p1287: *"this liability scale is **not the same as** the latent scale
> hereby defined for the GLMM."* That sentence is the whole reason this handover exists.

**Eq 26/27 — observed data scale, Poisson + log (exact, Foulley & Im 1993):**

    h²_obs = λ·V_A,ℓ / ( λ·[exp(V_A,ℓ + V_RE + V_O) − 1] + 1 )
    λ      = exp( μ + (V_A,ℓ + V_RE + V_O)/2 )                            (27)

**Eq 28 — observed-scale ICC / repeatability, Poisson + log (this is the one the
repeatability work needs):**

    H²_obs = λ·(exp(V_A,ℓ) − 1) / ( λ·[exp(V_A,ℓ + V_RE + V_O) − 1] + 1 )

**Eq 25 — binomial + probit, liability → observed:** `h²_obs = t²/(p(1−p)) · h²_liab`,
`p` = incidence, `t` = standard normal density at the `p`th quantile.

---

## The decision (Shinichi, 2026-09-08)

**Use the paper's names. Report all three scales. Never return `NaN` for a quantity that is
defined.**

| field | equation | applies to |
|---|---|---|
| `h2_latent` | Eq 4 | **every** family, Poisson included |
| `h2_liability` | Eq 24 | binomial/bernoulli (logit, probit, cloglog) **only**; `nothing`/absent elsewhere |
| `h2_observation` | Eq 26 (Poisson-log), Eq 25 (binomial-probit) | every family |

`h2_liability` is a **new** field. `h2_latent` **changes meaning for binomial families** — it
must stop including `π²/3`; that value moves to `h2_liability`. **This is a breaking change to
a public contract.** Treat it as such: NEWS entry, version bump, and a migration note saying
plainly that a binomial `h2_latent` from an earlier version equals the new `h2_liability`.

---

## Why this is NOT the `ln(1 + 1/λ)` fix you may have seen suggested

Three independent LLM reviews of this question all proposed
`h2_latent = σ²_A / (σ²_A + σ²_E + ln(1 + 1/λ̄))`. **Do not implement that as `h2_latent`.**
That term is the Nakagawa & Schielzeth (2010) *distribution-specific variance* — an
**approximation convention** for a data-scale ICC, mean-dependent, and **not** the latent
scale of Eq 4. Eq 4 needs **no** extra term. Exact observed-scale results already exist
(Eqs 26/28), so the approximation is not needed anywhere in this package.

---

## Cross-project scope — "this pertains to other projects" (Shinichi)

The same three-scale confusion is very likely present, in the same shape, elsewhere. **Audit,
do not assume:**

- **`hsquared` (the R twin).** Measured 2026-09-08: **no** `h2_latent` / `h2_observation` /
  `latent_total` anywhere in `R/`, and no `ln(1+1/λ)`. It exports `heritability()`,
  `direct_heritability()`, `heritability_interval()`, `heritability_standard_error()`
  (see `NAMESPACE`). So the twin has **no** non-Gaussian scale surface yet — decide whether
  it gains the same three-field contract or explicitly documents that it is Gaussian-only.
  **Do not let the twins diverge silently**; that is what the parity apparatus exists to stop.
- **`gllvmTMB` — there is an existing, documented decision that uses the OTHER convention.**
  `docs/dev-log/audits/2026-05-17-link-residual-design-decision.md` adds `π²/3` (logit), `1`
  (probit), `π²/6` (cloglog) to the **latent-scale Σ**, and calls it *"the correct latent-scale
  repeatability denominator"*. Under Eq 4/Eq 24 that is the **liability** scale. **The audit's
  reasoning is good** (ascertainment invariance; link-defined constants) — the issue is purely
  the NAME. Reconcile the vocabulary across packages; do not silently flip gllvmTMB's numbers.
- **`drmTMB` / `DRM.jl` / `GLLVM.jl` — repeatability.** Any ICC/repeatability on a non-Gaussian
  scale faces the identical triad. **Eq 28** is the exact Poisson-log observed-scale ICC.

---

## Files created / modified by THIS handover

- `docs/dev-log/handover/2026-09-08-codex-handover.md` (this file) — **new**
- `docs/dev-log/coordination-board.md` — one entry under Active Lane Split
- **No source file touched.** `src/nongaussian.jl` is unmodified.

---

## Next immediate steps (yours)

1. Read `src/nongaussian.jl` around lines **1161–1215** on `origin/main`.
2. Implement the three fields per the table above. Keep `var_link` / `var_distribution`
   reporting; they are the ingredients and are useful.
3. **Tests — known-answer, not just smoke.** Minimum:
   - Poisson-log `h2_latent` equals `V_A/(V_A+V_RE+V_O)` **exactly**, and is finite for
     every input where the old code returned `NaN` (a direct regression test on the defect).
   - Binomial-logit `h2_liability` reproduces the **old** `h2_latent` value bit-for-bit
     (proves the value moved rather than changed).
   - Binomial-logit `h2_latent` (new) is **strictly greater** than `h2_liability` whenever
     `V_L > 0` — the denominator shrank.
   - Eq 26 against a Monte-Carlo simulation from known parameters (recovery, not parity).
   - Eq 28 likewise, since repeatability is the cross-project ask.
   - A **negative control**: perturb one constant and confirm the suite goes red.
4. `julia --project=. -e 'using Pkg; Pkg.test()'`
5. NEWS + migration note (breaking change, see above).
6. Rose close-out before any public claim.

## Blockers / open questions for the maintainer

- **`hsquared` scope:** add the three-field contract, or document Gaussian-only? Not decided.
- **`gllvmTMB` rename:** its `link_residual` decision is sound but uses "latent" for what the
  paper calls liability. Renaming touches a public surface — Shinichi's call.
- **Fixed effects:** Eqs 17–19 marginalise over fixed effects. This function carries
  `V_fixed`/`predictor_variance`; confirm which convention each reported scale assumes and
  document it. The paper is emphatic that fixed effects materially move data-scale quantities.

## Gotchas

- **Lane traffic is heavy.** `tools/lane_preflight.sh` reported **7 lanes live** on 2026-09-08
  and `src/nongaussian.jl` is contained in **four** codex branches —
  `codex/hsq09-ng-contract-julia-repair`, `codex/hsq09-s8-julia-claim-surface`,
  `codex/hsq09-s9-evidence-manifest`, `codex/hsq09-h1t-telemetry-amendment`. **`ng-contract-julia-repair`
  is editing this exact logic** (`cc2db0d0`, +184/−8 vs main). Coordinate before you write, or
  you will collide.
- This branch is cut from **`origin/main`**, which is *behind* `ng-contract-julia-repair`. If
  that lane lands first, rebase onto it rather than reverting its work.
- The working checkout was on `codex/2026-07-13-v07-performance-localization` with foreign
  untracked files (`.claude/agents/shannon.md`, `sim/phase2_*.jl`). **Never stage those.**

## How to resume

    cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
    git fetch origin && git checkout claude/h2-three-scale-naming-20260908
    cat docs/dev-log/handover/2026-09-08-codex-handover.md
    bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD"      # 7 lanes live as of 2026-09-08
    julia --project=. -e 'using Pkg; Pkg.instantiate()'

`AGENTS.md` is native to you — read it first. Team mirror in `.codex/agents/*.toml`; **Rose
audit is mandatory** before any "done / fixed / passing" claim. You run the live toolchain
here (real Julia fits, `Pkg.test()`, simulation) — this specification was written by a
planning-side session that deliberately did not fit anything.

> Related: `docs/dev-log/coordination-board.md` · `AGENTS.md` · de Villemereuil et al. 2016,
> Genetics 204:1281–1294 · `gllvmTMB/docs/dev-log/audits/2026-05-17-link-residual-design-decision.md`
