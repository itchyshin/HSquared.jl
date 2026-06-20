# Session handover — 2026-06-20 (v11) · START HERE

Inheritance note for a fresh session. Repository state is truth; this is the
at-a-glance pointer. Supersedes v10. This session ran under a `/goal` directive
("finish as many planned slices as possible in 4 hours") and a user push to
"**finish all of 1**" (the genetic-GLLVM arc) with ultracode verification.

## How to inherit (do this first)

You are **Ada**, orchestrator of `HSquared.jl`. Run the `hsquared-rehydrate` skill,
then read: this note → `AGENTS.md` + `CLAUDE.md` (DoD, honest-status, lane routing)
→ `ROADMAP.md` + `docs/design/11-completion-plan.md` +
`docs/dev-log/scout/2026-06-20-genetic-gllvm-scope.md` → `docs/design/capability-status.md`
+ `docs/design/validation-debt-register.md` + `validation_status()` (**41 rows**) →
`docs/dev-log/2026-06-20-cpu-engine-correctness-audit.md` → GitHub issues **#61 / #93
/ #53 / #50**.

## Current state (repo = truth)

- Branch **`main` @ `d8f5f4b`** (this note adds one more commit). Clean; CI + Documenter green.
- `Pkg.test()` green; `validation_status()` = **41 rows**. One public-covered capability
  (v0.1 univariate Gaussian animal model); everything else `experimental`/`partial`.
  **Nothing promoted to covered this session.** Zero stale open PRs (v7/v9 closeouts closed).

## DONE this session (8 PRs merged — #95, #97–#100, #101, #102, #103)

- **#95** Plotting **set B** (`variance_components_plot_data`) — completes engine
  plot-data for figure sets A/B/C/D.
- **The full GENETIC-GLLVM arc (#50)** — descriptors → Gaussian solve → non-Gaussian
  marginal → REML, all SUPPLIED-loadings / low-rank, internal/experimental:
  - **#97** `genetic_gllvm_descriptors(Λ; uniqueness)` — rotation-invariant descriptors.
  - **#98** `genetic_gllvm_gaussian_mme` — the Gaussian genetic GLLVM IS the multivariate
    model at `G0 = G_lat = ΛΛ'(+Ψ)`.
  - **#99** `genetic_gllvm_descriptors(result)` overload — same descriptors for an
    estimated FA/lowrank multivariate fit (`communality = 1 − Ψ/diag(G)`).
  - **#102** `gllvm_laplace_marginal_loglik` — **the genuinely new capability** (a `K>1`
    latent field under a non-Gaussian response; gap §3). **Ultracode-verified
    `confirmed_correct`** (3 lenses + Rose) + two MEDIUM test gaps closed in-PR.
  - **#103** `fit_gllvm_laplace_reml` — REML estimation of `G_lat` over the marginal
    (`K=1` Poisson → `fit_laplace_reml`; Gaussian self-consistency vs multivariate).
- **#100** CPU engine correctness audit note (AI-REML + Laplace re-derived clean).
- **#101** v10 handover.

## Accuracy posture (unchanged from v10)

CPU engine internally well-validated (riskiest kernels manually re-derived; independent
oracles/reductions throughout); the genetic-GLLVM marginal additionally passed an
**ultracode adversarial-verification Workflow**. **Remaining gap to `covered` =
EXTERNAL-comparator parity (cross-lane / R lane), not solo engine code.** GPU parked
(no benchmark). **A large multi-agent fan-out is fragile against the API session limit
(failed 3× earlier); keep ultracode workflows SMALL + batched** (the 3-lens verify
worked).

## What remains (prioritized)

1. **Highest-leverage, non-solo:** R-lane **external comparator runs** (#41/#49
   multivariate; fitted-Mrode #46; genomic #3) → promote `partial`→`covered`.
2. **Genetic-GLLVM follow-ons** (the arc core is done; these EXTEND it): a known-truth
   **recovery study** (structured non-Gaussian REML — opt-in sim, recovery NOT yet
   claimed); the **factor-analytic (`+Ψ`)** latent structure; a **fitted-object/EBV
   extractor + `nongaussian_result_payload` analogue**; per-trait families;
   unbalanced/missing records; export decisions; the **R `gllvm()`/`latent()` bridge**
   (gated on #50 Q1/Q2 + #44/#37 per #61).
3. **Held (do NOT build until unblocked):** plotting engine adaptations (gated on R's
   #93 answers); #53 combined-inverse `:metafounder` payload (gated on R confirming A4).
4. Other solo big builds: production sparse fitting + large-pedigree hardening (#6);
   calibrated genome-wide thresholds (#7); a matrix-free PCG operator (→ large-scale,
   needs benchmarks).

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** Sister repos READ-ONLY; GitHub issues = coordination.
- **Land via PR**; squash-merge CI-green slices. TDD + full DoD + Rose audit per slice.
  **Julia at `~/.juliaup/bin/julia` (NOT on PATH).**
- **Outward posting (issue comments / closing others' PRs) is the user's call** — confirm.
- Local `Pkg.test()` + `docs/make.jl` before push; **CI on a clean checkout is the
  authoritative gate** (Dropbox can desync / re-touch the working tree mid-edit).
- **Watch the API usage limit** (rolling window; it reset mid-session); prefer bounded
  incremental work and SMALL batched ultracode workflows.

## Smallest safe next action

A genetic-GLLVM follow-on (recovery study or the FA `+Ψ` structure) OR a non-solo R-lane
comparator. Check #93 / #53 / #50 for R replies and adapt (flexible).
