# Proposal — should the default heritability interval switch from delta/Wald to profile-LRT?

Status: **PROPOSAL for Rose + maintainer (G10) — no change made.** A public-contract recommendation
(it would change `heritability_interval`'s default + the R twin), so it is gated on maintainer sign-off +
R-twin coordination (Codex). `validation_status()` unchanged; public-covered = 1; `V1-HERIT-TCAL` planned.

## The evidence (W1 Campaign 1, committed; numbers re-derived from the committed TSVs)

The predeclared coverage sim (1000 reps/cell; `2026-06-29-w1-c1-interval-coverage.tsv` +
`…-medium-coverage.tsv`), level 0.95. **The ranking is on INTERPRETABLE cells only** — small design h²≥0.3
and all medium cells; tiny and small-h²=0.1 are boundary-dominated (`interval_success` 57–86%, coverage on a
selected subsample) and excluded. (An earlier draft cited a level-lumped medium *summary*; numbers below
come straight from the level-separated TSVs.)

| method (95%) | σ²a small (h²=0.3/0.5/0.7) | σ²a medium | h² (small / medium, repr.) | failure mode |
|---|---|---|---|---|
| **delta/Wald (current default)** | 0.855 / 0.842 / 0.915 — **under** | 0.944 / 0.925 / 0.870 | over-covers (0.96–0.99) | **anti-conservative** for σ²a at small n; conservative for h² |
| **profile-LRT** | 0.902 / 0.949 / 0.971 | 0.984 / 0.965 / 0.882 — **over** at medium | near-nominal (0.94–0.96) | **conservative** (over-covers σ²a at medium; best for h²) |
| bootstrap | 0.907 / 0.865 / 0.931 — under | 0.884 / 0.919 / 0.870 — under | under-covers | under (not calibrated) |

Cross-design: the σ²a delta under-coverage **improves toward nominal with n** (0.842→0.925 at h²=0.5,
small→medium); a residual high-h² narrowness (~0.87 across *all three* methods) persists at q=240.

## Recommendation

The methods are **not** uniformly ordered, so the case is about **failure mode, not "closest to nominal":**
profile-LRT is near-nominal for h² and **conservative** for σ²a (it *over*-covers at medium), while
delta/Wald is conservative for h² but **anti-conservative for σ²a at small n** — its under-coverage is the
single most dangerous failure (a too-narrow interval that overstates precision). **An anti-conservative
default interval is the worse error for users.** That — not "profile is best-calibrated everywhere" (it is
not: profile slightly under-covers h²=0.3 in the small design and over-covers σ²a at medium) — is the honest
argument that the current delta default should not stand unflagged. Profile also self-describes its clamp
flags on flat surfaces.

## The decision (maintainer)

| option | pro | con |
|---|---|---|
| **(a) switch default → `:profile` now** | trades an anti-conservative default for a conservative one; uses an already-implemented, already-tested method (no new code — a one-keyword flip at `src/likelihood.jl:1464` + inverting one test assertion) | still under-covers σ²a at high h² (~0.88) and *over*-covers σ²a at medium — an improvement in failure mode, **not** a uniform calibration win or a fix; changes the user-facing default → R-twin coordination + an **R doc edit** + a deprecation/communication step |
| **(b) hold; wait for calibrated `V1-HERIT-TCAL`** | one coherent change; the planned method targets the boundary + high-h² regime the C1 data exposes | leaves the *worst*-calibrated method as the default in the interim |
| **(c) keep delta default, document profile as the recommended opt-in** | zero contract change | the default stays mis-calibrated; users must know to opt in |

**My recommendation:** (a) **or** (c) — both stop shipping the least-calibrated method as the silent default.
(a) is the cleaner user outcome if the R-twin change is coordinated; (c) is the zero-risk interim. Either
way the C1 evidence says the *current* delta default should not stand unflagged.

## Fences

- This is a recommendation, **not a change**. No default is altered here; no code touched.
- A default change touches the **public R↔Julia contract** → requires both twins updated (Codex) +
  maintainer **G10** + a real **Rose** audit of the new default's claim.
- Mechanics (for the maintainer): a Julia default flip changes R behavior with **no R code change** (R
  `heritability_interval.hsquared_fit` is a thin engine pass-through), BUT the R roxygen docstring describes
  the delta/logit method and says `se` is "NA for the profile method" — so it needs an **R documentation
  edit**, not just communication.
- Status note (Rose): this proposal was **Rose-audited (clean-with-changes → revised)** — the ranking is
  scoped to interpretable cells, numbers re-derived from the committed TSVs, and the claim framed as
  failure-mode (conservative vs anti-conservative), not "best-calibrated everywhere."
- Profile-LRT is an *improvement*, **not** a calibrated fix — `V1-HERIT-TCAL` (the boundary + high-h²
  calibration) stays the planned end state regardless of this interim choice.
- `validation_status()` = 48 unchanged; public-covered = 1.
