# After-task — V2-SSHINV engine-row G10 flip (H-scale VCs)

Date: 2026-09-04. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-ss-flip-20260903`. Type: covered flip (engine-only).

```
PLATFORM: cursor | LANE: cursor/08-ss-flip-20260903
OTHER LANES: Codex DRAFT #137/#274 cite-only · Dropbox FOREIGN
Active lenses: Ada / Shannon fence · Rose (CLEAN pre-flip packet) · Darwin · Boole
               Curie/Fisher (n≫6 cite) · Henderson (Hinv) · Grace (CI)
Spawned subagents: none
Current lane: scratch WT — Dropbox FOREIGN
```

## Goal

Fire owner **`G10 SS`** on the fresh SS Rose **CLEAN** packet. Flip
`V2-SSHINV` `partial→covered` for H-scale σ²a / σ²e only. Leave
`public_covered_count` at **7**. Leave experimental **0.7.0**. Do not
bump 0.8.0. Do not re-flip FA.

## What landed

- `src/validation_status.jl` `V2-SSHINV` field-4 `partial→covered`.
- Evidence keeps construction history + AGHmatrix / #167; adds
  construction `0b03d67e`, freeze `8e6e038b`, PASS `0533e9da`,
  recovery-sub `e6d0573d`, Boole `17cd2e1b` + nod `82c0b4f5`,
  h² fence `e9676014`, Darwin SIGN `2ca6cdaf`, Mrode Ch.11 NO-ANCHOR,
  Rose CLEAN packet path.
- `test/runtests.jl` SS pins now require `covered` plus those SHAs /
  no-anchor / recovery-sub / h²-fence phrases.
- Twin docs: capability-status, validation-debt, public-claims,
  generated `docs/src/validation-status.md`.
- `tools/status_cache.json` machine covered 14→15; `public_covered_count` **7**.
- Board + check-log.d + this report.

## Public-claim audit

**Allowed:** engine-covered H-scale σ²a / σ²e at validation scale,
ordinary defaults (`τ=ω=1`, blend=ridge=0), teaching kernel
`G = A₂₂ + 0.05 I`. Opt-in. Point-estimate. Julia API.

**Blocked:** R-public SS · ordinary-route `single_step()` · VanRaden-G
as the covered cell · metafounder `H^Γ` · APY · non-default knobs ·
field ssGBLUP · h² as covered · “unbiased” · “calibrated intervals” ·
0.8.0 / 1.0 / CRAN / General · count 7→8 · FA re-flip.

## Tests of the tests

SS pins require `covered` + NO-ANCHOR + recovery-sub + h²-fence
(`reported, not claim-gated`) + Darwin / Boole SHAs. FA pins stay
`covered` (not re-edited).

## Checks

Recorded in `docs/dev-log/check-log.d/2026-09-03-v08-ss-v2-sshinv-covered-flip.md`.

## Coordination

R pointer follows this flip SHA (R SS stays opt-in partial). R FA stays
planned (#169). Flip landed; Rose was CLEAN pre-flip.

## Limitations / next

preGSf90 / blupf90+ missing. R-public SS later. 0.8.0 only after a
separate owner **`bump 0.8.0`** phrase (both engine pillars now covered
on 0.7.0; R FA planned is OK).
