# 2026-09-04 — V2-SSHINV engine-row G10 flip (H-scale VCs; count stays 7)

**Not 0.8.0.** Experimental stays **0.7.0**. `public_covered_count` stays **7**
(engine ≠ R-public). R SS stays opt-in partial. `V4-FA` stays covered.

```
PLATFORM: cursor | LANE: cursor/08-ss-flip-20260903
OTHER LANES: Codex DRAFT #137/#274 cite-only · Dropbox FOREIGN
Active lenses: Ada / Shannon fence · Rose CLEAN pre-flip · Darwin SIGN · Boole nod
Spawned subagents: none (Rose packet already CLEAN; not re-spawned)
Current lane: scratch WT ~/local-scratch/lanes/HSquared.jl-08-ss-flip-20260903
```

## Pins

| Item | Value |
|---|---|
| Owner G10 | **`G10 SS`** (2026-09-04) |
| Rose CLEAN | `~/local-scratch/h2-08-ss-rose-packet-2026-09-03-post-missing-fix.md` (tip `d724993d` / `cf82a2b9`) |
| Darwin SIGN | `2ca6cdaf` |
| design-56 nod | `82c0b4f5` RATIFIED 2026-09-03 — Shinichi |
| Construction | `0b03d67e` |
| n≫6 freeze / PASS | `8e6e038b` / `0533e9da` 48/48 |
| Recovery-sub | `e6d0573d` (preGSf90 / blupf90+ absent; not AGREE) |
| h² fence | `e9676014` |
| Boole freeze | `17cd2e1b` |
| Base tip | `d724993d` |

## Commands and outcomes

```sh
bash tools/preamble_cap.sh
# CAP OK -- preamble within budget (12186 B / 1 snapshot entry)

julia --project=. tools/write_validation_status_page.jl
# wrote docs/src/validation-status.md; rows: 56

julia --project=. tools/gen_status_json.jl --refresh-count
# cache: rows=56 covered=15 covered_external=3 partial=37 planned=1 public_covered_count=7

julia --project=. -e 'using HSquared; s = only(r for r in validation_status() if r.id == "V2-SSHINV"); @assert s.status == "covered"; fa = only(r for r in validation_status() if r.id == "V4-FA"); @assert fa.status == "covered"'
# V2-SSHINV=covered V4-FA=covered

julia --project=. -e 'using Pkg; Pkg.test()'
# Testing HSquared tests passed (exit 0; ~249 s; Phase 0 scaffold 404/404)
```

Machine ladder 14→15 is **not** the R-public count. `Project.toml` version **0.7.0**.

7→8 **not warranted** (engine ≠ R-public).

## Fence

`V2-SSHINV` covered · `V4-FA` covered · count **7** · experimental **0.7.0** ·
R SS opt-in partial · R FA planned · no 1.0 / CRAN / General · no h² covered ·
no VanRaden-G / metafounder `H^Γ` / APY as covered.
