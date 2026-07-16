Read first: /Users/z3437171/shinichi-brain/AGENTS.md

# HSquared.jl Agent Instructions

`HSquared.jl` is the Julia computational twin of the R package `hsquared`.
The R package owns the public user language; this Julia package owns the
engine reality.

## Live Phase Snapshot

> **ONE entry. Replace it; never prepend.** Before adding a new entry, move the current one —
> **verbatim** — to `docs/dev-log/phase-snapshot-archive.md`. Repo state is truth; this block is a
> pointer, not a log. It reached **31 entries / 66 KB** before this line existed, because the old
> wording said "refresh" and every agent read that as "prepend".
>
> Authoritative elsewhere, and always more current than this: phase state → `ROADMAP.md` · what is
> actually fitted → `docs/design/capability-status.md` · history → `docs/dev-log/phase-snapshot-archive.md`.

- **As of 2026-07-16 (v0.7 genomic public-activation arc — RETRY-7 ARCHITECTURE + SEED CONTRACT COMPLETE; NO RNG).**
  Research-informed route-safe R admission, weighted D0F/D1 route-lineage
  conservation, adjudication schema v2, exact idempotent receipt recognition,
  and Julia replay route typing are implemented. A full-cardinality synthetic
  D0F-to-D1 lifecycle and mutation campaign passed, and Hopper/Noether,
  Gauss/Karpinski, and Grace/Rose architecture reviews are CLEAN. Disjoint
  Retry-7 phenotype/bootstrap bases `2042000000` / `2043000000` are reserved
  but unspent. Exact-head `R CMD check`, CI, clean Totoro deployment rehearsal,
  preseal, chronology audit, official compute, and adjudication remain pending.
  Default R routing remains held and `public_covered_count` remains **5**; only
  the supplied-`Ginv` estimator is covered. Platform ownership is sequential:
  one fresh Terra/high Codex task continues implementation; use Sol only for
  explicit seed-contract, adjudication, and final adversarial-gate jobs. START
  HERE: `docs/dev-log/handover/2026-07-16-codex-handover.md`.

## Core Scope

- Sparse pedigree, genomic, and custom relationship precision matrices.
- REML/ML/AI-REML mixed-model fitting for quantitative-genetic models.
- EBVs/BLUPs, heritability, variance components, G matrices, and diagnostics.
- Later: factor-analytic G matrices, GLLVM-style high-dimensional responses,
  non-standard inheritance systems, and accelerator-aware computation.

Phase status is **not** recorded here; it drifts. `ROADMAP.md` is authoritative for phase
state, and `docs/design/capability-status.md` for what is actually fitted versus planned.
Make no capability claim that is not a row in that file.

## Twin Boundary

- `hsquared` speaks to applied R users.
- `HSquared.jl` computes.
- R syntax must not promise Julia capabilities that are not implemented,
  tested, documented, and recorded in `docs/design/capability-status.md`.

## Standing Review Lenses

These are review perspectives, not always-running agents. Say explicitly when
actual subagents are running.

The 21 lenses and their full charters live in `.claude/agents/*.md` (Claude) and
`.codex/agents/*.toml` (Codex) — one file per lens, loaded on demand when you spawn one.
The routing table below is the contract; the roster is only an index of that directory.

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
bash tools/preamble_cap.sh          # this file is @imported into every session -- keep it small
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
- clean CI if pushed;
- `bash tools/preamble_cap.sh` green (this file is re-read every session; it is capped).
