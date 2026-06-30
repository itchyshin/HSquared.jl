# Handover → next Claude (HSquared.jl + hsquared) — 2026-06-30

You are the next **Claude** session picking up the HSquared.jl Julia engine lane (and its R twin
`hsquared`). The prior session resumed a frozen state and **finished v0.5 (QTL) to covered**. This doc is
durable; the chat is gone. Read it, rehydrate, and continue.

## Mission / goals (the durable "why")

- Two-twin quantitative-genetics stack: `hsquared` (R, user language) ⇄ `HSquared.jl` (Julia, engine reality).
- **Honest status is the #1 rule:** no fitting/coverage/significance claim without the full evidence chain +
  a real Rose audit. Repository state, not chat, is truth.
- The prior session's `/goal` was **"finish all of v0.5"** — **ACHIEVED** (V5 → covered, scoped). That goal's
  Stop hook is now satisfiable; **the maintainer should `/goal clear`** if it lingers.

## What was accomplished this session (all merged)

Resumed a frozen session and drove v0.5 (QTL genome-wide significance) from stuck → **covered (scoped)**,
across both twins, every slice pre-registered + Rose-audited:

| PR | Lane | What |
|---|---|---|
| #203 / #204 | Julia | add-one threshold calibration gates (validation, 4 designs) — PASS (recovered from the #202 anti-conservative-quantile negative) |
| #205 | Julia | PLINK max(T) external comparator — reproduces the rule |
| #207 | Julia | **production calibration on Totoro**: REUSE-shortcut NEGATIVE + verified diagnosis + **REBUILD-gate PASS** (exact rule, type-I 0.0542/0.0504 at α) |
| #208 | Julia | `genome_wide_marker_scan` — the validated exact rule, exported |
| hsquared #113 | R | `gwas(genome_wide = TRUE)` activation — live-verified element-wise + R CMD check 0/0/0 |
| #209 + hsquared #114 | both | **V5 `partial → covered` (scoped)** — the G10 flip (Rose PROMOTE-WITH-CHANGES → changes applied) |

Plus: **Totoro** (Shinichi's 384-core server) set up + used + **persisted to memory** (`~/shinichi-brain/tools/totoro-setup.md`, the global `AGENTS.md` compute section, this repo's coordination board); **JuliaCall installed** and the live R↔Julia bridge verified.

## Current working state

- **HSquared.jl** `main` @ `261b52c7` (#209). `validation_status()` = **48 rows / covered 8 / covered_external 3 / partial 36 / planned 1**. **V5-MARKER-THRESHOLD = covered (scoped)**. `Pkg.test()` green. Post-merge CI was in_progress at handover — verify green.
- **hsquared** `main` @ `c4e73ef` (#114). R public `gwas(genome_wide=TRUE)` surface stays **experimental** (engine-covered ≠ R-public-covered; the V4-MV-REML / Rose-risk-5 pattern). `R CMD check` 0/0/0 locally.
- **public-covered FITTING = 1 UNCHANGED** (v0.1 Gaussian) — V5 is opt-in significance, NOT a fitting capability and NOT the public default. This invariant is hard-pinned in `tools/gen_status_json.jl`.

### The V5 covered claim — exact scope (do not re-state it wider)
> **Covered:** genome-wide significance via the **exact per-dataset add-one permutation rule**
> (`genome_wide_marker_scan` / R `gwas(genome_wide=TRUE)`) — **type-I CONTROL only**, **fixed-effect /
> intercept-only**, on the tested LD designs (n∈{300..2000}, m∈{100..10000}).
> **Fenced out (NOT covered):** mixed-model/LOCO genome-wide null; power/coverage; broader-LD/covariate-adjusted;
> the `(1-α)` quantile rule + the fixed-null-reuse shortcut; the map-annotated formula API.

## Key decisions & rationale

- **The exact per-dataset rule, not the reuse shortcut.** Production calibration (#207) found the type-I-sim's
  fixed-null-REUSE shortcut mildly anti-conservative (0.056–0.061); diagnosed it (REUSE 0.0642 vs REBUILD
  0.0478) as a SIM artifact. The shipped rule rebuilds the null per analysis (REBUILD) → conservative/controlled.
- **Contract extension (maintainer-chosen):** the R calibration metadata allows `empirical_type1 = NA` for
  `permutation_addone` (no per-call type-I; validity by construction + externally validated) with a REQUIRED
  `validation_reference`.
- **Engine covered, R public surface experimental** — the conservative twin-discipline.
- **G10 was the maintainer's explicit merge** — the flip was held until sign-off, never self-promoted.

## Files created / modified (session diff `218f635d..261b52c7` on HSquared.jl; `8c5c886..c4e73ef` on hsquared)

Highlights (full list via `git diff --name-only 218f635d..261b52c7`):
- Julia engine: `src/genomic.jl` (`genome_wide_marker_scan`), `src/HSquared.jl` (export), `src/validation_status.jl` (V5 covered), `test/runtests.jl`, `test/fixtures/genome_wide_scan_parity/`, `docs/src/api.md`.
- Julia sims/comparator: `sim/phase5_qtl_addone_gate.jl`, `…_design_sweep.jl`, `…_production_calibration.jl`, `…_rebuild_production_gate.jl`, `phase5_reuse_vs_rebuild_diagnostic.jl`, `comparator/prepare_plink_threshold.jl` + `comparator/plink_threshold/`.
- Julia status/docs: `docs/design/{capability-status,validation-debt-register,16-promotion-gate-predicates}.md`, `docs/dev-log/recovery-checkpoints/2026-06-30-v5-*.md`, `docs/dev-log/after-task/2026-06-30-v5-*.md`, `docs/dev-log/check-log.d/2026-06-30-v5-covered-flip.md`, `docs/dev-log/coordination-board.md`, `tools/status_cache.json`.
- R twin: `R/gwas.R`, `tests/testthat/test-gwas.R`, `man/gwas.Rd`, `NEWS.md`, `docs/design/{capability-status,validation-debt-register}.md`, `docs/dev-log/after-task/2026-06-30-v5-gwas-genome-wide-activation.md`.
- This handover + the `AGENTS.md` snapshot edit.

## NEVER-COMMIT (foreign untracked — never `git add -A`)
- `sim/.v2gate_run.log.txt`
- `sim/phase6_nongaussian_interval_coverage.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`

## Plans / roadmap (beyond the immediate)

Per `AGENTS.md` + `docs/design/18-programme-plan-2026-06.md`, with v0.5 now covered:
1. **v0.4 broader-DGP MV recovery** + the in-suite unstructured-`sommer` test (closest standing item).
2. **v0.6 non-Gaussian / GLLVM** — Poisson/Binomial/probit/NB2/beta-binomial exist (`partial`); coverage is conservative-not-calibrated. Priority T1 = ordinal/categorical threshold (calving ease). Same-estimand comparator = `glmmTMB`.
3. **V5 standing debt** (covered ≠ debt retired): a 2nd external comparator (GCTA/statgenGWAS), mixed-model genome-wide calibration, broader-LD/covariate-adjusted (Freedman–Lane) + coverage, the #45 post-fit-scan dependency.
4. Cross-cutting: small-sample interval calibration (`V1-HERIT-TCAL`, planned); production sparse fitting (Wave F F4–F8).

## Next immediate steps (pick by leverage)
1. **Verify post-merge CI green** on both `main`s (`gh run list --limit 3` in each repo); the PR CI was green pre-merge.
2. **Maintainer:** `/goal clear` if "finish all of v0.5" lingers (achieved).
3. Start the next phase (roadmap above) — v0.4 broader-DGP MV is the closest; or chip at V5 standing debt (the GCTA 2nd comparator).

## Blockers / open questions
- None blocking. v0.5 is closed at covered. The V5 standing-debt items are owed-not-blocking.
- **Compute:** Totoro is set up (`~/hsq_work/HSquared.jl`, Julia 1.10.0) — reach for it for big-CPU sims, ≤100 cores. JuliaCall is installed for live R↔Julia bridge work.

## Gotchas / failed approaches (don't relearn these)
- **Permutation p-values are RNG-stream-dependent across Julia MAJOR versions** — do NOT assert cross-version byte-identity on `genome_wide_p_values`; pin the deterministic `chisq` exactly and the genome-wide p STRUCTURALLY (the fixture is the Julia-1.10 reference; the R LIVE bridge checks within-version).
- **`julia` is NOT on PATH** — use `~/.juliaup/bin/julia`. **Live R bridge** needs `export PATH="$HOME/.juliaup/bin:$PATH"` + `export HSQUARED_JULIA_PROJECT="<HSquared.jl path>"` (+ `NOT_CRAN=true` for live tests).
- The **full hsquared suite WITH the live bridge can crash R** (JuliaCall + many fits = memory) — run live tests filtered (`devtools::test(filter="gwas")`); CI runs them skipped.
- Three classifier guardrails this session (PLINK download, Totoro SSH, external binaries) needed **explicit maintainer authorization** — don't work around them.

## Mission-control

| Repo | main / CI | What shipped | Next by leverage |
|---|---|---|---|
| HSquared.jl | `261b52c7` (#209) · CI verify | **V5 → covered (scoped)**; `genome_wide_marker_scan`; production calibration (REUSE neg + REBUILD pass); PLINK comparator | v0.4 broader-DGP MV · V5 standing debt (GCTA) · v0.6 non-Gaussian |
| hsquared | `c4e73ef` (#114) · CI verify | `gwas(genome_wide=TRUE)` activated (R public surface stays experimental) | mirror only after a Julia covered move |

## How to resume (rehydration recipe)
1. Run the **`hsquared-rehydrate`** skill (live git/CI + `ROADMAP.md`, `docs/dev-log/coordination-board.md`, `docs/dev-log/check-log.md`, newest after-task, `docs/design/01-v0.1-contract.md`, `capability-status.md`, `validation-debt-register.md`).
2. Read the `AGENTS.md` **Live Phase Snapshot** (top bullet points here) + this doc + the V5 after-tasks (`docs/dev-log/after-task/2026-06-30-v5-*.md`).
3. **Before any public claim, spawn a real `rose-systems-auditor`** (mandatory gate).
4. Claude does planning/refactor/prose + pure-logic/CI checks; for **live R/TMB + Julia fits, `R CMD check`, heavy sims** prefer Codex or the live-env exports above.

### One-command resume (paste in YOUR authenticated terminal, from the HSquared.jl repo root)
- Interactive: `claude "Rehydrate from docs/dev-log/handover/2026-06-30-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."`
- Autonomous (clean context): `claude -p "Rehydrate from docs/dev-log/handover/2026-06-30-claude-handover.md + the AGENTS.md snapshot, then execute the Next Immediate Steps." --max-budget-usd 5`
