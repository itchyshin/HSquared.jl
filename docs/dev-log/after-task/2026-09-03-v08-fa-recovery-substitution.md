# After-task — 0.8 FA WOMBAT recovery-substitution disclosure (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-fa-20260903`. Type: honesty artifact (no campaign, no flip).

```
PLATFORM: cursor | LANE: cursor/08-fa-rose-g11-20260903
OTHER LANES: cursor/08-fa Boole freeze (design-54) · cursor/08-fa no-anchor
             (design-55) · cursor/08-ss #295 cite-only · G5 cite-only
Active lenses: Rose (this slice) · Ada/Shannon fence
Spawned subagents: none
Current lane: Julia FA #292 — §3 #2 disclosure only
```

## Goal

Clear design-41 §3 #2 for FA after S4 PASS: start a thin WOMBAT AGREE if
the binary exists, otherwise write an honest recovery-substitution. No
covered flip. No forged Rose CLEAN.

## What landed

- Rechecked WOMBAT on the laptop and on Totoro (ControlMaster live).
  **Absent both places.** No AGREE path started.
- Decision:
  `docs/dev-log/decisions/2026-09-03-v08-fa-recovery-substitution-disclosure.md`
- This report + matching `check-log.d` entry.
- Receipt on `~/local-scratch/h2-08-fa-rose-packet-2026-09-03.md`.

Did **not** edit `capability-status.md`, `validation_status.jl`, the
public-claims register, or the coordination board (other live leases).

## Public claim audit

Allowed: "WOMBAT is not installed; S4 known-truth PASS is banked; §3 #2
is a written recovery-substitution, kind still REML; comparator debt
retained; Rose stays NOT CLEAN."
Blocked: WOMBAT AGREE / FA REML parity; `V4-FA` covered; `cov = fa`;
loadings+SE; count 8; 0.8.0; 1.0 / CRAN; Rose CLEAN; Darwin SIGN.

## Checks this slice

```sh
# laptop
command -v wombat WOMBAT wombat64
# not found

# Totoro via live ControlMaster
ssh -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22" \
    -o BatchMode=yes -o ConnectTimeout=15 totoro \
    'command -v wombat; command -v WOMBAT; find ~ /opt /usr/local /home -maxdepth 4 -iname "*wombat*"'
# host=totoro; binaries absent; find empty
```

No `Pkg.test` / Documenter this slice (docs-only; no `src/` change).

## Tests of the tests

S4 TSV and freeze SHAs were re-read, not re-run. This slice does not
change the 8/10 bar or the driver.

## Coordination notes

Lease `cursor:08-fa-rose-g11-20260903` on the three new files only.
Boole holds design-54 + the board; no-anchor holds design-55 +
`validation_status.jl`. Board row deferred so those slices do not collide.

## What did not go smoothly

A directory-wide docs lease was refused (expected). Narrowed to unique
filenames. Totoro socket was live (dated 31 Aug) and attached without Duo.

## Known limitations

Disclosure satisfies §3 #2’s substitution clause only. It is **not**
design-16 path (b) (no existing FA same-estimand leg). Rose packet remains
**NOT CLEAN**.

## Next

Other §3 blockers stay with their slices (Boole, Darwin, no-anchor, R
parity). A **new** Rose packet on the tip that carries those artifacts —
this after-task is not that re-audit. No auto-flip.
