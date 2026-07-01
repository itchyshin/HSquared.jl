# Handover → next session — v0.6 non-Gaussian h² surface COMPLETE (2026-07-01, session close)

Meta: 2026-07-01 ~05:30 MDT · from Claude (overnight autonomous + maintainer-engaged close) · the
definitive session-close handover. Supersedes the incrementally-edited `2026-07-01-claude-handover.md`
(still valid; this is the clean consolidated version).

## Mission-control snapshot

| Field | State |
| --- | --- |
| Programme goal (`/goal`) | *finish — Fast & Accurate Algorithms for Mixed & Latent-Variable Model Fitting (HSquared · DRM · GLLVM)* — long-horizon; this session completed the **v0.6 non-Gaussian heritability** slice of it |
| `main` | `94d20319` — count **50**, covered 8, covered_external 3, partial 38, planned 1; **public-covered FITTING = 1** (v0.1 Gaussian). UNCHANGED all session |
| Open PRs | **9** (#215–#223), all Rose-clean, CI-green, nothing flipped to covered |
| Headline | The **entire non-Gaussian h² surface** (latent/liability/observation for every family) is now implemented and **externally validated against the QGglmm reference package** |
| Honesty pins | count 50 · public-covered fitting 1 · no "unbiased"/"covered" drift · engine-covered ≠ R-public-covered |

## The 9 open PRs

**Two family chains (fitting; covered-READY — joint estimator + agreeing same-estimand comparator + passing pre-declared 48-seed gate):**
- Ordinal: **#215** (joint `fit_laplace_reml(family=:ordered_probit)`) → **#218** (`ordinal::clmm` comparator) → **#220** (48-seed recovery gate)
- Gamma: **#216** (joint `family=:gamma`) → **#217** (`glmmTMB Gamma` comparator) → **#219** (48-seed recovery gate) *(also carries the Gamma rail fix + this handover)*

**h² surface (the `nongaussian_heritability` transform; all externally QGglmm-validated):**
- **#221** — threshold **liability** + **binary observed-0/1** + the **QGglmm comparator for the 4 builtin observation scales** (logit, probit, Poisson, binomN; 25 comparisons, ≤4.5e-6)
- **#223** — **ordinal (K>2) per-category observed** h² (vector field `h2_observation_by_category`; validated ≤3.2e-8 vs `model=ordinal`); **stacked on #221**
- **#222** — Gamma **latent** (trigamma `V_link`) + Gamma **data** scale (validated ≤5e-11 vs a QGglmm custom Gamma model)

## The h² ledger — every cell done + externally validated

| Family | Latent/liability | Observation/data | QGglmm comparator |
| --- | --- | --- | --- |
| Bernoulli/Binomial (logit) | ✓ | ✓ (GH) | ✓ binom1/binomN.logit ≤2.5e-6 |
| Bernoulli-probit | ✓ liability | ✓ (= Dempster–Lerner) | ✓ binom1.probit ≤4.5e-6 |
| Poisson | NaN (correct) | ✓ (log-normal) | ✓ Poisson.log ≤1.7e-16 |
| Gamma | ✓ trigamma | ✓ multiplicative closed form | ✓ custom Gamma ≤5e-11 |
| Ordinal K>2 | ✓ liability | ✓ per-category vector | ✓ model=ordinal ≤3.2e-8 |

## Verified merge recipe (I ran throwaway trial-merges — all keep-both, suites green)

- **Family chains onto `main`:** ordinal (#215→#218→#220) then gamma (#216→#217→#219) — 3 trivial keep-both conflicts (the `fit_laplace_reml` allow-list + the two `elseif` cases + the two joint-estimation testsets; `validation_status.jl`/`test` auto-merge). Verified green earlier.
- **h² stack:** #223 (includes #221) + #222 — the SAME keep-both pattern on 5 files (`src/nongaussian.jl` `_nongaussian_h2_core` — keep the probit/ordinal AND the `:gamma` branch; `test/runtests.jl` — both testsets; `src/validation_status.jl` + `capability-status.md` + `validation-debt-register.md` — combine both surfaces' V6-NS-H2 evidence/owed additions). All "keep both / combine", no logic conflict.
- **AGENTS.md snapshot** — each session prepends a bullet; trivial keep-both (like #213↔#211).

## What is maintainer-gated (NOT autonomous)

1. **Merge the 9 PRs** (recipe above). Autonomous push to `main` is blocked by policy.
2. **G10 — the covered flip.** Ordinal + Gamma families have every doc-16 prerequisite; flipping `partial → covered` moves **public-covered fitting 1 → 3**. Non-delegable; wants a final full-chain Rose.

## Remaining programme (beyond this session)

- **MCMCglmm** same-estimand comparator (the other owed h² comparator; heavy Bayesian).
- **Fisher/Falconer** sign-off on the h² decomposition (human review).
- h² **intervals/SEs**, the **R-bridge** activation of `nongaussian_heritability` (cross-repo — the R twin `hsquared`, not edited from here).
- v0.4 broader-DGP MV recovery; V5 standing debt (GCTA 2nd comparator); v0.7+ phases.

## Rehydration recipe for the next session

1. Run the `hsquared-rehydrate` skill (live git/CI + ROADMAP, coordination board, check-log, newest after-task, capability-status, validation-debt-register).
2. Read this handover; confirm honesty pins on `main` (`grep public_covered tools/status_cache.json` → 1; count guard `test/runtests.jl:174` `== 50`).
3. Spawn a real `rose-systems-auditor` before ANY covered claim.

## One-command resume (paste in an authenticated terminal)

```
claude "Rehydrate from docs/dev-log/handover/2026-07-01-session-close-handover.md. The v0.6 non-Gaussian h² surface is complete across 9 Rose-clean PRs (#215–#223), all externally QGglmm-validated. Next: either run a verified full 9-PR trial-merge + hand me the recipe, or (maintainer-gated) the merge + G10. Do NOT flip covered without maintainer G10."
```

## Tooling banked this session

- **QGglmm 0.8.0** installed (CRAN) — the external h² reference; comparators live in `comparator/qgglmm_probit_observed/` (logit/probit/Poisson/binomN + a general harness) and `comparator/qgglmm_ordinal_observed/` (ordinal); the Gamma custom-model comparator in `comparator/qgglmm_gamma_observed/`.
- Convention pinned (the load-bearing one QGglmm caught): `var.p` for the observation integration is the **predictor variance** `V_A+V_fixed`, NOT `V_A+V_link+V_fixed`.
