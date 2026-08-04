# Session Handoff → Claude: F6 CI-honesty repaired + S5 frozen (HSquared.jl, Julia engine lane)

**Date:** 2026-08-04 (evening) · **From:** Claude (Shinichi driving) · **To:** a fresh Claude session ·
**Branch:** `codex/2026-07-13-v07-performance-localization` @ `b9b09758` — **fully pushed, in sync with
origin (0/0)** · **PR:** #274 (DRAFT — do not auto-merge) · **CI: GREEN on both matrix legs.**

> Predecessor: `docs/dev-log/handover/2026-08-04-shinichi-handover.md` (Szymek → Shinichi, earlier the
> same day). That document is still accurate on the sign-off ledger; it is **stale on CI and on
> push-state** — see Critical Context.

---

## Critical Context

**1. The thing that started this arc: "all local checks green" was true and still misleading.** Szymek's
handover said exactly that, and it was honest — his local `Pkg.test()` did pass. But `gh` was not
installed on his machine, so CI was invisible to him, and **CI was red**. Do not treat a local green as
a verified green. That distinction is the whole subject of this arc.

**2. It is now genuinely green, verified by CI and not by assertion.**

```
2026-08-04T18:19  success  b9b09758   <- the fix, both legs
2026-08-04T12:40  failure  42572f91
2026-08-04T10:51  failure  67b60d8b   <- the F6 arc introduced it
2026-07-25T14:04  success  2278811c
```

**3. NOTHING WAS PROMOTED.** `public_covered_count` is **5** and has not moved. All three engine fitters
(`fit_ai_reml`, `fit_eigen_reml`, `fit_matrix_free_reml`) remain **experimental / staged**. No capability
row flipped in this arc.

**4. The S5 gate is FROZEN and NOT RUN.** Frozen at commit `33ab68f6`. Do not run it without reading
"Blockers" below — one pre-declared threshold is still the maintainer's to own.

---

## What Was Accomplished

**A. The CI failure diagnosed, not guessed.** Reproduced locally on both installed Julia versions:

| | Julia 1.10.0 | Julia 1.12.6 |
|---|---|---|
| `hash(y)` | `1681c2cce99015df` | `0ed8df03f84d8621` |
| `exact_sa2` | 0.248016 | 0.485196 |
| `mf.converged` | **false** | true |
| `mf.iterations` | **200 (cap)** | 116 |
| rel. err | 5.45% | 0.79% |

`rng = MersenneTwister(20260728)` generated the **entire dataset** — pedigree topology *and* phenotypes —
and Julia's `randn` stream is not version-stable, so the two CI legs were never fitting the same data.
`converged=false` was **iteration-cap exhaustion**, NOT the zero-boundary early break.

**B. Fixed as a CLASS, not an instance — three sites, not one.** The repo already had a written policy this
violated (`docs/dev-log/after-task/2026-06-14-phase4b-structured-recovery-harness.md`: *"CI remains
RNG-free"*), and had already fixed this exact mechanism once (`test/runtests.jl` `boundary_fixture` note).

1. **F6 K=1** — 4 stochastic claims moved to a new opt-in driver `sim/f6_matfree_recovery.jl`; the
   structural assertions stay in CI, rebuilt on a **literal deterministic fixture**.
2. **K=2 sibling** — its numeric claims **duplicated** `sim/v08_s2fit_recovery_scale.jl`'s opt-in recovery
   mode, so they were **deleted, not relocated**; its structural assertions (shape/tags, probe-count
   monotonicity, two `ArgumentError` guards) have no analog there and were kept.
3. **A third instance found on the way** — the probe-count monotonicity check still flipped on 1.12 *after*
   the data was made deterministic, because the residual sensitivity is inside
   `fit_multi_effect_mc_reml`'s **own seeded probe draws**. Now asserts on the estimator's self-reported
   `trace_mcse` (a dispersion statistic) instead of a point-estimate comparison.

**C. S5 frozen with feasibility measured, not assumed.** The predecessor handover withheld the freeze
because "S8 (Totoro/DRAC access) is OPEN". **That premise was false** — Totoro was reachable the whole time
through the existing `ControlMaster` socket, and Julia 1.10.0 was *already installed* at
`~/hsq_work/julia-1.10.0/bin/julia`. A single-seed probe at the pre-declared `q = 25,000`:

- measured fill `nnz(L)/n` = **583.3** (continuing the documented `50→77→149→262→471` trend)
- `fit_matrix_free_reml` **CONVERGED in 59 iterations**, wall **54.26 s** single-core
- ⇒ Leg A ≈ 45–48 min serial, or a few minutes at 48-way on Totoro. **Affordable.**

**D. G10 answered.** Shinichi confirmed **G10 sign-off is NOT delegated** — it stays with him. Open since
the 2026-07-24 Szymek onboarding note. Recorded in
`docs/dev-log/decisions/2026-08-04-g10-not-delegated-and-s5-freeze-record.md`.

**E. Cross-repo finding filed.** The RNG-version fragility generalises: GLLVM.jl and DRM.jl share the
identical CI matrix (`'1'`, `'1.10'`) and use RNG in tests (57 files / 666 sites; 153 files / 1159 sites),
neither with `StableRNGs`. Filed as **GLLVM.jl #182** and **DRM.jl #388** — framed as *shared exposure +
a cheap check*, explicitly **not** a bug claim, since no failure was demonstrated in either.

---

## Current Working State

- **Working:** `Pkg.test()` green on Julia **1.10.0** and **1.12.6** (both re-run independently, not just
  quoted); `docs/make.jl` exit 0; `tools/preamble_cap.sh` CAP OK; CI green on both legs at `b9b09758`.
- **Frozen, not run:** the S5 gate (`sim/phase_s5_matfree_tail_recovery_gate.jl` +
  `docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md`). SMOKE-verified
  only.
- **Blocked / not started:** S6 (at-scale ASReml comparator), S7 (R bridge — other repo), S9/D1 (PAUSED).

---

## Key Decisions & Rationale

- **KEEP STAGED** for all three fitters — unchanged. Nothing in this arc strengthened any of them.
- **G10 NOT delegated** — matches the 2026-06-30 precedent ("the flip was held until sign-off, never
  self-promoted"), and Szymek has stepped off the lane.
- **Repair by the repo's own policy** (move stochastic claims to opt-in `sim/`) rather than adding
  `StableRNGs` — no new dependency, and it fixes the class rather than the instance.
- **S5's PRIMARY criterion is mean relative error vs known truth, NOT `|bias| ≤ 2·MCSE`.** The template's
  own note (`sim/phase_f5_scale_recovery_gate_v2.jl:27`) says a bias/MCSE test is *pathological as MCSE→0*,
  which is why its tail leg uses relative mode. bias/MCSE is informational only. Estimator-agreement is kept
  at the existing `N_ANCHOR=2000` because the exact comparator costs ~1529 s at tail scale.
- **Outcome classification is THREE-WAY** (CONVERGED / CAP-EXHAUSTED / NON-GRACEFUL), because the boundary
  "graceful" contract alone would have scored an un-converged, 5.45%-off fit as passing. A **fourth**
  outcome (`converged=false` with `iterations < cap`, via the positivity early-break) is reachable and is
  logged as an explicit anomaly.

---

## Landing State

**Gate output annotated. `handoff_gate.sh` reports FAIL — every failure is pre-existing and declared below;
none is this session's work.**

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `HSquared.jl` `codex/2026-07-13-v07-performance-localization` `b9b09758` | y | **y (0/0 in sync)** | #274 open, DRAFT | **LANDED** |
| `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` | n (untracked) | n | — | **PROTECTED — must stay this way** |
| 15 branches, last commits **2026-06-21 → 2026-07-09** | y | n (1–3 each) | — | **CARRIED-OVER (pre-existing)** |
| PR #274 | — | — | open | **CARRIED-OVER, deliberate** |

**Declarations:**

- **The quarantined sim is PROTECTED, not carried-over work.** D-84: *never inspect, stage, edit, or hash
  it.* A byte-identical rescue copy exists at `~/Dropbox/_archive/hsquared-quarantine-rescue-20260725/`. It
  is **not gitignored**, so one `git clean -fd` destroys it. **Never `git add -A` in this repo.**
- **The 15 stale branches are not mine.** They date from 2026-06-21 to 2026-07-09 — weeks before this
  session. I did not create, touch, or land any of them, and deciding their fate is a separate cleanup task,
  not a handover blocker. Listed so they are visible rather than invisible.
  Resume (if you ever want them): `git log --oneline origin/<branch>..<branch>` per branch.
- **PR #274 stays DRAFT.** Not auto-merged, by standing instruction.

---

## Next Immediate Steps

Ordered. **Run lane preflight and reconcile against git before starting any of them** — classify each
`OWED` / `DONE` / `RETRACTED` / `PROTECTED`.

1. **Settle the `CAP-EXHAUSTED ≤ 4/48` threshold with Shinichi** (see Blockers). It is the one number in
   the frozen gate with no in-repo precedent. Cheap to change *now*; binding once compute consumes it.
2. **Run the S5 gate on Totoro** — frozen, feasible, ~3.4 min at 48-way. This converts
   `fit_matrix_free_reml` from *consistent with our other estimator* to *validated against truth*, the leg
   the predecessor handover called the one that matters most. **It still promotes nothing.**
3. **S6 — the at-scale ASReml comparator.** The existing run is q=2000 / fill 75.2, **below** the measured
   crossover of 150 — i.e. the regime where the exact path still wins, not the tail this fitter exists for.
   **ASReml is ESTIMAND-ONLY; never record or imply a timing (§4 fence).**
4. **S7 — the R bridge** (separate repo). Still the **only** thing that can move `public_covered_count`
   off 5. `hsquared` already has `hs_fit_julia_ai_reml_payload` and a wired `target="ai_reml"`, so
   `fit_ai_reml` is the cheapest first target. **Caution: that repo is 7 commits ahead of its own origin
   with a dirty tree** — resolve before scheduling bridge work.

---

## Blockers / Open Questions

- **`CAP-EXHAUSTED ≤ 4/48` (~8.3%) is an unowned judgment call.** Unlike A2's 0/48 (rule-of-three), nothing
  anchors it. It was frozen with an explicit *owner-revisable-before-run* note. **Shinichi's call.**
- **Leg X's anchor pedigree** — Fisher flagged that it should be high-fill rather than the template's
  half-sib, else the anchor barely exercises the approximation the gate exists to check. He made the call
  and flagged it; not independently reviewed.
- **`nprobe = 64` is still untuned.** The 07-28 handover asked for an `nprobe`-vs-error study. An
  informational arm was added to the frozen gate; **the study itself has not been done.**
- **`V1-EIGEN-REML` has a debt-register row but NO `validation_status()` row**, so the published ladder
  shows one staged fitter and not the other. Deliberately untouched — adding a row moves the count 56→57
  and a test assertion. Its own slice.
- **`fit_multi_effect`'s `:auto` still hard-codes `K == 1 → :exact`**, on an assumption F0 falsified.
  Documented, not changed.
- **`sommer` is not installed on Szymek's machine** — five committed `run_sommer_*.R` comparators cannot run
  there. Repo-health, independent of everything above.

---

## Gotchas & Failed Approaches

- **A seeded RNG is NOT version-stable.** `MersenneTwister(n)` gives different streams across Julia minor
  versions. Seed-pinned ≠ version-pinned. This repo has now been bitten **twice**.
- **The zero-boundary hypothesis was FALSIFIED here.** Published REML work reports failure-to-produce-a-CI in
  17.5–30.5% of replicates via the variance hitting zero — that is *not* what happened; it was cap
  exhaustion. Recorded as falsified, not quietly dropped. Do not resurrect it as the explanation.
- **Absence from `git log` is NOT absence from the session.** Three agents (including the orchestrator)
  reached confident wrong conclusions by reasoning from `git log` about work that was still **uncommitted**
  and had been copied to a remote host. Git records commits, not working trees. This cost ~7 commits.
- **`git blame` cannot attribute anything in this repo's multi-agent sessions** — every commit carries
  byte-identical author/`Co-Authored-By` trailers. Provenance questions can only be resolved from routing
  records that live *outside* the repo. Structural weakness; recorded in the check-log.
- **A relative error against a boundary estimate is meaningless.** At `nm=60` the exact fit lands on
  `sigma_a2 ≈ 4e-5` and the naive denominator collapses (measured `rel.err` 40925 on Totoro, 980 locally
  with a too-tight absolute cutoff). Judge "on the boundary" **relative to trait scale**; report ANOMALY
  (NaN), never a spurious FAIL. Both drivers now do this.
- **A SMOKE mode that always fails trains its reader to ignore it.** The opt-in driver shipped that way
  briefly; SMOKE is now plumbing-only and deliberately does not assert recovery at a shrunken size.

---

## How to Resume

```sh
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
git fetch origin
git checkout codex/2026-07-13-v07-performance-localization
git log --oneline -1          # expect b9b09758 or later
gh run list --limit 3         # expect CI success at b9b09758
```

Read in order: `AGENTS.md` (Live Phase Snapshot) → this document →
`docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md` (the frozen gate)
→ `docs/design/capability-status.md`.

**Verification command (safe, ~10 min):**
`julia --project=. -e 'using Pkg; Pkg.test()'` — note the local default is **Julia 1.10.0**; `julia +1.12`
gives 1.12.6. Both must pass.

**Environment:** Totoro is reachable without re-auth via the existing socket —
`SOCK=$(ls ~/.ssh/cm-*totoro* | head -1)` then
`ssh -o ControlPath="$SOCK" -o ControlMaster=no -o BatchMode=yes totoro '<cmd>'`. Julia lives at
`~/hsq_work/julia-1.10.0/bin/julia`; it is **not** on PATH. Keep to ≤100 cores and
`OPENBLAS_NUM_THREADS=1`.

**Do not stage:** `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`. Never `git add -A`.

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-04-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
