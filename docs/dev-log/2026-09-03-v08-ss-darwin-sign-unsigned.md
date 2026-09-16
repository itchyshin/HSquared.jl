# 0.8 Darwin single-step SIGN sheet — **SIGNED 2026-09-03**

> **SIGNED.** Owner ink recorded 2026-09-03. **Not** a covered flip.
> `public_covered_count` stays **7**. `V2-SSHINV` stays **partial**.
>
> Canonical packet: `~/local-scratch/h2-08-ss-darwin-sign-2026-09-03.md`
> Owner: **Shinichi** · Date: **2026-09-03**
> Phrase: *"please go ahead and merge what you need to do - and I approve
> to keep going"* (treated as `sign both`; A27 "go ahead" pattern).

**0.8 single-step biology draft — σ²a / σ²e on constructed H.**
n=240 GATE PASS at freeze `8e6e038b` is evidence, not a flip.

```
PLATFORM: cursor | LANE: cursor/08-ss-20260903 (#295)
Active lenses: Darwin (UNSIGNED draft). Ada / Shannon / Rose fence.
Spawned subagents: none
Current lane: Julia 0.8 SS WT — unsigned Darwin SIGN echo
```

---

## One-line action

**RECOMMEND SIGN** (owner ink). Headline recovered quantity =
additive **σ²a** and residual **σ²e** on constructed single-step **H**
(Martini/Aguilar defaults; `G = A₂₂ + 0.05 I`, not VanRaden), not
pedigree-only `A` and not genomic-only `G`. n=240 **48/48 GATE PASS**
at freeze **`8e6e038b`** (σ²a 0.86·MCSE; σ²e 0.89·MCSE). **h²**
reported, not gated. **Agents do not tick.**

---

## What Darwin would sign (on ink)

Design-41 §3 criterion 5: the biologically meaningful recovered
quantity for ordinary single-step is **H-scale σ²a / σ²e**, not
pedigree h² and not `genomic_variance_ratio`.

| Role | Quantity |
|---|---|
| **Primary** | **σ²a** and **σ²e** under `fit_single_step_reml` on constructed **H** (`G ≠ A₂₂`; τ=ω=1, blend=ridge=0) |
| DGP fence | Teaching kernel `G = A₂₂ + 0.05 I` (same estimand as AGHmatrix Hmatrix) |
| Out of this SIGN | VanRaden · metafounder `H^Γ` · APY · field ssGBLUP · h² as covered · flip |

**Not transferable:** 0.7 `genomic_variance_ratio` · 0.8 FA G/R ·
AGHmatrix construction AGREE as fit parity.

You are **not** signing a covered flip, Rose CLEAN, Boole, G5, G10,
0.8.0, or count 7→8.

---

## n=240 48/48 pins (cite; do not re-run)

| Pin | Value |
|---|---|
| Tip | `0533e9da` |
| Freeze | `8e6e038b` · driver SHA-256 `c010249bf46c2824b2c576137731b629b7e3c1da1a33de99c943997e05bd3d86` |
| Cell | n=240 · last-gen 50% geno · `G = A₂₂ + 0.05 I` · τ=ω=1 |
| Seeds | `20265000:20265047` |
| Bar | 48/48 converged · σ²a / σ²e `|bias| ≤ 2·MCSE` · **PASS** |
| σ²a | 1.0441 vs 1.00 · +0.0441 / 0.0516 · 0.86·MCSE |
| σ²e | 1.4586 vs 1.50 · −0.0414 / 0.0466 · 0.89·MCSE |
| h² | 0.4147 vs 0.40 · 0.79·MCSE · **not a PASS object** |
| Checkpoint | `docs/dev-log/recovery-checkpoints/2026-09-03-v08-ss-n-recovery-gate-predeclaration.md` |

n=6 smoke is an unidentified dump, not this gate.

---

## SIGN / HOLD / REJECT — owner only

| # | Item | Proposed | SIGN | HOLD | REJECT |
|---|---|---|---|---|---|
| 1 | Headline = σ²a / σ²e on H, not A-only or G-only? | YES | [x] | [ ] | [ ] |
| 2 | Teaching `G = A₂₂ + 0.05 I`; VanRaden / field out? | YES | [x] | [ ] | [ ] |
| 3 | 48/48 at `8e6e038b` is evidence, not a flip? | YES | [x] | [ ] | [ ] |
| 4 | h² reported-not-gated, not the headline? | YES | [x] | [ ] | [ ] |
| 5 | No 0.7 / FA ink transfer? | HARD YES | [x] | [ ] | [ ] |
| 6 | Teaching/sim vs field; no “genomic heritability”? | HARD YES | [x] | [ ] | [ ] |
| 7 | G5 / Boole / Rose stay out of this SIGN? | YES | [x] | [ ] | [ ] |

**Whole-sheet (owner only):**

- [x] **SIGN as recommended**
- [ ] **HOLD** (annotate a biology fence)
- [ ] **REJECT** (say why)

**SIGN status this pass:** **SIGNED.** Owner authorization 2026-09-03.

**Signed (Darwin / Shinichi):** Shinichi  **Date:** 2026-09-03

---

## NON-goals

No flip. No Rose CLEAN. No `single_step()` freeze. No G5 invented. No
count 7→8. No 0.8.0 / 1.0. No forged ink.

**Fence:** SIGNED 2026-09-03 Shinichi · no capability edit · `public_covered_count` **7**.
