# check-log — 2026-09-01 h2 A19 registry hygiene

**Arc:** A19 — Julia General hygiene (no Registrator)  
**Lane:** `claude/lane-h2-twin-20260901` @ `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`  
**Prep:** `docs/dev-log/release/0.5.0-julia-registry-checklist.md` · `~/local-scratch/h2-a19-registry-prep.md`  
**Lens:** Grace

## Changes

| Artifact | Action |
|----------|--------|
| `test/test_aqua.jl` | Added (DRM sister pattern; `ambiguities=false`, `deps_compat=true`) |
| `test/runtests.jl` | `include("test_aqua.jl")` before first testset |
| `.github/workflows/TagBot.yml` | Added (DRM/GLLVM sister) |
| `CITATION.cff` | Honest placeholder; `version: 0.0.1` matches Project.toml; **DOI pending** |
| `Project.toml` | Aqua in `[extras]`/`[targets]`; stdlib + extras `[compat]`; **version stays `0.0.1`** |
| `src/HSquared.jl` | Removed undefined export `fit_eigen_reml` (Aqua catch) |

**Not done (owner ASK):** `version = "0.5.0"` bump; Registrator; General PR; git tag; Zenodo DOI.

## Commands

```sh
cd ~/local-scratch/lanes/HSquared.jl-h2-twin-20260901
julia --project=. -e 'using Pkg; Pkg.test("HSquared"; test_args=`Aqua`)'
```

(Note: `test_args` did not isolate Aqua-only on this runner; Aqua ran first via
`include`, then the full suite continued.)

## Results

| Check | Outcome |
|-------|---------|
| Aqua.jl quality assurance | **Pass 10 / Fail 0** (8.6s) after export + extras-compat fixes |
| Full `Pkg.test()` continuation | **passed** (same invocation) |

First Aqua attempt failed on (1) undefined export `fit_eigen_reml`,
(2) missing `[compat]` for `[extras]` — both fixed before green.

## Remaining A19

- Documenter install honesty refresh (GLLVM `Pkg.add(url=...)` until General)
- Confirm `DOCUMENTER_KEY` present for TagBot SSH
- Campaign merge + Shinichi OK → bump 0.5.0 → Registrator
- Twin DOI after General accept

## Prohibitions held

No Registrator, no version bump to 0.5.0, no push, no G10, no covered flips, no S5.
