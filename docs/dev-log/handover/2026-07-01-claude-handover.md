# Handover → next Claude — v0.6 non-Gaussian h² comparator lane (MCMCglmm leg done; lane closing) — 2026-07-01

Meta: 2026-07-01 · from Claude (MCMCglmm h² comparator session) · TARGET = claude · docs-only handoff.
You are Claude, picking up the HSquared.jl **Julia engine lane**. This session added the MCMCglmm
observation-scale h² comparator and then, on the maintainer's instruction, is **closing the lane with a
hand-off** rather than building further. Read this, then the after-task report it links.

## Critical Context (read or you'll go wrong)
1. **The v0.6 non-Gaussian h² comparator work is SPREAD ACROSS BRANCHES and is essentially COMPLETE — do
   NOT rebuild it.** The two comparators the V6-NS-H2 row still lists as "owed" already EXIST on their own
   branches (they're owed only in the sense of "not yet merged to `main`"):
   - **Ordinal (K>2) observed**: engine `h2_observation_by_category` + `comparator/qgglmm_ordinal_observed/`
     → branch `feat/2026-07-01-v06-ordinal-observed-h2` (#223; QGglmm agree ≤3.2e-8 per its `result.txt`).
   - **Gamma (data) scale**: engine Gamma h² + `comparator/qgglmm_gamma_observed/` → branch
     `feat/2026-07-01-v06-gamma-latent-h2` (#222; ≤5e-11). A glmmTMB Gamma *fitting* comparator is on
     `feat/2026-07-01-v06-gamma-recovery`.
2. **Nothing is pushed.** This session's commit lives ONLY locally (see below). Origin is behind. Pushing
   is the maintainer's call — say so loudly.
3. **Honesty pins hold everywhere:** `validation_status()` = **50**, public-covered FITTING = **1**,
   V6-NS-H2 stays **`partial`**. No covered flip happened or should happen without the maintainer's **G10**.

## What Was Accomplished (this session)
- Built the **MCMCglmm observation-scale h² comparator** (`comparator/mcmcglmm_observed/`) — the remaining
  owed h² comparator on the base branch. Poisson, A=I / repeated-records: fit MCMCglmm 2.36 → transform the
  posterior via de Villemereuil's documented QGglmm workflow (`var.a=VCV[,"id"]`, `var.p=rowSums(VCV)`,
  `QGparams(model="Poisson.log")` per draw) → the engine's `h2_observation` point **0.5017 lies inside the
  MCMCglmm 95% CI [0.4491, 0.5153]** (V_units≈0.013 ⇒ var.p≈V_A). A DISTRIBUTIONAL agreement within MCMC
  error — NOT machine precision, NOT unbiasedness.
- Updated **V6-NS-H2 "owed → MCMCglmm RUN"** in lockstep across all 3 status surfaces + the `nongaussian.jl`
  docstring/comment + the doc-14 backlog + doc-19 (two stale "no comparator yet" premises fixed). Also fixed
  a pre-existing drift in `validation_status.jl`'s caveat field.
- **Real `rose-systems-auditor` audit → PROMOTE-WITH-CHANGES → the one change (doc-19) applied → clean
  PROMOTE.** Rose reproduced every number byte-identically and verified the honesty pins.
- Committed the slice (`80a049a4`) and **fast-forwarded the base branch
  `feat/2026-07-01-v06-ordinal-liability-h2` to it (local merge, per the maintainer's choice)**.
- **Reconnaissance finding** (Critical Context #1): confirmed the ordinal + Gamma QGglmm comparators already
  exist on #222/#223, and that **MCMCglmm has NO Gamma family** (`gamma=FALSE`; only `exponential`=Gamma ν=1)
  — so MCMCglmm-Gamma is the wrong tool (glmmTMB is the same-estimand comparator, already present).

Full detail: `docs/dev-log/after-task/2026-07-01-v06-mcmcglmm-observed-h2-comparator.md` +
`docs/dev-log/check-log.d/2026-07-01-v06-mcmcglmm-observed-h2-comparator.md` +
`docs/dev-log/recovery-checkpoints/2026-07-01-mcmcglmm-observed-h2-comparator.md`.

## Branch map — where each non-Gaussian h² comparator lives (the key artifact)
| Scale / family | engine h² | external comparator(s) | branch (PR) |
| --- | --- | --- | --- |
| logit + binary-probit + Poisson + Binomial(n>1) observed | ✓ | QGglmm exact ≤4.5e-6 (`qgglmm_probit_observed/`) **+ MCMCglmm-Poisson distributional (`mcmcglmm_observed/`, THIS session)** | `feat/2026-07-01-v06-ordinal-liability-h2` (= local base, `80a049a4`) |
| probit/ordinal **liability** | ✓ | (closed form; Dempster–Lerner cross-check) | same base |
| **ordinal (K>2) observed / per-category** | ✓ `h2_observation_by_category` | QGglmm `model=ordinal` ≤3.2e-8 (`qgglmm_ordinal_observed/`) | `feat/2026-07-01-v06-ordinal-observed-h2` (#223) |
| **Gamma latent + data** | ✓ | QGglmm custom-Gamma ≤5e-11 (`qgglmm_gamma_observed/`) + glmmTMB Gamma fit | `feat/2026-07-01-v06-gamma-latent-h2` (#222) + `…-gamma-recovery` |
| ordinal/Gamma family FITTING (joint estimate + recovery gate) | ✓ | `ordinal::clmm` / `glmmTMB Gamma` + 48-seed gates | #215–#220 (see session-close handover) |

## Current Working State
- **Working:** the MCMCglmm-Poisson comparator (reproducible, seeded); `Pkg.test()` green (count guard 50);
  `docs/make.jl` exit 0. Base branch `feat/2026-07-01-v06-ordinal-liability-h2` locally contains it.
- **In progress / owed (mechanical, maintainer):** consolidating #215–#223 + this MCMCglmm leg onto `main`
  — the **9-PR merge recipe is in `docs/dev-log/handover/2026-07-01-session-close-handover.md`** (verified
  keep-both trial-merges). This session did NOT run that recipe (hand-off chosen).
- **Blocked (human-only):** the Fisher/Falconer sign-off on the h² decomposition; the **G10** covered flip;
  the R-bridge activation of `nongaussian_heritability` (cross-repo — the R twin `hsquared`, NOT editable
  from this lane).

## Key Decisions & Rationale
- **Poisson, not probit, for the MCMCglmm leg** — the probit route is a verified `var.p`-convention trap
  (`QGparams(binom1.probit, var.p=V_A+1)`=0.102 vs engine 0.170); Poisson's `var.p=rowSums(VCV)` is
  unambiguous (de Villemereuil vignette).
- **Framed distributional, not machine-precision** — MCMCglmm is Bayesian and shares the Poisson-GLMM
  information limit; agreement = engine point inside the posterior CI, nothing stronger.
- **Local merge, not pushed** — the maintainer chose "merge locally into base" for this slice.
- **Hand off rather than build MCMCglmm-ordinal** — the maintainer chose hand-off after learning the QGglmm
  ordinal/Gamma comparators already exist; the marginal MCMCglmm-ordinal leg (buildable but fiddly re
  cutpoints, on top of #223) was deliberately NOT built.

## Files Created / Modified (this session; all in commit `80a049a4` unless noted)
- **NEW** `comparator/mcmcglmm_observed/{generate.jl,run_mcmcglmm.R,README.md,result.txt,.gitignore}`
  (generated `data.csv`/`engine_h2.csv`/`mcmcglmm_h2_agreement.csv` are git-ignored — never commit them).
- **NEW** `docs/dev-log/{recovery-checkpoints,check-log.d,after-task}/…-mcmcglmm-observed-h2-comparator.md`.
- **MODIFIED** `src/validation_status.jl`, `src/nongaussian.jl`, `docs/design/{capability-status.md,
  validation-debt-register.md,14-program-backlog.md,19-h2-scale-contract.md}`.
- **THIS handover** `docs/dev-log/handover/2026-07-01-claude-handover.md` + the `AGENTS.md` snapshot bullet
  (committed separately, on top of `80a049a4`).

## Next Immediate Steps (ordered)
1. **Maintainer:** decide whether to push `feat/2026-07-01-v06-ordinal-liability-h2` (now carrying the
   MCMCglmm leg) to origin, or fold it into the 9-PR batch.
2. **Maintainer:** run the 9-PR merge recipe (session-close handover) to consolidate #215–#223 + this leg → `main`.
3. **Human:** Fisher/Falconer sign-off on the h² decomposition; then the **G10** covered flip (would move
   public-covered fitting 1→3 for ordinal+Gamma FITTING — the h² transform itself stays a scale-labelled
   partial surface).
4. **Cross-repo (R lane):** activate `nongaussian_heritability` in `hsquared` (scale label must travel the
   bridge; doc-19 §6).
5. **Optional, low-priority:** the MCMCglmm-ordinal distributional leg on top of #223 (marginal — QGglmm
   already covers ordinal exactly).

## Blockers / Open Questions
- **Unpushed** — this lane's work is local only; if not pushed it is fragile. Maintainer's call.
- Human-only: Fisher/Falconer review + G10 (cannot be delegated).

## Gotchas & Failed Approaches (don't retry)
- **Do NOT rebuild the ordinal/Gamma QGglmm comparators** — they exist on #222/#223.
- **Do NOT attempt an MCMCglmm-Gamma comparator** — MCMCglmm has no Gamma family; glmmTMB is the tool.
- The probit `var.p = V_A + 1` convention gives a wrong (0.102 vs 0.170) answer — a documented trap.
- Branch topology is a thicket of divergent stacked branches; the h² work is fragmented across #221/#222/#223.

## How to Resume
1. Run the `hsquared-rehydrate` skill (live git/CI + `ROADMAP.md`, coordination board, check-log, newest
   after-task, `capability-status.md`, `validation-debt-register.md`).
2. Read this doc + the `AGENTS.md` snapshot + the session-close handover (for the 9-PR merge recipe).
3. Spawn a real `rose-systems-auditor` before ANY covered claim. Claude plans/refactors/writes prose + runs
   `Pkg.test()` / `docs/make.jl`; the live MCMCglmm/QGglmm/glmmTMB runs need R 4.6.0 at `/usr/local/bin/Rscript`.

### One-command resume (paste in your OWN authenticated terminal, from the repo root)
```
claude "Rehydrate from docs/dev-log/handover/2026-07-01-claude-handover.md + the AGENTS.md snapshot. The v0.6 non-Gaussian h² comparator lane is complete (MCMCglmm-Poisson leg merged locally into feat/2026-07-01-v06-ordinal-liability-h2; QGglmm ordinal/Gamma comparators live on #222/#223). Do NOT rebuild them. Next: (maintainer) push + 9-PR merge recipe; (human) Fisher/Falconer + G10. Do NOT flip covered without G10."
```

## Mission-control summary
| Field | State |
| --- | --- |
| Lane | HSquared.jl Julia engine — v0.6 non-Gaussian h² comparators |
| Local base branch | `feat/2026-07-01-v06-ordinal-liability-h2` @ `80a049a4` (carries the MCMCglmm-Poisson leg) — **UNPUSHED** |
| `main` | `94d20319` (untouched); origin base behind by 1 |
| CI | not pushed → not run; local `Pkg.test()` green (count 50) + `docs/make.jl` exit 0 |
| Comparators | logit/probit/Poisson/binomN + MCMCglmm-Poisson (base) · ordinal QGglmm (#223) · Gamma QGglmm+glmmTMB (#222/recovery) |
| Honesty pins | count 50 · public-covered fitting 1 · V6-NS-H2 partial — nothing flipped |
| Rose | PROMOTE (this session's MCMCglmm slice) |
| Highest-leverage next | maintainer 9-PR merge → Fisher/Falconer → G10 |
