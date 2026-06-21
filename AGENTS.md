# HSquared.jl Agent Instructions

`HSquared.jl` is the Julia computational twin of the R package `hsquared`.
The R package owns the public user language; this Julia package owns the
engine reality.

## Live Phase Snapshot

> Refresh this block in every after-task report (GLLVM.jl pattern). Repo state
> is truth; this is the at-a-glance pointer.

- **As of 2026-06-20 (autonomous segment — ULTRACODE; 3 PRs, main at `a2bbfd3`/#119).**
  On top of the committed plotting-layer runway (`*_plot_data` preparers #91/#92/#94/#95/#116,
  CPU benchmark #115, threshold calibration #112, GLLVM consumability #113), this segment
  landed **3 full-DoD PRs**, each adversarially verified before merge:
  **(1) `HSquaredMakieExt`** (PR #117) — the Julia **drawing** half of the plotting layer:
  a `Makie` weak-dep package extension (`/src` stays dependency-free; stub `hsquared_figure`
  throws `MethodError` until a backend loads) that draws sets B/C (`variance_components` forest,
  EBV caterpillar, G-scree) with the #93 honest-status behaviors rendered ON the figure
  (raw whiskers no-clamp, `[0,1]` on the h² panel only, scree-not-biplot guard, non-PD-G
  %-suppression). Makie is deliberately OUT of CI (cost discipline) — CI gates the stub, the
  full draw is local-verified (CairoMakie, PNG). Rose: CLEAN.
  **(2) Binomial per-record `n_trials`** (PR #118) — generalized the Binomial family from a
  common scalar to a per-record `n_trials[i]` (the general `cbind(successes, failures)` GLMM
  the R lane flagged on **#61**), via `BinomialVectorResponse` + a `_fam_record` resolver
  threaded through all 10 kernel sites; constant-vector==scalar to ~1e-12, an independent
  per-record Gauss–Hermite oracle gate, mixed-regime recovery (n∈1..30, q=345: 5/5, rel≤0.062).
  5-agent Gauss/Noether/Curie+Rose Workflow: code clean, fixed a stale-negative register claim.
  **(3) Binomial/Bernoulli profile-LRT σ²a interval** (PR #119) — extended `laplace_reml_interval`
  to all single-component families with self-describing `lower_clamped`/`upper_clamped`/`converged`
  flags; `:variational` rejected (ELBO≠LRT). Fisher+Rose review corrected an over-generalized
  "two-sided" claim and caught two stale "Poisson-only" doc claims — all fixed before landing.
  `Pkg.test()` + Documenter green on each; all 3 CI-green on clean checkout (**CI on a clean
  checkout is the authoritative gate**); `validation_status()` has **41 rows** (4 covered);
  **nothing promoted to covered**. Cross-lane **#61 engine side is now resolved** (per-record
  `n_trials` built) — draft answers for #38/#61/#93 are prepared but **NOT posted** (outward
  posting is the user's call; the auto-mode classifier blocks issue comments without explicit
  per-issue authorization). **Next:** the metafounder R-bridge (gated on #61 Q1–Q4), the
  eigenbasis bridge for `:lowrank`/`:factor_analytic` (#42, after R ratifies the FA convention),
  HSquaredMakieExt follow-on figure kinds (genetic-correlation heatmap, Manhattan/QQ, RR
  reaction-norm/surface), the Gaussian two-component interval (nuisance profiling), or —
  highest-leverage but cross-lane — the R-lane external comparator runs.
  Read `docs/dev-log/after-task/2026-06-20-session-handover-v13.md` (START HERE).
- **Covered (public):** v0.1 univariate Gaussian animal model only. Everything
  else is `experimental`/`partial` — nothing was promoted to covered this session.
- **Active programme (next-phase plan):** BT1 clean base = **done**. BT2 engine
  bridge-readiness (#42 diagonal done; #43/#44/#45 **done**; #42 lowrank/fa eigenbasis
  exposure gated on R ratification of the FA convention) and BT3 Julia-native
  validation (#46 fitted target + #49 JWAS scaffold **done** as a serialized target +
  opt-in scaffold; #47 SEs/LRTs done; #48 threshold machinery **done**, calibration
  evidence opt-in) are **landed**. **#54 random regression is now slices 1+2+3
  complete** (descriptors → supplied-covariance MME → REML estimation); the
  multivariate REML recovery is now characterised (no detectable bias + accurate EBVs,
  robust to cold vs warm start — the "6/10" was G sampling variance, not bias), still
  `partial` pending an external comparator. **Innovation backlog: #53 metafounders
  (supplied-Γ construction) DONE; PCG MME solver (production-path primitive) DONE.**
  Remaining: external-comparator EVIDENCE + fitted-Mrode confrontation (R-lane + opt-in
  JWAS run), multivariate recovery calibration (#4, gate not re-declared); innovation
  backlog #50 genetic GLLVM + CRN + APY genomic scaling + a matrix-free PCG operator
  (the actual large-scale enabler — edges into performance-claim territory needing
  benchmarks); RR slice 4 (eigen-function / PE term / R `rr()` spec); the metafounder
  R-bridge + single-step H^Γ (gated on #61 Q1–Q4); scout cadence #56; Phase 7/8
  hardware-gated.

## Core Scope

- Sparse pedigree, genomic, and custom relationship precision matrices.
- REML/ML/AI-REML mixed-model fitting for quantitative-genetic models.
- EBVs/BLUPs, heritability, variance components, G matrices, and diagnostics.
- Later: factor-analytic G matrices, GLLVM-style high-dimensional responses,
  non-standard inheritance systems, and accelerator-aware computation.

Phase 0 is complete. Phase 1 has started with pedigree normalization, sparse
`Ainv` construction, and an experimental dense validation path. Production
model fitting is not implemented.

## Twin Boundary

- `hsquared` speaks to applied R users.
- `HSquared.jl` computes.
- R syntax must not promise Julia capabilities that are not implemented,
  tested, documented, and recorded in `docs/design/capability-status.md`.

## Standing Review Lenses

These are review perspectives, not always-running agents. Say explicitly when
actual subagents are running.

| Name | Role |
| --- | --- |
| Ada | Orchestrator, phase planner, final integrator |
| Shannon | Coordination manager, lane checks, handoffs |
| Boole | Formula grammar and user-facing syntax |
| Hopper | R-to-Julia bridge and model-spec parity |
| Emmy | Package architecture and fitted-object design |
| Gauss | Numerical estimation, REML, sparse linear algebra |
| Karpinski | Julia performance, dispatch, allocations, type stability |
| Noether | Equation/syntax/implementation consistency |
| Fisher | Inference, identifiability, intervals, comparators |
| Curie | Simulation, recovery tests, edge cases |
| Jason | Literature and package scout |
| Darwin | Ecology/evolution audience and biological framing |
| Pat | Applied user tester and error-message reader |
| Florence | Figures and visual diagnostics |
| Grace | CI, Documenter, release, reproducibility |
| Rose | Systems auditor and claim-vs-evidence gate |
| Henderson | Mixed-model equations, BLUPs, sparse Ainv |
| Mendel | Non-standard inheritance systems |
| Falconer | Quantitative-genetic interpretation |
| Kirkpatrick | G matrices and factor-analytic genetic covariance |
| Mrode | Textbook animal-model validation canon |

## Current Member Routing

- **Ada + Shannon**: keep the programme aligned across `HSquared.jl`,
  `hsquared`, `DRM.jl`, `GLLVM.jl`, `drmTMB`, and `gllvmTMB`.
- **Henderson + Mrode + Gauss**: own the Phase 1 pedigree/Ainv and later
  animal-model equation checks.
- **Karpinski + Grace**: own Julia package hygiene, CI, Documenter, dispatch,
  and sparse performance review.
- **Hopper + Boole + Emmy**: keep Julia engine utilities compatible with the
  future R formula and bridge contract.
- **Jason + Rose**: scout sister packages and comparator tools, then prevent
  unsupported public claims.
- **Pat + Darwin + Florence**: keep docs readable for applied quantitative
  geneticists and ecological/evolutionary users.

These names remain review lenses unless an actual subagent is spawned and named
separately.

### Lane routing (which lens reviews which change)

Adopted 2026-06-19 (DRM.jl lane-boundary pattern). Charters live in
`.claude/agents/*.md` and `.codex/agents/*.toml`.

| Change class | Required lens(es) |
| --- | --- |
| `src/` numerics, REML, sparse linear algebra | Gauss + Karpinski + Noether |
| Formula / bridge / result-payload contract | Hopper + Boole + Emmy |
| Validation evidence, fixtures, recovery, comparators | Curie + Fisher + Mrode |
| Non-standard inheritance, quant-gen interpretation | Mendel + Falconer |
| G matrices / factor-analytic covariance | Kirkpatrick |
| **Any public claim / pre-publish / repo-visibility** | **Rose (mandatory)** |
| CI / Documenter / release / reproducibility | Grace |
| Cross-repo / cross-lane coordination | Ada + Shannon |

Scripted Workflow macros (run only on explicit opt-in / ultracode): an
engine-quality pass (Gauss/Karpinski/Noether over `src/`), an R-bridge-parity pass
(Hopper over payload + fixtures), and a validation-gate pass (Curie/Fisher/Mrode +
Rose) before any `experimental→covered` move.

## Sister Project Boundaries

Use the local sister projects as references:

- `DRM.jl`: Julia twin operating model, DocumenterVitepress setup, quality
  gates, and R-bridge discipline.
- `GLLVM.jl`: Julia engine structure, status-page discipline, performance claim
  gates, and high-dimensional design patterns.
- `drmTMB`: R package process, formula grammar discipline, validation debt,
  after-task reporting, and fitted/planned/missing separation.
- `gllvmTMB`: long/wide documentation discipline, covariance grammar, and
  reader-first public docs.

Code reuse rule: adapt architecture and process patterns freely, but do not copy
statistical code or public claims from sister projects without checking license,
provenance, tests, and fit for `HSquared.jl`.

## Memory Rules

Private memory may suggest where to look. Repository state, tests, docs,
issues, PRs, and check logs decide what is true.

Maintain repo-visible memory in:

- `ROADMAP.md`
- `docs/design/`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/`
- `docs/dev-log/recovery-checkpoints/`
- `docs/dev-log/decisions/`
- `docs/dev-log/scout/`

## Development Rules

1. Keep status language honest: no model-fitting claims without code and
   validation.
2. Do not change the public R-Julia contract without updating both twins.
3. Do not add a fitted capability without tests, documentation, capability
   status, validation-debt rows, and a Rose audit.
4. Do not copy statistical claims or code from sibling projects; adapt
   process patterns and record provenance.
5. Keep changes narrow and reviewable.

## Standard Commands

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
git status --short --branch
gh run list --limit 3
```

## Definition Of Done

A slice is done only when the relevant items are present:

- implementation;
- tests;
- documentation;
- example or explicit not-public-yet note;
- check-log evidence;
- after-task report;
- capability-status row;
- validation-debt row;
- Rose claim-vs-evidence audit;
- clean local checks;
- clean CI if pushed.
