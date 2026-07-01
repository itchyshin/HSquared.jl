# 2026-07-01 v0.6 ordinal (K>2) PER-CATEGORY observed-scale h²

## Goal
Lens: Fisher/Falconer/Gauss + Rose. Implement the ordinal (K>2) per-category observation-scale h² —
the LAST fenced non-Gaussian h² scale. Maintainer-approved API: a new vector field
`h2_observation_by_category` (keeping the scalar `h2_observation = NaN`). Extends `V6-NS-H2` (stays
`partial`, count 50). Branch `feat/2026-07-01-v06-ordinal-observed-h2` (off #221).

## What was done
- **Probe first (de-risk):** the per-category formula `h²_k = Ψ_k²V_A/[p_k(1−p_k)]` matched QGglmm
  `model="ordinal"` EXACTLY before any code landed (μ=0,V_A=0.5,θ=[0,1]: [0.21221,0.02058,0.16587]).
- **`src/nongaussian.jl`:** a `cutpoints` kwarg on `_nongaussian_h2_core` (threaded from the fit's
  `variance_components.cutpoints` or the `OrderedProbitResponse.thresholds`); the `:ordered_probit`
  branch computes the K-vector via the module's `_gh_expect`/`_norm_cdf`/`_norm_pdf` and returns
  `h2_observation_by_category` (scalar `h2_observation` stays NaN). Missing-cutpoints guard. The
  `:bernoulli_probit` return is unchanged (no vector field — the return is family-conditional).
- **`test/runtests.jl`:** the K=3 ordinal now asserts the per-category vector (validated values,
  `0<h²<1`) + the K=2 reduction (complementary categories equal, and == the binary observed h²) +
  the missing-cutpoints guard.
- **EXTERNAL comparator:** `comparator/qgglmm_ordinal_observed/compare.R` — engine == QGglmm ordinal to
  **≤3.17e-8** over 6 cases (K=3, K=4).
- **Status (3 surfaces):** ordinal observed done + validated; the ordinal comparator moved from owed to
  done.

## Commands / results
- `Rscript comparator/qgglmm_ordinal_observed/compare.R …/engine_h2obs.csv` → `PASS`, max 3.17e-8.
- `Pkg.test()` → PASS (testset 21/21; count guard `== 50` UNCHANGED).
- Real `rose-systems-auditor` audit (recorded in the PR).

## Claim boundary
This COMPLETES every non-Gaussian h² scale in the V6-NS-H2 surface (all externally validated vs QGglmm).
NOT a covered claim; `validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED; V6-NS-H2
stays `partial`. Remaining owed: MCMCglmm, Fisher/Falconer sign-off, intervals/SEs, R surface, G10.
Merge note: composes with #221 (base) + #222 (Gamma) — the V6-NS-H2 row + `_nongaussian_h2_core` combine
(keep-both). The `h2_observation_by_category` field is a heterogeneous addition (ordinal return only),
per the maintainer's approved API shape.
