# check-log — 2026-09-01 h2-b5 A18 CI/deploy + Documenter mirror (Julia)

**Arc:** A18 — Documenter main-push deploy; drop blanket `warnonly`; sidebar by job;
generate validation-status table from `validation_status()`  
**Lane:** `claude/lane-h2-twin-20260901` @ `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`  
**Sister patterns:** DRM.jl / GLLVM.jl Documenter.yml (`push: branches: [main]`);
R A17 capability-ledger generator  

## Changes

- `.github/workflows/Documenter.yml` — add `push: branches: [main]` (was tag/PR/dispatch only).
- `docs/make.jl` — `warnonly = [:missing_docs]` (was `true`); job-shaped `pages`
  mirroring R navbar; call generator before `makedocs`.
- `tools/write_validation_status_page.jl` — NEW; splices generated table into
  `docs/src/validation-status.md` between markers.
- `docs/src/validation-status.md` — table now generated (55 rows; previously
  hand-maintained and missing rows such as `V1-SIRE-FIT`).
- `test/runtests.jl` — drift guard: every `validation_status()` id must appear
  in the generated Documenter page.

## Commands

```sh
cd ~/local-scratch/lanes/HSquared.jl-h2-twin-20260901
julia --project=. tools/write_validation_status_page.jl
bash tools/preamble_cap.sh
julia --project=docs docs/make.jl
julia --project=. -e 'using HSquared, Test;
  include("test/runtests.jl")'  # too heavy — use scoped filter below
# Scoped drift-guard smoke (loads package + reads page):
julia --project=. -e '
using HSquared, Test
status = validation_status()
page = read("docs/src/validation-status.md", String)
@test length(status) == 55
@test occursin("BEGIN GENERATED validation-status-table", page)
@test all(occursin("`$(r.id)`", page) for r in status)
println("drift_guard_ok rows=", length(status))
'
```

## Results

| Check | Outcome |
|-------|---------|
| `julia --project=. tools/write_validation_status_page.jl` | **PASS** — 55 rows written |
| `bash tools/preamble_cap.sh` | **PASS** — CAP OK |
| `julia --project=docs docs/make.jl` | **PASS** — makedocs + Vitepress build exit 0; deploy skipped locally (`Documenter could not auto-detect the building environment`); missing_docs remain warnings under `warnonly = [:missing_docs]` |
| drift-guard smoke | **PASS** — all 55 ids present between markers |

Full `Pkg.test()` was **not** re-run in this slice (suite is large; A11 tip already
green). Drift guard is a pure string/id check; Documenter build exercised the
generator path via `docs/make.jl`.

## Remaining A18 gaps (honest)

- First post-merge Documenter deploy on `main` not verified (no push).
- R twin still lacks pkgdown live-deploy proof for the new Pages path.
- Reader “current-limits” equivalent page on Julia is still the generated
  validation table + mission-control — not a full R `current-limits.Rmd` mirror.
- Blanket `warnonly = true` removed, but `[:missing_docs]` still suppresses the
  large undocumented-export list (intentional; G8 targets broken doctest/cross-ref).

## Prohibitions held

No push, no G10 sign, no covered flip, no S5 re-run, no owner-ask #1 resolution,
no codex v07 README merge.
