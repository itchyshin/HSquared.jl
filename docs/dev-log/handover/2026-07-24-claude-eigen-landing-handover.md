# Session Handoff — H2 engine-performance RESOLVED + eigen-once fitter LANDED → next Claude lane

**Meta:** 2026-07-24 · **from:** Claude (Julia engine lane) · **to:** next Claude (or Codex) lane · **branch:**
`codex/2026-07-13-v07-performance-localization` @ `be6bb766` (pushed) · **PR:** #274 (DRAFT, no auto-merge) ·
**mode:** landed — everything committed + pushed.

## Critical Context (read or go wrong)

1. **This thread is RESOLVED and LANDED — not in-flight.** The H2 engine-PERFORMANCE thread (szymekdr report)
   is diagnosed, fixed, benchmarked, and a new fitter is shipped experimental. All committed + pushed. The
   prior handover's premise ("`fit_ai_reml` doesn't converge OOB") was DISPROVED — it was a stale checkout +
   no-signal data. Do NOT re-open the diagnosis.
2. **`fit_ai_reml` converges in 5–8 Newton iterations, no bug** (Gauss re-derived the algebra). The "slow" is
   fill-in-driven **selected-inverse** cost on high-fill pedigrees, not the Cholesky. On realistic pedigrees
   the fit is already fast (n=10000 = 0.64 s).
3. **New experimental fitter `fit_eigen_reml`** (one-factorization eigen-once single-effect REML) recovers
   AI-REML to ~1e-8 and is 6.95× faster on high-fill n=10000. Wired via `fit_animal_model(target = :eigen |
   :auto)`. **EXPERIMENTAL — `public_covered_count` STAYS 5, no capability-status covered move.**
4. **D1 genomic-recovery stays PAUSED (D-68)** — a SEPARATE thread on this same branch. Do not conflate.
5. **TMB native engine NOT built** — still deferred, owner-gated (D-2026-06-12).

## What Was Accomplished (all committed on `codex/2026-07-13-v07-performance-localization`)

- **Diagnosis** (`2bf3c1ab`.. + docs `ebd16562`): decision-hinge measured on Totoro (real h²=0.4 signal);
  Gauss algebra audit (no bug); brain sweep caught the already-overturned ordering lever. Findings:
  `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md`.
- **Robustness fixes** (`2bf3c1ab`): `PosDefException` graceful-stop guards on BOTH AI-REML loops (single +
  multi-effect) + degenerate-likelihood routing; iteration-count regression guard; `score_trace` diagnostic.
- **Benchmarks** (recorded in findings doc): symbolic-reuse = minor (~1× total); eigen-once = the real win.
- **`fit_eigen_reml`** (`2bf3c1ab`) + `target = :eigen`/`:auto` dispatch (`_auto_reml_route`, fill proxy
  `nnz(L)/n > 60`); exported; API-referenced. Status rows (`ff04be30`): capability-status experimental,
  validation-debt `V1-EIGEN-REML`. R-bridge coordination contract for the R twin (`ebd16562`).
- **Verification:** local `Pkg.test` GREEN (5 new testsets: 9/9, 5/5, 5/5, 11/11, 6/6); Rose audited the
  diagnosis AND the fitter (both CLEAR, edits applied); `preamble_cap` OK.

## Current Working State

- **Working tree:** clean except the 4 pre-existing FOREIGN files (retry5 ×2, two-lever, replay) — untouched;
  do NOT commit them.
- **Totoro scratch (`~/hsq_work/`):** `bench_signal.jl`, `bench_fillin.jl`, `bench_symbolic.jl`,
  `bench_eigen.jl`, `bench_fillratio.jl` + outputs — reusable; checkout at `f70559c` (pre-my-commits; `git
  pull` to get the eigen fitter if you re-benchmark there).
- **Blocked on nothing.** The next steps are follow-ons, not blockers.

## Key Decisions & Rationale

- **Eigen-once is EXPERIMENTAL, not covered** — a covered/public claim needs a pre-declared multi-seed
  recovery gate + an external same-estimand comparator (ASReml/blupf90) + a Rose audit. Not done; flagged in
  `V1-EIGEN-REML`.
- **`:auto` routes by fill proxy `nnz(L)/n`, NOT n** — eigen loses on well-structured pedigrees at every n
  (measured: realistic nnz/n≈17–19 → sparse; random ≥76 → eigen). Threshold 60 is a conservative first-pass.
- **R exposure is the R twin's job** — this Julia lane does not edit `hsquared`; the contract + ledger-#58
  comment are the handoff.
- **PR #274 mixes H2 + D1** on the shared branch — flagged to the owner (may want to split before merge).

## Landing State

| Artifact | Committed | Pushed | PR | State |
|---|---|---|---|---|
| Engine + tests (`src/likelihood.jl`, `src/HSquared.jl`, `test/runtests.jl`) | `2bf3c1ab` | ✅ | #274 | LANDED |
| Status/snapshot docs (capability-status, validation-debt, AGENTS.md, archive) | `ff04be30` | ✅ | #274 | LANDED |
| Diagnosis/benchmark/R-bridge/after-task docs + handover banner | `ebd16562` | ✅ | #274 | LANDED |
| API reference (`docs/src/api.md`) | `be6bb766` | ✅ | #274 | LANDED |
| This handover | (commit after writing) | pending | #274 | LANDING |
| 4 foreign dirty files | no | no | — | CARRIED-OVER (foreign; leave alone) |

## Next Immediate Steps (ordered — none are blockers)

1. **Szymek close-out:** communicate — not broken, "slow" understood, fill-in-aware fast path exists; the
   calibrated "matching ASReml is realistic" message. (Owner meets him.)
2. **Promotion experimental → covered** for `fit_eigen_reml`: pre-declared multi-seed recovery gate +
   external comparator (ASReml/blupf90) + Rose. Only then may any covered/count row move.
3. **Refine `:auto`** threshold from the conservative first-pass to the joint fill×n crossover (chip spawned;
   extend `bench_eigen.jl` timing).
4. **R lane:** implement the R `method="eigen"` route from the bridge contract; confirm count stays 5.
5. (Owner) split PR #274 into H2 vs D1 if desired before merge.

## Blockers / Open Questions

- None blocking. Owner decisions pending only for: the D-2026-06-12 TMB pivot (if ever pursued); whether to
  promote eigen to covered (needs the gate above); PR split.

## Gotchas & Failed Approaches

- **Do NOT benchmark REML with no-signal `y`** (σ²→0 boundary) and **benchmark the CURRENT checkout** — the
  whole prior misdiagnosis was a stale Totoro checkout + no-signal data.
- **Ordering (AMD/METIS) is NOT a lever** — measured-and-overturned 2026-06-23 (AMD is CHOLMOD default).
- **`nohup julia … &` over ssh holds the channel** — read the output FILE, not the ssh return.
- **eigen-once is `Z=I`-only, single-effect, dense `O(n³)`** — K≥2 can't be simultaneously diagonalized.

## How to Resume

1. Run `hsquared-rehydrate`; read this handover + the `AGENTS.md` snapshot +
   `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md`.
2. Spawn **Rose** before any public/capability claim; **Gauss/Karpinski** for any further AI-REML/eigen numerics.
3. The engine work is DONE — pick a follow-on (Szymek, promotion gate, `:auto` refinement) or a new lane.

**One-command resume (paste in an authenticated terminal):**

```sh
claude "Rehydrate with hsquared-rehydrate + docs/dev-log/handover/2026-07-24-claude-eigen-landing-handover.md. The H2 engine-performance thread is RESOLVED and LANDED (fit_ai_reml converges fast, no bug; eigen-once fitter fit_eigen_reml shipped experimental, target=:eigen/:auto; PR #274 draft). Do NOT re-open the diagnosis. Pick a follow-on: (a) close the loop with Szymek, (b) the experimental→covered promotion gate for fit_eigen_reml (recovery gate + ASReml/blupf90 comparator + Rose), or (c) refine the :auto fill threshold. Fences: public_covered_count=5, no capability move; D1 genomic PAUSED (D-68); TMB deferred (D-2026-06-12). Do NOT touch the 4 foreign dirty files."
```

## Mission-control summary

| Repo / lane | Branch / state | Shipped this thread | Next by leverage |
|---|---|---|---|
| HSquared.jl (engine perf) | `codex/2026-07-13-v07-performance-localization` @ `be6bb766`, PR #274 draft | diagnosis (converges fast, no bug); PosDef guards ×2 + iter guard; `fit_eigen_reml` + `:eigen`/`:auto` (experimental) | Szymek → promotion gate → `:auto` refine |
| hsquared (R twin) | (untouched this lane) | R-bridge contract + ledger-#58 handoff | implement `method="eigen"` route |
| D1 genomic-recovery | PAUSED (D-68), same branch | — | separate thread; do not conflate |

> Related: `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md` ·
> `docs/dev-log/after-task/2026-07-24-h2-engine-perf-eigen-fitter.md` ·
> `docs/dev-log/native-engine-arc/2026-07-24-eigen-fitter-r-bridge-contract.md` · PR #274 · ledger issue #58.
