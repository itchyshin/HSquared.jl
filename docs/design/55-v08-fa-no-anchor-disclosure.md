# 55 — V4-FA no-anchor disclosure (design-41 §3 #4)

> **Status: DISCLOSURE WRITTEN · NOT A COVERED FLIP.**
> Clears the textbook-anchor sub-gate for a *future* `V4-FA` covered row.
> `V4-FA` stays **partial**. `public_covered_count` stays **7**.
> Experimental version stays **0.7.0**. No `cov = fa` freeze here.
> Twin pointer: this file lives on `HSquared.jl` #292
> (`cursor/08-fa-20260903`). Capability-status and the generated
> `docs/src/validation-status.md` page were **not** edited in this slice
> (foreign lease on those paths).

```
PLATFORM: cursor | LANE: cursor/08-fa-20260903 (#292)
OTHER LANES: cursor/08-fa-boole-freeze holds design-54 + board ·
             cursor:g5-stale-copy holds capability-status + docs/src/
Active lenses: Rose (packet) · Ada/Shannon fence
Spawned subagents: none
Current lane: Julia FA no-anchor disclosure only
```

## Why this exists

The Standard-Tier Covered-Flip Gate (hsquared `docs/dev-log/decisions.md`,
2026-07-09) and design-41 §3 #4 require every covered flip to carry either

1. a pinned textbook number (named source, edition, example/equation,
   reproduced value), or
2. an explicit in-surface **no-anchor disclosure**.

Rose's 2026-09-03 FA packet
(`~/local-scratch/h2-08-fa-rose-packet-2026-09-03.md`) marked §3 #4
**BLOCKER**: no Mrode / Meyer / Kirkpatrick worked FA pin, and no
disclosure drafted for a future `V4-FA` covered row.

This file is that disclosure.

## Disclosure (canonical text)

**NO-ANCHOR DISCLOSURE (Standard-Tier covered-flip gate item 2 /
design-41 §3 #4):** There is no Mrode factor-analytic pin table. Mrode
does not publish a worked FA REML example with pin-able reconstructed
`G = ΛΛ' + Ψ` or uniqueness (`ψ`) numbers. Meyer / Kirkpatrick
literature are not pinned textbook numbers for this row. Mrode Example
5.1 is a supplied-covariance BLUP/MME anchor and does **not** transfer
to estimated FA `G0` / `ψ`. A future `V4-FA` covered flip must carry
this disclosure, never an implied Mrode / textbook FA pin.

Precedent (same gate, already written):

- direct-maternal has no Mrode Ch.7 anchor;
- genomic GREML has no clean Mrode genomic-\(h^2\) pin
  (`docs/design/51-v07-greml-s0-estimand.md`);
- unstructured MV REML discloses that Mrode 5.1 does not anchor
  *estimated* `G0`/`R0`.

## What this does not do

- Does **not** flip `V4-FA` to covered.
- Does **not** retire WOMBAT / recovery-substitution (§3 #2), Darwin
  SIGN (§3 #5), Boole `cov = fa` freeze (§3 #6), or R-twin parity
  (§3 #8).
- Does **not** pin a Meyer / Kirkpatrick / evolqg number. Those remain
  optional later pins; they are not implied by this disclosure.
- Does **not** treat S4 8/10 `ok_recovery` as a textbook substitute.

## Surfaces that carry the same sentence

| Surface | This slice |
|---|---|
| This file (canonical) | written |
| `docs/design/validation-debt-register.md` `V4-FA` | mirrored |
| `docs/design/06-public-claims-register.md` FA row | mirrored |
| `src/validation_status.jl` `V4-FA` **evidence** | mirrored |
| `docs/design/capability-status.md` FA row | **deferred** (g5 lease) |
| `docs/src/validation-status.md` | **deferred** (g5 lease; `claim_boundary` left unchanged so the A25 page-sync test stays green) |

## Provenance

Rose packet 2026-09-03 §3 #4. Gate text: hsquared
`docs/dev-log/decisions.md` (2026-07-09 Standard-Tier). Direct-maternal
example: `AGENTS.md` Definition of Done. Genomic example: design-51.
MV estimated-`G0`/`R0` example: A29 (`bc3cb79d` and twin).
