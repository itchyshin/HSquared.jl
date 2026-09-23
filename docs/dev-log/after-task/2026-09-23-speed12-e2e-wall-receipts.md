# After-task: speed12 end-of-arc e2e wall receipts

Date: 2026-09-23
Lane: claude/lane-speed12-20260919 @ fc3fc938
Active lenses: Shannon (coord), Curie (measurement), Rose (claim fence). No spawned subagents.

## Outcome

Banked 16 attested wall cells across five kinds (animal REML, sparse selinv,
post-fit uncertainty, multi-effect, large pedigree). Live Mac measurements
plus S1/S2/phase5 banked Totoro numbers. Script
`sim/e2e_wall_receipts.jl`; TSV `sim/results/e2e_wall_receipts_fc3fc938.tsv`.
Plan table: `docs/dev-log/plans/2026-09-23-speed12-e2e-wall-receipts.md`.

## Headline (honest)

- Kernel selinv: up to **300.6×** (Totoro q=20k fill≈471) and **284×** (Mac fill≈150).
- Projected high-fill animal REML: **~95×** at q=5k fill≈150 (S1×S2; not wired).
- Post-fit PEV: **~27×** dense(hist) vs selinv(live) at q≈500.
- Multi-effect Totoro K=3 q=1000: **~658×** dense vs sparse (estimator confound).
- Benign halfsib: SelectedInversion is **not** a win (S2 S_c ≪ 1).

## R twin

`hsquared` has **no** parallel wall-receipt script.

## Checks

- `julia --project=. sim/e2e_wall_receipts.jl` → wrote 16-row TSV (exit 0).
- Lease held then released on HSquared.jl paths sim/,bench/,docs/dev-log/,LOOP/.

## Rose

OK for measurement banking. Not a public performance claim. Not a D-271
decision. Projected rows must stay labelled projected.

## Next

Orchestrator: D-271 SelectedInversion optional-extension call; optional leaf-S2b
remeasure on Szymek kernel (origin/main).
