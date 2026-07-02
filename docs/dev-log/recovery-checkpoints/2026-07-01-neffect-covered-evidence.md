# V3-NEFFECT-REML covered evidence — gate PASS + sommer comparator AGREE (2026-07-01)

Both doc-16 covered legs for the arbitrary-N independent-random-effect REML estimator
(`fit_multi_effect_reml`, ultraplan Phase 2) are satisfied. This checkpoint banks the
evidence for the `partial → covered` flip (engine / validation-scale; `public_covered_count`
stays 1 — no R surface).

## Leg 1 — PRE-DECLARED 48-seed bias/MCSE recovery gate: PASS

- Predeclaration committed **before** the run: `68cc7acc`
  (`docs/dev-log/recovery-checkpoints/2026-07-01-neffect-recovery-gate-predeclaration.md`),
  after v1 was withdrawn for a confounded design (dam-level maternal aliased the full-sib
  additive covariance — caught by a pre-run diagnostic, not relaxed).
- Harness `sim/phase3_neffect_recovery_gate.jl` byte-identical pre/post run.
- DGP: 860-animal half-sib pedigree (records = all q); K=3 independent effects — animal-A,
  env1-I(80), env2-I(60), both environmental factors assigned INDEPENDENTLY of the pedigree
  and of each other; truth (σ_a²,σ_g1²,σ_g2²,σ_e²)=(1.0,0.5,0.5,1.0), μ=2.0. Seeds
  20260800..20260847, cold-start `initial=[1,1,1,1]`.
- **Result: 48/48 converged; all four `|bias| ≤ 2·MCSE`:**

  | component | mean | truth | bias | MCSE | \|bias\|/MCSE |
  | --- | --- | --- | --- | --- | --- |
  | σ_a²  | 0.9886 | 1.00 | −0.0114 | 0.0336 | 0.34 |
  | σ_g1² | 0.4959 | 0.50 | −0.0041 | 0.0135 | 0.30 |
  | σ_g2² | 0.4974 | 0.50 | −0.0026 | 0.0185 | 0.14 |
  | σ_e²  | 1.0001 | 1.00 | +0.0001 | 0.0215 | 0.00 |

  Read as **NO DETECTABLE across-seed bias** (largest 0.34·MCSE), never "unbiased".

## Leg 2 — same-estimand external REML comparator (`sommer` 4.4.5): AGREE

- `comparator/prepare_sommer_neffect.jl` reconstructs the predeclared seed 20260800 dataset
  EXACTLY (same RNG draw order as the gate) and records the engine optimum;
  `comparator/run_sommer_neffect.R` fits the SAME model on the SAME data with
  `sommer::mmer(y ~ 1, random = ~ vsr(animal, Gu=A) + vsr(g1) + vsr(g2), rcov=~units)` —
  same-estimand REML (animal ~ A·σ_a², both env ~ I), independent optimizer.
- **Result: AGREE — all four components match to ~1e-4 relative (max 8.09e-5):**

  | component | engine | sommer | rel.diff |
  | --- | --- | --- | --- |
  | σ_a²  | 1.017538 | 1.017456 | 8.1e-5 |
  | σ_g1² | 0.380138 | 0.380137 | 1.5e-6 |
  | σ_g2² | 0.501361 | 0.501349 | 2.5e-5 |
  | σ_e²  | 0.963859 | 0.963906 | 4.9e-5 |

  Both maximize the same REML likelihood on the same data and converge to the same optimum.

## Scope of the covered claim

`fit_multi_effect_reml` correctly implements arbitrary-N INDEPENDENT-effect REML on the
tested identified design (Gaussian, dense/validation-scale). NOT: small-sample accuracy of
any single component; correlated effects (that is `V4-DIRECT-MATERNAL`); production sparse
scale (dense oracle only — owed: the sparse AI-REML `K`-component estimator, Phase 5); an R
public surface (`public_covered_count` stays 1 — engine-covered ≠ R-public-covered, the
V3-TWOEFFECT-REML / V4-MV-REML precedent). Covered does NOT retire the standing debt.

Maintainer G10 delegated 2026-07-01 ("Delegate G10 — flip autonomously once evidence
passes").

## Rose audit → PROMOTE (2026-07-01)

A real `rose-systems-auditor` subagent audited the proposed flip and **independently
reproduced both legs** rather than trusting the banked numbers: it re-ran the sommer
comparator (→ AGREE, max rel.diff 8.09e-5, matching this doc) and re-ran the K=1/K=2/K=3
reduction testset (→ 8/8 pass). It verified all five items clean:

1. **Withdrawal honest** — v1→v2 changed the DGP (dam-level maternal → two pedigree-
   independent environmental factors) but kept the SAME pass criteria, SAME seeds, SAME
   truth; a design correction, not a criteria relaxation.
2. **Predeclaration before run** — `68cc7acc` precedes the evidence.
3. **Gate PASS** — 48/48 converged, all four `|bias|≤2·MCSE` (max 0.34).
4. **Same-estimand comparator** — sommer's animal effect is genuinely A-structured
   (`vsr(animal, Gu=A)`, not identity) on the same seed-20260800 data; no same-estimand trap.
5. **Scope honesty** — `V4-DIRECT-MATERNAL` is a separate row (no conflation); the estimator
   has NO R surface (`public_covered_count` staying 1 is correct); row count unchanged by
   this flip (52 at the time of this 2026-07-01 gate; 53 as of 2026-07-02).

The audit was interrupted by a `/compact` at the final scratchpad-cleanup step, AFTER every
substantive check had passed — the verdict is an unambiguous **PROMOTE** on the completed
evidence. Flip applied across all three status surfaces + `tools/status_cache.json`
(covered 10→11, partial 38→37); `Pkg.test()` green post-flip.
