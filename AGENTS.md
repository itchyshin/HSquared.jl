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

- **As of 2026-07-08 (plotting-layer AlgebraOfGraphics migration — RECOVERED + FIXED + VERIFIED
  LIVE + ROSE-AUDITED, on a branch awaiting merge; Claude solo (Opus), R-lane session on maintainer
  instruction; rows **55** / covered **13** / `public_covered_count` **5** UNCHANGED).** Five plotting files had sat
  uncommitted for two days (mtime 07-06) as an unfinished mid-conversion of `HSquaredMakieExt` to
  AlgebraOfGraphics (`:variance_components` + `:breeding_values`); AoG had never existed on any ref.
  **Five defect classes fixed** (three found by reading, two — (4) and (5) — only by rendering the PNG
  and looking at it)**:** (1) every marker drawn TWICE — the manual `scatter!` was restoring
  z-order after the whiskers overpainted, so AoG now owns the single marker layer and whiskers go behind
  via `translate!`; (2) `_axes_by_panel` pattern-matched `Label`s out of `fig.content` and index-zipped
  them to axes (two undocumented internals) — replaced with AoG's supported `FigureGrid.grid` accessor +
  a shape guard; (3) the full term list was forced onto EVERY facet's yticks — now per-facet; (4) *found
  only by rendering the PNG and looking at it* — title/subtitle drawn once PER FACET, `ylabel` leaking
  the mapped variable `"rank"`, x/y scales LINKED across facets (h² on `[0,1]` crushed against a `0–40`
  variance scale), and the `[0,1] boundary` annotation clipped at the data limit; (5) *found only by
  rendering the PNG, and it had PASSED an object assertion* — the `[0,1] boundary` flag was anchored at
  `hi` for EVERY crossing, so a `lo <= 0` interval flagged the one end it respects, with the headroom
  bump on the wrong side; the flag is now anchored at the crossed end (both ends when both cross) and the
  driver asserts anchor position, row, and alignment rather than merely counting the annotation.
  **VERIFIED:** compat
  pin resolves (`AlgebraOfGraphics 0.13.0` + `Makie 0.24.13` + `CairoMakie 0.15.13`, Julia 1.10.0), the
  extension precompiles, **9/9 kinds draw a `Makie.Figure`** (explicit + inferred); on the *forest payload
  specifically*: `Scatter=1` per axis, `NaN` whisker draws nothing, whisker/zero-line `z=-1.0`, boundary
  `Text` on the h² axis ONLY (control payload draws none); both AoG figures rasterize, `Pkg.test()` GREEN
  dependency-free. **One machine, one version set** (Julia 1.10.0, macOS/arm64) — not a cross-version or
  cross-platform claim. The facet-order assumption HOLDS on AoG 0.13.0. Re-runnable, **mutation-tested**
  driver: `docs/dev-log/scripts/2026-07-08-plotting-aog-livedraw.jl` (it rasterizes BEFORE asserting, so
  the PNGs exist on a failing run). The driver also runs as the **opt-in `plotting` CI job** — off by
  default; dispatch CI with `run_plotting = true` — which uploads the figures as an artifact.
  **Standing trap:** the default-CI stub test
  asserts `isempty(methods(hsquared_figure))` with Makie/AoG out of that environment, so it passes
  *precisely when the extension fails to load* — a green `Pkg.test()` is NEVER evidence about the
  drawing layer. Also:
  **`julia` is not on `PATH` in a Claude Code shell** (`~/.juliaup/bin`) — do not conclude the toolchain
  is absent. Branch `feat/2026-07-08-plotting-aog`, pushed, **PR #264 open, NOT merged**; `main`
  untouched. **Two** real `rose-systems-auditor` audits, both PROMOTE-WITH-CHANGES, all changes applied:
  the first on the branch (false 2026-06-22 AoG evidence pointer in `test/runtests.jl`, unreproducible
  evidence, under-covering SUPERSEDED banner); the second on the defect-5 delta (a dangling "(see below)"
  evidence pointer, a defect count left inconsistent across four surfaces, three absolutes falsified by
  the new opt-in CI job, and an `if: always()` artifact upload defeated by rasterizing *after* asserting).
  Coordination board NOT updated (Julia-lane slice run from an R-lane session) — do that on merge.
  **SIX GATES THAT COULD NOT FAIL** were found closing this slice, each by the reflex the previous
  one taught: (1) the CI stub test above; (2) `shinichi-brain/tools/check-after-task.R` defined a
  main and never called it, so the documented CLI exited 0 for ANY input — including nonexistent
  files — for its entire life, while `protocols/after-task.md` cited it as *the* DoD gate; (3) the
  sibling sweep found `rose-pattern-scan.R` with the identical defect (both R honesty gates dead;
  every shell/Python tool fine); (4) `handoff_gate.sh` audited only the checked-out branch;
  (5) **restoring (3)'s missing `main()` did NOT restore the gate** — a later negative control showed
  `rose-pattern-scan.R <nonexistent-root>` still exiting 0, because `list.files()` globs a missing
  directory into zero files with no error and no warning, so a typo'd path "passed"; (6) this repo's
  own live-draw driver asserted `nplots(ax, Text) == 1` — it *counted* the `[0,1]` flag and never
  asked where it sat, which is exactly how defect (5) of the plotting layer survived a Rose audit.
  (2) fixed + pushed (`shinichi-brain` @ `3468312`, guarded by `sys.nframe() == 0L` — NOT
  `!interactive()`, which is FALSE under `Rscript -e 'source(...)'` too and would break the
  workaround); (4) fixed independently by a parallel session (`1f1df6f`); (3)+(5) genuinely fixed at
  `shinichi-brain` @ `d85299f` (root guard) and `@bbc1c34` (locale-independent matching), lesson banked
  at `@58a2936`; (6) fixed here — the driver now asserts anchor position, row, and alignment.
  **Before trusting a green, make it go red on purpose — including the gate you just repaired.**
  Nothing promoted. Evidence: `docs/dev-log/check-log.d/2026-07-08-plotting-aog.md`.
  START HERE: `docs/dev-log/handover/2026-07-08-claude-handover.md`.

- **As of 2026-07-03 (doc-25 V7 GPU stream COMPLETE + V8 stream COMPLETE — ALL numbered slices done;
  Claude solo (Opus), autonomous; `/goal` "finish everything left in doc-25"; rows **55** / covered
  **13** / `public_covered_count` **5** UNCHANGED throughout).** The doc-25 numbered map is CLEARED.
  This continuation delivered + MERGED, each pre-declared + Rose-audited: **V8.5** APY genomic inverse
  (#253), **V8.4** external blupf90 comparator for the matrix-free fit — estimand leg (#254), and the
  ENTIRE **v0.7 GPU stream**: **V7.1** G-B Float32 (#255, tamia H100 — Float64 gate 7.3e-15, Float32
  GEBV ~1e-6, speedup MODEST ~1.2×, TF32 not engaged), **V7.2** G-7.2 cross-device (#256, Narval A100 —
  agreement PORTABLE ~1e-15, Float64 gate 3.0e-15; GBLUP bench 5.9×→46.7×), **V7.4** G-D backend
  dispatcher (#257, opt-in `backend=:cuda` on the two construction ops; `:cpu` byte-identical), **V7.3**
  G-C large-panel benchmark (#258, tamia H100 — handles n=20k×m=300k on one H100, 29% of 80GB; Float32
  modest, transfer-bound), and **V7.5** G-E close-out (this slice — `status_cache` pointer refreshed,
  stream consolidated). HONEST GPU summary: numerically exact + architecture-portable + handles realistic
  panels, but Float32 only a minor win + no R-public surface → `V2-GRM-GPU` stays `partial`, NO covered
  move. **doc-25 FULLY CLOSED** — both owed hardening legs now DISCHARGED (each Rose-audited + merged):
  **V8.4 at-scale** (blupf90 vs exact-sparse vs matrix-free at q=4060, PR #260 — exact==blupf90 4.7e-6,
  matrix-free ≤1%; the exact-infeasible regime q≫50k has NO external oracle by construction) and
  **coverage-calibrated intervals** (DRAC fir job 46853279 — empirical coverage of the shipped
  `:delta`/`:profile` h²/σ²a intervals: CONSERVATIVE over-coverage at small n, converging to nominal,
  `:profile` > `:delta`; a characterization, no covered flip). `public_covered_count` **5** held across
  the ENTIRE arc. START HERE: `docs/dev-log/after-task/2026-07-03-interval-coverage.md`.

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
