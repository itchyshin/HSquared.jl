# 2026-09-03 — Boole `single_step()` freeze (n≫6 ordinary defaults)

**Not a covered flip.** `V2-SSHINV` stays partial. Count stays **7**.
Experimental **0.7.0**.

## What

Boole freeze of `single_step()` argument names + ordinary-default engine
route, scoped to the n≫6 cell (`τ = ω = 1`, `blend_weight = ridge = 0`,
`G = A₂₂ + 0.05 I`). Canonical:
`docs/design/56-single-step-grammar-freeze.md`.

Formula `single_step(1 | id, Hinv = Hinv)` and
`single_step(1 | id, pedigree = ped, markers = M)` are **name** freezes.
Default-path auto-route is not authorised. `markers = M` (VanRaden `G`)
is not the covered-claim cell.

## Checks

Docs only. No engine test run this slice (no `src/` change). Prior n≫6
evidence remains freeze SHA `8e6e038b` / GATE PASS recorded on that
predeclaration.
