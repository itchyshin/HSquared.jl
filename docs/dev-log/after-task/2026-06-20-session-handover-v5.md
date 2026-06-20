# Session handover — 2026-06-20 (v5) · START HERE

Inheritance note for a fresh session. Repository state is truth; this is the
at-a-glance pointer. Supersedes v4 (`2026-06-20-session-handover-v4.md`).

## Rehydrate path

Run the `hsquared-rehydrate` skill, then read in order: **this note** → `AGENTS.md`
(Live Phase Snapshot + lane routing) → `docs/design/capability-status.md` +
`docs/design/validation-debt-register.md` → `docs/dev-log/coordination-board.md` →
the newest `docs/dev-log/check-log.d/*` and `after-task/*`. **The live cross-lane
thread is GitHub issue #61** — read all comments (the two most recent are this
session's Julia-lane coordination notes).

- **Dev docs:** https://itchyshin.github.io/HSquared.jl/dev/
- **Control centre widget** (`~/.claude/hsquared-control-centre`, `:8791`): refreshed
  this session; `status.json` reflects the ultracode pass (preserve `live_agents`).

## Goal (standing)

Finish the next-phase programme. The committed BT2/BT3 engine runway is DONE; what
remains is hardware-gated (Phase 7/8), cross-lane (R-twin external-comparator
EVIDENCE), or innovation backlog. **The honest bottom line: the engine surface is
broad and well-tested; most `partial` rows are blocked on EXTERNAL-comparator
evidence (R-lane / sommer / ASReml / JWAS) or hardware, not on more engine code.**

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** R twin (`../hsquared`) is READ-ONLY; GitHub issues are
  the coordination channel.
- **Land via PR**; merge CI-green slice PRs. TDD + full Definition of Done per slice.
  No fitting/genomics/GPU/GLLVM claim without the evidence chain. **Julia is at
  `~/.juliaup/bin/julia` (NOT on PATH).**
- Local checks before push: `Pkg.test()` + `docs/make.jl`. **CAVEAT:** the repo lives
  under Dropbox, which can transiently rewrite working-tree files mid-edit (you will
  see "file modified by user or linter" reminders and occasional `.git/index.lock`
  staleness). **CI on a clean checkout is the AUTHORITATIVE gate.** If a local push
  hits a divergent-branch/lock error, `git fetch` then `git reset --hard origin/main`
  is safe (all work lands via PR; main has no local-only commits).

## Current state (repo = truth)

- Branch **`main` @ `3793dc7`** (before this handover merges). Working tree clean;
  CI + Documenter green; **0 open PRs**.
- `Pkg.test()` green; `validation_status()` has **36 rows**.
- One public-covered capability: the v0.1 univariate Gaussian animal model.
  Everything else `experimental`/`partial` — nothing promoted to covered.

## DONE this session (ultracode pass, Ada — 3 PRs merged)

Each = full-DoD PR with adversarial review (actual subagents).
- **#77 — #54 slice 3, RR REML.** `fit_random_regression_reml(y, X, Phi, Z, Ainv)`
  estimates the reaction-norm coefficient covariance `K_g` (k×k) + homogeneous `σ²e`
  by dense log-Cholesky NelderMead on `V = W(A⊗K_g)Wᵀ + σ²e I` (`W = face-splitting`);
  EBVs/β via GLS BLUP at the estimate. Validated by an independent marginal oracle +
  beats-off-optimum + degree-0 (`k=1`) reduction to `fit_sparse_reml` (`K_g[1,1]=2σ²a`)
  + BLUP/β agreement with `random_regression_mme`. 4-lens review (Henderson correct /
  Gauss merge / Karpinski merge / Rose fix_then_merge — all fixes applied). `V3-RR-REML`
  added to `validation_status()`.
- **#78 — V4-MV-REML recovery evidence.** Enhanced `sim/phase4_multivariate_reml_recovery.jl`
  to report per-parameter bias±2·MCSE, EBV accuracy, Wilson CI. 12-seed run → **no
  detectable bias** (all 6 covariance params |bias|≤2·MCSE at m=12; EBV accuracy
  ≈0.90; 12/12 converged). The "6/10 failed" was **G sampling variance at q=80/n=240,
  not estimator bias**. Rose-audited: "unbiased" hedged to "no detectable bias at
  m=12"; recovery checkpoint at
  `docs/dev-log/recovery-checkpoints/2026-06-20-multivariate-reml-recovery-mcse.md`.
- **#79 — cold-start replication.** `--cold-start=true` flag; the optimizer reaches the
  SAME optimum unaided on all 12 seeds (max |Δrel_G| 2.7e-5) → the warm-start caveat
  is resolved. V4-MV-REML stays `partial` (external comparator is the covered-blocker).
- **Ultracode Workflow + coordination:** a workflow (3 review lenses + 4 plan/twin
  readers + synthesis) verified slice 3 and mapped the completion plan / capability
  gaps / R-lane needs; two coordination notes posted to **#61**.

## R-lane action items (live on #61)

1. **#43/#21:** guard the dense PEV/reliability `merge()` in `R/julia-bridge.R` on
   `!hasproperty(hsq_result, :prediction_error_variance)` so the engine's `:selinv`
   field passes through.
2. **#45/#23:** build the post-fit `gwas(fit, markers)` unpack against
   `marker_scan_result_payload`; keep wording at nominal Wald + Bonferroni/BH.
3. **#48:** keep `gwas()` significance wording uncalibrated until #7 calibration.
4. **#44/#18:** hold the non-Gaussian parser grammar until the twin method-vocabulary
   design note lands (Julia-owned).
5. **#2/#6:** fitted-Mrode confrontation against `test/fixtures/animal_model_fitted_target/`.
6. **THE handoff (#10/#49):** run sommer/ASReml/BLUPF90 against the existing
   `test/fixtures/phase4_multitrait_parity/` Julia target and record agreement
   tolerance + versions — the remaining covered-blocker for the flagship multi-trait
   capability. The engine half is done; do NOT expect a separate `multivariate_comparator/`
   fixture (use `phase4_multitrait_parity/`).
7. **FA convention (#42 ↔ R#7):** ratify before bridging any structured-fit field.

## What remains (next-session candidates, prioritized)

1. **Solo engine, genuinely new:** larger-pedigree `:selinv` PEV correctness
   (V1-SELINV-PEV gap — confirm selinv == dense diagonal on a 100+-animal pedigree).
2. **Eigenbasis bridge exposure for `:lowrank`/`:factor_analytic` (#42)** — Julia half
   is small, gated on R ratifying the FA convention (#42↔R#7).
3. **RR slice 4:** eigen-function (covariance-function) decomposition / permanent-
   environment term / R `rr()` model-spec (jointly scoped with R) — see
   `docs/dev-log/decisions/2026-06-20-random-regression-roadmap.md`.
4. **Cross-lane (highest leverage, not solo):** the R-lane external-comparator run
   (#10/#49) and the fitted-Mrode confrontation (#2/#6).
5. Innovation backlog #50–#53; scout cadence #56. Phase 7/8 hardware-gated.

## Smallest safe next actions

1. Larger-pedigree `:selinv` correctness evidence (solo, clean) — or
2. After R ratifies the FA convention: the eigenbasis structured-fit bridge — or
3. Record any further opt-in recovery/comparator evidence (turns a `partial` toward
   `covered`).

## Verification snapshot

- `gh pr list --state merged` → #77/#78/#79 merged this session; 0 open after this
  handover merges.
- CI + Documenter green on `main`. `Pkg.test()` green; `validation_status()` → 36 rows.
- #61 carries the live cross-lane thread (two Julia-lane notes posted this session).
