# After-task — V4-FA engine-row G10 flip (S4 G/R cell)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-fa-g10-20260903`. Type: covered flip (engine-only).

```
PLATFORM: cursor | LANE: cursor/08-fa-g10-20260903
OTHER LANES: SS honesty #299/#168 OPEN · Codex DRAFT #137/#274 cite-only
Active lenses: Ada / Shannon fence · Rose (CLEAN pre-flip packet) · Darwin · Boole
               Curie/Fisher (S4 cite) · Kirkpatrick (FA fence) · Grace (CI)
Spawned subagents: none
Current lane: scratch WT — Dropbox FOREIGN
```

## Goal

Fire owner G10 on the fresh FA Rose **CLEAN** packet. Flip `V4-FA`
`partial→covered` for the S4 cell only. Leave `public_covered_count` at **7**.
Leave experimental **0.7.0**. Do not bump 0.8.0. Do not flip SS.

## What landed

- `src/validation_status.jl` `V4-FA` field-4 `partial→covered`.
- Evidence keeps Phase 4B history + NO-ANCHOR pins; adds S4 `d8148a3a`,
  recovery-sub `d3e9ca09`, Darwin/nod `2ca6cdaf`, design-54/55.
- `test/runtests.jl` FA pins now require `covered` plus those SHAs.
- Twin docs: capability-status, validation-debt, public-claims,
  generated `docs/src/validation-status.md`, multivariate-models Phase 4B prefix.
- `tools/status_cache.json` machine covered 13→14; `public_covered_count` **7**.
- Board + check-log.d + this report.

## Public-claim audit

**Allowed:** engine-covered S4 G/R/interior ψ at t=4 K=1, validation-scale,
opt-in, Julia API.

**Blocked:** R-public FA · `cov=fa` parser · loadings+SE · per-trait h² /
r_g / evolvability on FA G · WOMBAT AGREE · interval “calibrated” ·
0.8.0 / 1.0 / CRAN / General · count 7→8.

## Tests of the tests

FA pins still require NO-ANCHOR + Phase 4B `did not pass` / `8/10` / `9/10`
history. New pins: `d8148a3a`/`ok_recovery`, `d3e9ca09`/`recovery-substitution`,
Darwin SHA/filename, `54-fa-grammar-freeze`/`RATIFIED`.

## Checks

- `bash tools/preamble_cap.sh` — CAP OK
- `Pkg.test()` — **Testing HSquared tests passed** (exit 0)
- `validation_status()` V4-FA == `covered`
- count **7** · version **0.7.0**

## Coordination

R pointer follows this flip SHA (R FA stays planned / partial-pointer).
SS remains NOT CLEAN (`V2-SSHINV` field-7 honesty rewrite #299/#168 not
merged at flip time). Flip landed; Rose was CLEAN pre-flip.

## Limitations / next

WOMBAT missing. R-public FA later. SS G10 only after a later CLEAN packet.
0.8.0 only after FA **and** SS are both §3 + Rose CLEAN on both twins
plus a separate version-bump phrase.
