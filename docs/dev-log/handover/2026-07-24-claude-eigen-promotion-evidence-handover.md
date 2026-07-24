# Session Handoff — `fit_eigen_reml` experimental→covered EVIDENCE PACKAGE assembled (staged) → owner + R lane

**Meta:** 2026-07-24 · **from:** Claude (Julia engine lane) · **to:** the owner (G10 decision) + next
Claude/Codex lane + the R twin · **branch:** `codex/2026-07-13-v07-performance-localization` @
`a9d8c01e` + the S8 consolidation commit · **PR:** #274 (DRAFT) · **mode:** landed — all evidence
committed + pushed.

## Critical Context (read or go wrong)

1. **This is a STAGED evidence package, NOT a promotion.** The eigen-once single-effect REML fitter
   `fit_eigen_reml` (`V1-EIGEN-REML`) has its **G11 legs discharged**, but **no capability-status row was
   flipped** and **`public_covered_count` stays 5**. The engine experimental→covered flip is the owner's
   **G10** call; the R public surface additionally needs the R bridge. Do NOT read this as "eigen is covered".
2. **G11 is fully satisfied** for eigen: a PRE-DECLARED 48-seed × 2-arm known-truth recovery gate PASSED
   (both arms 48/48 converged, all `|bias| ≤ 2·MCSE`, eigen ≡ AI-REML ≤ 2.62e-7) AND a same-estimand
   external REML comparator (`sommer` 4.4.5) AGREED to 7.77e-9. Rose G8 audit run (verdict below).
   **Erratum (Rose):** the gate's two arms are a fill gradient (WS `nnz(L)/n≈17` → HF `≈49` at n=1000),
   both fit eigen DIRECTLY; at n=1000 BOTH sit below the `:auto` threshold 60, so the gate does NOT exercise
   `:auto`'s eigen-selected regime (needs `>60`, n≥2000 random) — that rests on direct-fit substitutability.
3. **The recovery gate's pre-declaration was frozen at commit `1d9ec57d` BEFORE the run** — the acceptance
   rule cannot have been tuned to results. Do not "improve" the gate script and re-run it as if it were the
   same pre-declared evidence; a changed gate needs a fresh pre-declaration.
4. **`:auto` threshold was measured + KEPT at 60** (validated, conservative). It was NOT changed. An
   n-adaptive refinement is scoped + deferred (single-rep benchmark noise; the crossover is n-dependent).
5. **Fences held and MUST stay held:** `public_covered_count`=5; no capability flip; D1 genomic PAUSED
   (D-68); TMB deferred (D-2026-06-12); the R twin (`hsquared`) NOT edited from this lane; the 4 foreign
   dirty files (retry5 ×2, two-lever, genomic-replay) untouched — never in any session commit.

## What Was Accomplished (all committed on `codex/2026-07-13-v07-performance-localization`)

- **Recovery gate** (`1d9ec57d` freeze + `d61f79e0` result): `sim/phase_eigen_reml_recovery_gate.jl` +
  predeclaration + result checkpoints. Ran on Totoro (julia 1.12.6) at the frozen commit → `GATE: PASS`.
- **`sommer` comparator** (`e9c3a811`): `comparator/{prepare_sommer_eigen.jl,run_sommer_eigen.R}` +
  result checkpoint → `AGREE (7.77e-9)`. G11 comparator leg. Generated `sommer_eigen/` data gitignored.
- **`:auto` crossover benchmark** (`f27c6131` script + `a9d8c01e` doc): `sim/bench_eigen_crossover.jl` +
  the crossover doc → threshold 60 validated + kept; routing-test comment updated (no assertion change).
- **Szymek close-out draft** (`2026-07-24-szymek-closeout-draft.md`) — owner sends; ASReml honesty fence held.
- **Status + closure** (S8 consolidation commit): `V1-EIGEN-REML` debt row + capability-status row updated
  (G11 discharged, STAY partial/experimental, count 5); after-task; check-log; R-twin coordination note;
  this handover.
- **Verification:** local `Pkg.test()` PASSED (0 failures; eigen + `:auto` testsets green). **Rose G8 audit:
  CLEAR-WITH-CHANGES** (`docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md`) — evidence genuine +
  independently reproduced (Rose reran the gate seeds + comparator engine target), all fences hold; the 3
  required changes were WORDING corrections (the HF arm at n=1000 is ≈49 fill < threshold 60 so `:auto` picks
  sparse for both arms; the all-96 eigen≡AI-REML bound is 2.62e-7 not 2.18e-7), **all applied**.

## Current Working State

- **Working tree:** clean except the 4 pre-existing FOREIGN files (retry5 ×2, two-lever, genomic-replay) —
  untouched; do NOT commit them.
- **Totoro (`~/hsq_work/HSquared.jl`):** detached at the frozen commit `1d9ec57d`; logs `eigen_gate.log`,
  `eigen_crossover.log` retained. `bench_eigen.jl` (pre-existing) + `bench_eigen_crossover.jl` (this session)
  reusable. Clone's fetch refspec only tracks `main` — fetch a feature branch explicitly.
- **Blocked on nothing.** The remaining items are the owner's G10 decision + the R lane's bridge.

## Key Decisions & Rationale

- **STAGE, not flip.** Per the session fence ("no capability move"), the package is assembled + Rose-audited
  and left for the owner's G10 call. Even engine experimental→covered is deferred to the owner.
- **Two-arm gate DGP** (well-structured + higher-fill; a fill gradient WS≈17→HF≈49 at n=1000): validate
  eigen by DIRECT fits across low- and higher-fill structure. Owner-approved. NOTE (Rose G8 correction): at
  n=1000 both arms are below the `:auto` threshold 60 — the gate does NOT run inside `:auto`'s eigen regime.
- **Comparator single-seed (WS 20267000) + transitive high-fill.** Matches the V3/V4 precedent; the
  high-fill regime is established via `sommer`≡eigen (WS, 1e-8) + eigen≡AI-REML (all 96 seeds, 2e-7). A direct
  high-fill `sommer` run is a cheap optional add if a reviewer wants it.
- **Threshold kept at 60.** Measured crossover brackets it; a scalar can't be optimal at every n (crossover
  is n-dependent) but 60 is safely conservative with no catastrophic misroute. n-adaptive deferred.

## Landing State

| Artifact | Commit | Pushed | State |
|---|---|---|---|
| Recovery gate + predeclaration (freeze) | `1d9ec57d` | ✅ | LANDED |
| Recovery gate result (PASS) | `d61f79e0` | ✅ | LANDED |
| Crossover benchmark script | `f27c6131` | ✅ | LANDED |
| `sommer` comparator (AGREE) | `e9c3a811` | ✅ | LANDED |
| Crossover doc + routing-test comment | `a9d8c01e` | ✅ | LANDED |
| Status rows + after-task + check-log + coordination + Szymek + this handover | S8 commit | (after writing) | LANDING |
| 4 foreign dirty files | — | — | CARRIED-OVER (foreign; leave alone) |

## Next Immediate Steps (ordered — none are blockers)

1. **Owner (G10):** decide whether to flip `V1-EIGEN-REML` engine experimental→covered given G11 discharged
   + Rose verdict, or keep staged. `public_covered_count` stays 5 regardless (engine ≠ R-public).
2. **R lane:** implement the R `method="eigen"` opt-in route per the bridge contract
   (`2026-07-24-eigen-fitter-r-bridge-contract.md`); confirm count stays 5. Ledger Julia #5/#6 ↔ R #2/#5.
3. **Owner:** send the Szymek close-out; request his real pedigree + `hsquared` version to close on his data.
4. **Optional (deferred):** multi-rep `:auto` benchmark (→ maybe raise 60 to ~70 / n-adaptive); a direct
   high-fill `sommer` comparator seed.
5. **Owner:** consider splitting PR #274 (H2 + D1) before merge.

## Blockers / Open Questions

- None blocking. Owner decisions pending: the G10 flip (or keep staged); the PR split; the deferred
  threshold micro-optimization.

## Gotchas & Failed Approaches

- **Freeze BEFORE running.** The pre-declaration commit hash is the integrity anchor; never re-run a
  modified gate as the same evidence.
- **Do NOT benchmark REML with no-signal `y`** and **benchmark the CURRENT checkout** (the original H2
  misdiagnosis was a stale checkout + no-signal data).
- **`:auto` crossover is single-rep + noisy** (a t_eigen=21.6s GC outlier at n=4000); trust the 2–3×-margin
  brackets, not the marginal cells.
- **Dropbox `.git/index.lock`** recurs (repo under Dropbox); verify no live git process, then retry.
- **Totoro clone tracks only `main`** in its fetch refspec — `git fetch origin <branch>` explicitly.

## How to Resume

1. Run `hsquared-rehydrate`; read this handover + `docs/dev-log/after-task/2026-07-24-eigen-promotion-evidence-package.md`
   + the Rose audit + `docs/design/16-promotion-gate-predicates.md`.
2. If flipping to covered: spawn a fresh **Rose** full-chain audit + get owner G10; only then move the row +
   confirm `public_covered_count` stays 5.
3. The engine evidence is DONE — the next moves are the owner's G10 and the R lane's bridge.

**One-command resume (paste in an authenticated terminal):**

```sh
claude "Rehydrate with hsquared-rehydrate + docs/dev-log/handover/2026-07-24-claude-eigen-promotion-evidence-handover.md. The fit_eigen_reml experimental→covered EVIDENCE PACKAGE is assembled + staged: G11 discharged (48-seed×2-arm recovery gate PASS + sommer comparator AGREE 7.77e-9), :auto threshold validated (kept 60), Rose G8 audit done, status rows stay partial/experimental, public_covered_count stays 5. Do NOT re-open. Next: owner G10 flip decision (or keep staged); R lane method=\"eigen\" bridge; send the Szymek draft. Fences: no capability move; D1 PAUSED (D-68); TMB deferred; do NOT touch the 4 foreign dirty files."
```

## Mission-control summary

| Repo / lane | Branch / state | Shipped this session | Next by leverage |
|---|---|---|---|
| HSquared.jl (eigen promotion) | `codex/2026-07-13-…` @ S8 commit, PR #274 draft | G11 discharged (gate PASS + sommer AGREE); `:auto` validated; Rose audit; status staged partial | owner G10 → R bridge → send Szymek |
| hsquared (R twin) | untouched this lane | R-bridge contract handed off | implement `method="eigen"` route |
| D1 genomic-recovery | PAUSED (D-68), same branch | — | separate thread; do not conflate |

> Related: `docs/dev-log/after-task/2026-07-24-eigen-promotion-evidence-package.md` ·
> `docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md` · the recovery-checkpoint + native-engine-arc
> docs · `docs/design/16-promotion-gate-predicates.md` · PR #274 · ledger Julia #5/#6 ↔ R #2/#5.
