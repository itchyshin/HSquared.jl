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

- **As of 2026-07-24 (H2 engine-PERFORMANCE thread live — collaborator report; REML fit is the wall; handed to next lane).**
  Triggered by **szymekdr** (Discord): `hsquared` slow + crashes at genomic G n≈1000. **MEASURED on Totoro:**
  the A-inverse is FAST (`pedigree_inverse` 800=3 ms, 100k=2.2 s — **not** the bug); the default
  `fit_sparse_reml` (derivative-free) scales ≈ **n^2.6** (Szymek: 10k=1708 s vs ASReml 12.9 s, 100k=2 s); and
  the supposed fast path **`fit_ai_reml` runs to its 100-iteration cap / `not_converged`** at every size and
  tolerance (reaches the right loglik) — the concrete meaning of Shinichi's *"something is not really
  working."* **CONFOUND:** that was measured on no-signal data (σ²a→0, AI-REML's documented hard boundary);
  the real-signal confirming run (`bench_signal.jl`) **DIED unresolved** and is the **decision hinge** — re-run
  it first. Two-workflow ultra-plan (adversarial, beat-the-plan): **do NOT build the TMB native engine yet** —
  cheaper Option-A ladder first (dense-`Ginv` crash guard + flip pedigree default to a *working* `fit_ai_reml`
  + warm bridge), gated on the measurement. Native engine would PIVOT founding decision D-2026-06-12 (owner
  decision pending). **D1 genomic-recovery stays PAUSED (D-68; owner leans GO) — a SEPARATE thread, do not
  conflate.** `public_covered_count=5`; nothing moved. START HERE:
  `docs/dev-log/handover/2026-07-24-claude-handover.md` → first action: re-run `~/hsq_work/bench_signal.jl` on
  Totoro (real h²=0.4 signal). Ultra-plan detail: `docs/dev-log/native-engine-arc/native-engine-plan-hardened.md`.

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
