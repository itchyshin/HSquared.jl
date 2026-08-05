# Handover → Szymek — what changed since your 08-04 handoff, and what's yours next

**Date:** 2026-08-04 (evening) · **From:** Shinichi's Claude session · **To:** Szymek ·
**Branch:** `codex/2026-07-13-v07-performance-localization` @ `1934c542` — **everything pushed** ·
**PR #274** still DRAFT · **CI: GREEN on both legs.**

Read this after `docs/dev-log/handover/2026-07-24-szymek-onboarding.md` (still accurate on how the
repo works — nothing in it is retracted).

---

## First, the thing you need to know, and it is not a criticism

**CI was red when you handed off, and you had no way to see it.** Your handover said "all local checks
green," which was **true** — your `Pkg.test()` genuinely passed. But `gh` isn't installed on your
machine, so GitHub's own result was invisible to you. It had gone red on both 2026-08-04 runs.

This is a tooling gap, not a lapse, and it's worth being concrete about *why* your local run passed
while CI failed, because the reason is genuinely interesting:

```
Julia 1.10.0   hash(y)=1681c2cc…   converged=FALSE  iterations=200 (cap)  rel.err 5.45%
Julia 1.12.6   hash(y)=0ed8df03…   converged=TRUE   iterations=116        rel.err 0.79%
```

The F6 test seeded `MersenneTwister(20260728)` and generated its **entire dataset** from that stream.
**Julia's `randn` stream is not stable across minor versions**, so the two CI legs were never fitting
the same data — different pedigree *and* different phenotypes. Julia 1.10 happened to draw a harder
dataset that needed more than the 200-iteration EM cap.

**Your fitter was never broken.** `converged=false` was cap exhaustion, not a numerical defect.

**The one practical ask: install `gh`.** `brew install gh` (or your platform's equivalent), then
`gh auth login`. After that, `gh run list --limit 5` before every handoff. That single command would
have caught this.

---

## What changed while you were off the lane

**1. The RNG fragility is fixed as a class — three sites, not one** (`7ceaff17`).

The repo already had a written policy this violated: *"CI remains RNG-free"*, stochastic recovery
harnesses live in `sim/`, out of the test suite
(`docs/dev-log/after-task/2026-06-14-phase4b-structured-recovery-harness.md`). And it had already been
bitten once before by the same mechanism. So the fix follows the repo's own rule rather than inventing
a new one:

- **F6 K=1** — the four stochastic assertions moved to a new opt-in driver
  `sim/f6_matfree_recovery.jl`, on the *same* fixture and seed you used. Structural assertions stay in
  CI, rebuilt on a literal deterministic fixture. In-CI count 32 → 28.
- **The K=2 sibling** (`test/runtests.jl:3491`) — its numeric claims **duplicated**
  `sim/v08_s2fit_recovery_scale.jl`'s opt-in recovery mode, so they were deleted rather than
  relocated. Its structural checks were kept.
- **A third instance** — the probe-count monotonicity check still flipped on 1.12 *after* the data was
  made deterministic, because the remaining sensitivity lives inside `fit_multi_effect_mc_reml`'s
  **own probe draws**. It now asserts that `trace_mcse` shrinks with `nprobe`, rather than comparing a
  point estimate.

**2. Your S5 gate is written and FROZEN** (`33ab68f6`) — **not run.** Pre-declaration +
`sim/phase_s5_matfree_tail_recovery_gate.jl`, SMOKE-verified only.

**3. S8 was never a real blocker, and this one's on us, not you.** Your handover reasonably said the
gate was withheld pending Totoro/DRAC access. In fact **Totoro was reachable the whole time** through
an existing SSH `ControlMaster` socket on Shinichi's machine, and **Julia 1.10.0 was already installed
there** at `~/hsq_work/julia-1.10.0/bin/julia`. You had no way to know that — those are Shinichi's
credentials, not yours.

So `q=25,000` feasibility is now **measured**, not assumed:

| | |
|---|---|
| measured fill `nnz(L)/n` | **583.3** (continuing your 50→77→149→262→471 trend) |
| outcome | **CONVERGED in 59 iterations** |
| wall clock | **54.26 s** single-core |
| ⇒ Leg A (48 seeds) | ~45–48 min serial, **a few minutes at 48-way** |

**4. A small defect in the new driver, found and fixed.** Its SMOKE mode reported a meaningless
`GATE: FAIL` at `nm=60`: the exact fit lands on the variance boundary (`sigma_a2 ≈ 4e-5`) and the
relative-error denominator collapses. Worth knowing generally — **judge "on the boundary" relative to
trait scale**, and report an anomaly, never a spurious FAIL.

---

## Your G10 question, answered

You asked in the onboarding note whether G10 was delegated to you. It went unanswered for eleven days;
**Shinichi has now answered: it is NOT delegated.** Promotion sign-off stays with him.

Read this the way it's meant: it matches the standing precedent (2026-06-30 — *"the flip was held until
sign-off, never self-promoted"*), and it is **not** a comment on your work. Nothing changes about how
you operate:

- **You develop and generate evidence freely.** That has never needed his sign-off.
- **Only the `experimental → covered` flip** — the public claim — is his.

Recorded in `docs/dev-log/decisions/2026-08-04-g10-not-delegated-and-s5-freeze-record.md`.

---

## What's yours next, if you want it

**The S5 run is the natural one, and it's ready.** Frozen, feasible, minutes of compute. It converts
`fit_matrix_free_reml` from *"agrees with our other estimator"* to *"recovers known truth"* — the leg
your own handover called the one that matters most, and the one every current F6 leg is missing.

**Two things must happen first, and both are Shinichi's, not yours:**

1. **The `CAP-EXHAUSTED ≤ 4/48` threshold.** Unlike the `0/48` non-graceful bound (rule-of-three), this
   one has no in-repo precedent — it's a judgment call. It's frozen with an explicit
   *owner-revisable-before-run* note, because freezing binds the gate once compute consumes it.
2. **Compute.** Totoro is Shinichi's box. Either he runs it, or he gives you access. Don't try to
   arrange this yourself.

**Also still open, and genuinely yours if you'd like them:**

- **S6, the at-scale external comparator.** Your ASReml run is q=2000 / fill 75.2 — **below** the
  measured crossover of 150, i.e. the regime where the exact path still wins, not the high-fill tail
  the fitter exists for. **ASReml is estimand-only. Never put ASReml and a timing on the same page**
  (§4 fence) — both comparator scripts carry that instruction in-file.
- **The `nprobe = 64` study.** Your 07-28 handover asked for it and it still hasn't been done. An
  informational arm was added to the frozen gate, but that's not the study.
- **`fit_multi_effect`'s `:auto`** still hard-codes `K == 1 → :exact`, on an assumption F0 falsified.

---

## Two gotchas worth carrying into any repo you work in

**1. A seeded RNG is not version-stable.** `MersenneTwister(n)` gives different streams across Julia
minor versions. If a test *generates data* from a seeded RNG and then asserts a tolerance, it is not
deterministic across versions — only across runs on one version. This generalises: the same exposure
was found in GLLVM.jl and DRM.jl (identical CI matrix, RNG throughout, no `StableRNGs`) and filed as
GLLVM.jl #182 and DRM.jl #388.

**2. Absence from `git log` is not absence from the session.** Working-tree files can be copied to a
server and run, leaving no git trace. Three agents got this wrong today, at some cost.

---

## Practical notes for your machine

- **`gh` — please install it.** The one concrete gap this arc exposed.
- **`sommer` isn't installed on your box**, so five committed `run_sommer_*.R` comparators can't run
  there. Committed evidence pins sommer 4.4.5 / R 4.6.0 against your R 4.6.1. Repo-health, independent
  of everything above.
- **Julia version matters now.** Shinichi's default is 1.10.0; `julia +1.12` gives 1.12.6. CI runs
  both. Test both before pushing:
  ```sh
  julia --project=. -e 'using Pkg; Pkg.test()'
  julia +1.12 --project=. -e 'using Pkg; Pkg.test()'
  julia --project=docs docs/make.jl
  gh run list --limit 5          # <- the new one
  ```
- **Never `git add -A` in this repo.** `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` is a
  quarantined, untracked, **not-gitignored** file — one `git clean -fd` destroys it. Leave it alone
  entirely: never open, stage, edit, or hash it.

---

## State, in one place

| | |
|---|---|
| Branch | `codex/2026-07-13-v07-performance-localization` @ `1934c542`, pushed, in sync |
| CI | **GREEN**, both legs (`Julia 1.10` + `Julia 1`) — verified on GitHub, not just locally |
| PR #274 | OPEN, **DRAFT** — do not auto-merge |
| `public_covered_count` | **5** — unchanged; nothing promoted, no capability row flipped |
| Three engine fitters | all still **experimental / staged** |
| S5 | **FROZEN at `33ab68f6`, NOT RUN** |
| D1 genomic | **PAUSED** (D-68 / D-71) |

**Resume:**

```sh
cd <your HSquared.jl clone>
git fetch origin && git checkout codex/2026-07-13-v07-performance-localization && git pull
git log --oneline -1        # expect 1934c542 or later
gh run list --limit 5       # once you've installed gh
```

Then point your Claude at: `AGENTS.md` → this note →
`docs/dev-log/handover/2026-08-04-claude-handover.md` (the agent-facing version, with the full
Landing State ledger) → `docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md`
(the frozen gate).

Thanks for the F6 work — the fitter itself came through this arc unscathed. What broke was the test
harness around it, and it broke in a way the repo had already documented and then forgotten.
