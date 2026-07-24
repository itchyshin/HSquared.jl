# Result — F5 v2 (corrected) production-scale recovery gate

**2026-07-24 · Totoro (julia 1.12.6, single-thread) · v2 gate frozen at `4fb6fb66` BEFORE running ·
OPT-IN, NOT CI · promotes NOTHING; `public_covered_count` stays 5.**

## Relationship to v1 (full transparency — no relaxation)
The v1 gate (`77ecad3a`) remains a **BANKED NEGATIVE** (`2026-07-24-f5-scale-recovery-gate-result.md`)
— that record stands untouched. v2 is a **fresh, correctly-specified re-declaration**, not a re-scoring
of v1's data: fresh disjoint seeds (20268500–20268807), frozen before running, correcting the
demonstrably-wrong Leg-C criterion. The recovery legs (A relative ≤5%, B |bias|≤2·MCSE) are UNCHANGED.

**What changed and why:** v1's Leg C required `converged=false` at the σ→0 boundary. A per-seed
diagnostic proved that with near-constant y the fitter **correctly** converges to a finite,
non-throwing, near-zero σ²≈1e-14 — the actual #182 contract (no throw, no NaN, finite, non-negative).
v1's criterion rejected correct behaviour. v2's Leg C tests the **actual contract** (finite ·
non-throwing · non-negative; convergence not required), so it accepts BOTH a graceful stop AND a
converge-to-valid-tiny-σ², while still failing on a throw / NaN / negative variance.

## Verdict: **PASS** (A ∧ B ∧ C ∧ X) — from `sim/drac/results/f5_gate_v2.log`

`GATE_JSON {"gate_pass":true,"version":"v2-corrected","A":{"rel_sa":0.00195,"rel_se":0.00065,...},...}`

| Leg | Criterion (pre-declared v2) | Result | |
|---|---|---|---|
| **A** recovery at q=100,000 | 48/48 conv AND mean rel.err ≤ 5% | σ²a **0.19%**, σ²e **0.065%**, 48/48 | **PASS** |
| **B** deep pedigree (15-gen, n≈4500) | 48/48 conv AND \|bias\| ≤ 2·MCSE | σ²a \|bias\|/MCSE **1.12**, σ²e **0.55**, 48/48 | **PASS** |
| **C** boundary (finite·non-throwing·non-neg) | 8/8 graceful | **8/8** — 4 converge to a valid tiny σ²≈1e-14, 4 stop gracefully (σ²e≈0.01); all finite, non-negative | **PASS** |
| **X** eigen ≈ AI-REML (n=2000) | ≤ 1e-6 | **1.18e-7** | **PASS** |

The corrected Leg C's per-seed detail makes the point concrete: the 8 boundary seeds split **4
(conv=true, σ²a≈1e-14) / 4 (conv=false, graceful stop)** — exactly the two honest, finite, non-throwing
behaviors that v1's `converged=false` criterion had conflated into a spurious failure. No recovery
criterion was loosened — Legs A and B use v1's identical thresholds, on fresh seeds.

## What this means
The **pre-declared recovery-at-scale gate PASSES** on the corrected specification: `fit_ai_reml`
recovers truth at **q=100,000** (0.19%/0.065%, 48/48), is unbiased on a deep 15-generation inbred
pedigree (all |bias| ≤ 2·MCSE), matches the eigen fitter to **1.18e-7**, and is graceful at the σ→0
boundary (8/8). With the F8 `sommer` comparator (AGREE 3.6e-5) and the F0 scale characterization, the
evidence package is **complete**. It still promotes NOTHING — a production-default flip owes maintainer
G10 + the R bridge; scope stays the low-fill regime (the high-fill n>20k tail is the documented,
deferred F6 follow-on).

> Related: `2026-07-24-f5-scale-recovery-gate-v2-predeclaration.md` · v1 (banked negative)
> `2026-07-24-f5-scale-recovery-gate-result.md` · `2026-07-24-f8-sommer-aireml-comparator.md` ·
> `2026-07-24-f0-adversarial-highfill-decision.md`.
