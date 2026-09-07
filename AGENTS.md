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

- **As of 2026-09-07 (Path FULL 0.9 finish — R-lane Layer B honesty PRs #191/#192 MERGED;
  Julia lane owes FA/SS honesty + bridge fences + a merge-when-green pass on #313; owner
  STOPPED the Cursor continuous run).** `public_covered_count` **stays 7** on both twins;
  version **0.8.0** on both twins; **0.9.0 NOT authorized**; after 0.9 → **0.10.x**, not
  **1.0**. This is a **twin-repo** campaign — the R sibling `hsquared` carries the full
  narrative and the ordered critical-path chain; this repo's job is narrower: land the Julia
  FA/SS status-honesty draft (scratch commit `2b1ad22`, not yet a PR), the Julia
  bridge-production-fences draft (`d47aa3f`, not yet a PR), and merge-when-green **Julia #313**
  (Gate-6 Rose evidence mirror, OPEN/CLEAN/CI-green at handover time), then run fresh
  `Pkg.test()` / `docs/make.jl` / `preamble_cap.sh` and record them in `check-log.md` (tail
  currently ends 2026-08-04 — no entry yet for this arc). **G10 held** `V1-MATFREE-REML` this
  session (owner: "the evidence packet is not sufficient for an experimental→covered flip");
  S5's frozen pre-declaration (`33ab68f6`) stays frozen, not run. **STANDING DRIFT FOUND AND
  NOT SILENTLY FIXED:** this snapshot block had been stale on `main` since `e6bf8a17`
  (2026-07-12) — nearly two months — because all the intervening Julia-engine narrative
  (Szymek's arc, the matrix-free fitter, the 2026-08-04 G10/S5 saga, and the September #294-#313
  stack) happened on `main` via ordinary PRs that never touched this block; the "2026-08-04"
  narrative some agents may recall lives only on the abandoned branch
  `codex/2026-07-13-v07-performance-localization` (tip `853bcc12`), which was **never merged to
  `main`** and still sits uncommitted/unpushed-diverged in the Dropbox checkout as of this
  handover. Do not treat that branch's AGENTS.md content as authoritative for `main`. **Do
  not** authorize 0.9.0, bump `Project.toml`, tag, or flip any row from this lane — that chain
  is owner-gated and lives in the R twin's handover. Julia `#267` (pre-existing, CI FAILURE)
  and `#265` (chore) are off this campaign's critical path.
  START HERE: `docs/dev-log/handover/2026-09-07-codex-handover.md` (this repo's pointer doc;
  it sends you to `hsquared/docs/dev-log/handover/2026-09-07-codex-handover.md` — the sibling
  repo, same Dropbox parent — for the full Path FULL narrative and Landing State ledger).
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
