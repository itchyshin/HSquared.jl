# 2026-06-19 Honesty closeout S1 (#47 rows + #38 doc + #44 V6-LAPLACE row)

- Goal: close three honest-status drifts the R lane flagged on issue #61, none new
  math: refresh the in-code `validation_status()` rows that still listed covariance
  SEs/LRTs as *missing* (#47, already shipped in PR #59), harmonize one retired
  AI-REML doc claim (#38), and add the citable Phase-6 non-Gaussian row that exists
  in the registers but not in `validation_status()` (#44, blocker-first).
- Lenses: Rose (claim-vs-evidence, lead), Noether (math/status consistency),
  Fisher (inference wording), Hopper (R honesty-gate unblock).

## Verified before editing (repo = truth)

- SE/LRT functions exported on `main` (`src/HSquared.jl:76,81`) and tested (PR #59),
  but `src/validation_status.jl` still listed them as missing — V4-MV-REML L233,
  V4-FA L242. `capability-status.md` + `validation-debt-register.md` were updated in
  #59; the in-code `validation_status()` data was the surface that drifted.
- `multivariate_covariance_standard_errors` is `:unstructured`-fit only (explicit
  guard, `src/multivariate.jl:927-928`): structured/FA loadings are
  rotation-nonidentified, so V4-FA keeps structured SEs honestly absent and gains
  only the LRT.
- No V6/Laplace row in `validation_status()` (only an AI-REML caveat at L99), but
  `validation-debt-register.md` already carries V6-LAPLACE/VA/FIT/BERNOULLI/BINOMIAL
  and `capability-status.md` the matching rows. Only `validation_status()` lacked it.
- `03-engine-contract.md:455` carried "ratio ~0.99 on a 250-animal simulation" — a
  claim retired from `validation_status()` on 2026-06-13 as Rose-blocking
  (no backing test); the doc line was missed in that cleanup. Committed wording is
  "~8% vs an independent finite-difference REML Hessian" (`V1-HERIT-CI`).

## Changes

- `src/validation_status.jl`: V4-MV-REML evidence now records the SEs+LRT (PR #59)
  and drops them from `missing`; V4-FA evidence records the boundary-aware LRT and
  notes structured SEs are intentionally absent (rotation), `missing` keeps
  "standard errors for the rotation-nonidentified structured loadings"; new
  consolidated **V6-LAPLACE (partial, Phase 6)** ladder row mirroring the register
  rows (Gaussian→`sparse_reml_loglik` exact; Poisson/Bernoulli/Binomial Laplace+VA;
  `fit_laplace_reml`/`NonGaussianFit`; missing = `MarginalMethod` dispatch + bridge
  shape + GLLVM.jl/gllvmTMB comparator + R model-spec).
- `docs/design/03-engine-contract.md`: #38 wording harmonized to `V1-HERIT-CI`.
- `test/runtests.jl`: +15 assertions (V4-MV-REML SE/LRT in evidence + out of missing;
  V4-FA LRT in evidence + structured-SE wording in missing; V6-LAPLACE row shape);
  count 31→32, `validation[end]` → `V6-LAPLACE`.

## Commands / results

- Pre-edit RED proof: a one-off `validation_status()` load confirmed all five new
  assertions failed against the unedited source (length 31; no V6-LAPLACE; V4 rows
  still listed SEs/LRTs as missing).
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**;
  suite 1822 → **1837** (+15). New "Phase 4 multivariate covariance SEs + LRTs"
  (30/30) and the Phase-6 testsets remain green.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → exit 0 (see after-task).

## Claim boundary

Honest-status surfaces only — no new engine behavior, no capability moved to
covered, no R bridge/payload change. Reduces drift; cannot overclaim by
construction. The V6-LAPLACE row stays `partial` and records the bridge/dispatch
and external-comparator gaps explicitly.
