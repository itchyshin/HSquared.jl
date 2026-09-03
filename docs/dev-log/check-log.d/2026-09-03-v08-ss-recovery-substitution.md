# 2026-09-03 — 0.8 SS second-comparator honesty (preGSf90 / blupf90+ absent)

**Not a covered flip.** `V2-SSHINV` stays partial. Count stays **7**. Experimental **0.7.0**.
Rose stays **NOT CLEAN**. AGHmatrix remains **construction AGREE only**.

## Commands

```sh
# laptop PATH
command -v preGSf90; command -v 'blupf90+'; command -v blupf90; command -v airemlf90; command -v renumf90
# all empty (2026-09-03)
mdfind -name preGSf90; mdfind -name 'blupf90+'
# empty

# Totoro (ControlMaster, 2026-09-03 ~12:31Z UTC)
ssh -o BatchMode=yes -o ConnectTimeout=15 totoro \
    'hostname; command -v preGSf90; command -v blupf90+; command -v airemlf90; command -v renumf90;
     find /opt /usr/local /usr /home /opt/software ~/apps ~/local ~/hsq_work -maxdepth 5 \
       \( -iname preGSf90 -o -iname "blupf90+" -o -iname blupf90 -o -iname airemlf90 -o -iname renumf90 \) -type f'
# HOST=totoro; binaries not found; find empty; module absent
```

Recovery evidence used, not re-run: freeze `8e6e038b`, PASS recorded at `0533e9da`,
branch tip at write `6f8e851b` (Darwin unsigned sheet),
48/48 GATE PASS
(`docs/dev-log/recovery-checkpoints/2026-09-03-v08-ss-n-recovery-gate-predeclaration.md`).

Construction evidence used, not re-run: AGHmatrix 3.0.1 Martini τ=ω=1,
`max|Hinv Δ| = 4.24e-12`, `COMPARATOR: AGREE`
(`comparator/aghmatrix_hmatrix/result.txt`).

## Outcome

`preGSf90` / `blupf90+` **absent** (laptop + Totoro). No AGREE path.
Written substitution:
`docs/dev-log/decisions/2026-09-03-v08-ss-recovery-substitution-disclosure.md`

Kind still REML. Fit-level / second-construction comparator debt retained.
No capability-row edit.
