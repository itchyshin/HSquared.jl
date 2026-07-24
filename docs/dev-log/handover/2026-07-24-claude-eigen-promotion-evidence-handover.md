# Handover → next Claude (HSquared.jl, Julia engine lane) — 2026-07-24 (eigen promotion evidence)

**You are the next Claude**, resuming the `HSquared.jl` Julia engine lane. This is the canonical
session-entrypoint handover (the `AGENTS.md` snapshot points here). **Branch:**
`codex/2026-07-13-v07-performance-localization` @ `8bdfc78b` (pushed, in sync) · **PR:** #274 (DRAFT — do
not auto-merge) · **From:** Claude (this session) · **Mode:** landed — everything committed + pushed;
working tree clean except 4 pre-existing FOREIGN files.

## Goals / mission (the durable "why")

`HSquared.jl` is the Julia **engine** twin of the R package `hsquared`; R owns the public user language,
Julia owns the engine reality. No fitting/perf claim without the full evidence chain; repo state (not
chat) is truth. This session's mission: assemble the **experimental→covered evidence package** for the
eigen-once single-effect REML fitter `fit_eigen_reml` (`V1-EIGEN-REML`) to the doc-16 G11 bar, **staged
for the owner's promotion call** — folding in the owner's three follow-ons (Szymek close-out, promotion
gate, `:auto` threshold). **Standing fences:** `public_covered_count` stays **5**; no capability-status
row flips; D1 genomic PAUSED (D-68); TMB deferred (D-2026-06-12); R twin not edited from this lane.

## What was accomplished this session

The eigen promotion **evidence package is assembled, Rose-audited, and STAGED — nothing promoted.**
`V1-EIGEN-REML` stays `partial`/`experimental`; `public_covered_count` stays **5**.

- **G11 recovery leg → PASS.** Pre-declared 48-seed × 2-arm known-truth gate, frozen at `1d9ec57d`
  **before** the run, executed on Totoro (julia 1.12.6): both arms 48/48 converged (eigen + AI-REML),
  all `|bias| ≤ 2·MCSE` (worst 1.01·MCSE, WS σ²a), eigen ≡ AI-REML ≤ 2.62e-7.
- **G11 comparator leg → AGREE.** `sommer` 4.4.5 independent REML matched `fit_eigen_reml` to **7.77e-9**
  on gate seed 20267000 (local R). With the gate, **G11 is fully discharged.**
- **`:auto` threshold (follow-on c) → measured + KEPT at 60.** Fill×n crossover benchmarked on Totoro;
  60 is validated + safely conservative; n-adaptive refinement scoped + DEFERRED. **No `src` logic change.**
- **Szymek close-out (follow-on a) → drafted** (owner sends; ASReml honesty fence held twice).
- **Rose G8 audit → CLEAR-WITH-CHANGES** (real spawned audit; reran the gate seeds + comparator target).
  She caught a real error, now fixed everywhere: **the gate ran at n=1000, where even the HF arm's
  `nnz(L)/n ≈ 49` is below the `:auto` threshold 60**, so `:auto` routes BOTH arms to sparse — eigen was
  validated by DIRECT fits across a WS≈17→HF≈49 fill gradient, NOT inside `:auto`'s eigen-selected regime
  (that needs n≥2000). An erratum is in the result doc; the claim is corrected in all docs.
- **Melissa plan-vs-actual reconcile** (2 drift, 2 unclear, 1 adaptive) — all addressed.
- **Verify:** `Pkg.test()` PASSED (0 failures). `docs/make.jl` unaffected (no Documenter-source changed).

## Current working state

- **Working / landed:** all six session commits pushed (see the graph in Files below). Branch in sync.
- **In progress:** none — the engine evidence is done.
- **Blocked:** nothing. The next moves are owner (G10) + R-lane (bridge) decisions.
- **Foreign dirty files (NEVER commit — not this session's):** `docs/dev-log/after-task/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`,
  `docs/dev-log/check-log.d/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`,
  `docs/dev-log/2026-07-18-two-lever-news-fit-laplace-reml-is-the-cox-reid-lever.md`,
  `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`.

## Key decisions & rationale

- **STAGE, not flip.** Per the session fence, the package is assembled + Rose-audited and left for the
  owner's G10 call; even the engine experimental→covered move is deferred. Count stays 5 regardless
  (engine-covered ≠ R-public-covered).
- **Two-arm gate = a fill GRADIENT (WS≈17 → HF≈49 at n=1000), fit eigen DIRECTLY** — validates recovery
  across low/higher-fill structure. **NOT a run inside `:auto`'s eigen regime** (Rose's correction).
- **Comparator single-seed (WS 20267000) + transitive high-fill.** Matches V3/V4 precedent; a direct
  high-fill `sommer` seed is a cheap optional add.
- **Threshold kept at 60** (a scalar can't be optimal at every n; the crossover proxy rises with n).

## Files created / modified (session diff `8b3809c6..8bdfc78b`)

Engine/sim/comparator (new): `sim/phase_eigen_reml_recovery_gate.jl`, `sim/bench_eigen_crossover.jl`,
`comparator/prepare_sommer_eigen.jl`, `comparator/run_sommer_eigen.R` · `.gitignore` (+`sommer_eigen/`) ·
`test/runtests.jl` (routing-test COMMENT only — no assertion change).
Docs (new): `docs/dev-log/recovery-checkpoints/2026-07-24-eigen-reml-recovery-gate-{predeclaration,result}.md`,
`.../2026-07-24-eigen-reml-comparator.md`, `docs/dev-log/native-engine-arc/2026-07-24-eigen-auto-threshold-crossover.md`,
`.../2026-07-24-szymek-closeout-draft.md`, `docs/dev-log/after-task/2026-07-24-eigen-promotion-evidence-package.md`,
`docs/dev-log/check-log.d/2026-07-24-eigen-promotion-evidence.md`,
`docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md`,
`docs/dev-log/plan-actual/2026-07-24-eigen-promotion-evidence.md`, and **this doc**.
Docs (edited): `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`
(`V1-EIGEN-REML` — G11 discharged, stays partial), `docs/dev-log/coordination-board.md` (R-twin handoff note),
`AGENTS.md` (snapshot pointer → this doc), `docs/dev-log/phase-snapshot-archive.md` (archived prior entry).

Commit graph: `1d9ec57d` freeze → `d61f79e0` gate PASS → `f27c6131` benchmark → `e9c3a811` comparator →
`a9d8c01e` crossover doc → `8bdfc78b` consolidation (+ this handover commit).

## Next immediate steps (ordered — none blocking; hand LIVE-toolchain items to in-session compute / Codex)

1. **Owner (G10):** flip `V1-EIGEN-REML` engine experimental→covered given G11 + Rose, or keep staged.
   Count stays 5 either way. If flipping: spawn a FRESH full-chain Rose + get sign-off before moving the row.
2. **R lane (R twin, not this repo):** implement the opt-in R `method="eigen"` route per the bridge
   contract (`docs/dev-log/native-engine-arc/2026-07-24-eigen-fitter-r-bridge-contract.md`); confirm count 5.
   Ledger: Julia #5/#6 ↔ R #2/#5.
3. **Owner:** send the Szymek close-out; request his real pedigree + `hsquared` version.
4. **Optional (deferred, live compute):** a direct high-fill `sommer` comparator seed; a multi-rep `:auto`
   benchmark (→ maybe raise 60 to ~70 / n-adaptive); a larger-n / broader-h² recovery gate.
5. **Owner:** consider splitting PR #274 (H2 + D1) before merge.

## Blockers / open questions

None blocking. Owner decisions pending: the G10 flip (or keep staged); the PR split; the deferred
follow-ups. **D1 genomic lane stays PAUSED (D-68)** — separate thread on this same branch; do not conflate.

## Gotchas / failed approaches

- **Freeze BEFORE running** — the pre-declaration commit hash is the integrity anchor; never re-run a
  modified gate as the same evidence. The frozen predeclaration + gate-script comments say the HF arm is
  "`≥76`→`:auto`→eigen" — that is an **n≥2000** figure, WRONG at the gate's n=1000; the result-doc erratum
  is the correction (frozen files can't be edited without breaking freeze integrity).
- **Do NOT benchmark REML with no-signal `y`** and **benchmark the CURRENT checkout** (the original H2
  misdiagnosis was a stale checkout + no-signal data — do not re-open it).
- **`:auto` crossover is single-rep + noisy** (a t_eigen=21.6 s GC outlier at n=4000) — trust the
  2–3×-margin brackets, not the marginal cells.
- **Dropbox `.git/index.lock`** recurs (repo under Dropbox) — verify no live git process, then retry.
- **Totoro clone (`~/hsq_work/HSquared.jl`) tracks only `main`** in its fetch refspec — `git fetch origin
  <branch>` explicitly, then `git checkout FETCH_HEAD`. julia is `~/.juliaup/bin/julia` (1.12.6), not on the
  non-interactive PATH. Socket: `SOCK=$(ls ~/.ssh/cm-*totoro* | head -1)` (no Duo).

## How to resume (TARGET = claude)

1. Run the **`hsquared-rehydrate`** skill (live git/CI + ROADMAP + coordination board + check-log + newest
   after-task + capability-status + validation-debt).
2. Read the `AGENTS.md` Live Phase Snapshot, THIS doc, then the detail set:
   `docs/dev-log/after-task/2026-07-24-eigen-promotion-evidence-package.md`,
   `docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md` (the G8 audit + its 3 corrections),
   `docs/design/16-promotion-gate-predicates.md` (the G1–G11 bar).
3. **Before ANY public/capability claim or a promotion flip, spawn a REAL Rose subagent** (mandatory G8;
   a lens is not enough). Gauss/Karpinski for any further eigen/`:auto` numerics.
4. **Division of labour:** Claude plans/refactors/writes prose + runs pure-logic/CI checks; hand the LIVE
   toolchain (real fits, `R CMD check`, sims, a direct high-fill `sommer` run, Totoro campaigns) to the
   in-session compute you drive or to a Codex session. Skills live in `.claude/skills/`.

### One-command resume (paste in an authenticated terminal, from the repo root)

- Interactive: `claude "Rehydrate with hsquared-rehydrate + docs/dev-log/handover/2026-07-24-claude-eigen-promotion-evidence-handover.md + the AGENTS.md snapshot. The fit_eigen_reml experimental→covered evidence package is assembled + STAGED (G11 discharged: 48-seed×2-arm recovery gate PASS + sommer comparator AGREE 7.77e-9; Rose G8 CLEAR-WITH-CHANGES applied; :auto threshold validated/kept 60). Do NOT re-open. Continue with the Next Immediate Steps: owner G10 flip-or-stay, R method=\"eigen\" bridge, send the Szymek draft. Fences: public_covered_count=5, no capability move; D1 PAUSED (D-68); TMB deferred; do NOT touch the 4 foreign dirty files."`
- Autonomous, clean context: the same prompt via `claude -p "…" --max-budget-usd <cap>`.

## Mission-control summary

| Repo / lane | Branch / state / CI | Shipped this session | Next by leverage |
|---|---|---|---|
| HSquared.jl (H2 engine — eigen promotion) | `codex/2026-07-13-…` @ `8bdfc78b`, PR #274 draft; `Pkg.test` green | G11 discharged (gate PASS + sommer AGREE 7.77e-9); `:auto` validated (kept 60); Rose G8 CLEAR-WITH-CHANGES applied; staged partial | owner G10 flip-or-stay → R bridge → send Szymek |
| hsquared (R twin) | untouched this lane | R-bridge contract handed off | implement `method="eigen"` route (count stays 5) |
| D1 genomic-recovery | PAUSED (D-68), same branch | — | separate thread; do not conflate |

> Detail companions: `docs/dev-log/after-task/2026-07-24-eigen-promotion-evidence-package.md` ·
> `docs/dev-log/scout/2026-07-24-rose-eigen-evidence-audit.md` ·
> `docs/dev-log/plan-actual/2026-07-24-eigen-promotion-evidence.md` · prior-thread handovers:
> `2026-07-24-claude-eigen-landing-handover.md`, `2026-07-24-claude-handover.md` (superseded) · PR #274 ·
> ledger Julia #5/#6 ↔ R #2/#5.
