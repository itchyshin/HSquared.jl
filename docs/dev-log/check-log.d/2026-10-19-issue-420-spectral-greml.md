# 2026-10-19 issue 420: spectral REML for the single-genomic-effect model

Goal: replace the dense n x n AI-REML default in `fit_gblup_reml` with one eigen-decomposition
(`_genomic_eigen`) and a bounded 1-D Brent profile on `Vg / (Vg + Ve)`, for `Z = I`,
`target = :ai_reml`. Dense AI-REML stays reachable with `solver = :dense_ai_reml` and is the
fallback for ineligible models, non-positive or non-finite spectra, and optima on the boundary.

Commands: `julia --project=. test/test_issue_420_spectral_greml.jl` (red on main: 4 errors, 0
passed; green on branch: 20 passed); `test_genomic_variance_boundary.jl`,
`test_genomic_greml_s0_identity.jl`, `test_genomic_summary_contracts.jl` unchanged and green.
Simulated n = 1814 (3000 markers, Julia 1.13.2, one CPU): spectral `fit_gblup_reml` 0.6 s,
dense 10.7 s, loglik difference -1.4e-12, variance components equal to 8 digits.

Claim boundary: engine-internal speed-up of `fit_gblup_reml` only. The R `target = "genomic"`
route enters through `_fit_ai_reml_genomic_boundary` in `src/likelihood.jl`, which this slice
does not edit (draft PR 449 owns that region), so the R call overhead in #420 is not addressed.
No capability-status change; no new fitted capability.
