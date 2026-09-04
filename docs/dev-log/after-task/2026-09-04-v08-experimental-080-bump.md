# After-task — experimental version 0.7.0 → 0.8.0

Date: 2026-09-04. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-ver-080-jl-20260903`. Type: experimental number only.

```
PLATFORM: cursor | LANE: cursor/08-ver-080-jl-20260903
OTHER LANES: Codex DRAFT #137/#274 cite-only · Dropbox FOREIGN
Active lenses: Ada / Shannon fence · Rose (bump surfaces only)
Spawned subagents: none
Current lane: scratch WT — Dropbox FOREIGN
```

## Goal

Fire owner **`bump 0.8.0`**. Change the experimental number 0.7.0 → 0.8.0
because both 0.8 **engine** pillars are covered (`V4-FA`, `V2-SSHINV`).
Leave `public_covered_count` at **7**. Leave the experimental label on.
Do not flip any row. Do not lift experimental. Do not tag.

## What landed

- Version surfaces: `Project.toml`, `CITATION.cff`, changelog, README,
  index, capability-status live banners, `V2-SSHINV` claim-boundary
  version sentence, SS test pin, board, this report.
- `tools/status_cache.json` `public_covered_count` **7**.
- Field-4 of `V4-FA` and `V2-SSHINV` unchanged (**covered**).

## Public-claim audit

**Allowed:** experimental **0.8.0** number. Version tracks the engine
pillar pair, not R-public count.

**Blocked:** count 7→8 · R-public FA · R-public SS · ordinary-route
`single_step()` · `cov = fa` · experimental lift · tag / General / CRAN
/ 1.0 · WOMBAT AGREE · preGSf90/blupf90+ fit AGREE · H-scale h² as
claim-gated.

## Twin

R lockstep branch `cursor/08-ver-080-r-20260903`. Merge together after
both CI green. Julia first or same hour.


## Local checks

- `Project.toml` version **0.8.0**
- `tools/status_cache.json` `public_covered_count` **7**
- `bash tools/preamble_cap.sh` CAP OK
- `julia --project=. -e 'using Pkg; Pkg.test()'` **passed** (HSquared v0.8.0)
- `V4-FA` field-4 **covered**; `V2-SSHINV` field-4 **covered**
