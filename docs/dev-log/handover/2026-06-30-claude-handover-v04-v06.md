# Handover → next Claude — v0.4 recovery + v0.6 ordinal kernel (2026-06-30)

Meta: 2026-06-30 · from Claude · autonomous overnight segment (maintainer away until ~05:00).
You are the next Claude, picking up **four staged PRs** and an open next-arc decision.

## Merge guide (conflicts PRE-CHECKED via a throwaway trial-merge)

**Merge order: #211 → #212 → #214 → #213.** #211 and #212 merge clean. Two trivial conflicts remain
(both = "keep both additions"):

- **#214 (Gamma) conflicts with #212 (ordinal)** in `src/nongaussian.jl` and `test/runtests.jl` — both
  add a new family at the same anchor points (a struct after `BernoulliProbitResponse`, kernels after
  the probit `_fam_weight`, a `_check_counts`, and a testset after the H3 probit testset). **Resolution:
  keep BOTH** the `OrderedProbitResponse` and `GammaResponse` additions (they are adjacent, non-overlapping
  — no shared logic). Then **add the deferred `V6-GAMMA` row** (below) so the family is tracked.
- **#213 (this handover) conflicts with #211** in `AGENTS.md` — both prepend a Live Phase Snapshot bullet.
  **Resolution: keep BOTH bullets** (the overnight-segment bullet on top, then #211's v0.4 bullet).

### Deferred `V6-GAMMA` row (add when merging #214, per the count-guard sequencing)

Append after the `V6-ORDINAL` row in `src/validation_status.jl` (a 7-tuple), bump the count guard
`test/runtests.jl` `length(validation)` 49→**50**, and mirror into `capability-status.md` +
`validation-debt-register.md` (`partial`):

> `V6-GAMMA` · "non-Gaussian Gamma (log-link, positive continuous) family (T-Gamma)" · Phase 6 · partial
> · evidence: `GammaResponse(shape)` (internal, log-link, supplied shape ν); log-concave observed-info
> weight `ν y e^{-η}`; validated by the ν=1→Exponential reduction + finite-difference score/weight gates
> + finite end-to-end marginal + guards (`test/runtests.jl`). · owed: joint shape estimation, the
> `:symbol` resolver + `fit_laplace_reml`/R wiring, the **glmmTMB `Gamma(link="log")`** same-estimand
> comparator (valid here, unlike the ordinal case), a recovery gate, observation-scale h². · boundary:
> experimental/internal/Laplace-only/supplied-shape; not exported, not wired to R, not the public
> default, NOT a covered claim.

## Critical Context

- **Two PRs are STAGED, CI-green, real-Rose-audited, and NOT merged** — both await the maintainer.
  Do **not** self-merge either (covered-row change + maintainer scope call).
  - **[#211](https://github.com/itchyshin/HSquared.jl/pull/211)** — v0.4 MV broader-DGP recovery
    (full-sib + 3-trait **discharged**, additive; covered UNCHANGED). Gate: **G10**.
  - **[#212](https://github.com/itchyshin/HSquared.jl/pull/212)** — v0.6 ordered-categorical
    (ordinal) probit **family kernel** (experimental/`partial`; `validation_status()` 48→49).
    Gate: **maintainer review** (new engine capability).
- **Honesty pins hold on `main`:** `validation_status()` = **48**, covered **8**, **public-covered
  fitting = 1**. #212's 48→49 is on its branch only (not merged).
- **`main` @ `c2b5babc`** unchanged this segment (both arcs are on their own branches).

## Goals / mission

Programme goal (maintainer `/goal`): *finish — Fast & Accurate Algorithms for Mixed &
Latent-Variable Model Fitting (HSquared · DRM · GLLVM)*. This is a long-horizon programme, not a
one-session finish. Covered public default remains v0.1 Gaussian; every non-Gaussian/QTL/MV
capability is experimental/partial until it clears the doc-16 covered gate (G1–G11 + maintainer
G10). Engine-covered ≠ R-public-covered.

## What Was Accomplished

1. **v0.4 broader-DGP recovery (#211)** — discharged the two owed *pure-Julia* recovery items on the
   covered `V4-MV-REML` row. Extended `sim/phase4_multivariate_reml_recovery.jl` with a full-sib
   pedigree + general-`t` sim; pre-declared two gates (committed BEFORE the run); a **real
   Curie/Fisher/Mendel pre-run panel** (all PROCEED); ran **48-seed cold-start gates on Totoro**;
   both PASS all four criteria (full-sib t=2 + 3-trait t=3, R9-clean, no off-diagonal MCSE
   inflation). Lockstep debt discharge. Real Rose → PROMOTE-WITH-CHANGES (applied). Detail:
   `docs/dev-log/after-task/2026-06-30-mv-broaderdgp-recovery.md`.
2. **v0.6 ordinal family kernel (#212)** — the pure-Julia core of the T1 arc. New internal
   `OrderedProbitResponse(thresholds)` (K ordered categories, K-1 SUPPLIED cutpoints) with exact
   log-concave kernels (observed-information weight). Deterministic oracle: exact K=2/θ=[0]
   reduction to `BernoulliProbitResponse`, 3-category kernel gates, end-to-end marginal reduction
   (Δ~1e-16). `partial` row on all 3 surfaces. Real Rose → PROMOTE-WITH-CHANGES (docstring
   Fisher→observed fix applied). Detail: `docs/dev-log/after-task/2026-06-30-v06-ordinal-family-kernel.md`.

## Current Working State

- **Working / done:** both arcs complete + CI-green + Rose-clean + staged. `Pkg.test` and
  `docs/make.jl` green on both branches. Board (`:8791`) regenerated (48/8/1, both PRs listed).
- **In progress:** none — both slices are finished and handed to the maintainer.
- **Blocked (needs the maintainer / external):** merging #211 (G10) + #212 (review); the v0.6
  same-estimand comparator choice; V5 GCTA (external binary); any covered promotion.

## Key Decisions & Rationale

- **Ordinal weight = OBSERVED information, not Fisher.** Ordered probit is log-concave in η, so
  observed info ≥ 0 and reduces EXACTLY to the binary probit at K=2 (Fisher would not reduce). This
  is why the K=2 reduction gate is the load-bearing test.
- **Comparator finding (important):** the roadmap lists **glmmTMB** for v0.6, but **glmmTMB does NOT
  fit cumulative-link ordinal models**. The correct same-estimand tool is **R `ordinal::clmm`**
  (Laplace-ML); MCMCglmm `threshold` is Bayesian-agreement-only. Recorded in #212's debt row + the
  scout note.
- **Held rather than stacking:** did not open a 3rd row-adding PR (the count-guard "one row-adding
  PR at a time" discipline) and did not build v0.6 cutpoint-estimation on the unreviewed #212 kernel.

## Files Created / Modified

- **#211 branch (`feat/2026-06-30-v04-broaderdgp-recovery`):** `sim/phase4_multivariate_reml_recovery.jl`,
  `sim/selftest_phase4_extensions.jl`, `docs/dev-log/decisions/2026-06-30-mv-reml-{fullsib,3trait}-gate.md`,
  `docs/dev-log/recovery-checkpoints/2026-06-30-mv-{fullsib,3trait}-{48seed.md,results.txt}`,
  `docs/design/{capability-status,validation-debt-register}.md`,
  `docs/dev-log/{check-log.d,after-task}/2026-06-30-mv-broaderdgp-recovery.md`,
  `AGENTS.md`, `tools/control-centre/index.html`.
- **#212 branch (`feat/2026-06-30-v06-ordinal-family`):** `src/nongaussian.jl`, `src/validation_status.jl`,
  `test/runtests.jl`, `docs/design/{capability-status,validation-debt-register}.md`,
  `docs/dev-log/{check-log.d,after-task}/2026-06-30-v06-ordinal-family-kernel.md`.
- **This handover branch (`docs/2026-06-30-claude-handover-v04-v06`):** this doc + the `AGENTS.md` snapshot bullet.

## Next Immediate Steps (ordered)

1. **Maintainer:** review + merge **#211** (G10) and **#212** (new capability). After each merge,
   the `main` `validation_status()` count updates (48 → still 48 after #211 → 49 after #212); the
   second row-adding merge (#212) may need a trivial count-guard rebase (48→49).
2. **Close the two stale PRs #193 and #191** (superseded docs/handover) — maintainer call.
3. **Next arc (recommended): finish v0.6 T1 ordinal** on top of the merged #212 kernel —
   (a) joint cutpoint estimation, (b) the `:symbol` resolver + `fit_laplace_reml` wiring,
   (c) the **`ordinal::clmm`** same-estimand comparator (Codex baton — live R), (d) a pre-declared
   recovery gate, (e) observation-/liability-scale h². Then Gamma/lognormal (the v0.6 plan's next
   family). Alternative: **V5 GCTA** 2nd comparator (needs the GCTA binary).
4. Do NOT build v0.6 cutpoint-estimation until #212 is reviewed/merged (avoid stacking).

## Blockers / Open Questions

- v0.6 comparator: confirm **`ordinal::clmm`** (not glmmTMB) as the same-estimand ordinal tool.
- Covered promotions, merges, outward posting, credential/compute decisions: maintainer-only.

## Gotchas & Failed Approaches

- **Totoro stale-clone trap:** `~/hsq_work/HSquared.jl` was on a v0.5 branch; a plain
  `git checkout <branch>` failed and `set -e` did NOT abort (failed middle-of-`&&`-chain), so the
  first campaign silently reran the default cell (identical results = the tell). Always **verify
  `HEAD` + a harness arg-grep** on Totoro before running; the first run was discarded (no leak).
- **`_norm_cdf(±∞)` → NaN** via the erfc continued-fraction at infinity — short-circuit ±∞.
- **Ordinal weight:** Fisher information does NOT reduce to the binary probit; use observed info.
- **`validation_status()` rows are 7-tuples** `(id, capability, phase, status, evidence, owed, boundary)` —
  a 6-tuple errors in the constructor.
- **Never stage** the 3 foreign untracked files (`docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`,
  `sim/.v2gate_run.log.txt`, `sim/phase6_nongaussian_interval_coverage.tsv`). `git add -A` staged
  them once this session → removed via `commit --amend`. Prefer explicit `git add <paths>`.

## Mission-control snapshot

| Item | State |
| --- | --- |
| `main` | `c2b5babc`/#210 · `validation_status()` 48 · covered 8 · **public-covered fitting = 1** |
| PR #211 (v0.4) | CI ✅ · Rose ✅ · covered UNCHANGED · awaits **G10** |
| PR #212 (v0.6 ordinal) | CI ✅ · Rose ✅ · `partial` (48→49 on branch) · awaits **review** |
| Stale PRs | #193, #191 — superseded, worth closing |
| Compute | Totoro set up (`~/hsq_work`, Julia 1.10.10); juliaup local (`~/.juliaup/bin/julia`) |
| Next arc | finish v0.6 T1 ordinal (comparator = `ordinal::clmm`) · or V5 GCTA |

## How to Resume

1. Run the **`hsquared-rehydrate`** skill (live git/CI + `ROADMAP.md`, coordination board,
   check-log, newest after-task, `docs/design/capability-status.md` + `validation-debt-register.md`).
2. Read this doc + the `AGENTS.md` snapshot + the two after-task reports (linked above).
3. `gh pr view 211` / `gh pr view 212` for live state; verify `main` HEAD before acting.
4. Spawn a real **Rose** audit before any covered/public claim.
5. **One-command resume** (paste in your authenticated terminal, from the repo root):

```
claude "Rehydrate from docs/dev-log/handover/2026-06-30-claude-handover-v04-v06.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```
