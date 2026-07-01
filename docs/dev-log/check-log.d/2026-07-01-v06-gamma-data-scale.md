# 2026-07-01 v0.6 Gamma DATA/observation-scale h² (+ QGglmm custom-model comparator)

## Goal
Lens: Fisher/Falconer/Gauss + Rose. Implement + externally validate the Gamma (log-link)
data/observation-scale heritability — the last previously-fenced observation scale except ordinal K>2.
Extends `V6-NS-H2` (stays `partial`, count 50). Folded into #222 (the Gamma latent-h² PR).

## What was done
- **Derived the closed form** (μ-independent): `h²_obs = V_A/[e^{V_pred}(1+1/ν)−1]`, the lognormal
  reduction of the NS-2017 multiplicative decomposition `Ψ²V_A/(Var(μ)+E[μ²/ν])` for the Gamma-log
  family (`Ψ=E[μ]`, `Var(y|η)=μ²/ν`). `0<h²_obs<1`.
- **`src/nongaussian.jl`:** the `:gamma` branch of `_nongaussian_h2_core` now returns the computed
  `h2_observation` (was fenced `NaN`) via explicit lognormal pieces (transparent `var_distribution`).
- **`test/runtests.jl`:** the Gamma testset (renamed LATENT + DATA) now asserts the data-scale value
  (closed form), `0<h²_obs<1`, and μ-independence (was: `isnan`). 16 assertions.
- **EXTERNAL comparator:** `comparator/qgglmm_gamma_observed/compare.R` runs QGglmm's CUSTOM Gamma-log
  model (`var.func=μ²/ν`, mathematically determined) — engine == QGglmm to **≤5.07e-11** over 7 cases.
- **Status (doc-19 §3 Gamma row + 3 surfaces):** Gamma data scale done + validated; owed field now
  lists only the ORDINAL (K>2) observation scale (Gamma latent + data both done).

## Commands / results
- `Rscript comparator/qgglmm_gamma_observed/compare.R comparator/qgglmm_gamma_observed/engine_h2obs.csv`
  → `PASS`, max 5.07e-11 (7 cases).
- `Pkg.test()` → PASS (Gamma testset 16/16; count guard `== 50` UNCHANGED).
- Real `rose-systems-auditor` audit (recorded in the PR).

## Claim boundary
The Gamma data-scale h² is an EXACT closed form, externally validated against the QGglmm reference
(custom Gamma model). NOT a covered claim; `validation_status()` = 50 UNCHANGED; public-covered = 1
UNCHANGED; V6-NS-H2 stays `partial`. Remaining owed: the ordinal(K>2) observation scale, MCMCglmm, a
Fisher/Falconer sign-off, and G10. Merge note: composes with #221 (both extend the V6-NS-H2 row +
`_nongaussian_h2_core` — trivial keep-both/combine).
