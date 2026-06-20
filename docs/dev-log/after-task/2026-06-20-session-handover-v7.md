# Session handover — 2026-06-20 (v7) · START HERE

Inheritance note for a fresh session. Repository state is truth; this is the
at-a-glance pointer. Supersedes v6 (`2026-06-20-session-handover-v6.md`).

## How to inherit the plan, mission control, and goal (do this first)

Run the `hsquared-rehydrate` skill, then read in order:
1. **THIS note.**
2. **The goal/doctrine** → `AGENTS.md` (Live Phase Snapshot + Definition of Done +
   honest-status rules + lane routing) and `CLAUDE.md`.
3. **The plan** → `ROADMAP.md` + `docs/design/11-completion-plan.md`.
4. **Mission control** → the widget at `~/.claude/hsquared-control-centre/status.json`
   (served on `:8791`; `status.json` is the live state — preserve `live_agents`).
5. **Honest status** → `docs/design/capability-status.md` +
   `docs/design/validation-debt-register.md`; and `validation_status()` in-code (38 rows).
6. **Cross-lane** → GitHub issue **#61** (read all comments — RR/MV/selinv notes +
   the metafounder Q1–Q4 bridge gate).
7. Newest `docs/dev-log/check-log.d/*` + `after-task/*`.

## Current state (repo = truth)

- Branch **`main` @ `06506e7`** (before this handover merges). Working tree clean;
  CI + Documenter green; **0 open PRs**.
- `Pkg.test()` green; `validation_status()` has **38 rows**.
- One public-covered capability: the v0.1 univariate Gaussian animal model. Everything
  else `experimental`/`partial` — nothing promoted to covered.

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** Sister repos (`../hsquared`, `../GLLVM.jl`,
  `../gllvmTMB`, …) are READ-ONLY; GitHub issues are the coordination channel.
- **Land via PR**; merge CI-green slice PRs. TDD + full DoD per slice. No
  fitting/genomics/GPU/GLLVM/performance claim without the evidence chain. **Julia at
  `~/.juliaup/bin/julia` (NOT on PATH).**
- **Reuse, don't reinvent:** adapt architecture/process patterns from sister projects;
  do NOT copy statistical code/claims without checking license/tests/fit (AGENTS.md rule).
- Local checks before push: `Pkg.test()` + `docs/make.jl`. **CAVEATS:** (1) Dropbox can
  transiently rewrite working-tree files mid-edit + leave a stale `.git/index.lock`
  (`rm -f .git/index.lock`, then `git fetch && git reset --hard origin/main` is safe —
  all work lands via PR). (2) A rapid push to a PR branch can fail to trigger Actions
  (0 check-runs) — push an empty no-op commit to re-trigger. **CI on a clean checkout is
  the AUTHORITATIVE gate.** (3) gh GraphQL (auto-merge) intermittently 401s — a REST
  `gh api -X PUT repos/OWNER/REPO/pulls/N/merge -f merge_method=squash` after CI-green
  is the reliable path; a poll-then-merge watcher loop works.

## DONE this session (ultracode pass, Ada — 9 PRs: #77–#85)

- **#77** RR REML (`fit_random_regression_reml`).
- **#78** V4-MV-REML recovery evidence — estimator **no detectable bias** + EBV≈0.90
  (the "6/10" was G sampling variance, not bias). Checkpoint in `recovery-checkpoints/`.
- **#79** cold-start replication — warm-start caveat closed.
- **#80** handover v5.
- **#81** `:selinv` PEV == dense on a 110-animal pedigree (V1-SELINV-PEV).
- **#82** **metafounders (#53)** — supplied-Γ `A^Γ` + combined/descriptive inverses +
  inbreeding (Legarra 2015). `Γ` supplied, not estimated. Scout note in
  `docs/dev-log/scout/2026-06-20-metafounder-Agamma-algorithm-pin.md`.
- **#83** **PCG MME solver** (`solve_animal_model_pcg`) — iterative == direct.
- **#84** handover v6.
- **#85** **matrix-free MME operator** — `solve_animal_model_pcg(...; matrix_free=true)`
  applies `C·v` without assembling `C`; validated `C·eᵢ == C[:,i]` exactly. Correctness
  only, NO performance claim (no benchmark).

New `validation_status()` rows this session: `V3-RR-REML`, `V1-METAFOUNDER`, `V1-PCG`
(35 → 38). Two ultracode **Workflows** drove design/review.

## IN FLIGHT at handover — genetic GLLVM (#50) scoping

A genetic-GLLVM **scout/design Workflow** was running at close (run id `w5o3jgjxo`,
script saved under the session's `workflows/scripts/genetic-gllvm-scout-*.js`). It maps
the **reuse-not-reinvent** boundary. If its synthesis wasn't persisted to
`docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md` before close, the new session
should **re-run that scout** (or read the workflow output) before building.

**What we already know (the user's binding directives):**
- **The GLLVM team already has working code — REUSE it, do NOT reinvent.**
  `GLLVM.jl` (engine: `src/em_fa.jl`, `bridge.jl`, `confint*.jl`, the latent-variable
  GLLVM core) and `gllvmTMB` (R; **`R/animal-keyword.R` already integrates an
  animal/genetic relationship into the latent layer** — this is the "already working"
  genetic GLLVM; mirror its design + identifiability/rotation discipline).
- **HSquared.jl already owns** the pieces the genetic side needs: Phase-6 non-Gaussian
  Laplace/VA marginal (`src/nongaussian.jl`), relationship inverses
  (`pedigree_inverse`/`metafounder_inverse`/genomic `G`), structured/FA G
  (`src/multivariate.jl`), evolvability, and the **FA rotation convention**
  (rotation-invariant functionals only — never raw loadings;
  `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`).
- **Genetic GLLVM = a GLLVM whose latent rows carry a genetic-relationship covariance**
  (`Σ_LV` over individuals = `A·σ²` / structured), plugging HSquared's relationship +
  non-Gaussian machinery into the GLLVM latent layer — NOT a from-scratch GLLVM.
- **First slice should be descriptors / supplied-covariance first** (mirroring how RR,
  multivariate, and metafounders started): a deterministic, reduction-validated piece,
  no fitting/covered claim, rotation-invariant only, Rose-gated. Coordinate the
  engine↔GLLVM-team boundary on the coordination channel before any cross-repo contract.
- Lenses that gate it: Kirkpatrick (latent genetic axes) + Fisher (identifiability) +
  Gauss (numerics) + Rose (claims).

## R-lane action items (live on #61)

1. **Metafounder bridge (#53):** answer **Q1–Q4** (Γ marker / UPG-vs-MF grammar / Γ
   shape + group round-trip / combined-vs-descriptive inverse row count). R already
   reserves `metafounder()`/`unknown_parent_group()`/`group()`. Bridge PR after ratify.
2. **THE multivariate handoff (#10/#49):** R runs sommer/ASReml/BLUPF90 against
   `test/fixtures/phase4_multitrait_parity/`; record tolerance + versions. Engine half done.
3. **#43/#21** bridge merge-guard; **#45/#23** post-fit scan unpack; **#48** keep `gwas()`
   wording uncalibrated; **#44/#18** hold non-Gaussian parser until the method note;
   **#2/#6** fitted-Mrode confrontation; **FA convention (#42↔R#7)** ratify.

## What remains (prioritized)

1. **Genetic GLLVM (#50)** — the next big SOLO build (reuse GLLVM.jl/gllvmTMB; see above).
   Start with the scout synthesis, then a descriptors/supplied-first slice.
2. **Cross-lane (highest leverage, not solo):** the R-lane external-comparator runs +
   the metafounder bridge (after Q1–Q4).
3. Matrix-free PCG → a recorded large-pedigree **benchmark** (a PERFORMANCE claim — gated);
   advanced preconditioners; wire PCG into the fit path.
4. RR slice 4 (eigen-function / PE term / R `rr()` spec); opt-in BLUPF90 metafounder
   comparator; CRN; APY genomic scaling; scout cadence #56. Phase 7/8 hardware-gated.

## Smallest safe next action

Re-run / read the genetic-GLLVM scout, persist
`docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md`, then implement the first
descriptors/supplied-covariance genetic-GLLVM slice (reusing GLLVM.jl + Phase-6,
rotation-invariant, Rose-gated) — or pick up any R-lane-unblocked item above.

## Verification snapshot

- `gh pr list --state merged` → #77–#85 merged this session; 0 open at handover.
- CI + Documenter green on `main` @ `06506e7`. `Pkg.test()` green; `validation_status()`
  → 38 rows. #61 carries the live cross-lane thread.
