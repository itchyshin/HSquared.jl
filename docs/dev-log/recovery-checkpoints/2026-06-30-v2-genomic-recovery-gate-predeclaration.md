# Pre-declaration — V2-GREML genomic bias/MCSE recovery gate (doc-33 path-b)

Status: **PRE-DECLARED, to be committed BEFORE the run** (no post-hoc relaxation; 2026-06-14 rule).
This is the substitutable-gate candidate that — together with the executed BLUPF90 same-estimand
comparator (`2026-06-30-v2-genomic-blupf90-comparator.md`, PR #200) — would support a `V2-GREML`
covered close (still gated on a real Rose audit + maintainer **G10**; a covered promotion is the
maintainer's non-delegable, atomic call). Mirrors the V3-TWOEFFECT-REML gate
(`2026-06-30-v3-two-effect-recovery-gate-predeclaration.md`).

## Estimator + DGP

`fit_gblup_reml(y, X, Z, Ginv)` on `y = μ + u + e`, `u ~ N(0, K·σ²g)`, `e ~ N(0, I·σ²e)`.

- **N = 300** individuals, **M = 1000** biallelic markers, allele frequencies `~ U(0.1, 0.9)` drawn
  **fresh per seed** (so the relationship structure `G` varies across seeds — the gate averages over
  genomic structures, not one fixed `G`).
- VanRaden `G` (method 1); **`K = G + ridge·I`** with `ridge = 0.01`; **`Ginv = inv(K)`**.
- Breeding values `u ~ N(0, K·σ²g)` are drawn with `chol(K)`, so the supplied `Ginv` is **exactly** the
  model covariance and **`σ²g` is the exact estimand** (no model misspecification).
- Truth `(σ²g, σ²e) = (0.6, 0.4)`, `μ = 2.0`, **`h² = 0.6`**. Harness: `sim/phase2_genomic_reml_recovery.jl`.

**Scope of the gate (declared up front).** This tests the REML **estimator on a supplied genomic
precision matrix** — exactly what `V2-GREML` claims. It does **NOT** test the marker→`G` construction
or ridge realism (whether a ridged VanRaden `G` recovers the TRUE marker-based additive variance) —
that is `V2-GRM`/`V2-GBLUP` G-construction parity, deliberately out of scope. Same posture as the
two-effect / V4-MV gates: simulate from the exact model, check the estimator recovers truth.

## Seeds (UNSEEN at declaration)

48 cold-start seeds **20260800 .. 20260847** — disjoint from the comparator seed (20260630) and the
two-effect gate's (20260700..20260747), so no result is observed before this gate is fixed.

## PASS criteria (ALL required; fixed here, not adjustable after seeing results)

1. **Convergence:** 48/48 seeds converge.
2. **No detectable bias:** `|bias| ≤ 2·MCSE` for EACH of **σ²g, σ²e, h²**, where `bias = mean(θ̂) − truth`
   and `MCSE = sd(θ̂)/√48`. (h² is the headline estimand and a ratio, so it is gated explicitly, not just
   implied by the two VCs.)

## Interpretation (declared in advance)

- **PASS** = NO DETECTABLE across-seed bias — a low-power non-rejection, read as "consistent with an
  unbiased estimator," NEVER as "unbiased" (same honest framing as V3/V4).
- **FAIL** = a banked NEGATIVE. `V2-GREML` stays `partial`; the result is recorded honestly (e.g. a small
  finite-sample REML bias, or a ridge-induced σ²g offset), and the covered close does NOT proceed on this
  gate. NO relaxation of the criteria.
- Either way: `validation_status()` count, public-covered fitting = 1, and the comparator evidence (PR #200)
  are unaffected by the gate OUTCOME; only a PASS + Rose + G10 would move the row to covered.

## RESULT (run 2026-06-30, AFTER the predeclaration commit `cb22e679`) — **GATE: PASS**

`sim/phase2_genomic_reml_recovery.jl`, 48 seeds 20260800..20260847, julia 1.10.0,
`JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1`:

| component | mean | truth | bias | MCSE | \|bias\|/MCSE | verdict |
|---|---|---|---|---|---|---|
| σ²g (genomic additive) | 0.5908 | 0.60 | −0.0092 | 0.0222 | 0.41 | PASS |
| σ²e (residual) | 0.4061 | 0.40 | +0.0061 | 0.0192 | 0.32 | PASS |
| h² | 0.5902 | 0.60 | −0.0098 | 0.0195 | 0.50 | PASS |

**48/48 converged; all three `|bias| ≤ 2·MCSE` → GATE PASS.** Read as NO DETECTABLE across-seed bias —
**never "unbiased"**: σ²g sits −1.5% (0.41·MCSE) below truth and h² −1.6% (0.50·MCSE, the largest
standardized residual), consistent with small-sample REML behaviour (the same honest reading as
V3-TWOEFFECT-REML's σ1² and V4-MV-REML's G[1,1]). The downward σ²g tilt is the expected REML
finite-sample direction, within tolerance.

**Consequence:** `V2-GREML` now has BOTH doc-18-§priority-3-owed pieces — this pre-declared bias/MCSE
gate (PASS) + the executed `blupf90+` 2.60 same-estimand comparator
(`2026-06-30-v2-genomic-blupf90-comparator.md`, PR #200). It is **covered-READY**. The
`partial → covered` promotion is the maintainer's non-delegable, atomic **G10** (a separate promotion PR);
this run does NOT flip the status. SCOPE OF VALIDITY: supplied-`Ginv` REML estimator, exact-model recovery,
N=300 single design point — G-construction parity (`V2-GRM`), broader N/M/h² designs, and the `sommer`
2nd REML leg remain owed even after a covered close.
