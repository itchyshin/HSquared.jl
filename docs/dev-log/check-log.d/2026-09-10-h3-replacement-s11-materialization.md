# H3 replacement S11 materialization — 2026-09-10

Candidate `codex/hsq09-h3-s11-authorized-20260910` is based on the sealed
refusal template `9e226a08`. The ratified replacement manifest specifies
separate fresh seed ranges for `r_g` and `r_am`, 2,000 requested seeds each,
an `interval_success` floor of 1,800 each, and a per-estimand binomial-MCSE
classification band. It locks the existing H3 S10 receipt identities and the
new driver/launcher hashes.

Local controls passed: closed-schema manifest plus five mutation controls,
driver load, retained-row reconciliation including a failure-retention
mutation, and seven Narval launcher assertions. Full `Pkg.test()` exited zero
with the S11 controls registered. This is implementation and local validation,
not a pre-run or campaign receipt.

The live DRAC status wrapper found existing sockets but reported them unusable;
no fresh SSH login was attempted and no `sbatch` command was submitted. G3 and
G4 remain deliberately unmet until an existing Narval control socket is usable
and the authorized pre-run then arrays can retain their own receipts.
