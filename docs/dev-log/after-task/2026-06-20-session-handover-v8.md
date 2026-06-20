# Session handover — 2026-06-20 (v8) · START HERE

Inheritance note for a fresh session. Repository state is truth; this is the
at-a-glance pointer. Supersedes v7 (`2026-06-20-session-handover-v7.md`); the v7
PR **#86 is still open** (a leftover — merge or close it whenever).

## How to inherit the plan, mission control, and goal (do this first)

Run the `hsquared-rehydrate` skill, then read in order:
1. **THIS note.**
2. **Goal/doctrine** → `AGENTS.md` (Live Phase Snapshot + Definition of Done +
   honest-status rules + lane routing) and `CLAUDE.md`.
3. **Plan** → `ROADMAP.md` + `docs/design/11-completion-plan.md`.
4. **Mission control** → the widget at `~/.claude/hsquared-control-centre/status.json`
   (served on `:8791`; preserve `live_agents`).
5. **Honest status** → `docs/design/capability-status.md` +
   `docs/design/validation-debt-register.md`; `validation_status()` in-code (38 rows).
6. **Cross-lane** → GitHub issues **#61** (joint critical path) and **#50** (genetic
   GLLVM design note posted this session).
7. Newest `docs/dev-log/check-log.d/*` + `after-task/*`.

## Current state (repo = truth)

- Branch **`main` @ `a89ee7c`**. Working tree clean; CI + Documenter green.
  **1 open PR: #86** (the v7 closeout doc — leftover from the prior session).
- `Pkg.test()` green; `docs/make.jl` exit 0; `validation_status()` = **38 rows**.
- One public-covered capability (v0.1 univariate Gaussian animal model); everything
  else `experimental`/`partial`. **Nothing promoted to covered this session.**

## DONE this session (autonomous run, Ada — 3 PRs: #87–#89)

- **#87** Genetic GLLVM (#50) **scope + reuse-not-reinvent design note** (docs-only;
  `docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md`). The killed scout Workflow
  was redone read-only (3 Explore passes). **Design note also posted to issue #50.**
- **#88** **`rr_eigenfunctions`** (#54 slice 4) — Kirkpatrick covariance-function
  eigen-decomposition of a supplied `K_g` (reuses `genetic_pca`); descriptive,
  supplied-covariance, rotation-invariant; 17/17 tests; Rose **MERGE** (reproduced
  spectral reconstruction 1.3e-15 + eigenfunction orthonormality 2.3e-8).
- **#89** **`metafounder_animal_model`** (#53) — wires the validated `inv(A^Γ)` into
  `henderson_mme`; `Γ=0` reduces to the classical animal model (bit-exact); Rose
  **MERGE** + independently confirmed the animal-only EBVs match the full combined
  MME (explicit metafounder levels) to 1.5e-15; 7/7 tests; supplied-variance/Γ only.

**Stale-items finding (saves the next session time):** #61's "lowest-effort"
honesty asks **#38 / #44 / #47 are ALREADY DONE on current main** — that snapshot
(2026-06-19) predates PR #59 (multivariate SEs+LRTs) and the consolidated
`V6-LAPLACE` `validation_status()` row. Do **not** redo them. (The in-code
`validation_status()` deliberately carries ONE consolidated `V6-LAPLACE` row that
points to the register's 5 detailed V6 rows.)

## Genetic GLLVM (#50) — the headline build, currently GATED

The scope doc + the #50 comment define it: a GLLVM whose latent rows carry a genetic
covariance `A` (`vec(U) ~ N(0, G_lat ⊗ A)`) — plug HSquared's relationship inverses
+ non-Gaussian marginal into the GLLVM latent layer; **reuse, don't reinvent**
(GLLVM.jl MIT patterns / gllvmTMB GPL-3 **design-only** / HSquared own code direct).
3-slice plan: (1) descriptors → (2) supplied-covariance latent marginal → (3) REML.

**Gates before building (per #61 + the user's "coordinate cross-team first"):**
- **#44** (non-Gaussian bridge / MarginalMethod) and **#37/#42** (FA calibration +
  rotation-convention ratification) — #61 states "#50 depends on #44 AND #37".
- Cross-team answers on #50: **Q1** (GLLVM.jl dependency-vs-mirror), **Q2** (`animal_*`
  grammar vs a distinct `gllvm()`/`latent()` vocab). Q3 (rotation contract) folds
  into the FA-convention ratification already pending on #42 ↔ R #7.

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** Sister repos READ-ONLY; GitHub issues = coordination.
- **Land via PR**; merge CI-green slices (REST squash:
  `gh api -X PUT repos/itchyshin/HSquared.jl/pulls/N/merge -f merge_method=squash`).
  TDD + full DoD + Rose audit per slice. **Julia at `~/.juliaup/bin/julia` (not on PATH).**
- **Outward posting (GitHub issue comments) is the user's call** — confirm first
  (the auto-mode classifier will block agent-posted issue comments unless the user
  explicitly authorizes). PR push/merge is fine.
- Local checks before push: `Pkg.test()` + `docs/make.jl`. **CI on a clean checkout
  is the authoritative gate** (Dropbox can desync the working tree).

## What remains (prioritized)

1. **Genetic GLLVM (#50)** — GATED (cross-team Q1/Q2 + #44/#37). When unblocked,
   start with the descriptors slice (reuses multivariate.jl FA-G + evolvability.jl).
2. **Cross-lane (highest leverage, not solo):** the R-lane external-comparator runs
   (#41/#49 multivariate; fitted-Mrode #46) + the metafounder bridge.
3. **Solo-unblocked engine slices:** RR permanent-environment term / curve-valued
   EBV-trajectory PEV (#54 later slices); a known-truth `K_g` recovery harness;
   a matrix-free-PCG large-pedigree **benchmark** (a PERFORMANCE claim — gated on a
   recorded measurement); wire PCG into the fit path.

## Smallest safe next action

If cross-team is unblocked: the genetic-GLLVM **descriptors** slice
(`genetic_gllvm_descriptors`). Otherwise a solo-unblocked engine slice above (RR
permanent-environment term is the cleanest next descriptive/supplied step).

## Verification snapshot

- `gh pr list --state merged` → #87/#88/#89 merged this session. `main` @ `a89ee7c`,
  CI + Documenter green; `Pkg.test()` green; `validation_status()` = 38 rows.
- #86 (v7 closeout) still open. #50 carries the genetic-GLLVM design note; #61 the
  joint critical path.
