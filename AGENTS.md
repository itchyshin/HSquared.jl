# HSquared.jl Agent Instructions

`HSquared.jl` is the Julia computational twin of the R package `hsquared`.
The R package owns the public user language; this Julia package owns the
engine reality.

## Core Scope

- Sparse pedigree, genomic, and custom relationship precision matrices.
- REML/ML/AI-REML mixed-model fitting for quantitative-genetic models.
- EBVs/BLUPs, heritability, variance components, G matrices, and diagnostics.
- Later: factor-analytic G matrices, GLLVM-style high-dimensional responses,
  non-standard inheritance systems, and accelerator-aware computation.

Phase 0 is an honest scaffold. Model fitting is not implemented.

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

1. Keep Phase 0 honest: no model-fitting claims without code and validation.
2. Do not change the public R-Julia contract without updating both twins.
3. Do not add a fitted capability without tests, documentation, capability
   status, validation-debt rows, and a Rose audit.
4. Do not copy statistical claims or code from sibling projects; adapt
   process patterns and record provenance.
5. Keep changes narrow and reviewable.

## Standard Commands

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
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
