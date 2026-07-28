# Handover → next Claude (HSquared.jl, Julia engine lane) — 2026-07-28 (canonical entrypoint)

**Branch:** `codex/2026-07-13-v07-performance-localization` @ `929442d1` — **6 commits AHEAD of
origin, NOT PUSHED** · **PR:** #274 (DRAFT — do not auto-merge) · **Owner:** Szymek (directed this
session) · **Mode:** paused by owner until **Thursday 2026-07-30**; tree clean, all work committed.

> **Resume correctly — the previous handover did not.** Its one-command resume did **not** check
> out the branch it documented, so this session opened on `main`, **153 commits behind**, with a
> stale 2026-07-08 `AGENTS.md` in context. The entrypoint file it named did not exist on that ref.
> **Check out the branch first** (see "How to resume"), then rehydrate.

## Critical context

- **JULIA ENGINE lane.** The R lane (`hsquared`) is a SEPARATE repo — do not edit it from here.
- **`public_covered_count` = 5. Nothing is promoted.** THREE engine fitters are experimental.
- **Do NOT flip any capability without a FRESH promote-specific Rose (G8) + explicit owner G10.**
- **D1 genomic PAUSED** (D-68/D-71); **TMB deferred**;
  `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` stays quarantined (the only survivor of
  the old "4 foreign files" fence — `2278811c` landed the other three).

## REQUIRED SIGN-OFF LEDGER

Nothing below has been signed off. Each row states who owns it and what it unblocks.

| # | Sign-off / gate | Owner | Applies to | Status | Blocks |
|---|---|---|---|---|---|
| S1 | **G10 maintainer sign-off** | **Shinichi** (or delegated to Szymek — *unconfirmed*) | `fit_eigen_reml` | **OPEN** — owner chose KEEP STAGED 2026-07-24 | experimental→covered flip |
| S2 | **G10 maintainer sign-off** | **Shinichi** (or delegated) | `fit_ai_reml` | **OPEN** — owner chose KEEP STAGED 2026-07-24 | experimental→covered flip |
| S3 | **G10 maintainer sign-off** | **Shinichi** (or delegated) | `fit_matrix_free_reml` | **OPEN** — never requested; evidence incomplete | experimental→covered flip |
| S4 | **FRESH promote-specific Rose (G8)** | spawned `rose-systems-auditor` | any of the three, at flip time | **OPEN** — the 2026-07-28 Rose was slice-scoped, NOT a promotion audit | any flip |
| S5 | **Pre-declared known-truth recovery gate at `n > 20 000`** | Szymek (needs cluster) | `fit_matrix_free_reml` | **OPEN** — nothing measured above n=10 000 | S3, and re-wiring `:auto` |
| S6 | **AT-SCALE external comparator** | Szymek (needs cluster) | `fit_matrix_free_reml` | **OPEN** — ASReml ran at q=2000, *below* the crossover | S3 |
| S7 | **R bridge** (`method="eigen"`, ai_reml, matrix-free routes) | **R lane — separate repo** | all three | **OPEN** — handed off, not implemented | the `public_covered_count` moving off 5 |
| S8 | **Totoro/DRAC access** | **Shinichi** to grant | S5, S6 | **OPEN — ASK PENDING** | S5, S6 |
| S9 | **D1 successor authorization** | **Shinichi** | D1 genomic lane | **OPEN** — 5 of 6 preconditions still unmet | any D1 work |

**Discharged this session (for the record, not sign-offs):** external comparator at *validation
scale* (ASReml-R AGREE); slice-scoped Rose G8 (CLEAR-WITH-CHANGES, all applied).

**Delegation question that has never been answered:** the Szymek onboarding note
(`2026-07-24-szymek-onboarding.md`) says to *"clarify with him whether he's delegating G10 to you"*.
Until Shinichi answers, treat **every** G10 as his.

## What happened this session (2026-07-28)

Six commits. Started by discovering the checkout was on the wrong ref (see the warning above).

1. **`5047676d` + `07b3399a` — F6 implemented.** `fit_matrix_free_reml`: matrix-free PCG +
   Hutchinson stochastic trace, so `C` is never assembled or factorized during the fit. It removes
   the **Takahashi selected inverse** (381 s/call at q=20 000), not the Cholesky (0.35 s) — that was
   the wall F0 measured. **Mis-scoped going in:** the v0.8-S2 `K≥2` machinery already existed and
   ran unmodified as `K=1`, so this was an `AnimalModelFit` adapter + a route, **no new numerics**.
2. **`46c25c98` — provenance repair + `:auto` withdrawn.** The benchmark had never been run; the
   committed figures came from a scratch file. Re-run with median-of-3 → `sim/matrix_free_crossover.tsv`.
   **The numbers moved** (15.32× → 16.59×). The `:auto` divert was **removed** by owner decision.
3. **`29d04a1d` — ASReml-R comparator, AGREE.** Estimand only, no timings.
4. **`929442d1` — Rose findings applied.** CLEAR-WITH-CHANGES, five required changes.

## Three defects worth not repeating

- **A number that traces to a scratch file is not evidence.** It moved when re-run properly.
- **Fixing a defect on a page does not fix the same defect elsewhere on that page.** Rose found a
  mixed-machine table 26 lines above the one I had just repaired.
- **Updating six surfaces is not updating all of them.** The removed `:auto` route survived in the
  function's own docstring — which Documenter publishes. Rose called it a push-blocker, correctly.

## Current state

- **Landed:** all six commits, tree clean. `Pkg.test()` exit 0 (zero failures suite-wide);
  `docs/make.jl` exit 0 (6 pre-existing/environmental warnings); `preamble_cap.sh` CAP OK;
  `tools/status_cache.json` refreshed (56 rows, `public_covered_count` 5).
- **NOT pushed.** 6 commits ahead of origin. PR #274 is draft; the maintainer merges.
- **Blocked:** S5/S6 on S8 (cluster access). Nothing else is blocked.
- **`gh` is not installed here** — CI and PR state cannot be checked from this machine.

## Next immediate steps (ordered)

1. **Ask Shinichi for Totoro time** (S8) — unblocks S5 and S6, the two legs that decide whether
   `fit_matrix_free_reml` is trustworthy rather than merely consistent with our other estimator.
2. **Draft the tail-scale gate predeclaration** (S5). Follow the leg-shaped F5 pattern
   (`sim/phase_f5_scale_recovery_gate_v2.jl` + its `*-predeclaration.md`): fresh disjoint seeds
   (grep-verified), a `SMOKE` const, `GATE_JSON`, `exit(gate ? 0 : 1)`. **Freeze only once compute
   is confirmed — freeze-then-run, never the reverse.** Watch the F5 Leg-A gotcha: an MCSE
   criterion is pathological at very large n; use relative recovery at scale.
   Fold in the **`nprobe`-vs-error** study (64 is an untuned default).
3. **R lane (separate repo):** the opt-in R routes for all three fitters; count stays 5.
4. **Owner G10** (S1/S2/S3) — each needs a fresh Rose first.

## Carried forward, not scheduled

- **`sommer` is not installed** on this machine, so five committed `run_sommer_*.R` comparators
  cannot run here; committed evidence pins sommer 4.4.5 / R 4.6.0 against this box's R 4.6.1.
  Repo-health, independent of F6.
- **`fit_multi_effect`'s `:auto` still hard-codes `K == 1 → :exact`**, justified by the assumption
  F0 falsified. Documented, not changed. A real fix routes it on measured fill.
- **`docs/src/validation-status.md`'s hand-maintained table has drifted** from `validation_status()`
  (omits `V1-EIGEN-REML`, `V1-MATFREE-REML`, `V6-ORDINAL`, `V6-GAMMA`). Its own `@example` block
  renders all 56 rows correctly. Worth its own slice.

## Gotchas

- **Never write a result number before the run produces it.** Blank the table, run, then fill from
  the committed artifact.
- **ASReml: estimand comparisons only.** The §4 fence
  (`docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md:96-102`) forbids
  performance claims. Never put ASReml and a timing on the same page. Both comparator scripts carry
  an in-file instruction not to add a stopwatch.
- **Szymek has no Totoro/DRAC access** — those are Shinichi's credentials. Ask what compute he has.
- Julia is `~/.juliaup/bin/julia` (1.12.6); R is `/usr/local/bin/Rscript` (4.6.1) with ASReml-R
  4.2.0.482 licensed.

## How to resume (TARGET = claude)

```sh
cd <repo> && git fetch origin
git checkout codex/2026-07-13-v07-performance-localization   # DO THIS FIRST — main is far behind
git log --oneline -1                                          # expect 929442d1 or later
```

Then: run the **`hsquared-rehydrate`** skill, read the `AGENTS.md` Live Phase Snapshot, then THIS
doc. Before ANY public/capability claim or a flip, spawn a **REAL** Rose subagent.

- Interactive: `claude "Check out branch codex/2026-07-13-v07-performance-localization FIRST, then rehydrate with hsquared-rehydrate + docs/dev-log/handover/2026-07-28-claude-handover.md. F6 (fit_matrix_free_reml) landed experimental + OPT-IN; public_covered_count=5; nothing promoted. Read the REQUIRED SIGN-OFF LEDGER before acting — every G10 is Shinichi's unless he has said otherwise. Fences: no flip without a FRESH Rose + G10; ASReml estimand-only (no timings, §4); D1 PAUSED; do not touch the quarantined sim file."`

## Mission-control summary

| Lane | Branch / state | Shipped this session | Next by leverage |
|---|---|---|---|
| HSquared.jl (F6 matrix-free) | `codex/2026-07-13-…` @ `929442d1`, **6 ahead, unpushed**; PR #274 draft | fitter + opt-in fence + ASReml AGREE + Rose applied | tail-scale gate (needs S8) |
| HSquared.jl (ai_reml, eigen) | same branch; STAGED | — | R bridge → G10 |
| hsquared (R twin) | separate repo, untouched | — | opt-in routes for all three; count stays 5 |
| D1 genomic | PAUSED (D-68/D-71) | — | do not conflate; needs S9 |

> Detail: `docs/dev-log/after-task/2026-07-28-f6-matrix-free-single-effect.md` ·
> `docs/dev-log/check-log.d/2026-07-28-f6-matrix-free-single-effect.md` ·
> `docs/dev-log/recovery-checkpoints/2026-07-28-asreml-matfree-comparator.md`.
> Prior arc: `docs/dev-log/handover/2026-07-24-claude-handover.md`.
