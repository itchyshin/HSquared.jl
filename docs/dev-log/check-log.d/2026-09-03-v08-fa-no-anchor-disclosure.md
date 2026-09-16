# 2026-09-03 — V4-FA no-anchor disclosure (no flip)

**Arc:** Rose §3 #4 blocker after S4 PASS. Packet
`~/local-scratch/h2-08-fa-rose-packet-2026-09-03.md`.
**Lane:** Julia `cursor/08-fa-20260903` (#292).
**Worktree:** `~/local-scratch/lanes/HSquared.jl-08-fa-20260903`

## Why

A future `V4-FA` covered row needs a pinned textbook number **or** an
explicit no-anchor disclosure. There is no Mrode FA pin table. This
slice writes the disclosure. Status stays **partial**.

## What changed

| File | Change |
|---|---|
| `docs/design/55-v08-fa-no-anchor-disclosure.md` | Canonical disclosure (slot 55; 54 held by Boole freeze) |
| `docs/design/validation-debt-register.md` | `V4-FA` row mirrors the sentence |
| `docs/design/06-public-claims-register.md` | FA claims row mirrors the sentence |
| `src/validation_status.jl` | `V4-FA` **evidence** mirrors the sentence; `status` stays `partial`; `claim_boundary` unchanged |
| `test/runtests.jl` | Pins `NO-ANCHOR DISCLOSURE` + "no Mrode factor-analytic pin table" on evidence; status still `partial` |

Deferred (foreign leases): `docs/design/capability-status.md`,
`docs/src/validation-status.md` (g5). Coordination board (Boole freeze).

## Commands and outcomes

| Command | Result |
|---|---|
| `julia --project=. -e 'using HSquared; … V4-FA asserts'` | `status=partial` · `disclosure=true` · `mrode_fa=true` · `design55=true` · `OK` |

## Fence

- `V4-FA` stays `partial`. Count stays **7**. Experimental **0.7.0**.
- No WOMBAT invented. No Darwin SIGN. No `cov = fa` freeze.
- No 1.0 / CRAN / General.
