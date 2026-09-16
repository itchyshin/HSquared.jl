# 2026-09-03 — Boole freeze: `cov = fa` / `factor_analytic` (S4-scoped)

**Status: BOOLE-FROZEN · NOT a covered flip · maintainer nod still pending.**

Canonical text: `docs/design/54-fa-grammar-freeze.md`.

S4 PASS (`8/10 ok_recovery` at `d8148a3a`, cell `d4-k1`) is recovery
evidence, not a grammar. Design-38 covers unstructured 2-trait `cbind()`
only. This decision freezes the FA **names and engine-control route** that
S4 actually used, so a later flip cannot invent a different spelling.

Frozen:

- `genetic_structure = :factor_analytic` and `rank = K`
- `G0 = ΛΛ' + Ψ`, unstructured `R0`
- planned formula constructor `fa(K = k)` (parser still rejects `cov`)
- covered-claim cell, if a later packet flips: `t = 4`, `K = 1`, slack `> 0`

Still draft: R `cov =` parser, default-path auto-route, R bridge
activation, `K > 1`, residual FA, loadings as identified axes.

`V4-FA` stays **partial**. Count stays **7**. Experimental **0.7.0**.
No 1.0 / CRAN. Rose CLEAN is not this file.
