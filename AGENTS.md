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

- **As of 2026-07-19 (v0.7 genomic public-activation arc — D0F RE-SEALED at C_fix `5325e95`: PASS / COMPLETE, identical fits, new receipt identity).**
  The D0F stage was re-sealed to fold in the hsquared `recompute.R:278` fix (`r_recomputer_path`
  derived by name, not `= script`; two unconditional git-identity gates bind the sealed R head, so
  the fix forced a full 576-fit re-run). New receipt `reseal-d0f/stage_adjudication_receipt.tsv`:
  `v07-genomic-recovery-v3-adjudication-2`, **`verdict=PASS`, `stage_decision=COMPLETE`**, sha
  `0f5fbb54…` (supersedes retry8 `04cc0740…`); `validate-final` re-derived the **new** receipt
  byte-identical (RC=0). **Identical fits, new receipt identity** — NOT byte-identical to `04cc0740`:
  attempt max-diff `3.18e-12` bit-identical to retry8, tally 556 interior / 10 lower / 10 upper
  identical, 5 bound post-run reviews CLEAN. summary max-diff moved `7.11e-15 → 2.27e-13` — a benign
  1-ULP reshuffle on re-measured runtime/RSS medians (Gauss: no scientific quantity moved;
  `recompute.R:278` is identity-only), both ≪1e-10. Receipt identity fields advanced by design
  (`r_driver`/`r_recomputer_commit` `5325e95`, `r_recomputer_sha` `eb29c8f4`, `preseal` `b209ec0c`,
  `adjudication_key` `88d4cf2f`); driver bytes (`d1a7d930`) and Julia replay (`976814`) unchanged.
  **Spawned-Rose close-out CONFIRMED-WITH-CAVEATS** (PASS holds; summary figure + Gauss caveat
  folded in; 12-doc supersede ledger sound). Per the pre-registration this COMPLETE receipt **only
  opens D1/D2**: `public_covered_count` stays **5**, `ordinary_auto_genomic` route NOT activated,
  V2-GRM/V2-GINV stay partial. **D1 STATUS (2026-07-19): two latent D1-ONLY blockers found + fixed, both
  fail-closed pre-draw — ZERO seed drawn.** (1) `recompute.R:278` → the `0f5fbb54` re-seal above.
  (2) `marker_ratio` float-precision drift in Julia `_validate_manifest` (R serializes `10/3` at 14 digits in
  `cell_table.tsv` vs full Float64 in the manifest; the exact `==` drifted) → **fixed** (local `8f214eb3`,
  deployed `fa409fe6`; now tolerant `≤1e-12` like `_read_cell_table`; membership/order/seed stay exact).
  Running D1 needs a **3rd D0F re-seal at Julia `fa409fe6`** (the admission hard-binds deployed julia ==
  the D0F predecessor's `julia_replay_commit`; byte-identical fits, new receipt identity), then D1 admission
  (bind the NEW `reseal2-d0f`, NOT `reseal-d0f`) → PRE-gate → panel → conditional draw. `public_covered_count`
  stays **5**. START HERE:
  `docs/dev-log/handover/2026-07-19-claude-handover-d1-blocker2-reseal.md`.

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
