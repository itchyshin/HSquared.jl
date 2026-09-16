# After-task — 0.8 S1 FA diagnose scaffold (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-fa-20260903`. Type: evidence scaffolding.

```
PLATFORM: cursor | LANE: cursor/08-fa-20260903
OTHER LANES: G5 #157/#291 cite-only · Codex DRAFT #137/#274 cite-only
Active lenses: Ada · Shannon · Rose fence · Curie/Fisher (S1) · Kirkpatrick (FA)
Spawned subagents: none
Current lane: Julia 0.8 WT
```

## Goal

Start the owner-armed 0.8 pillar (FA-G + single-step) with a **predeclared**
design-42 diagnose driver and a single-step construction dump. No covered flip.

## What landed

- `sim/v08_fa_s1_diagnose.jl` — per-seed `ℓ_fit` vs `ℓ_truth`, `min(ψ̂)`,
  `cond(Ĝ)`, frozen classification rules.
- `sim/v08_ss_s0_construction_probe.jl` — tiny `G=A22` reduction + dump
  (not Mrode Ch.11, not AGHmatrix).
- `docs/dev-log/decisions/2026-09-03-v08-s1-fa-diagnose-predeclare.md`

## Public claim audit

Allowed: "S1 diagnose driver exists and is predeclared; construction probe
exists."  
Blocked: FA / single-step covered; `cov=fa`; loadings+SE; WOMBAT parity;
0.8.0 / count 8; 1.0 / CRAN.

## Checks this slice

- Local `--mode=truth-only --cell=d3-contrast`: exit 0 (3 finite truth logliks).
- Local SS construction probe: exit 0 (`G=A22` residual 0).
- Totoro reachable (`loadavg` 0.04); `~/hsq_work/HSquared.jl` present; WOMBAT
  absent. Fit cell launched after commit if the host stays quiet.

## Next

1. Totoro `--cell=d3-contrast --mode=fit` (2 banked fails + 1 pass).
2. Classify; only then S2/S3. R catch-up after a Julia claim-surface change —
   none in this slice.
