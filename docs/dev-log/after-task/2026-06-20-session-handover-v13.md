# Session handover — 2026-06-20 (v13) · START HERE

Inheritance note. Repository state is truth; this is the at-a-glance pointer.
Supersedes v12. This autonomous segment ran under ULTRACODE, continuing the
"finish as many planned slices as possible" goal — preface cleanup + a solo drawing
item, then two engine-accuracy slices, each adversarially verified before merge.

## How to inherit (do this first)

You are **Ada**, orchestrator of `HSquared.jl`. Run `hsquared-rehydrate`, then read:
this note → `AGENTS.md` + `CLAUDE.md` → `ROADMAP.md` + `docs/design/11-completion-plan.md`
→ `docs/design/capability-status.md` + `docs/design/validation-debt-register.md` +
`validation_status()` (**41 rows, 4 covered**) → the three after-task reports below →
issues **#61 / #93 / #38 / #50 / #42**.

## Current state (repo = truth)

- Branch **`main` @ `a2bbfd3`** (+1 commit for this note). Clean; CI + Documenter green.
- `Pkg.test()` green; `validation_status()` = **41 rows** (4 covered = the v0.1 univariate
  Gaussian animal model). Everything else `experimental`/`partial`. **Nothing promoted to
  covered this segment.** Zero stale open PRs.
- **Julia at `~/.juliaup/bin/julia` (NOT on PATH).**

## DONE this segment (3 PRs: #117, #118, #119 — each adversarially verified)

- **#117 `HSquaredMakieExt`** — the Julia **drawing** half of the plotting layer.
  A `Makie` weak-dep package extension (`/src` stays dependency-free; `hsquared_figure`
  is a method-less stub that throws `MethodError` until a backend loads). Draws sets B/C —
  the `variance_components` forest, the EBV caterpillar, the G-eigenvalue scree — with the
  #93 honest-status behaviors rendered ON the figure (raw whiskers never clamped, `[0,1]`
  annotated on the h² panel only, scree-NOT-biplot guard, non-PD-`G` %-suppression,
  validation-scale PEV caveat in the subtitle). **Makie is deliberately OUT of default CI**
  (cost discipline) — CI gates the stub contract (4 assertions); the full draw is
  LOCAL-verified with CairoMakie (all 3 kinds → `Makie.Figure`, guards fire, PNG rasterized).
  Rose subagent: CLEAN. Rows: `V-PLOT-DRAW` (debt) + a capability-status row; plotting
  design `13-plotting-layer.md` §8.
- **#118 Binomial per-record `n_trials`** — generalized the Binomial family from a common
  scalar to a per-record `n_trials[i]` (the general `cbind(successes, failures)` GLMM the R
  lane flagged on **#61**). Internal `BinomialVectorResponse` + a `_fam_record(f,i)` resolver
  threaded through all 10 Laplace+VA kernel sites (scalar families = identity, zero behavior
  change). Validated: constant-vector==scalar to ~1e-12 (Laplace AND VA), all-ones==Bernoulli,
  an INDEPENDENT per-record tensor Gauss–Hermite oracle gate, mixed-regime recovery
  (n∈1..30, q=345: 5/5, rel≤0.062). 5-agent Gauss/Noether/Curie+Rose Workflow: code clean,
  no overclaim; it caught a stale-NEGATIVE register claim (fixed).
- **#119 Binomial/Bernoulli profile-LRT σ²a interval** — extended `laplace_reml_interval`
  to all single-component families (`:poisson`/`:bernoulli`/`:binomial`) reusing `_profile_root`.
  A shared `_resolve_single_family` helper de-dups the family construction. The interval
  returns **`lower_clamped`/`upper_clamped`/`converged` flags** so a non-crossing (clamped)
  endpoint is self-describing (two-sidedness is `σ̂²a`-position-dependent, NOT a family
  property: scalar m=20 two-sided, the per-record fixture lower-clamps, binary Bernoulli
  doubly-clamped). `marginal = :variational` is rejected (the ELBO ≠ a χ²₁ LRT). A focused
  Fisher+Rose review CORRECTED an over-generalized "two-sided" claim and caught two stale
  "Poisson-only" doc claims (`validation_status.jl` V6-LAPLACE, capability V6-FIT) — all fixed.

## Cross-lane status (NOT posted — outward posting is the user's call)

- **#61 engine side is RESOLVED** — per-record `n_trials` is built (R's general
  `cbind(successes, failures)` bridge mapping is now mechanical; integer-valued doubles
  accepted). Draft answer ready.
- **#38** (the "250-animal AI-matrix" wording) is **already fixed on main** — `03-engine-contract.md`
  reads the R lane's exact suggested replacement; the issue can be CLOSED. Draft ready.
- **#93** plotting contract — the Julia side is now COMPLETE incl. the drawing extension;
  remaining is R wiring `autoplot.R` to the bridge payloads. Draft update ready.
- All three drafts are in the chat record; **the classifier blocks issue posting without
  explicit per-issue authorization** — give it if you want them posted.

## What remains (prioritized)

1. **Highest-leverage, non-solo:** R-lane **external comparators** (multivariate #41/#49,
   fitted-Mrode #46, genomic #3, genetic-GLLVM vs GLLVM.jl/gllvmTMB) → the only path to
   promote `partial`→`covered`.
2. **Solo, accuracy-focused:** HSquaredMakieExt follow-on figure kinds (genetic-correlation
   heatmap, Manhattan/QQ from set D, RR reaction-norm/eigenfunctions/surface from set A);
   the Gaussian two-component (σ²a,σ²e) interval (nuisance profiling); a probit/threshold
   comparator for the binary σ²a bias.
3. **Gated on R:** the metafounder R-bridge + single-step H^Γ (#61 Q1–Q4); the eigenbasis
   bridge for `:lowrank`/`:factor_analytic` (#42, after R ratifies the FA convention);
   genetic-GLLVM R-facing payload/grammar (#50 Q1/Q2).
4. **Solo big builds:** production sparse fitting + large-pedigree hardening (#6); a
   matrix-free PCG operator (→ large-scale — edges into performance-claim territory, needs
   benchmarks; the user parked GPU/speed: "accuracy first").

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** Sister repos READ-ONLY; GitHub issues = coordination.
- **Land via PR**; squash-merge CI-green slices. TDD + full DoD + Rose audit per slice.
- **Outward posting (issue comments / closing others' PRs) is the user's call** — confirm;
  the auto-mode classifier blocks issue posting without explicit per-issue authorization.
- Local `Pkg.test()` + `docs/make.jl` before push; **CI on a clean checkout is the gate**
  (Dropbox can desync the working tree mid-edit). Use `git add <files>` (not `-A`).
- **Honest status both ways:** no fitting/perf/GPU claim without the full chain — AND no
  stale "X is missing" once X exists (the Rose-principle sweep catches both).

## Smallest safe next action

A solo HSquaredMakieExt follow-on figure kind, the Gaussian two-component interval, or — if
the user authorizes — post the #38/#61/#93 drafts. Check #93/#61/#42/#50 for R replies first.
