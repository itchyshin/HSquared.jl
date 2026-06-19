# HSquared.jl Agent Instructions

`HSquared.jl` is the Julia computational twin of the R package `hsquared`.
The R package owns the public user language; this Julia package owns the
engine reality.

## Live Phase Snapshot

> Refresh this block in every after-task report (GLLVM.jl pattern). Repo state
> is truth; this is the at-a-glance pointer.

- **As of 2026-06-19 (handover v2).** `main` @ `2a3eed5` carries the full
  Phase-4B/5/6 engine work (PR #36) plus multivariate covariance SEs/LRTs (#47, PR
  #59) and the refreshed Documenter API page. Suite **1822**, CI green. Remote
  heads: `main` + `gh-pages`; **0 open PRs**. Read
  `docs/dev-log/after-task/2026-06-19-session-handover-v2.md` first. NOTE: an
  ultracode BT2/BT3 workflow + a JWAS comparator agent were killed by a process
  exit (committed nothing) — relaunch.
- **Covered (public):** v0.1 univariate Gaussian animal model only. Everything
  else is `experimental`/`partial`.
- **Active programme (next-phase plan):** BT1 clean base = **done**. BT2 = engine
  bridge-readiness for #42 (structured covariance), #43 (PEV/reliability), #44
  (non-Gaussian + `MarginalMethod` dispatch), #45 (post-fit marker scans),
  coordinated live with the R twin. BT3 = Julia-native validation #46 (fitted
  Mrode), #47 (covariance SEs/LRTs), #48 (calibrated thresholds), #49 (comparator
  fixtures). Innovation backlog #50–#55; scout cadence #56.

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
