# Pre-declaration — V3-TWOEFFECT-REML bias/MCSE recovery gate (doc-33 path-b)

Status: **PRE-DECLARED, committed BEFORE the run** (no post-hoc relaxation; 2026-06-14 rule). This is the
substitutable-gate candidate that — together with the executed BLUPF90 same-estimand comparator
(`2026-06-30-v3-two-effect-blupf90-comparator.md`, PR #195) — would support a `V3-TWOEFFECT-REML`
covered close (still gated on a real Rose audit + maintainer **G10**; a covered promotion is the
maintainer's non-delegable, atomic call).

## Estimator + DGP

`fit_two_effect_reml` on `y = μ + u1[animal] + u2[group] + e`, `u1 ~ N(0, A·σ1²)` (additive, pedigree A),
`u2 ~ N(0, I·σ2²)` (common-environment group, assigned INDEPENDENTLY of the pedigree), `e ~ N(0, I·σe²)`.
Half-sib q=860 (20 sires / 40 dams / 800 offspring), 80 groups. Truth `(σ1²,σ2²,σe²) = (1.0, 0.5, 1.0)`,
`μ = 2.0`. Harness: `sim/phase3_two_effect_bias_mcse.jl` (same DGP as the recovery harness
`sim/phase3_two_effect_recovery.jl`, aggregated across seeds).

## Seeds (UNSEEN at declaration)

48 cold-start seeds **20260700 .. 20260747** — deliberately disjoint from the recovery harness's seeds
(20260618..20260622), so no result was observed before this gate was fixed.

## PASS criteria (ALL required; fixed here, not adjustable after seeing results)

1. **Convergence:** 48/48 seeds converge.
2. **No detectable bias:** `|bias| ≤ 2·MCSE` for EACH of σ1², σ2², σe², where `bias = mean(σ̂²) − truth`,
   `MCSE = sd(σ̂²)/√48`.

## Interpretation (declared in advance)

- **PASS** = NO DETECTABLE across-seed bias — a low-power non-rejection, read as "consistent with an
  unbiased estimator," NEVER as "unbiased" (same honest framing as V4-MV-REML's G[1,1]).
- **FAIL** = a banked NEGATIVE. `V3-TWOEFFECT-REML` stays `partial`; the result is recorded honestly (e.g.
  a small finite-sample REML bias in σ1², analogous to V4), and the covered close does NOT proceed on this
  gate. NO relaxation of the criteria.
- Either way: `validation_status()` count, public-covered fitting = 1, and the comparator evidence (PR #195)
  are unaffected by the gate OUTCOME; only a PASS + Rose + G10 would move the row to covered.

## RESULT (run 2026-06-30, AFTER the predeclaration commit `41bd18f6`) — **GATE: PASS**

`sim/phase3_two_effect_bias_mcse.jl`, 48 seeds 20260700..20260747, julia 1.10.0:

| component | mean | truth | bias | MCSE | \|bias\|/MCSE | verdict |
|---|---|---|---|---|---|---|
| σ1² (animal) | 0.9785 | 1.00 | −0.0215 | 0.0380 | 0.57 | PASS |
| σ2² (group) | 0.4815 | 0.50 | −0.0185 | 0.0155 | 1.20 | PASS |
| σe² (residual) | 1.0066 | 1.00 | +0.0066 | 0.0200 | 0.33 | PASS |

**48/48 converged; all three `|bias| ≤ 2·MCSE` → GATE PASS.** Read as NO DETECTABLE across-seed bias —
**never "unbiased"**: σ1² sits −2.15% (0.57·MCSE) below truth, the largest standardized residual, consistent
with small-sample REML behaviour (the same honest reading as V4-MV-REML's G[1,1]). σ2² is the next-largest
(1.20·MCSE), still within tolerance.

**Consequence:** `V3-TWOEFFECT-REML` now has BOTH doc-18-owed pieces — this pre-declared bias/MCSE gate
(PASS) + the executed BLUPF90 same-estimand comparator (PR #195). It is **covered-READY**. The
`partial → covered` promotion is the maintainer's non-delegable, atomic **G10** (a separate promotion PR);
this run does NOT flip the status. Still owed even after a covered close: ratio (σ1/σ2) intervals, correlated
direct–maternal genetic (2×2 G), and the R-facing model-spec.
