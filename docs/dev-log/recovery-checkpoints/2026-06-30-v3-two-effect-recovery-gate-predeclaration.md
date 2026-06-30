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
