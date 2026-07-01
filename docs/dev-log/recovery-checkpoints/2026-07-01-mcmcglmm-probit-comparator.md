# MCMCglmm same-estimand h² comparator — RUN + AGREES (probit liability, 2026-07-01)

**What.** The last owed external comparator for the V6-NS-H2 non-Gaussian h² surface (the
QGglmm legs are banked; an MCMCglmm leg was still owed). MCMCglmm is Bayesian, so this is a
**distributional** same-estimand check: the engine's Laplace *point* estimate must fall inside
MCMCglmm's Bayesian **95% credible interval** — agreement within MCMC error, NOT a
machine-precision identity.

**Design (the clean match): probit LIABILITY.** MCMCglmm `family="threshold"` fixes the
residual variance at 1 == the engine's probit convention `V_link = 1` (Dempster–Lerner). Both
sides fit the same simulated liability-threshold binary dataset (`G=400 × n=8`, σ²a=0.8). Engine:
`fit_laplace_reml(:bernoulli_probit)` (on `main`, #171) → σ̂²a, `h²_liab = σ̂²a/(σ̂²a+1)`, QGglmm
`binom1.probit` observed h² (the exact PR-branch `nongaussian_heritability` formulas). MCMCglmm:
posterior of (VA, μ) → the same transforms per draw. Harness: `comparator/mcmcglmm_observed/`.

**Result (seed 20260701, eff. size ~1000 — all three engine points INSIDE the 95% CrI):**

| quantity | engine point | MCMCglmm [95% CrI] | agree |
| --- | --- | --- | --- |
| σ²a | 0.7540 | 0.7875 [0.6250, 0.9672] | INSIDE |
| h²_liability | 0.4299 | 0.4392 [0.3846, 0.4917] | INSIDE |
| h²_observed | 0.2736 | 0.2795 [0.2447, 0.3129] | INSIDE |

**Pitfall banked.** The naive LOGIT comparison (engine `:bernoulli` vs MCMCglmm
`family="categorical"` with the residual pinned ≈0) gave VA=0.284 vs the engine's 1.109 on the
SAME data (~4× off) despite clean mixing — the known MCMCglmm categorical fixed-residual
convention issue. The probit/threshold design is the correct same-estimand match; the logit one
is documented as a dead end in the README so it is not re-tread.

**Honesty fence.** Evidence toward the owed MCMCglmm comparator, on the probit
liability/observed scale (Fisher/Falconer's flagged primary scale). It does NOT flip covered.
**For the real #221/#223 PR:** the V6-NS-H2 `missing`/`owed` field can move from "an MCMCglmm
comparator [owed]" to "MCMCglmm probit-liability comparator RUN + AGREES (within MCMC error;
`comparator/mcmcglmm_observed/`); the ordinal-K>2 + Gamma MCMCglmm legs still owed." Still owed
independently: the MCMCglmm ordinal + Gamma legs, the maintainer Fisher/Falconer sign-off, and
the maintainer **G10** covered flip. V6-NS-H2 / V6-ORDINAL / V6-GAMMA stay `partial`; count 50 /
public-covered 1 UNCHANGED (this ran on `main` + a comparator dir; no engine/status change).
