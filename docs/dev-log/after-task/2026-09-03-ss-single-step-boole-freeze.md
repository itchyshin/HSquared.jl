# After-task — Boole `single_step()` freeze (n≫6 ordinary defaults, no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-ss-20260903`. Type: grammar freeze.

```
PLATFORM: cursor | LANE: cursor/08-ss-boole-freeze-20260903
OTHER LANES: FA sibling cursor/08-fa-20260903 #292 holds design-54 / decisions/
             · G5 stale-copy #296 holds capability-status + docs/src/
             · H1/H3 #294 · Codex DRAFT #274 cite-only
Active lenses: Boole (this freeze) · Ada/Shannon fence · Rose packet receipt
Spawned subagents: none
Current lane: Julia #295 freeze only (no R twin copy this slice)
```

## Goal

Clear Rose §3 item 6 (Boole grammar + argument-naming freeze) for
single-step, scoped to the ordinary defaults the n≫6 gate actually
covers (`τ = ω = 1`, blend/ridge = 0, `G = A₂₂ + 0.05 I`). No covered
flip.

## What landed

- `docs/design/56-single-step-grammar-freeze.md` — Boole freeze.
- This report + check-log.d + board row.
- Predeclaration “Still open” row for Boole updated to frozen.
- Comparator README next-step 4 marked as Boole landed (Darwin / R /
  Rose still owed).

Ratification lives in the design-56 block. The same-PR G5 substitution
disclosure row for §3 #6 is updated to FROZEN so the packet does not
contradict itself.

## Public claim audit

Allowed: "Boole froze `single_step()` names + the n≫6 ordinary-default
engine route; formula spellings are a name freeze only; no flip."
Blocked: `V2-SSHINV` covered; R `single_step()` covered; default-path
fitting; VanRaden `markers = M` as the covered cell; non-default
τ/ω/blend/ridge; metafounder `H^Γ`; count 8; 0.8.0; 1.0 / CRAN; Rose
CLEAN.

## Checks this slice

Docs only. No `Pkg.test()` (no `src/` change). No capability-row edit
(G5 lease holds that file).

## Next

Rose packet receipt: §3 #6 for single-step moves from “grammar exists;
not frozen” to HOLD (freeze on disk; maintainer nod still pending for a
flip). Darwin SIGN, G5 second-comparator honesty, R catch-up, and Rose
CLEAN remain open.
