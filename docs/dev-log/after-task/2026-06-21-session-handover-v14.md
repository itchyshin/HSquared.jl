# Session handover — 2026-06-21 (v14) · START HERE

Inheritance note. **Repository state is truth; this is the at-a-glance pointer.**
Supersedes v13 (v13 predates PRs #121/#122 and said "3 PRs"; this segment landed 4
substantive + 2 housekeeping). You are inheriting a clean, fully-merged checkpoint.

## How to inherit (do this first)

You are **Ada**, orchestrator of the **Julia engine lane** `HSquared.jl` (the
computational twin of the R package `hsquared`; the R repo is a separate, READ-ONLY
sister session). Run the `hsquared-rehydrate` skill, then read in order:
this note → `AGENTS.md` + `CLAUDE.md` → `ROADMAP.md` +
`docs/design/11-completion-plan.md` → `docs/design/capability-status.md` +
`docs/design/validation-debt-register.md` + `validation_status()` (**41 rows, 4
covered**) → `docs/design/13-plotting-layer.md` (the plotting layer) → the four
after-task reports from this segment (below) → issues **#61 / #93 / #38 / #50 / #42**.

## Current state (repo = truth)

- Branch **`main` @ `e0a48cc`** (#122). Clean working tree, synced with origin. **Zero
  open PRs.** CI + Documenter green on a clean checkout.
- `Pkg.test()` green; `julia --project=docs docs/make.jl` green.
- `validation_status()` = **41 rows, 4 covered** (the 4 covered = the v0.1 univariate
  Gaussian animal-model foundation). Everything else is `experimental` / `partial`.
  **Nothing promoted to `covered` this segment.**
- **Julia is at `~/.juliaup/bin/julia` — NOT on PATH.** Always use the full path.

## DONE this segment (6 PRs: #117–#122; 4 substantive, each adversarially verified)

1. **#117 — `HSquaredMakieExt`** (the Julia drawing half of the plotting layer).
   A `Makie` **weak-dependency** package extension. `/src` stays dependency-free: it
   carries only an exported, **method-less stub** `hsquared_figure(data; kind, …)`
   (`src/plotting_ext.jl`) + the honest-status drawing contract; the drawing **methods**
   live in `ext/HSquaredMakieExt.jl`, which Julia loads only when a Makie backend is in
   scope (`using CairoMakie`/`GLMakie`). One dispatcher infers `kind` and draws the #93
   honest-status behaviors **ON** the figure. **Makie is deliberately OUT of default CI**
   (heavy GL/Cairo stack — cost discipline): CI gates the *stub contract*; the full draw
   is verified LOCALLY with CairoMakie. Rose subagent: CLEAN.
2. **#118 — Binomial per-record `n_trials`** (the general `cbind(successes, failures)`
   GLMM the R lane flagged on **#61**). Generalized the Binomial family from a common
   scalar to a per-record `n_trials[i]` via an internal `BinomialVectorResponse` + a
   `_fam_record(f,i)` resolver threaded through all 10 Laplace+VA kernel sites (scalar
   families = identity, zero behavior change). Validated: constant-vector==scalar to
   ~1e-12 (Laplace AND VA), all-ones==Bernoulli, an INDEPENDENT per-record tensor
   Gauss–Hermite oracle gate, mixed-regime recovery (n∈1..30, q=345: 5/5, rel≤0.062).
   5-agent Gauss/Noether/Curie+Rose **Workflow**: code clean; it caught a stale-NEGATIVE
   register claim (fixed).
3. **#119 — Binomial/Bernoulli profile-LRT σ²a interval** (closed the `V6` "no intervals"
   gap). Extended `laplace_reml_interval` to all single-component families reusing
   `_profile_root`. The interval returns **`lower_clamped`/`upper_clamped`/`converged`
   flags** so a non-crossing (clamped) endpoint is self-describing (two-sidedness is
   `σ̂²a`-position-dependent, NOT a family property); `marginal = :variational` is rejected
   (the ELBO ≠ a χ²₁ LRT). A focused **Fisher+Rose** review CORRECTED an over-generalized
   "two-sided" claim, added the clamp flags, and caught two stale "Poisson-only" doc
   claims (`validation_status.jl` V6-LAPLACE, capability V6-FIT) — all fixed pre-merge.
4. **#121 — HSquaredMakieExt genetic-correlation heatmap** (set-C `:genetic_correlation`
   kind). Draws the rotation-invariant `D⁻¹GD⁻¹` heatmap (diverging RdBu, fixed
   `colorrange=(-1,1)`, low-/NaN-h² traits flagged in the subtitle). **Florence** review
   caught a silent NaN-h² flag gap (fixed). Drawing-only, local-verified.
5. **#120 / #122** — the v13 handover + a snapshot-accuracy touch-up (housekeeping).

**The headline:** every multi-agent review this segment found a *genuine* defect — a
wrong claim, a hazard, an uncalibrated path, stale docs, a NaN gap — all fixed
pre-merge, none rubber-stamped. Lean on adversarial verification; it earns its keep.

## Honest status — what is real

- **Covered (public):** v0.1 univariate Gaussian animal model only.
- The **non-Gaussian engine** (Laplace + VA marginals; Poisson/Bernoulli/Binomial incl.
  per-record `n_trials`; `fit_laplace_reml` REML; the profile-LRT σ²a interval) is a
  strong, multi-angle-validated **experimental** surface — dense/validation-scale, NO
  external comparator, NO R model-spec, not the public default. Binary Bernoulli σ²a is
  downward-biased (an information effect, reported-not-gated).
- The **genetic-GLLVM (#50)** arc is complete + recovery-validated for the
  supplied-loadings / low-rank+FA / Poisson case — `experimental`, INTERNAL.
- The **plotting layer**: engine `*_plot_data` preparers (sets A/B/C/D) + the
  `HSquaredMakieExt` drawing extension (forest, EBV caterpillar, G-scree,
  genetic-correlation heatmap) are landed; `experimental`, the draw is local-verified
  (Makie out of CI). Manhattan/QQ (set D) + RR set-A figure kinds are not yet drawn.
- **No fitting / performance / GPU claim.** GPU + speed are PARKED per the user's
  standing directive: *"accuracy first — no need to hurry."* CPU correctness is solid; a
  CPU benchmark baseline exists (#115, measurement only, no perf claim).

## Cross-lane state — drafts ready, NOT posted (the user's call)

Outward posting (issue comments / closing others' PRs) is **the user's decision**, and
the auto-mode classifier **blocks issue posting without explicit, per-issue
authorization**. Three draft answers are prepared (full text is in the v13/v14 chat
record); ask the user before posting:

- **#38** (R-filed: reword the "250-animal AI-matrix" claim) — **already fixed on `main`**
  (`03-engine-contract.md` reads R's exact suggested replacement); the issue can be CLOSED.
- **#61** (joint critical path; the Binomial-payload question) — **engine side RESOLVED**:
  per-record `n_trials` is built (#118), so R's `cbind`/weights → `n_trials` vector mapping
  is now mechanical (integer-valued doubles accepted).
- **#93** (plotting plot-data contract) — the **Julia side is COMPLETE** incl. the drawing
  extension; remaining is R wiring `autoplot.R` to consume the bridge payloads.

## What remains (prioritized)

1. **Highest-leverage, NON-solo (the only path to `covered`):** R-lane **external
   comparators** — multivariate (#41/#49), fitted-Mrode (#46), genomic (#3),
   genetic-GLLVM vs GLLVM.jl/gllvmTMB. These need the R lane / external tools; coordinate.
2. **Solo, accuracy-focused (no gate):** more `HSquaredMakieExt` figure kinds (GWAS
   Manhattan + QQ — `marker_manhattan_data`/`marker_qq_data` already exist; RR
   reaction-norm/eigenfunctions/surface — set-A preparers exist); the **Gaussian
   two-component (σ²a,σ²e) interval** (nuisance profiling — the remaining interval gap); a
   probit/threshold comparator for the binary σ²a bias.
3. **Gated on R replies:** the metafounder R-bridge + single-step H^Γ (#61 Q1–Q4); the
   eigenbasis bridge for `:lowrank`/`:factor_analytic` (#42, after R ratifies the FA
   convention); genetic-GLLVM R-facing payload/grammar (#50 Q1/Q2).
4. **Solo big builds:** production sparse fitting + large-pedigree hardening (#6); a
   matrix-free PCG operator (→ large-scale — edges into performance-claim territory,
   needs benchmarks; respect "accuracy first").

## Hard constraints (unchanged — do not violate)

- **Edit ONLY `HSquared.jl`.** Sister repos (the R `hsquared`, DRM.jl, GLLVM.jl, drmTMB,
  gllvmTMB) are READ-ONLY references; GitHub issues are the coordination channel.
- **Land via PR**; squash-merge CI-green slices. **Full DoD per slice:** implementation +
  TDD tests + docs + capability-status row + validation-debt row + check-log.d entry +
  after-task report + Rose claim-vs-evidence audit + clean local checks + clean CI.
- **Outward posting is the user's call** — confirm; the classifier blocks issue posting
  without explicit per-issue authorization.
- **Local checks before push:** `~/.juliaup/bin/julia --project=. -e 'using Pkg;
  Pkg.test()'` and `~/.juliaup/bin/julia --project=docs docs/make.jl`. **CI on a clean
  checkout is the authoritative gate** (Dropbox can transiently desync the working tree /
  re-touch files mid-edit). Use `git add <specific files>` (NOT `-A`).
- **Honest status BOTH ways:** no fitting/perf/GPU claim without the full evidence chain —
  AND no stale "X is missing" once X exists. Run the Rose-principle sweep (assume ten more
  of the same) on every claim edit; it caught real stale-negative claims twice this segment.
- **Adversarially verify** non-trivial slices (a Workflow or named-lens subagents) before
  landing — the reviews keep finding real defects.

## Smallest safe next action

A solo `HSquaredMakieExt` follow-on figure kind (GWAS Manhattan/QQ is the most bounded —
the preparers already exist), or the Gaussian two-component interval. First check
#93/#61/#42/#50 for R-lane replies, and ask the user whether to post the #38/#61/#93 drafts.
