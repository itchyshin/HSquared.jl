# Session handover — 2026-06-20 (v10) · START HERE

Inheritance note for a fresh session. Repository state is truth; this is the
at-a-glance pointer. Supersedes v9 (`2026-06-20-session-handover-v9.md`, which lives
only on the open PR #96 branch — close it as superseded). This session ran under a
`/goal` directive ("finish as many planned slices as possible in 4 hours").

## How to inherit the plan, mission control, and goal (do this first)

You are **Ada**, orchestrator of `HSquared.jl` (Julia quantitative-genetics engine,
computational twin of the R package `hsquared`). Run the `hsquared-rehydrate` skill,
then read in order:
1. **THIS note.**
2. **Goal/doctrine** → `AGENTS.md` (Definition of Done, honest-status rules, lane
   routing) + `CLAUDE.md`.
3. **Plan** → `ROADMAP.md` + `docs/design/11-completion-plan.md` +
   `docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md` (the genetic-GLLVM #50 slice plan).
4. **Honest status** → `docs/design/capability-status.md` +
   `docs/design/validation-debt-register.md`; `validation_status()` (**39 rows**).
5. **Accuracy posture** → `docs/dev-log/2026-06-20-cpu-engine-correctness-audit.md` (NEW).
6. **Cross-lane** → GitHub issues **#61** (joint critical path), **#93** (plotting
   contract — 8 open Qs awaiting R), **#53** (metafounders, A4), **#50** (genetic GLLVM, Q1/Q2).

## Current state (repo = truth)

- Branch **`main` @ `67d193a`**. Working tree clean; CI + Documenter green.
- `Pkg.test()` green; `validation_status()` = **39 rows**. One public-covered
  capability (v0.1 univariate Gaussian animal model); everything else
  `experimental`/`partial`. **Nothing promoted to covered this session.**
- **Stale open PRs to close (housekeeping):** **#96** (v9 handover, superseded by this
  note) and **#86** (v7 closeout, ancient). Outward PR actions are the user's call.

## DONE this session (5 PRs merged — #95, #97, #98, #99, #100)

- **#95** Plotting layer **set B** — `variance_components_plot_data(fit; level)` (the
  VC+h² forest, R `hs_gg_forest` shape). Completes the engine plot-data for all 4
  figure sets (A/B/C/D). Rose-audited (3 honest-status nits fixed in-PR).
- **#97** Genetic GLLVM (#50) **slice 1** — `genetic_gllvm_descriptors(Λ; uniqueness)`:
  rotation-invariant latent-structure descriptors from SUPPLIED loadings (`communality`,
  `genetic_pca`, …); pure composition of existing numerics; 24 RNG-free assertions.
- **#98** Genetic GLLVM (#50) **slice 2 (Gaussian part)** — `genetic_gllvm_gaussian_mme`:
  the Gaussian genetic GLLVM IS the multivariate animal model at `G0 = G_lat = ΛΛ'(+Ψ)`;
  builds `G_lat`, delegates to `multivariate_mme`; defining-identity + rotation + `t=1`
  → `henderson_mme` reductions. Correctness reduces to `multivariate_mme` (V4-MV).
- **#99** Genetic GLLVM (#50) — `genetic_gllvm_descriptors(result)` overload for an
  ESTIMATED factor-analytic/low-rank multivariate fit (`communality = 1 − Ψ/diag(G)`,
  reads identified `G`/`Ψ` only, never loadings); tested vs the real `fa`/`low` fits.
- **#100** `docs/dev-log/2026-06-20-cpu-engine-correctness-audit.md` — the accuracy-first
  deliverable: manual from-scratch re-derivation of `fit_ai_reml` (AI matrix + score)
  and `laplace_marginal_loglik` (both CORRECT), + evidence-class posture consolidation.

The genetic-GLLVM rows are folded into **`V6-GGLLVM-DESC`** (capability-status +
validation-debt + `validation_status()`); no inflated validation rows.

## Accuracy posture (the "make sure CPU is done properly" directive)

The CPU engine is **internally well-validated** — riskiest kernels (AI-REML, Laplace)
manually re-derived clean this session; most kernels carry independent in-repo oracles
or limiting-case reductions (see the audit note + the `V*` rows). **The remaining gap
to `covered` is EXTERNAL-comparator parity (ASReml/sommer/BLUPF90/JWAS/fitted-Mrode),
which is cross-lane (needs the R lane), not solo engine code.** GPU is correctly
**parked** (Apple Metal here, Compute Canada CUDA later) — no performance claim without
a recorded CPU benchmark. **A multi-agent fan-out audit failed 3× on API rate/session
limits**; next time use incremental manual subsystem reviews, or run the fan-out when
limits are clear (the script is at the workflow path in the session dir).

## What remains (prioritized)

1. **Highest-leverage, non-solo:** the **R-lane external comparator runs** (#41/#49
   multivariate; fitted-Mrode #46; genomic #3) — these promote `partial`→`covered`.
2. **Genetic GLLVM #50 — the genuine gap (§3 of the scope doc):** the **non-Gaussian
   K-factor latent marginal** (generalize `nongaussian.jl`'s single-factor Laplace/VA
   to `vec(g) ~ N(0, I_K ⊗ A)`, `η[i,t] = Σ_k Λ[t,k] g[i,k]`, multi-response penalized
   IRLS over `p+qK`) — **a substantial build; give it a dedicated session** (reductions:
   `K=1` → `laplace_marginal_loglik`, Gaussian → `multivariate`). Then **slice 3** REML
   over structured `G_lat`. R bridge gated on #50 Q1/Q2 + #44/#37.
3. **Held (do NOT build until unblocked):** plotting engine adaptations (gated on R's
   #93 answers — field rename `genetic_variance→value`, melt, `*_meta`, parity-test
   home); #53 combined-inverse `:metafounder` payload (gated on R confirming A4);
   genetic-GLLVM R bridge (gated on #50 Q1/Q2).
4. Other solo big builds: production sparse fitting + large-pedigree hardening (#6),
   calibrated genome-wide thresholds (#7), a matrix-free PCG operator (→ large-scale,
   edges into performance-claim territory needing benchmarks).

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** Sister repos READ-ONLY; GitHub issues = coordination.
- **Land via PR**; squash-merge CI-green slices (`gh api -X PUT
  repos/itchyshin/HSquared.jl/pulls/N/merge -f merge_method=squash`). TDD + full DoD +
  Rose audit per slice. **Julia at `~/.juliaup/bin/julia` (NOT on PATH).**
- **Outward posting (issue comments / closing others' PRs) is the user's call** —
  confirm first.
- Local `Pkg.test()` + `docs/make.jl` before push; **CI on a clean checkout is the
  authoritative gate** (Dropbox can desync / re-touch the working tree mid-edit).
- **Watch the API usage limit** — it reset mid-session (rolling window); the
  multi-agent fan-out is fragile against it (prefer bounded, incremental work).

## Smallest safe next action

Pick a bounded slice OR commit to the non-Gaussian K-factor latent marginal as a
dedicated build. Check #93 / #53 / #50 for R replies and adapt (flexible). Close the
stale PRs #96/#86 if the user authorizes.
