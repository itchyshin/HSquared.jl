# Session handover — 2026-06-20 (v12) · START HERE

Inheritance note. Repository state is truth; this is the at-a-glance pointer.
Supersedes v11. This session ran under a `/goal` ("finish as many planned slices as
possible in 4 hours") + a user push to **finish the whole genetic-GLLVM (#50)**.

## How to inherit (do this first)

You are **Ada**, orchestrator of `HSquared.jl`. Run `hsquared-rehydrate`, then read:
this note → `AGENTS.md` + `CLAUDE.md` → `ROADMAP.md` + `docs/design/11-completion-plan.md`
+ `docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md` → `docs/design/capability-status.md`
+ `docs/design/validation-debt-register.md` + `validation_status()` (**41 rows**) →
`docs/dev-log/2026-06-20-cpu-engine-correctness-audit.md` → issues **#61 / #93 / #53 / #50**.

## Current state (repo = truth)

- Branch **`main` @ `35ffd32`** (+1 commit for this note). Clean; CI + Documenter green.
- `Pkg.test()` green; `validation_status()` = **41 rows**. One public-covered capability
  (v0.1 univariate Gaussian animal model); everything else `experimental`/`partial`.
  **Nothing promoted to covered this session.** Zero stale open PRs.

## DONE this session (~12 PRs: #95, #97–#107)

- **#95** Plotting **set B** — completes engine plot-data A/B/C/D.
- **The COMPLETE genetic-GLLVM (#50)** — descriptors → Gaussian solve → non-Gaussian
  marginal → REML (low-rank + FA) → recovery, all SUPPLIED-loadings, internal/experimental:
  - **#97** `genetic_gllvm_descriptors(Λ)` (rotation-invariant descriptors).
  - **#98** `genetic_gllvm_gaussian_mme` (Gaussian GLLVM = multivariate model at `G0=G_lat`).
  - **#99** `genetic_gllvm_descriptors(result)` overload (estimated FA/lowrank fits).
  - **#102** `gllvm_laplace_marginal_loglik` — **the genuinely new** `K>1` non-Gaussian
    latent marginal; **ultracode-verified `confirmed_correct`** + 2 test gaps closed.
  - **#103** `fit_gllvm_laplace_reml` — REML over `G_lat` (low-rank).
  - **#105** `fit_gllvm_laplace_reml(...; structure = :factor_analytic)` — estimates `Ψ`.
  - **#106 / #107** `sim/phase6_gllvm_recovery.jl` — known-truth recovery, **POSITIVE**:
    rank-1 Poisson (`q=240`) mean `rel(G_lat)=0.091`, 5/5; rank-2 non-degenerate-ρ
    (`q=120`) mean `rel=0.205` + genetic correlations `mean|Δρ|=0.089`, 5/5.
- **#100** CPU correctness-audit note; **#101/#104** v10/v11 handovers.

All genetic-GLLVM rows are `V6-GGLLVM-DESC` / `-MARGINAL` / `-REML`.

## Genetic-GLLVM status — honest

The arc is **complete and recovery-validated for the supplied-loadings / low-rank+FA /
Poisson case** — a strong, multi-angle-validated experimental capability. Still
INTERNAL (not exported); `GLLVM-style animal models` stays `planned`; **nothing
covered** (covered needs an external comparator + the R bridge).

## What remains (prioritized)

1. **Highest-leverage, non-solo:** R-lane **external comparators** (#41/#49 multivariate;
   fitted-Mrode #46; genomic #3) → promote `partial`→`covered`. (Also the genetic-GLLVM
   external comparator: GLLVM.jl / gllvmTMB.)
2. **Genetic-GLLVM follow-ons (marginal):** FA(+Ψ) and Bernoulli/Binomial recovery
   calibration; larger-`q` rank-2; a **fitted-object/EBV extractor** surface; per-trait
   families; unbalanced/missing records. **GATED:** any R-facing payload/grammar
   (`gllvm_result_payload`, `gllvm()`/`latent()` vocab) waits on #50 Q1/Q2 + #44/#37 (#61).
3. **Held:** plotting engine adaptations (R's #93 answers); #53 combined-inverse
   `:metafounder` payload (R's A4).
4. **Other solo big builds:** production sparse fitting + large-pedigree hardening (#6);
   calibrated genome-wide thresholds (#7); a matrix-free PCG operator (→ large-scale,
   needs benchmarks).

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** Sister repos READ-ONLY; GitHub issues = coordination.
- **Land via PR**; squash-merge CI-green slices. TDD + full DoD + Rose audit per slice.
  **Julia at `~/.juliaup/bin/julia` (NOT on PATH).**
- **Outward posting (issue comments / closing others' PRs) is the user's call** — confirm.
- Local `Pkg.test()` + `docs/make.jl` before push; **CI on a clean checkout is the gate**
  (Dropbox can desync the working tree mid-edit).
- **Watch the API usage limit** (rolling window; it reset mid-session); prefer bounded
  incremental work and SMALL batched ultracode workflows (large fan-outs failed 3×).

## Smallest safe next action

A genetic-GLLVM follow-on (FA/Bernoulli recovery, or the fitted-object extractor), a
non-solo R-lane comparator, or a solo big build (#6/#7). Check #93/#53/#50 for R replies.
