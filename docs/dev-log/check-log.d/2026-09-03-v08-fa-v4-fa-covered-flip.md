# 2026-09-03 — V4-FA engine-row G10 flip (S4 G/R cell; count stays 7)

**Not 0.8.0.** Experimental stays **0.7.0**. `public_covered_count` stays **7**
(engine ≠ R-public). R FA stays planned. SS `V2-SSHINV` not flipped.

```
PLATFORM: cursor | LANE: cursor/08-fa-g10-20260903
OTHER LANES: SS honesty #299/#168 OPEN · Codex DRAFT #137/#274 cite-only · Dropbox FOREIGN
Active lenses: Ada / Shannon fence · Rose CLEAN pre-flip · Darwin SIGN · Boole nod
Spawned subagents: none (Rose packet already CLEAN; not re-spawned)
Current lane: scratch WT ~/local-scratch/lanes/HSquared.jl-08-fa-g10-20260903
```

## Pins

| Item | Value |
|---|---|
| Owner G10 | *"Go ahead and G10"* (2026-09-03) |
| Rose CLEAN | `~/local-scratch/h2-08-fa-rose-packet-2026-09-03-post-sign.md` (tip `ebf8d69a`) |
| Darwin SIGN | `2ca6cdaf` |
| design-54 nod | `2ca6cdaf` RATIFIED 2026-09-03 — Shinichi |
| S4 PASS | `d8148a3a` 8/10 `ok_recovery` t=4 K=1 |
| Recovery-sub | `d3e9ca09` (WOMBAT absent; not AGREE) |
| No-anchor | `8183ad66` |
| Boole freeze | `554d47e6` |
| Base tip | `ebf8d69a` |

## Commands and outcomes

```sh
bash tools/preamble_cap.sh
# CAP OK -- preamble within budget (12186 B / 1 snapshot entry)

julia --project=. -e 'using HSquared; s = only(r for r in validation_status() if r.id == "V4-FA"); @assert s.status == "covered"'
# covered

julia --project=. tools/write_validation_status_page.jl
# wrote docs/src/validation-status.md; rows: 56

julia --project=. tools/gen_status_json.jl --refresh-count
# cache: rows=56 covered=14 covered_external=3 partial=38 planned=1 public_covered_count=7

julia --project=. -e 'using Pkg; Pkg.test()'
# Testing HSquared tests passed (exit 0; ~215 s; Phase 0 scaffold 391/391)
```

Machine ladder 13→14 is **not** the R-public count. `Project.toml` version **0.7.0**.

7→8 **not warranted** (engine ≠ R-public).

## Fence

`V4-FA` covered · count **7** · experimental **0.7.0** · R FA planned ·
no 1.0 / CRAN / General · no loadings / per-trait h² / r_g / evolvability
as covered · no `cov=fa` parser.
