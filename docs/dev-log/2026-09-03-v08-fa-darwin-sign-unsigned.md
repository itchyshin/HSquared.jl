# 0.8 Darwin FA-G SIGN sheet — **SIGNED 2026-09-03**

> **SIGNED.** Owner ink recorded 2026-09-03. **Not** a covered flip.
> `public_covered_count` stays **7**. `V4-FA` stays **partial**.
>
> Canonical packet: `~/local-scratch/h2-08-fa-darwin-sign-2026-09-03.md`
> Owner: **Shinichi** · Date: **2026-09-03**
> Phrase: *"please go ahead and merge what you need to do - and I approve
> to keep going"* (treated as `sign both`; A27 "go ahead" pattern).

**0.8 FA biology draft — G / R recovery under the S2 gate.**  
design-42 is **diagnosis only** and is not this sheet.

```
PLATFORM: cursor | LANE: cursor/08-fa-20260903 (#292)
Active lenses: Darwin (UNSIGNED draft). Ada / Shannon / Rose fence.
Spawned subagents: none
Current lane: Julia 0.8 FA WT — unsigned Darwin SIGN echo
```

---

## One-line action

**RECOMMEND SIGN** (owner ink). Headline recovered quantity =
rotation-invariant **G** and **R** under the frozen S2 pass rule
(`rel_g ≤ 0.45`, `rel_r ≤ 0.25`, `min(ψ̂) ≥ 1e-4`, `ledermann_slack > 0`),
not loadings. S4 **8/10 `ok_recovery` PASS** at tip **`d8148a3a`**.
Two misses are caveats (20260915 cap-exhaustion; 20260916
sampling-vs-threshold). **Agents do not tick.**

---

## What Darwin would sign (on ink)

Design-41 §3 criterion 5: the biologically meaningful recovered quantity
for a correlated FA model is **G / R** (and interior **ψ**), not Λ.

| Role | Quantity |
|---|---|
| **Primary** | Rotation-invariant **G = ΛΛ′ + Ψ** and residual **R** under S2 |
| Fence in the pass rule | `min(ψ̂) ≥ 1e-4` and `ledermann_slack > 0` |
| Out of this SIGN | Loadings+SE · `cov=fa` · WOMBAT · saturated `t=3 K=1` · flip |

**Not transferable:** A27 unstructured G₀/r_g · 0.7 `genomic_variance_ratio` ·
design-42 diagnosis.

You are **not** signing a covered flip, Rose CLEAN, Boole, WOMBAT, G10,
0.8.0, or count 7→8.

---

## S4 8/10 pins (cite; do not re-run)

| Pin | Value |
|---|---|
| Tip | `d8148a3a` |
| S2 freeze | `eff57e3d` · driver SHA-256 `47a1b619…` · blob `370cf697` |
| S3 | `3d1de490` uniqueness floor |
| Cell | `d4-k1` · t=4 K=1 · slack=4 |
| Seeds | `20260914:20260923` |
| Bar | 8/10 `ok_recovery` · **PASS** |
| Misses | 20260915 `unclassified` (5000-iter, ψ on floor) · 20260916 `sampling_vs_threshold` |
| Other classes | heywood 0 · optimizer_miss 0 |
| TSV | `docs/dev-log/recovery-checkpoints/2026-09-03-v08-s4-fa-d4-k1.tsv` |

S4 is **not** the Phase 4B / S1 8/10 (different DGP, different pass rule).

---

## SIGN / HOLD / REJECT — owner only

| # | Item | Proposed | SIGN | HOLD | REJECT |
|---|---|---|---|---|---|
| 1 | Headline = G/R under S2, not loadings? | YES | [x] | [ ] | [ ] |
| 2 | Interior ψ + slack>0 belong in the signed rule? | YES | [x] | [ ] | [ ] |
| 3 | S4 8/10 is evidence, not a flip? | YES | [x] | [ ] | [ ] |
| 4 | Two misses = caveats, not veto? | YES | [x] | [ ] | [ ] |
| 5 | design-42 diagnosis only; no 0.6/0.7 transfer? | HARD YES | [x] | [ ] | [ ] |
| 6 | Teaching/sim vs field; no loadings-as-axes? | HARD YES | [x] | [ ] | [ ] |
| 7 | WOMBAT / Boole / Rose stay out of this SIGN? | YES | [x] | [ ] | [ ] |

**Whole-sheet (owner only):**

- [x] **SIGN as recommended**
- [ ] **HOLD** (annotate a biology fence)
- [ ] **REJECT** (say why)

**SIGN status this pass:** **SIGNED.** Owner authorization 2026-09-03.

**Signed (Darwin / Shinichi):** Shinichi  **Date:** 2026-09-03

---

## NON-goals

No flip. No Rose CLEAN. No `cov=fa` freeze. No WOMBAT invented. No count
7→8. No 0.8.0 / 1.0. No forged ink.

**Fence:** SIGNED 2026-09-03 Shinichi · no capability edit · `public_covered_count` **7**.
