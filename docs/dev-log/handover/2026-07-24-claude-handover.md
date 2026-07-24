# Session Handoff — H2 engine-performance thread (Szymek report → REML fit is broken/slow) → next Claude lane

**Meta:** 2026-07-24 · **from:** Claude · **to:** next Claude (or Codex) lane · **branch:**
`codex/2026-07-13-v07-performance-localization` @ `bfdd45b2` · **mode:** live-toolchain (Totoro benchmarking)

## Critical Context (read or go wrong)

1. **This is a NEW H2 thread — engine fitting PERFORMANCE — not the paused D1 genomic-recovery.** It was
   triggered by collaborator **szymekdr** (Discord): `hsquared` is slow and crashes on moderate genomic G
   (n≈1000). D1 genomic-recovery stays PAUSED (D-68; owner leans GO — separate thread, do not conflate).
2. **The fast REML path does NOT converge out-of-the-box.** `fit_ai_reml` (the AI-REML Newton method, the
   engine's supposed ASReml-class path) runs to its **100-iteration cap / `not_converged`** on the pedigree
   animal model at every size and every tolerance tried — while reaching the correct loglik. So it is *slower*
   than the "slow" `fit_sparse_reml` at the sizes tested. **This is the concrete meaning of Shinichi's
   "something is not really working."**
3. **The decision-hinge measurement is UNRESOLVED.** Whether `fit_ai_reml` converges with *real genetic
   signal* (vs the σ²a→0 boundary of my no-signal test) is the question that decides the whole arc — and the
   confirming run (`bench_signal.jl`) **died on Totoro with no output.** RE-RUN IT FIRST (see Next Steps).
4. **Do NOT start building the TMB native engine.** The ultra-plan's adversarial panel (beat-the-plan) found
   a cheaper dominant path; TMB is a *conditional endpoint*, gated on the measurement above. See the hardened
   plan.

## What Was Accomplished

- **Measured the real bottleneck (Totoro, direct Julia):**
  - A-inverse is FAST — `pedigree_inverse` 800=3 ms, 100k=2.2 s (sparse Henderson + O(n) Meuwissen–Luo). **Not
    the bug.** (`src/pedigree.jl`.)
  - Szymek's baseline (`hsquared` R → default `fit_sparse_reml`): n=1000→3.4 s, 2000→24.6 s, 10000→**1708 s**,
    100k→>1 hr; ASReml 10000→12.9 s, 100k→2 s. Scaling ≈ **n^2.6** (derivative-free NelderMead re-factorizing
    the sparse-Cholesky MME every eval).
  - `fit_ai_reml` on **no-signal** data: 100-iter cap / `not_converged` at n=1000 (2.46 s) and 2000 (19.3 s),
    every tol 1e-4→1e-8, Δloglik vs sparse_reml ≈ 0, scales ~n^3. Convergence test is `ai_score_norm < tol`
    (absolute score norm), `src/likelihood.jl:82`.
- **Ran a two-workflow ultra-plan** for the "native R engine" arc (recon across hsquared/HSquared.jl/drmTMB/
  gllvmTMB + adversarial panel). **Verdict: do NOT build TMB next**; cheaper Option-A ladder first, gated on
  Stage 0. Design persisted in `docs/dev-log/native-engine-arc/` (hardened plan, arc design, beat-the-plan,
  recon-r2).
- **Corrected two of my own overclaims mid-flight** (honesty log): (a) "the fix is adopt AI-REML" — but
  `fit_ai_reml` already exists AND doesn't converge OOB; (b) "found the convergence bug (tol too tight)" —
  then measured that looser tol *also* fails, and flagged the no-signal-boundary confound I had ignored.
- Updated the H2 mission-control board and filed a brain triage note ("HSquared perf triage — A-inverse is
  fast, the gap is hsquared has no native engine").

## Current Working State

- **Working:** all benchmark scripts on Totoro under `~/hsq_work/` (`bench_ped.jl`, `bench_fit.jl`,
  `bench_aireml.jl`, `bench_tol.jl`, `bench_signal.jl`); the HSquared.jl checkout there
  (`~/hsq_work/HSquared.jl`, head `662663e` — has the current pedigree/likelihood code); Totoro reachable via
  the passwordless ControlMaster socket.
- **In progress / unresolved:** the real-signal `fit_ai_reml` test (`bench_signal.jl`) — process died, no
  output. THE decision hinge.
- **Blocked:** the native-engine go/no-go and the "flip the default to `fit_ai_reml`" fix are both blocked on
  first making a native REML path actually converge fast.

## Key Decisions & Rationale

- **Native-engine arc PIVOTS founding decision D-2026-06-12** ("R = frontend, Julia = engine"). Not yet
  authorized — owner decision pending (and it makes `hsquared` a compiled package: CRAN/cross-platform tax).
- **Beat-the-plan override (2026-07-24):** the collaborator's pain is *slow + crash*, not *bridge*. The cheap
  Option-A ladder (dense-`Ginv` crash guard + flip pedigree default to a *working* `fit_ai_reml` + warm-bridge)
  dominates a multi-week TMB build. Full TMB only if Stage 0 proves the ASReml gap survives the cheap fixes AND
  the roadmap commits to non-Gaussian families. (`docs/dev-log/native-engine-arc/adv-beat-the-plan.md`.)
- **Claim ceiling unchanged:** `public_covered_count=5`; nothing moved; no repo capability claim changed.

## Landing State

`handoff_gate.sh` needs a path (was passed a bare name); state hand-verified below. The HSquared.jl tree is at
`bfdd45b2` with only pre-existing foreign/protected files dirty (untouched by this thread).

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| This handover + design docs + snapshot, `codex/2026-07-13-v07-performance-localization` | on a fresh branch (this handover) | see PR | opening, DO NOT auto-merge | LANDING |
| Benchmark scripts `~/hsq_work/bench_*.jl` (Totoro) | n/a (remote scratch) | n/a | none | CARRIED-OVER — reuse; re-run `bench_signal.jl` |
| `docs/dev-log/after-task/2026-07-15-v07-d0f-retry5-*` (2 files, M) | no | no | none | CARRIED-OVER — foreign protected (prior session) |
| `docs/dev-log/2026-07-18-two-lever-*.md`, `sim/phase2_v07_...replay.jl` (??) | no | no | none | CARRIED-OVER — foreign WIP / D2-D4 scaffold |
| Plan file `~/.claude/plans/splendid-weaving-shannon.md` | n/a (session plan) | n/a | none | CARRIED-OVER — PLAN 2 = native engine + STAGE 0 RESULTS |
| Scratchpad `native-engine-*.md`, `adv-*.md`, `recon-r*.md` | copied into repo `docs/dev-log/native-engine-arc/` | see PR | — | LANDED (persisted) |

## Next Immediate Steps (ordered, for the next lane — needs LIVE Julia on Totoro)

1. **RE-RUN `bench_signal.jl` cleanly on Totoro** (real h²=0.4 signal, `em_warmup` ∈ {0,5}). Does `fit_ai_reml`
   converge in ~6 iters with real signal? Launch detached + read the output FILE (not through a pipe):
   `cd ~/hsq_work/HSquared.jl && OPENBLAS_NUM_THREADS=1 nohup ~/.juliaup/bin/julia --project=. ~/hsq_work/bench_signal.jl > ~/hsq_work/signal_out.txt 2>&1 &`
   then `grep -E "^n=|DONE" ~/hsq_work/signal_out.txt`.
2. **Instrument the AI-REML iteration** (`src/likelihood.jl` `_fit_ai_reml_diagnostics`): print the score-norm
   and (σ²a, σ²e) each iteration. Determine: oscillates? plateaus above tol? is the score inconsistent with
   the loglik it's at? This distinguishes **boundary artifact** from **genuine bug**.
3. **Decide the fix:** if boundary → default `em_warmup>0` + a *relative* convergence criterion (not absolute
   `score_norm < 1e-8`); if bug → fix the AI step / score formula.
4. **Confirm + fix the genomic crash:** reproduce Szymek's n≈1000 dense-G crash; route dense `Ginv` through a
   dense branch (recon-r2 §dense-Ginv).
5. **Only then** choose Option A (cheap Julia-lane fixes + flip default) vs the TMB program, per the hardened
   plan. Get owner sign-off on the D-2026-06-12 pivot before any TMB / compiled-package work.

## Blockers / Open Questions

- **Decision hinge:** does `fit_ai_reml` converge fast with real signal? (Unresolved — re-run step 1.)
- **Owner decisions pending (for TMB path only):** authorize the D-2026-06-12 pivot; accept `hsquared` as a
  compiled package.
- **Szymek chat:** Shinichi meets Szymek his afternoon / our morning. He has benchmark scripts (Julia + R,
  earlier in the thread) to reproduce on his side; pin his hsquared version + whether the crash is pedigree
  vs genomic.

## Gotchas & Failed Approaches

- **Do NOT benchmark REML with no-signal `y`** (random `y` → σ²a→0, AI-REML's documented hard boundary; it
  even has an EM-warmup, off by default, for this). My initial "AI-REML is broken" read was on exactly this
  unfair input — verify with real signal before concluding.
- **Do NOT call the A-inverse the bottleneck.** Measured fast (3 ms / 800). The wall is the REML *fit*.
- **`nohup julia … &` over ssh holds the ssh channel open** (the Bash call times out) but the process runs —
  read the output FILE separately, don't rely on the ssh return.
- **Piping julia stdout through `grep`/`tail` buffers** and shows nothing until exit — write to a file with
  `flush(stdout)` after each line and read the file.
- `fit_ai_reml` default `tol=1e-8` (absolute score norm) is suspicious, but **looser tol (1e-4) also failed**
  on no-signal data — so it is not *only* the tolerance.

## How to Resume

1. Run `hsquared-rehydrate`; read this handover, the `AGENTS.md` snapshot, and
   `docs/dev-log/native-engine-arc/native-engine-plan-hardened.md` (the recommendation) +
   `~/.claude/plans/splendid-weaving-shannon.md` PLAN 2 (STAGE 0 RESULTS).
2. Spawn Rose before any public/capability claim; bring Gauss/Karpinski for the AI-REML numerics.
3. Do **Next Immediate Step 1** (re-run `bench_signal.jl`) — it decides everything.

**One-command resume (paste in an authenticated terminal):**

```sh
claude "Rehydrate with hsquared-rehydrate + docs/dev-log/handover/2026-07-24-claude-handover.md. This is the H2 engine-PERFORMANCE thread (Szymek report), NOT the paused D1 genomic lane. First action: re-run ~/hsq_work/bench_signal.jl on Totoro (real h2=0.4 signal, em_warmup 0 and 5) — does fit_ai_reml converge fast with real signal? Then instrument src/likelihood.jl _fit_ai_reml_diagnostics to see the score-norm trajectory. Diagnose boundary-vs-bug. Do NOT build the TMB engine; do NOT touch the paused D1 genomic-recovery. Fences: public_covered_count=5, no capability move; native-engine pivots D-2026-06-12 (owner decision pending)."
```

## Mission-control summary

| Repo / lane | Branch / state | What shipped this thread | Plan by leverage |
|---|---|---|---|
| HSquared.jl (engine perf) | `codex/2026-07-13-v07-performance-localization` @ `bfdd45b2` | measured A-inverse fast + REML fit is the wall; `fit_ai_reml` doesn't converge OOB; ultra-plan (don't build TMB) | re-run signal test → diagnose AI-REML convergence → cheap fix vs TMB |
| hsquared (R twin) | same branch | (untouched this thread; bridges to Julia; no native engine) | receives the fix once the engine path converges fast |
| D1 genomic-recovery | PAUSED (D-68); owner leans GO | — | separate thread; do not conflate |

> Related: `docs/dev-log/native-engine-arc/native-engine-plan-hardened.md` ·
> `docs/dev-log/native-engine-arc/adv-beat-the-plan.md` · `~/.claude/plans/splendid-weaving-shannon.md` (PLAN 2)
> · brain note "HSquared perf triage — A-inverse is fast".
