# check-log — 2026-09-04 experimental 0.8.0 version bump

**Arc:** experimental number `0.7.0` → `0.8.0` (engine FA + SS pillars already covered)  
**Lane:** `cursor/08-ver-080-jl-20260903` @ `~/local-scratch/lanes/HSquared.jl-08-ver-080-20260903`  
**Base:** `origin/main` `bd2ec128` (G10 SS merge #301; flip `cf2a9bbf`)  
**Fence:** number only. No covered flip. `public_covered_count` stays **7**.
Experimental label **retained**. No tag / General / CRAN / 1.0.

## Changes

- `Project.toml` — `version = "0.8.0"`.
- `CITATION.cff` — `version: 0.8.0`; tagged comment v0.8.0; DOI still pending.
- `docs/src/changelog.md` — prepend `## 0.8.0 (experimental)`.
- README / index / capability-status live banners — Experimental **0.8.0**; count **7**.
- `V2-SSHINV` claim-boundary version sentence `0.7.0` → `0.8.0` (field-4 stays **covered**).
- `test/runtests.jl` SS pin follows that sentence.
- Board + this file + after-task.

## Commands

```sh
cd ~/local-scratch/lanes/HSquared.jl-08-ver-080-20260903
rg -n '^version' Project.toml
rg -n '"public_covered_count"' tools/status_cache.json
bash tools/preamble_cap.sh
julia --project=. -e 'using TOML; println(TOML.parsefile("Project.toml")["version"])'
```

## Results

| Check | Outcome |
|-------|---------|
| `Project.toml` version | **0.8.0** |
| `public_covered_count` | **7** |
| `preamble_cap.sh` | CAP OK |
| `Pkg.test()` | **passed** |
| `V4-FA` / `V2-SSHINV` field-4 | both **covered** |
