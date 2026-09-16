# 2026-09-03 — 0.8 FA WOMBAT recovery-substitution disclosure

**Not a covered flip.** `V4-FA` stays partial. Count stays **7**. Experimental **0.7.0**.
Rose stays **NOT CLEAN**.

## Commands

```sh
# laptop PATH
command -v wombat; command -v WOMBAT; command -v wombat64
# all empty (2026-09-03)

# Totoro (ControlMaster, 2026-09-03T12:23:33Z UTC)
ssh -o ControlMaster=no \
    -o ControlPath="$HOME/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22" \
    -o BatchMode=yes -o ConnectTimeout=15 totoro \
    'hostname; command -v wombat; command -v WOMBAT; type wombat WOMBAT;
     find ~ /opt /usr/local /home -maxdepth 4 -iname "*wombat*"'
# HOST=totoro; wombat/WOMBAT not found; find empty; module absent
```

S4 evidence used, not re-run: tip `d8148a3a`, fit SHA `3d1de490`,
8/10 `ok_recovery` PASS
(`docs/dev-log/recovery-checkpoints/2026-09-03-v08-s4-fa-d4-k1.md`).

## Outcome

WOMBAT **absent** (laptop + Totoro). No AGREE path. Written substitution:
`docs/dev-log/decisions/2026-09-03-v08-fa-recovery-substitution-disclosure.md`

Kind still REML. Comparator debt retained. No capability-row edit.
