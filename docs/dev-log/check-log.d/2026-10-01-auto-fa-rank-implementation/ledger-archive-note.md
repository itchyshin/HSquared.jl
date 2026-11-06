# Ledger provenance

The original combined full-check leaf is retained verbatim as full-check-original-ledger.archive.txt. It was split into julia-full-GATES.md (G5) and r-full-GATES.md (G6) before execution. The canonical eight-gate ledger still requires both outcomes. The R leaf now binds the exact current Julia project and retains complete check logs. No acceptance requirement was removed or abandoned.

The canonical eight-gate ledger consolidates child receipts and remains open. Child approval records bind their own ledger paths; copied root evidence is not a claim that the root CHECK has already been re-executed under a root approval. Final root replay is required at programme close.

## Consolidated child-ledger archive

Only `.unlazy/auto-fa-rank-implementation-20261001/GATES.md` is the active eight-gate ledger. The child ledgers below were copied byte-for-byte to `ledgers/receipts/` and removed from active `*-GATES.md` names to prevent duplicate suite replay. Their original SHA256 is also the archive SHA256. The G1-G6 CHECK commands in the active root are copied byte-for-byte from the listed child ledger; G7/G8 remain open.

- `engine-GATES.md` → `ledgers/receipts/engine-GATES.archive.txt`; gates G1, G2; original/archive SHA256 `7401beac49920852b2c79306434fa0b3748870b89f1307c9491240c70b951d06`; approval receipt(s): 7e784b64338235319a3c027e85a55d2ae07404fffcdfd36608b1a88decd5e0fd.json, 93613d53e1ebd815559360296b40e0dce252ecebe81dc29f4c80e4cf1253dbdd.json; execution receipt: `engine-gate-final.log`.
- `r-GATES.md` → `ledgers/receipts/r-GATES.archive.txt`; gates G3, G4; original/archive SHA256 `9f006296e63ce383fb26ad0408a118a9f9da75a168150fbf61a7ad651e022921`; approval receipt(s): cd574b3aaa1988dbb3a26a87fbb3895089c1e54eb57617b574a5ddab8e572d0e.json, d048aab069861a066742767750aad1f04e5b0702638f3f6491493b4d7b1d009c.json; execution receipt: `r-gate-final.log`.
- `julia-full-GATES.md` → `ledgers/receipts/julia-full-GATES.archive.txt`; gates G5; original/archive SHA256 `041e8c08181efeb15422170dba078ff678aa9a2e10ab895b636338440e320582`; approval receipt(s): 6d1b1da456ead8a26f4f999d38a3350e83bdbf929bd0600d52af6350174cd0df.json; execution receipt: `julia-full-gate-final.log`.
- `r-full-GATES.md` → `ledgers/receipts/r-full-GATES.archive.txt`; gates G6; original/archive SHA256 `5d2c51b5a228cf55c5fd1d2987a2bdd89e09f6eccae2058203cf768c7288df05`; approval receipt(s): 3125e78a0fef8e368e683c41e68eccb51b3dcf51e1090de2523bf0caf3c1c33a.json; execution receipt: `r-full-gate-final.log`.

The consolidated snapshot at `docs/dev-log/check-log.d/2026-10-01-auto-fa-rank-implementation/GATES.md` mirrors the active root ledger and is documentary only; do not replay it. Root final replay remains the sole active acceptance execution.
