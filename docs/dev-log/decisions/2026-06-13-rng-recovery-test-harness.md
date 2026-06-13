# Decision needed: an RNG-based recovery-test harness (or not)

Status: **resolved (hybrid) — same day, user-approved.** CI stays RNG-free;
estimators ship with deterministic correctness checks in CI + a one-off seeded
recovery documented in the after-task. The 3-component repeatability REML
(`fit_repeatability_reml`) was shipped on this basis. A committed seeded recovery
*harness* remains future (open sub-item).
Date: 2026-06-13. Lens: Curie (validation), Fisher (inference), Gauss (numerics).

## Context

The test suite is currently **RNG-free** (verified: no `rand`/`randn`/`seed!`,
no `Random` dependency). That keeps tests deterministic and version-robust, and
it has been fine through Phases 1–2.

But three capabilities have a validation that fundamentally needs *realistic
simulated data*, because the property under test is **statistical recovery** at
an **interior optimum**, which a tiny hand-built fixture cannot provide:

1. **Genomic REML** — shipped with deterministic evidence (AI == NelderMead
   optimum) + a *one-off, uncommitted* seeded recovery (σ²g 1.0 → 0.997). See
   `2026-06-13-genomic-reml.md`.
2. **Heritability-interval coverage** — the logit-delta interval is shipped, but
   its *coverage* is unvalidated; coverage calibration needs simulation. See
   `2026-06-13-heritability-interval-design.md`.
3. **Multi-component (≥3) REML** for the repeatability / permanent-environment
   model — prototyped this session: the dense 2-random-effect REML log-likelihood
   is **verified correct** (matches the animal-model REML up to a constant to
   1e-6) and a NelderMead optimum is a local max. But on a 4-animal fixture the
   optimum sits on a **boundary** (σ²a=0 or σ²pe=0, depending on the hand-chosen
   `y`) — separating additive from permanent-environment variance needs
   relationship contrast + replication that only larger/simulated data provide.
   So the *estimator* was **not shipped** (only the supplied-variance
   `repeatability_mme` was).

## Options

- **Introduce a seeded simulation test module** (e.g. `test/simulations.jl`) with
  a fixed seed and **version-robust loose bounds** (assert recovery within, say,
  ±25%, not pinned values), used for recovery tests across genomic REML,
  multi-component REML, and h² coverage. Risk: RNG streams can shift across Julia
  minor versions → must use loose bounds and large-ish n, never pinned draws.
- **Keep deterministic-only** and validate estimators by loglik-correctness +
  local-max + reduction properties only (no recovery claim), documenting recovery
  as one-off probes (the current genomic-REML approach).
- **Hybrid**: deterministic correctness in the suite + a separate, opt-in
  simulation script (not run in CI) for recovery, recorded in after-task reports.

## Recommendation

Adopt the **hybrid**: keep the CI suite deterministic; add an opt-in
`sim/` recovery script (seeded, loose bounds) that the dev runs and records, so
recovery evidence is reproducible without making CI RNG-dependent. Then ship the
3-component REML estimator (+ repeatability coefficient `t` and its interval)
with deterministic correctness in CI and recovery in the opt-in script.

This is a discipline call (does CI gain RNG?) — flagged for the user before
shipping the multi-component REML estimator.

## Outcome

`fit_repeatability_reml` (3-component REML, returning the repeatability `t` and
`h²`) **was shipped** under the hybrid: deterministic correctness checks in CI
(loglik reduces to the animal-model REML at σ²pe=0; BLUPs match `repeatability_mme`;
optimum beats a grid) + a one-off seeded recovery documented in the after-task
(CI stays RNG-free). Open sub-items: a committed seeded-recovery *harness*,
`t`/`h²` uncertainty intervals, and ML information.
