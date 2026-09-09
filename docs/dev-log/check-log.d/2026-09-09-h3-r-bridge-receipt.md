# R-to-Julia three-field bridge receipt — locked H3 candidate

- R candidate: `hsquared` branch `codex/hsq09-a3-r-plan` at `fd28257`.
- Julia project: locked isolated candidate
  `/private/tmp/hsq09-h3-prerun-20260909` at `c9a81a90` (engine basis
  `82f836f3`).
- Command: `HSQUARED_JULIA_TESTS=true`,
  `HSQUARED_REQUIRE_BRIDGE=true`, and `HSQUARED_JULIA_PROJECT` set to the
  locked candidate, with Julia's existing launcher supplied only to this test
  process PATH; `devtools::test(filter = "nongaussian-three-field-v09")`.
- Result: **104 pass, 0 fail, 0 skip** in 16 seconds.  The two live bridge
  cases that ordinarily skip without JuliaCall provisioning ran.
- Scope: Poisson/Binomial three-field admission and result normalization across
  R→Julia.  This is not an H3 `r_g`/`r_am` fit, coverage result, smoke,
  campaign, promotion, or release receipt.
