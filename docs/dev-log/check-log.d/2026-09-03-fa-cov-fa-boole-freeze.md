# 2026-09-03 — Boole `cov=fa` freeze (S4-scoped)

**Not a covered flip.** `V4-FA` stays partial. Count stays **7**.
Experimental **0.7.0**.

## What

Boole freeze of FA argument names + engine-control auto-routing, scoped to
the S4 `d4-k1` cell (`t=4`, `K=1`). Canonical:
`docs/design/54-fa-grammar-freeze.md`.

Formula `cov = fa(K = k)` is a **name** freeze. The R parser still rejects
`cov`. The R bridge still rejects `"factor_analytic"` / `rank`.

## Checks

Docs only. No engine test run this slice (no `src/` change). Prior S4
evidence remains `d8148a3a` / TSV
`docs/dev-log/recovery-checkpoints/2026-09-03-v08-s4-fa-d4-k1.tsv`.
