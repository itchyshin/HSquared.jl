# After-task — V4-FA no-anchor disclosure (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-fa-20260903`. Type: Rose §3 #4 paperwork.

```
PLATFORM: cursor | LANE: cursor/08-fa-20260903 (#292)
OTHER LANES: cursor/08-fa-boole-freeze holds design-54 + board ·
             cursor:g5-stale-copy holds capability-status + docs/src/ ·
             cursor/08-ss #295 cite-only · Codex DRAFT #137/#274 cite-only
Active lenses: Rose (packet) · Ada/Shannon fence
Spawned subagents: none
Current lane: Julia FA no-anchor disclosure only
```

## Goal

Write the explicit no-anchor disclosure for a *future* `V4-FA` covered
row. There is no Mrode FA pin table. Do not flip covered.

## What landed

- Canonical text: `docs/design/55-v08-fa-no-anchor-disclosure.md`
  (slot **55**; Boole freeze already claimed **54**).
- Mirrored on `validation-debt-register.md` `V4-FA`,
  `06-public-claims-register.md` FA row, and `validation_status.jl`
  `V4-FA` evidence.
- Test pins the disclosure string and `status == "partial"`.
- `claim_boundary` left unchanged so the A25 generated-page sync test
  stays green without touching `docs/src/` (g5 lease).

## Public claim audit

Allowed: "no-anchor disclosure written for a future `V4-FA` covered
row; row stays partial."
Blocked: `V4-FA` covered; count 8; 0.8.0; `cov = fa`; WOMBAT parity;
Darwin SIGN; 1.0 / CRAN.

## Checks this slice

Recorded in `docs/dev-log/check-log.d/2026-09-03-v08-fa-no-anchor-disclosure.md`.

## Tests of the tests

The new assertions require the disclosure on **evidence** and refuse a
status flip. They would fail if someone deleted the sentence or set
`V4-FA` to `covered` in the same commit.

## What did not go smoothly

- `docs/src/` and `capability-status.md` are leased by
  `cursor:g5-stale-copy`. Disclosure is on the linked design doc +
  debt + claims + `validation_status()` evidence instead.
- Coordination board is leased by the Boole `cov=fa` freeze sibling.
  Board row not written here.
- Design **54** was taken by that sibling; this slice took **55**.

## Known limitations

§3 #4 is the only gate this slice closes. WOMBAT / recovery-substitution,
Darwin, Boole, and R-twin parity remain blockers. Rose re-audit is a
later packet on a tip that carries those artifacts.

## Next

Leave the board to the Boole lane or a later Shannon pass. Do not
auto-flip.
