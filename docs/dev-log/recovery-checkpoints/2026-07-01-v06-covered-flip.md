# v0.6 covered flip — V6-ORDINAL + V6-GAMMA `partial → covered` (2026-07-01)

**What.** Phase 2 of the v0.6 completion plan: promote the two non-Gaussian fitting families
(ordinal `:ordered_probit`, Gamma `:gamma`) from `partial → covered` — the first NON-Gaussian
covered fitting families. **Engine/validation-scale, scoped, opt-in.**

**Gate.** A final full-chain `rose-systems-auditor` on merged `main` (`554c598d`) →
**PROMOTE-WITH-CHANGES**. Rose independently re-ran BOTH 48-seed recovery gates
(byte-identical reproduction), verified predeclaration-before-result ordering, confirmed each
family's three doc-16 G11 legs (joint estimator + agreeing same-estimand comparator + passing
pre-declared 48-seed gate), the pins, and the "never unbiased" discipline. All required changes
applied.

**Rose's critical correction (applied).** The flip is **engine-covered `validation_status()`
8 → 10**, but **`public_covered_count` STAYS 1** — the V6 families are engine-internal
(response types unexported, no R surface, not the default), identical to every prior
engine-covered flip (V2/V3/V4/V5). Moving public-covered to 3 would falsely assert three
R-public-default fitting capabilities. `public_covered_count` is hard-pinned to 1 in
`tools/gen_status_json.jl`. **Engine-covered ≠ R-public-covered.**

**Legs (doc-16 G11 substitutable gate, path b), per family:**
- Joint estimator: `fit_laplace_reml(family=:ordered_probit)` (σ²a + K−1 cutpoints);
  `family=:gamma` (σ²a + shape ν). Both with a `log(init)±8` safety rail.
- Same-estimand comparator: ordinal → `ordinal::clmm` (Laplace-ML; glmmTMB cannot fit
  cumulative-link) cutpoint Δ0.004 / σ²a Δ0.024; Gamma → `glmmTMB Gamma(link="log")` shape
  Δ0.003 / σ²a Δ0.017 (the ~3% σ²a gaps are the ML-vs-REML variance convention, not machine
  precision).
- Pre-declared 48-seed recovery gate: ordinal predeclared `3bef5b03`, 48/48, |bias|≤2·MCSE
  (σ²a +0.027/1.44·MCSE, θ_2, β); Gamma predeclared `5e86e067`, 48/48, |bias|≤2·MCSE (σ²a, ν).
  No detectable bias — never "unbiased".

**Scope + standing debt (covered does NOT retire it):** A=I/repeated-records single design
(ordinal q=120×4=480, Gamma q=80×4=320), Laplace-only, dense, asymptotic, INTERNAL. Owed:
broader-DGP + pedigree-A (non-I) recovery; a 2nd same-estimand comparator (MCMCglmm `threshold`
is Bayesian-agreement-only for ordinal; MCMCglmm has NO general Gamma — glmmTMB is the tool);
the `:symbol` payload + scale-labelled observation-scale h²; R activation.

**Lockstep surfaces (all updated):** `src/validation_status.jl` (both rows field-4
`partial→covered` + scoped-covered scaffold + field-7 strike "NOR a covered claim");
`test/runtests.jl` (status pins 223/229 + claim_boundary checks 226/232); `docs/design/capability-status.md`
(both rows `experimental → covered (scoped)` + fence); `docs/design/16-promotion-gate-predicates.md`
(V6 worked exemplar); `tools/status_cache.json` (covered 8→10, **public_covered_count 1**).

**Verification.** `Pkg.test()` GREEN; `validation_status()` = 50 rows (covered **10** /
covered_external 3 / partial 36 / planned 1); V6-ORDINAL + V6-GAMMA `covered`; no
self-contradiction (field-7 "NOR a covered claim" removed); `public_covered_count` = 1.

**Fence.** This is the ENGINE covered claim (scoped, validation-scale, opt-in). The R public
`hsquared` surface stays experimental — engine-covered ≠ R-public-covered. Public-covered
FITTING remains 1 (v0.1 univariate Gaussian).
