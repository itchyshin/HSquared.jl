# V6-ORDINAL recovery gate — 48-seed known-truth — 2026-07-01

Executes the recovery gate PRE-DECLARED in `sim/phase6_ordinal_recovery.jl` (committed `3bef5b03`,
BEFORE this run). Known-truth recovery for the ordered-probit JOINT estimator
`fit_laplace_reml(...; family = :ordered_probit)` (Phase 1, #215). Evidence for the v0.6 ordinal
covered path (doc-20 / doc-16 G11); promotes nothing — experimental/`partial`, public-covered
fitting = 1 UNCHANGED.

## Run

- Harness: `sim/phase6_ordinal_recovery.jl` (opt-in), 48 seeds. Design: A = I animal model + repeated
  records (120 animals × 4 records = 480 obs — INFORMATIVE, so the ≥3-category σ²a that is weakly
  identified on small data, cf. the Phase 1 caveat, IS identified here), K = 3 categories, engine
  parameterization `l = β + u + e`, `u ~ N(0, σ²a)`, `e ~ N(0,1)`, thresholds `[0, θ_2]`.
  Truth: σ²a = 0.5, θ_2 = 1.2, β = 0.3.
- Reproduce: `julia --project=. sim/phase6_ordinal_recovery.jl --seeds=48`.

## Result — aggregate Monte Carlo recovery (m = 48)

| param | true | mean | bias | MCSE | \|bias\| ≤ 2·MCSE |
| --- | --- | --- | --- | --- | --- |
| σ²a | 0.5000 | 0.5274 | +0.0274 | 0.0190 | yes (1.44·MCSE) |
| θ_2 (cutpoint) | 1.2000 | 1.2057 | +0.0057 | 0.0098 | yes (0.58·MCSE) |
| β (intercept) | 0.3000 | 0.3137 | +0.0137 | 0.0130 | yes (1.05·MCSE) |

- Convergence: **48/48**.
- `GATE ordinal_recovery within_2mcse_all=true converged_all=true gate_pass=true seeds=48`.

## Verdict + honest caveat

**The pre-declared ordinal recovery gate PASSES:** 48/48 converged and `|bias| ≤ 2·MCSE` for σ²a, the
cutpoint θ_2, and β. The cutpoint θ_2 recovers essentially exactly (0.58·MCSE). **σ²a is the weak axis
at 1.44·MCSE** — a slight upward pull, the documented small-sample threshold-model σ²a behavior (cf. the
Phase 1 weak-identification caveat + the V4-MV-REML G[1,1]-at-1.57·MCSE precedent). Read as **no
detectable bias** at this design/power (the MCSE floor 0.019 → a σ²a bias above ≈0.038 / 7.6% would be
detectable; the observed +0.027 is below that), never "unbiased". The informative design (480 obs)
resolves the Phase 1 weak-identification — σ²a IS identified here.

## Covered-path status for V6-ORDINAL (doc-16 prerequisites)

The ordinal family now has ALL the doc-16 covered PREREQUISITES assembled:
1. **Joint estimator** — `fit_laplace_reml(...; family=:ordered_probit)` (#215). ✅
2. **Same-estimand comparator** — `ordinal::clmm` agrees (cutpoint spacing Δ0.004;
   `2026-07-01-ordinal-clmm-comparator.md`). ✅
3. **Pre-declared recovery gate** — PASSES (this checkpoint). ✅

Owed for the covered FLIP: the maintainer's **G10** sign-off, a real Rose audit on the chain, and the
surface niceties (`:symbol` payload + scale-labelled h² — NOT doc-16 blockers). Engine-covered
readiness, NOT the public default.

## Fences

Experimental/`partial`; `validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED; NOT
a covered claim. Single informative design (A=I / q=120 / repeated records); broader-DGP + pedigree-A +
the small-data weak-identification boundary are documented follow-ups.
