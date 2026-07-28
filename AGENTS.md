Read first: /Users/z3437171/shinichi-brain/AGENTS.md

## LOAD-FIRST manifest
<!-- Generated from the brain dossier; refresh with `python3 ~/shinichi-brain/tools/route.py HSquared.jl`.
     Kept at the top for salience (both Claude via @import and Codex native); drift-checked by `route.py`. -->
- Compute is a default condition — before any heavy calibration/recovery/perf run ask *"Totoro or DRAC?"* (fast CPU ≤100 cores → Totoro; replicated multi-seed / GPU → DRAC arrays); scale out, never laptop-scale. Playbook: `~/shinichi-brain/projects/COMPUTE-PLAYBOOK.md`.
- Trust recovery-to-truth and run the sample-size ladder before changing an estimator verdict.
- Diff main before building; write symbolic alignment before adding an estimand or scale.
- Load `validation-harness` and the repo's own instructions below; preserve the R-public/Julia-engine boundary.
- A `partial` row must state what it does NOT cover; no covered flip without predeclared evidence.

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

- **As of 2026-07-28 (H2 F6 matrix-free fitter LANDED as experimental + OPT-IN; ASReml comparator AGREE; Rose applied).**
  **THREE engine fitters are now experimental; NOTHING is promoted; `public_covered_count` STAYS 5.**
  **(1) NEW — `fit_matrix_free_reml` (F6, this session):** matrix-free Monte-Carlo EM-REML for the single-effect
  animal model, discharging the F0-deferred high-fill lever. It was an ADAPTER + route over the existing v0.8-S2
  `K≥2` machinery (which runs unmodified as `K=1`) — no new numerics. Crossover (committed
  `sim/matrix_free_crossover.tsv`, Mac Studio, median-of-3): exact WINS at fill 50/77 (0.13×/0.37×), matrix-free
  wins 2.74× at fill 151 and **16.59× at fill 262**. **`:auto` NEVER selects it — OPT-IN ONLY** (owner decision:
  the route would have fired only at `n>20 000`, the one regime never measured). External comparator **ASReml-R
  4.2.0.482 AGREE 1.31e-7** vs exact, 0.33–0.51 SD vs matrix-free — **estimand only, no ASReml timing** (§4
  fence). Real spawned **Rose CLEAR-WITH-CHANGES, all applied** (incl. a push-blocker: a published docstring
  still described the removed route). **STILL OWED: recovery-to-truth at `n>20 000` (pre-declared gate), the
  AT-SCALE comparator, the R bridge, G10.** **(2) `fit_ai_reml` + (3) `fit_eigen_reml`:** STAGED for G10, owner
  chose KEEP STAGED; both owe the R bridge (see archive). **D1 genomic PAUSED (D-68/D-71); TMB deferred.**
  START HERE: `docs/dev-log/handover/2026-07-28-claude-handover.md` (carries the sign-off ledger).

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
