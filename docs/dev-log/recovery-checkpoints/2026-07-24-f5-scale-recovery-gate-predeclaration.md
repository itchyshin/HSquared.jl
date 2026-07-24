# F5 — PRE-DECLARED production-scale recovery + correctness gate (Wave F, Track A)

**2026-07-24 · pre-registration, committed BEFORE the gate runs.** Promotes NOTHING.
`public_covered_count` stays 5. A staged experimental→(production-default) declaration for the
sparse single-effect AI-REML fitter (`fit_ai_reml`) additionally requires the F8 same-estimand
comparator (`sommer`), a REAL spawned Rose audit (G8), and the maintainer's sign-off (G10). A
failure is a **banked negative**, never a post-hoc relaxation.

Gate script: `sim/phase_f5_scale_recovery_gate.jl` (frozen at the commit that carries this note).
Canonical run has **NO env var set**; `HSQ_F5_SMOKE=1` is a smoke-only toy-size override that does
not change any pre-declared parameter (the pre-declared values are the defaults).

## Estimand + truth
Phase-1 Gaussian animal model, `Z = I_n`, one record per animal. Truth **(σ²a, σ²e) = (1.0, 1.5)**
→ h² = 0.4, μ = 2.0. Interior, off-boundary (no σ→0). Estimator under test: `fit_ai_reml` (sparse
Henderson MME + CHOLMOD + Takahashi selected inverse), cold-started at (0.8, 0.8).

## Legs (all pre-declared; ALL must pass; no post-hoc relaxation)

**Leg A — recovery AT SCALE (the headline).** q = **100,000**, non-inbred half-sib pedigree
(disjoint unrelated sire/dam founder pools → F ≡ 0 by construction), so O(n) gene-dropping with
Mendelian-sampling variance 0.5·σ²a gives Cov(u) = σ²a·A **exactly**. 48 cold-start seeds
**20268000..20268047**. PASS: 48/48 converged **AND** across-seed **mean relative error ≤ 5%**
for σ²a **AND** σ²e. This is a **recovery** criterion, not a bias/MCSE non-rejection: at q=1e5 the
per-seed estimate is so precise that MCSE→0 and a `|bias| ≤ 2·MCSE` test would fail on a
scientifically negligible bias (the large-n MCSE trap). Unbiasedness is tested at moderate n in
Leg B, where MCSE is well-scaled.

**Leg B — DEEP pedigree (the >12-generation gap).** 15 discrete generations, 60-founder base →
genuine accumulating inbreeding; n ≈ **4,500**. Exact covariance via the dense Cholesky of
A = inv(Ainv) (u = √σ²a · chol(A).L · z), so the target is exact **regardless of inbreeding**.
48 seeds **20268100..20268147**. PASS: 48/48 converged **AND** |bias| ≤ 2·MCSE for σ²a **AND** σ²e.

**Leg C — BOUNDARY (the σ²→0 gap).** Near-constant y (no additive signal) at n = 2,000 must
terminate GRACEFULLY: `converged = false`, finite non-NaN variance components, **never** a throw
or NaN garbage (the #182 graceful-boundary contract). 8 seeds **20268200..20268207**. PASS: 8/8
graceful.

**Correctness cross-check X — eigen ≈ AI-REML.** At n = 2,000 (both estimators feasible), the
one-factorization eigen fitter and sparse AI-REML must AGREE on identical data to ≤ **1e-6** for
σ²a **AND** σ²e (independent-route corroboration; the dense-inverse == selected-inverse identity
is already covered in `test/runtests.jl`). 8 seeds **20268300..20268307**.

## Overall GATE = A ∧ B ∧ C ∧ X

Read as: **no detectable across-seed bias at production scale** (a low-power non-rejection) — never
worded "unbiased". The claim wording, if the gate passes and Rose clears, is scoped to the
**low-fill regime** per the F0 finding (`2026-07-24-f0-adversarial-highfill-decision.md`): the
high-fill, n > 20,000 tail is an explicit documented boundary (F6 = wire the existing PCG, deferred).

## Seeds — disjointness
Seeds 20268000–20268307 are freshly allocated for this gate, disjoint from the eigen gate
(20267000–20267147) and all prior gates; UNSEEN at declaration time.
