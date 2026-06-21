# Codex handover — HSquared.jl (2026-06-21) · START HERE (Codex team)

You are the **Codex team** inheriting `HSquared.jl`, the **Julia engine lane** (the
computational twin of the R package `hsquared`). The preceding work was done by the
**Claude** lane. **Repository state is truth**; this is the at-a-glance pointer.

## Who you are / how to inherit

- You read **`AGENTS.md` natively** (it is the source of truth — Claude reads it via
  `CLAUDE.md` → `@AGENTS.md`). Your team roster lives in **`.codex/agents/*.toml`**
  (Ada/Rose/Gauss/Curie/Fisher/Mrode/Henderson/Kirkpatrick/Karpinski/Grace/… — the same
  named lenses Claude used as review perspectives; spawn them as Codex subagents).
- You are **Ada**, the orchestrator, unless you delegate.
- Read, in order: this note → `AGENTS.md` → `ROADMAP.md` +
  `docs/design/11-completion-plan.md` → `docs/design/capability-status.md` +
  `docs/design/validation-debt-register.md` + `validation_status()` (**41 rows, 4
  covered**) → `docs/dev-log/after-task/2026-06-21-session-handover-v14.md` (the Claude
  segment detail) → the comparator-parity fixtures (`test/fixtures/*/README.md`) →
  issues **#61 / #93 / #38 / #50 / #42 / #41 / #46 / #3**.

## The Claude ↔ Codex division of labour (this is why this handover exists)

Per the operating contract: **Codex runs the live R/TMB and Julia toolchain — real
fits, `R CMD check`, simulations, rendering. Claude plans, refactors, writes prose, and
runs pure-logic tests.** Everything below is scoped to that boundary: the highest-value
work waiting for you is precisely the **execution-heavy** work Claude could set up but
not run to completion — the recovery sims at scale and, above all, the **external
comparator runs that are the only path to promoting anything `partial → covered`.**

Coordinate at every shared-contract touch and ROADMAP phase boundary; the durable
cross-lane channel is **GitHub issue comments** (Julia #5/#6/#7 ↔ R #2/#5/#6).

## Current state (repo = truth)

- **`main` @ `bf9decd`**. Clean tree, synced, **zero open PRs**. CI + Documenter green.
- **Julia:** `~/.juliaup/bin/julia` (you can run it live — this is your superpower vs the
  Claude lane). `Pkg.test()` green; `julia --project=docs docs/make.jl` green.
- `validation_status()` = **41 rows, 4 covered** — covered = the v0.1 univariate Gaussian
  animal model ONLY. Everything else `experimental`/`partial`. **Nothing else is covered,
  and the gate for covered is external-comparator evidence — which needs YOU to run it.**

## What Claude landed last segment (PRs #117–#123; context only)

1. **#117 `HSquaredMakieExt`** — Makie weak-dep drawing extension (forest / EBV
   caterpillar / G-scree / genetic-correlation heatmap). Makie is OUT of CI (cost
   discipline); the draw is LOCAL-verified only. **A Codex job:** wire a reproducible
   docs-render (or a CI job with Makie) so the draw is CI-gated, not just locally attested
   (the standing `V-PLOT-DRAW` debt).
2. **#118 Binomial per-record `n_trials`** — the general `cbind(successes, failures)` GLMM
   (resolves the engine side of **#61**). Validated to ~1e-12 reductions + a small-scale
   recovery.
3. **#119 Binomial/Bernoulli profile-LRT σ²a interval** — clamp/converged flags;
   `:variational` rejected.
4. **#121 genetic-correlation heatmap** drawing kind.
5. **#120/#122/#123** — handovers + snapshot housekeeping.

Each was adversarially verified by a named-lens review that caught a real defect. Keep
that discipline — spawn `rose-systems-auditor` + the relevant lens before any merge.

## Your highest-leverage work (execution-heavy — this is the point)

1. **External comparator runs → promote `partial → covered` (THE priority).** Claude
   flagged every `partial` row as blocked on external evidence it could not run. You can.
   Install and confront the Julia engine against the field standards, on the committed
   parity fixtures:
   - **Multivariate REML** (`V4-MV`/`V4-MV-REML`/`V4-FA`, #41/#49) vs **sommer / ASReml-R
     / BLUPF90 / WOMBAT** — fixtures in `test/fixtures/phase4_multitrait_parity/` +
     `test/fixtures/structured_covariance_parity/`.
   - **Fitted-Mrode confrontation** (`V1-*`, #46) — the serialized fitted target in
     `test/fixtures/animal_model_fitted_target/` (+ the opt-in **JWAS** scaffold).
   - **Genomic** (`V2-*`, #3) vs **AGHmatrix / BLUPF90 / JWAS**.
   - **Non-Gaussian / genetic-GLLVM** (`V6-*`, #50) vs **GLLVM.jl / gllvmTMB / MCMCglmm**.
   Each confrontation that passes (with a documented tolerance + provenance) is what lets
   Ada move a row to `covered` — record it under `docs/dev-log/recovery-checkpoints/` and
   update the capability/debt rows. **Do not move to `covered` without it.**
2. **Run the opt-in recovery sims at SCALE / more seeds.** They are deliberately outside
   CI (RNG). Claude ran them small/validation-scale; you can run them large and on the
   predeclared multi-seed plans. Reproducible invocation (single-threaded for determinism):
   `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 ~/.juliaup/bin/julia --project=. sim/<file>.jl`
   - `sim/phase6_{poisson,bernoulli,binomial,gllvm}_recovery.jl`,
     `sim/phase4{,b}_*recovery.jl`, `sim/phase5_marker_scan_recovery.jl`,
     `sim/phase5_threshold_calibration.jl`, `sim/summarize_recovery_calibration.jl`.
   - The multivariate-recovery calibration protocol
     (`docs/dev-log/decisions/2026-06-14-multivariate-recovery-calibration-protocol.md`)
     defines the seed-count/run-plan/reporting gate — execute it and report pass/fail.
3. **Live R↔Julia bridge execution.** The bridge payloads exist; the R lane recomputes
   today. Running a real R `hsquared` fit through the Julia engine (and the `autoplot.R`
   ↔ `hsquared_figure` drawing parity) is execution you can do — coordinate with the R lane.
4. **Solo Julia builds (no gate):** GWAS Manhattan/QQ + RR set-A drawing kinds
   (preparers exist); the Gaussian two-component (σ²a,σ²e) interval (nuisance profiling);
   production sparse fitting + large-pedigree hardening (#6). **GPU + raw speed are PARKED**
   per the user's standing directive **"accuracy first — no need to hurry."** A CPU
   benchmark baseline exists (`sim/cpu_fit_benchmark.jl`, measurement only — no perf claim);
   do not make a performance claim without benchmarks the user has asked for.

## Cross-lane — drafts prepared by Claude, NOT posted (the user's call)

Outward posting (issue comments / closing issues) is **the user's decision** — confirm
before posting. Three answers are ready:
- **#38** (reword the "250-animal AI-matrix" claim) — **already fixed on `main`**; can be CLOSED.
- **#61** (Binomial-payload question) — **engine side RESOLVED** (per-record `n_trials`,
  #118); R's `cbind`/weights → `n_trials` vector mapping is now mechanical.
- **#93** (plotting contract) — **Julia side COMPLETE** incl. the drawing extension;
  remaining is R wiring `autoplot.R` to consume the bridge payloads.

## Hard constraints (unchanged — non-negotiable)

- **Edit ONLY `HSquared.jl`.** Sister repos (R `hsquared`, DRM.jl, GLLVM.jl, drmTMB,
  gllvmTMB) are READ-ONLY references; GitHub issues are the coordination channel.
- **Land via PR**; squash-merge CI-green slices. **Full DoD per slice:** implementation +
  TDD tests + docs + capability-status row + validation-debt row + check-log evidence +
  after-task report + Rose claim-vs-evidence audit + clean local checks + clean CI.
- **Honest status, both ways:** NO fitting / performance / GPU / "covered" claim without
  the full evidence chain — AND no stale "X is missing" once X exists (run the
  Rose-principle sweep on every claim edit). A `covered` promotion REQUIRES external-
  comparator evidence with documented provenance + tolerance.
- **Local checks before push** (`Pkg.test()` + `docs/make.jl`); **CI on a clean checkout
  is the authoritative gate** (Dropbox can desync the working tree mid-edit). Use
  `git add <specific files>`, not `-A`.
- **Adversarially verify** non-trivial slices before landing (a Workflow or named-lens
  subagents from `.codex/agents/`) — the reviews keep finding real defects.
- **Do not copy statistical claims/code from sibling projects** without checking license,
  provenance, tests, and fit; adapt process patterns and record provenance.

## Smallest safe next action (for Codex specifically)

Pick ONE execution-heavy target and run it end to end: e.g. **run
`sim/phase4_multivariate_reml_recovery.jl` at the calibration-protocol seed count and
confront it against sommer on the `phase4_multitrait_parity` fixture** — that is the
shortest path to the first `partial → covered` promotion, and it is work only your lane
can do. Record the run under `docs/dev-log/recovery-checkpoints/`, then have Ada + Rose
gate the capability/debt-row update. First check #41/#46/#3/#50/#93 for R-lane replies,
and ask the user before posting the #38/#61/#93 drafts.
