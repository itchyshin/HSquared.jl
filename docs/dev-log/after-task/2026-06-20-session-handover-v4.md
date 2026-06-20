# Session handover — 2026-06-20 (v4) · START HERE

Inheritance note for a fresh session. Repository state is truth; this is the
at-a-glance pointer. Supersedes the v3 handover (`2026-06-19-session-handover-v3.md`).

## Rehydrate path

Run the `hsquared-rehydrate` skill, then read in order: **this note** →
`docs/design/11-completion-plan.md` → `AGENTS.md` (Live Phase Snapshot + lane
routing) → `docs/design/capability-status.md` + `docs/design/validation-debt-register.md`
→ `docs/dev-log/coordination-board.md` → the newest `docs/dev-log/check-log.d/*` and
`after-task/*`. **The live cross-lane thread is GitHub issue #61** — read all
comments first (a consolidated overnight coordination note + a closeout note are
the most recent).

- **Dev docs:** https://itchyshin.github.io/HSquared.jl/dev/
- **Control centre widget** (`~/.claude/hsquared-control-centre`, `:8791`): refreshed
  this session; `status.json` reflects the overnight run (preserve `live_agents`).

## Goal (standing)

Finish the next-phase programme plan (`docs/design/11-completion-plan.md`): three
Big Things + process + scout cadence. **BT1 done. The committed BT2/BT3 engine
runway is now DONE** (this session). What remains is hardware-gated (Phase 7/8),
cross-lane (R-twin activation + external-comparator EVIDENCE), or innovation backlog.

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** R twin (`../hsquared`) is READ-ONLY; GitHub issues on
  both repos are the coordination channel.
- **Land via PR**; merge policy = auto-merge / merge CI-green slice PRs. TDD + full
  Definition of Done per slice. No fitting/genomics/GPU/GLLVM claim without the
  evidence chain. **Julia is at `~/.juliaup/bin/julia` (NOT on PATH).**
- Local checks before push: `Pkg.test()` + `docs/make.jl`. **CAVEAT (new):** the repo
  lives under **Dropbox**, which can transiently rewrite working-tree files
  (incl. committed fixture CSVs) mid-run — a local `Pkg.test()` can show a spurious
  failure. **CI on a clean checkout is the AUTHORITATIVE gate** (a clean
  `git archive HEAD` export also reproduces green). Every PR this session was CI-gated.

## Current state (repo = truth)

- Branch **`main` @ `22725ca`** (after this handover branch merges, later). Working
  tree clean; remotes `main` + `gh-pages`; CI + Documenter green.
- `Pkg.test()` green (clean checkout); `validation_status()` has **35 rows**.
- One public-covered capability: the v0.1 univariate Gaussian animal model.
  Everything else `experimental`/`partial` — nothing was promoted to covered.

## DONE this session (overnight autonomous run, Ada — 9 PRs merged)

Each = full-DoD PR with a 3-lens adversarial review (findings addressed):
- **#43 (PR #65)** — PEV/reliability into the standard `result_payload(::AnimalModelFit)`
  via `:selinv`. Closes the engine half of **hsquared#21**.
- **#44 (PR #66)** — `MarginalMethod` dispatch (`Laplace`/`Variational`, wired into
  `fit_laplace_reml`, accepts `:LA`/`:VA`) + exported `nongaussian_result_payload`
  (carries `n_trials`; deliberately no `heritability` — family-uniform). Value-preserving.
- **#55 (PR #67)** — evolvability / G-matrix geometry (Hansen & Houle 2008):
  `evolvability`/`conditional_evolvability`/`respondability`/`autonomy`/`genetic_pca`/
  `g_max`/`mean_evolvability`. Rotation-invariant (functions of G, not loadings).
- **#45 (PR #68)** — post-fit `mixed_model_marker_scan(fit, markers)` /
  `single_marker_scan(fit, markers)`.
- **#48 (PR #69 + fast-follow #70)** — genome-wide threshold machinery
  (`genome_wide_threshold_from_null`, `genome_wide_pvalue`; correlation/LD-aware
  max-statistic) + opt-in `sim/phase5_threshold_calibration.jl`. Fast-follow made the
  threshold↔add-one-p framing honest (asymptotic, not "consistency") + finite guards.
- **FA rotation-convention decision (PR #71)** — doc-only; see below.
- **#46/#49 (PR #72)** — Julia-native FITTED univariate target fixture
  (`test/fixtures/animal_model_fitted_target/`, the engine fits + serializes its own
  output) + opt-in `comparator/` JWAS.jl scaffold (separate env, never a package dep).
- **#54 random regression / reaction norms — slices 1+2 (PR #74, #75)** — beyond the
  committed runway: slice 1 = supplied-`K_g` covariance-function DESCRIPTORS
  (`legendre_basis`/`standardize_covariate`/`rr_genetic_variance`/`…_covariance_surface`/
  `…_correlation_surface`/`rr_heritability`); slice 2 = supplied-covariance RR MME
  (`random_regression_mme`/`legendre_design`, `W = face-splitting(Z, Φ)`, precision
  `Ainv ⊗ inv(K_g)`, pinned by an independent dense oracle + degree-0 reduction to
  `henderson_mme`). DESCRIPTIVE/SUPPLIED-covariance — `K_g` NOT estimated. Roadmap:
  `docs/dev-log/decisions/2026-06-20-random-regression-roadmap.md` (slice 3 = REML).
- **Cross-lane:** consolidated coordination note + closeout on **#61** with R-lane
  action items + fixture paths.
- **Verification:** integrated `main` confirmed green on a **clean `git archive HEAD`
  checkout outside Dropbox** (authoritative — Dropbox can transiently desync the
  working tree; CI on a clean checkout is the gate).

## Decisions locked (carry forward)

- **FA rotation/interpretation convention (decided, #71):** bridge & do inference
  ONLY on rotation-INVARIANT functionals of G (eigenstructure via `genetic_pca`/
  `g_max`, evolvability, `Ψ`, G/correlations/`h²`, eigenvalues). **Never bridge raw
  loadings Λ; no SEs on loadings or individual eigenvectors.** Precedent: Kirkpatrick
  & Meyer (2004) / WOMBAT / ASReml `xfa`. See
  `docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`.
- **#48 threshold:** deterministic machinery is committed/CI-tested; the permutation
  calibration is opt-in (`sim/`). NOT a production genome-wide-significance claim —
  the R `gwas()` significance wording STAYS HELD until a realistic-LD/design
  calibration + external comparator land.
- **#46/#49:** the fitted target is a SERIALIZED confrontation target, not external
  evidence; JWAS (MCMC) vs REML is "agreement, not parity". No comparator evidence
  recorded yet; nothing promoted to covered. JWAS is never a package dependency.
- **#45:** the Julia `AnimalModelFit` already carries `spec.Ainv`; the "Ainv = NULL"
  is the R-side payload slot (R-lane item).

## R-lane action items (posted on #61)

1. **hsquared#21:** drop the opportunistic `merge()` in `R/julia-bridge.R` so the
   base `result_payload`'s `:selinv` PEV/reliability passes through (it currently
   overwrites with the `:dense` default). #21 is unconditional only on the
   `AnimalModelFit`/REML route; the Henderson route still rides opportunistic enrichment.
2. **#44:** confirm the R-facing `method` token (`"laplace"`/`"variational"`) +
   family-acceptance shape before treating the non-Gaussian payload as frozen.
3. **#45:** marshal the relationship precision back in the R fit payload (the
   `Ainv = NULL` slot) so an R `gwas()`/post-fit scan can be relatedness-corrected.
4. **#48:** keep the `gwas()` significance wording uncalibrated until a realistic
   calibration lands.
5. **FA convention (#42 ↔ R #7):** ratify before bridging any structured-fit field;
   then widen `multivariate_result_payload` to ACCEPT `:lowrank`/`:factor_analytic`
   exposing only the eigenbasis + invariants.
6. **#46:** run the `nadiv`/`pedigreemm`/published confrontation against
   `test/fixtures/animal_model_fitted_target/` (REML target); record tolerance + versions.

## What remains (next-session candidates, prioritized)

1. **Eigenbasis bridge exposure for `:lowrank`/`:factor_analytic` (#42)** — once the R
   lane ratifies the FA convention: widen `multivariate_result_payload` to expose
   `genetic_pca`/`g_max`/`Ψ`/eigenvalues for structured fits + structured-fit SEs on
   invariants only. (solo engine half; R ratification first.)
2. **#54 random regression — slice 3 (REML).** Slices 1 (descriptors) + 2
   (supplied-covariance MME) landed this session. Slice 3 = `fit_random_regression_reml`
   estimating `K_g`/residual by dense log-Cholesky REML (the direct analogue of
   `fit_multivariate_reml`; reuse `_chol_params_to_cov`), gated by the degree-0
   reduction to `fit_sparse_reml`. Full design in the roadmap note.
3. **Run + record the opt-in evidence:** `comparator/` JWAS run (#49), the recovery
   harnesses (`sim/phase4*`, `sim/phase6_*`, `sim/phase5_threshold_calibration.jl`),
   and the multivariate recovery calibration (#4 — still NOT passed). These produce
   the EXTERNAL/recovery evidence that gates `experimental → covered` moves.
4. Innovation backlog #50–#53 (genetic GLLVM, PCG+APY+MC-REML scaling, CRN,
   metafounders); scout cadence #56.
5. Hardware-gated, NOT this lane: Phase 7 (CPU/GPU), Phase 8 (HPC; #58 perf ideas).

## Smallest safe next actions

1. **#54 random regression** (solo engine slice, clean TDD) — or
2. Run an opt-in recovery/comparator harness and RECORD the evidence (turns a
   `partial` row toward `covered`), or
3. After R ratifies the FA convention on #42: the eigenbasis structured-fit bridge.

## Verification snapshot

- `gh pr list --state merged` → #65–#72 merged this session; 0 expected open after
  the handover PR.
- CI + Documenter green on `main`. `Pkg.test()` (clean checkout) green;
  `validation_status()` → 35 rows.
- #61 carries the live cross-lane thread (overnight coordination + closeout posted).
