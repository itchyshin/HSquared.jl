# After-task — 0.8 SS second-comparator honesty (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-ss-20260903`. Type: honesty artifact (no campaign, no flip).

```
PLATFORM: cursor | LANE: cursor/08-ss-g5-disclosure-20260903
OTHER LANES: cursor/08-fa #292 · cursor:g5-stale-copy #296 ·
             H1/H3 #294 · Codex DRAFT #137/#274 cite-only
Active lenses: Rose (this slice) · Ada/Shannon fence
Spawned subagents: none
Current lane: Julia SS #295 — §3 #2 disclosure only
```

## Goal

Clear design-41 §3 #2 for single-step after the n=240 GATE PASS: start a
thin `preGSf90` / `blupf90+` same-estimand path if the binaries exist,
otherwise write an honest recovery-substitution / construction-vs-fit
disclosure. No covered flip. No forged AGREE. Count stays 7.

## What landed

- Rechecked `preGSf90`, `blupf90+`, `airemlf90`, `renumf90` on the laptop
  and on Totoro (ControlMaster live). **Absent both places.** No AGREE
  path started.
- Decision:
  `docs/dev-log/decisions/2026-09-03-v08-ss-recovery-substitution-disclosure.md`
- This report + matching `check-log.d` entry.
- Receipts: `~/local-scratch/h2-08-ss-second-comparator-2026-09-03.md`;
  gap list `~/local-scratch/h2-08-ss-flip-gap-2026-09-03.md` updated.

Did **not** edit `capability-status.md`, `validation_status.jl`, the
public-claims register, or the coordination board (other live leases /
FA precedent).

## Public claim audit

Allowed: "`preGSf90` / `blupf90+` are not installed; AGHmatrix closed
construction only; n=240 known-truth PASS is banked; §3 #2 is a written
recovery-substitution, kind still REML; fit-level comparator debt
retained; Rose stays NOT CLEAN."
Blocked: preGSf90 AGREE / blupf90+ ssGBLUP parity; re-badging AGHmatrix
as fit; `V2-SSHINV` covered; count 8; 0.8.0; 1.0 / CRAN; Rose CLEAN;
Darwin SIGN.

## Checks this slice

```sh
# laptop
command -v preGSf90; command -v 'blupf90+'; command -v airemlf90; command -v renumf90
# all empty (2026-09-03)
mdfind -name preGSf90; mdfind -name 'blupf90+'
# empty

# Totoro via live ControlMaster
ssh -o BatchMode=yes -o ConnectTimeout=15 totoro \
    'command -v preGSf90; command -v blupf90+; command -v airemlf90; command -v renumf90;
     find /opt /usr/local /usr /home /opt/software ~/apps ~/local ~/hsq_work -maxdepth 5 \
       \( -iname preGSf90 -o -iname "blupf90+" -o -iname blupf90 -o -iname airemlf90 -o -iname renumf90 \) -type f'
# HOST=totoro; binaries absent; find empty; module absent
```

No `Pkg.test` / Documenter this slice (docs-only; no `src/` change).

## Tests of the tests

n=240 TSV/log and freeze SHA `8e6e038b` were re-read, not re-run. This
slice does not change the 48/48 bar or the driver.

## Coordination notes

Lease `cursor:hsquared` (fallback identity; intended
`cursor:08-ss-g5-disclosure-20260903`) on the three new files only.
`capability-status.md` stays with `cursor:g5-stale-copy-20260903`.
Board / `validation_status.jl` not touched so those slices do not collide.

## What did not go smoothly

A directory-wide docs lease would have been refused (expected). Narrowed
to unique filenames. Totoro socket was live (dated 31 Aug) and attached
without Duo. Dropbox checkout is on a different branch; this slice wrote
only in the SS worktree.

## Known limitations

Disclosure satisfies §3 #2’s substitution clause only. AGHmatrix remains
**construction AGREE**, not a fit-level second tool. Rose packet remains
unwritten / **NOT CLEAN**.

## Next

Other §3 blockers stay open (Darwin SIGN, Boole freeze, derived h²
identity, R element-wise catch-up). A **new** Rose packet on the tip
that carries those artifacts — this after-task is not that re-audit.
No auto-flip.
