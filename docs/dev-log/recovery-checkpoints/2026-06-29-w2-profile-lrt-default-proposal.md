# Proposal — should the default heritability interval switch from delta/Wald to profile-LRT?

Status: **PROPOSAL for Rose + maintainer (G10) — no change made.** A public-contract recommendation
(it would change `heritability_interval`'s default + the R twin), so it is gated on maintainer sign-off +
R-twin coordination (Codex). `validation_status()` unchanged; public-covered = 1; `V1-HERIT-TCAL` planned.

## The evidence (W1 Campaign 1, committed)

The predeclared small-sample coverage simulation (tiny/small/medium × h²∈{0.1,0.3,0.5,0.7} × {0.90,0.95},
1000 reps/cell, coverage on `interval_success`; `2026-06-29-w1-c1-interval-coverage*` + `…-medium-coverage*`)
ranks the three EXISTING interval methods at the 95% level (interpretable cells):

| method | σ²a (small→medium, representative) | h² | verdict |
|---|---|---|---|
| **delta / Wald (current default)** | 0.842–0.917 (h²=0.5) — **under-covers** | over-covers at high h² | the *current* default is the *worst*-calibrated for σ²a |
| **profile-LRT** | **0.949–0.957** (h²=0.3/0.5) — near-nominal | 0.943–0.960 | **best-calibrated** existing method |
| bootstrap | 0.865–0.905 — under-covers | under-covers | finite-sample-aware but not calibrated |

Cross-design: the σ²a under-coverage **improves toward nominal as n grows** (small-sample effect), with a
residual high-h² narrowness (~0.86 even at q=240, where profile too dips). The boundary non-interpretability
of tiny/low-h² resolves by q=240.

## Recommendation

**Profile-LRT is the better existing default** — it is near-nominal where the delta interval under-covers
σ²a, and it self-describes its clamp flags on flat surfaces. The current delta/Wald default is the least
calibrated of the three for the additive variance.

## The decision (maintainer)

| option | pro | con |
|---|---|---|
| **(a) switch default → `:profile` now** | immediate, evidence-backed calibration improvement; uses an already-implemented, already-tested method (no new code) | still under-covers at high h² (not a full fix); changes user-facing default → R-twin coordination + a deprecation/communication step |
| **(b) hold; wait for calibrated `V1-HERIT-TCAL`** | one coherent change; the planned method targets the boundary + high-h² regime the C1 data exposes | leaves the *worst*-calibrated method as the default in the interim |
| **(c) keep delta default, document profile as the recommended opt-in** | zero contract change | the default stays mis-calibrated; users must know to opt in |

**My recommendation:** (a) **or** (c) — both stop shipping the least-calibrated method as the silent default.
(a) is the cleaner user outcome if the R-twin change is coordinated; (c) is the zero-risk interim. Either
way the C1 evidence says the *current* delta default should not stand unflagged.

## Fences

- This is a recommendation, **not a change**. No default is altered here; no code touched.
- A default change touches the **public R↔Julia contract** → requires both twins updated (Codex) +
  maintainer **G10** + a real **Rose** audit of the new default's claim.
- Profile-LRT is an *improvement*, **not** a calibrated fix — `V1-HERIT-TCAL` (the boundary + high-h²
  calibration) stays the planned end state regardless of this interim choice.
- `validation_status()` = 48 unchanged; public-covered = 1.
