# F5 v2 — PRE-DECLARED production-scale recovery gate (CORRECTED re-declaration)

**2026-07-24 · pre-registration, committed BEFORE the v2 gate runs.** Promotes NOTHING;
`public_covered_count` stays 5.

## Why v2 exists (full transparency)
The v1 gate (`sim/phase_f5_scale_recovery_gate.jl`, frozen `77ecad3a`) is a **BANKED NEGATIVE** and
stays so — see `2026-07-24-f5-scale-recovery-gate-result.md`. Legs A (recovery @ q=1e5, 0.49%), B
(deep unbiasedness), X (eigen≡AI 3.4e-7) PASSED; **Leg C failed 6/8**. A per-seed diagnostic proved
this was a **test-design flaw, not a `fit_ai_reml` defect**: v1's Leg C required `converged=false` at
the σ→0 boundary, but with near-constant y the fitter **correctly** converges to a finite,
non-throwing, near-zero σ²≈1e-14 — the actual #182 boundary contract (no throw, no NaN, finite,
non-negative). v1's criterion rejected correct behaviour.

**v2 is a fresh, correctly-specified re-declaration — NOT a post-hoc relaxation of v1.** The
distinction: v1's banked negative stands untouched; v2 runs on **fresh disjoint seeds**
(20268500–20268807), frozen BEFORE running, and its Leg C tests the **actual** boundary contract.
The recovery criteria (Leg A relative ≤5%, Leg B |bias|≤2·MCSE) are **UNCHANGED** — they passed
legitimately in v1 and are not touched. Only the demonstrably-wrong Leg-C condition (`converged=false`)
is corrected.

## Estimand + truth
Phase-1 Gaussian animal model, `Z=I`. Truth **(σ²a, σ²e) = (1.0, 1.5)** → h²=0.4, μ=2.0. Estimator:
`fit_ai_reml`, cold-start (0.8, 0.8).

## Legs (all pre-declared; ALL must pass; no post-hoc relaxation)
- **A — recovery AT SCALE.** q=100,000 non-inbred half-sib gene-drop (F≡0 exact). 48 seeds
  **20268500..20268547**. PASS: 48/48 converged AND mean rel.err ≤ 5% for σ²a AND σ²e.
- **B — DEEP pedigree.** 15 generations, exact chol(A) cov, n≈4500. 48 seeds **20268600..20268647**.
  PASS: 48/48 converged AND |bias| ≤ 2·MCSE for σ²a AND σ²e.
- **C — BOUNDARY (corrected).** Near-constant y at n=2000. 8 seeds **20268700..20268707**. PASS:
  8/8 **graceful = no throw AND finite σ²a,σ²e AND both ≥ 0** (the #182 contract). **Convergence is
  NOT required** — converging to a valid tiny σ² is correct boundary behaviour.
- **X — correctness.** eigen ≈ AI-REML ≤ 1e-6 at n=2000. 8 seeds **20268800..20268807**.

## GATE = A ∧ B ∧ C ∧ X
A failure is a banked negative. Recovery read as "no detectable / small-relative-error recovery at
production scale", never "unbiased". Scope stays the low-fill regime (F0 finding); the high-fill
n>20k tail is a documented boundary + the deferred F6 follow-on.
