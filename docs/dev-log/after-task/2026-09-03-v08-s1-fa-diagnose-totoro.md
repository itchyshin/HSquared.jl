# After-task — 0.8 S1 Totoro d3-panel classify (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-fa-20260903`. Type: evidence scaffolding.

```
PLATFORM: cursor | LANE: cursor/08-fa-s1-totoro-20260903
OTHER LANES: G5 #157/#291 cite-only · Codex DRAFT #137/#274 cite-only · cursor/08-ss AGHmatrix
Active lenses: Ada · Shannon · Rose fence · Curie/Fisher (S1) · Kirkpatrick (FA)
Spawned subagents: none
Current lane: Julia 0.8 WT (panel evidence only)
```

## Goal

Finish the predeclared design-42 S1 classify on the full banked FA panel.
No covered flip.

## What landed

- Totoro `--mode=fit --cell=d3-panel` (10 seeds, 1 core, ~89 s, exit 0).
- Checkpoint + TSV + check-log.d for the panel.
- Contrast cell was already recorded on this branch (`5f07d026`); this slice
  does not rewrite that.

## Public claim audit

Allowed: "S1 panel ran; 8/10 `ok_recovery` and 2/10 `heywood_boundary`;
zero `optimizer_miss`; Heywood is typical at this Ledermann-saturated DGP."
Blocked: FA / single-step covered; `cov=fa`; loadings+SE; WOMBAT parity;
0.8.0 / count 8; 1.0 / CRAN; Rose CLEAN.

## Checks this slice

```sh
# Totoro
~/hsq_work/julia-1.10.0/bin/julia --project=. sim/v08_fa_s1_diagnose.jl \
  --mode=fit --cell=d3-panel
# exit 0; CLASS_COUNTS ok_recovery 8 / heywood_boundary 2
```

WOMBAT still absent on Totoro PATH. Did not touch G5 WTs or `comparator/`.

## Next

S2 prereg of a uniqueness-interior / Ledermann-slack gate. S3 is a Heywood
bound, not an EM warm-start. No flip until design-41 §3 + Rose CLEAN.
