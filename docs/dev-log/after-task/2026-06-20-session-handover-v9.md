# Session handover — 2026-06-20 (v9) · START HERE

Inheritance note for a fresh session. Repository state is truth; this is the
at-a-glance pointer. Supersedes v8 (`2026-06-20-session-handover-v8.md`).

## How to inherit the plan, mission control, and goal (do this first)

You are **Ada**, orchestrator of the `HSquared.jl` Julia quantitative-genetics
engine (computational twin of the R package `hsquared`). Run the
`hsquared-rehydrate` skill, then read in order:
1. **THIS note.**
2. **Goal/doctrine** → `AGENTS.md` (Definition of Done, honest-status rules, lane
   routing) + `CLAUDE.md`.
3. **Plan** → `ROADMAP.md` + `docs/design/11-completion-plan.md`.
4. **Mission control** → the widget at `~/.claude/hsquared-control-centre/status.json`
   (`:8791`; preserve `live_agents`).
5. **Honest status** → `docs/design/capability-status.md` +
   `docs/design/validation-debt-register.md`; `validation_status()` (38 rows).
6. **Plotting** → `docs/design/13-plotting-layer.md` (ratified architecture + Florence
   figure contract + the R-twin alignment §7).
7. **Cross-lane** → GitHub issues **#61** (joint critical path, just re-baselined),
   **#93** (plotting contract — 8 open questions awaiting R), **#53** (metafounders),
   **#50** (genetic GLLVM).

## Current state (repo = truth)

- Branch **`main` @ `2fefd31`**. Working tree clean; CI + Documenter green.
- **2 open PRs:** **#95** (Set B `variance_components_plot_data` — green, **Rose audit
  pending**, ready to merge) and **#86** (the old v7 closeout — leftover, merge/close).
- `Pkg.test()` green; `validation_status()` = **38 rows**. One public-covered
  capability (v0.1 univariate Gaussian animal model); everything else
  `experimental`/`partial`. **Nothing promoted to covered this session.**

## DONE this session (huge autonomous run, Ada — 7 PRs merged #87–#92,#94 + #95 open)

- **#87** Genetic GLLVM (#50) scope + reuse-not-reinvent design note (posted to #50).
- **#88** `rr_eigenfunctions` — Kirkpatrick covariance-function eigen-decomposition.
- **#89** `metafounder_animal_model` — wires `inv(A^Γ)` into `henderson_mme` (Γ=0
  reduces to the classical animal model; animal-only — see #53 hold below).
- **#90** v8 handover.
- **#91 + #92 + #95** the **PLOTTING LAYER** — engine plot-data preparers for all 4
  figure sets: **A** RR (`rr_eigenfunctions_plot_data` / `rr_genetic_variance_plot_data`
  / `rr_covariance_surface_plot_data`), **C** G-geometry
  (`genetic_pca_plot_data` / `genetic_correlation_plot_data`, rotation-invariant HARD
  contract), **B** variance-components forest (`variance_components_plot_data`, PR #95
  Rose-pending), **D** GWAS (`marker_*_data`, pre-existing). All `*_plot_data`
  NamedTuples, backend-free, honest-status-flagged.
- **#94** the plotting-layer design doc + R-twin alignment outcome.

## Cross-lane / "communicate and bridge" (posted this session)

- **#61 re-baselined** — discovered **5 of 6 bridge seams are already
  delivered-and-flipped** on both repos' current main (the #61 snapshot was badly
  stale; PR #59 + V6-LAPLACE + selinv-payload + RR + metafounders all predate it).
- **#53 metafounder reconciliation** — Q1–Q4 answers posted; the shipped
  `metafounder_animal_model` is **animal-only**, but R's ratified **A4 wants the
  combined (m+n) inverse** payload. **Julia is HOLDING the combined-inverse
  `:metafounder` payload build until R confirms A4.**
- **#93 plotting contract** — posted to the R twin with **8 open questions** (field
  rename `genetic_variance→value`, melt ownership, `*_meta` sourcing, Set-B interval
  knob, parity-test home, biplot scaling, a `breeding_values` preparer). The R twin
  already has `R/autoplot.R`; the engine preparers are **~90% R-consumable**; the
  engine will **adapt field shapes to `autoplot.R`** — **AWAITING R's answers**.

## Held (do NOT build until unblocked)

1. **#53 combined-inverse `:metafounder` payload** — gated on R confirming A4 (#53).
2. **Plotting engine adaptations** (the `genetic_variance→value` rename, melt format,
   `*_meta` NamedTuple, parity-test home) — gated on R's #93 answers (be FLEXIBLE —
   shape to what R replies).
3. **Genetic GLLVM #50 build** — gated on cross-team Q1 (GLLVM.jl dependency) / Q2
   (`animal_*` grammar) on #50, plus #44 (non-Gaussian bridge) + #37/#42 (FA
   calibration + rotation-convention ratification) per #61.

## What remains (prioritized)

1. **Merge PR #95** (Set B) — run the Rose claim-vs-evidence audit (it was interrupted
   at handover), then squash-merge if clean. (The Set-B branch is
   `julia/variance-components-plot-data`; tests 14/14 + docs green locally.)
2. **`HSquaredMakieExt`** — the Julia drawing weak-dep extension (Project.toml
   `[weakdeps]`/`[extensions]`), consuming the landed `*_plot_data` NamedTuples (the
   sisters DRM.jl/GLLVM.jl use docs-scripts; we add a real extension — `13-plotting-layer.md`).
3. **Act on R's #93 answers** — the field-rename + melt + meta + parity-test as R
   replies (flexible). The live RR parity test is the discipline.
4. **Genetic-GLLVM #50 descriptors slice** — the cross-team-independent first step
   (`genetic_gllvm_descriptors`, pure-Julia, rotation-invariant, reuses
   `factor_analytic_covariance` + `genetic_pca`); a design panel was scoped (the
   scope doc `docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md` has the full
   design). Build once Q1/Q2 + #44/#37 clear, or build slice-1 (it's Q1/Q2-independent).
5. **Highest-leverage non-solo:** the R-lane external comparator runs (#41/#49
   multivariate; fitted-Mrode #46) — promotes `partial`→`covered`.

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** Sister repos READ-ONLY; GitHub issues = coordination.
- **Land via PR**; squash-merge CI-green slices (`gh api -X PUT
  repos/itchyshin/HSquared.jl/pulls/N/merge -f merge_method=squash`). TDD + full DoD +
  Rose audit per slice. **Julia at `~/.juliaup/bin/julia` (NOT on PATH).**
- **Outward posting (issue comments) is the user's call** — confirm first; the
  auto-mode classifier blocks agent issue-posting/issue-creation unless the user
  explicitly authorizes (it did this session for #61/#53/#93).
- Local `Pkg.test()` + `docs/make.jl` before push; **CI on a clean checkout is the
  authoritative gate** (Dropbox can desync the working tree).
- **Plotting honesty (binding):** G-geometry plots the rotation-invariant
  eigenstructure, NEVER raw FA loadings; reliability is validation-scale; GWAS p is
  nominal/uncalibrated; h² intervals are asymptotic. (`13-plotting-layer.md` §4.)

## Smallest safe next action

Run the Rose audit on **PR #95** and merge it; then either start `HSquaredMakieExt`
or the genetic-GLLVM #50 descriptors slice. Check #93 / #53 / #50 for R replies and
adapt (flexible).

## Verification snapshot

- `gh pr list --state merged` → #87–#92, #94 merged this session. `main` @ `2fefd31`,
  CI + Documenter green; `Pkg.test()` green; `validation_status()` = 38 rows.
- Open: #95 (Set B, Rose-pending), #86 (leftover). Cross-lane threads live on
  #61 / #93 / #53 / #50.
