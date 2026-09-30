## 1. Goal

Require profile intervals to have a converged, non-boundary point fit and make the caller's iteration limit effective for supported single-component families.

## 2. Implemented

- The single-component `fit_laplace_reml` path now passes `iterations` to Optim's Brent method using its supported keyword API.
- `laplace_reml_interval` defaults to the fitter's 1,000-iteration limit and rejects non-finite point-fit likelihoods.
- Every profile LRT evaluation now requires a converged inner Laplace fit and a finite likelihood and deviance before root finding continues.
- `laplace_reml_interval` retains its positive iteration-count check and rejects unconverged or boundary point fits.
- The interval docstring now lists `:bernoulli_probit`, which the implementation already supported.
- Added tests for a truly capped nonconverged point fit, boundary rejection, and a deterministic interior Poisson interval.
- A separate read-only reviewer found the original no-op iteration limit and signed off on the corrected change. Astra's independent inference audit supported the finite-rail rejection and found the failed-profile-evaluation path, now guarded.

## 3a. Decisions and Rejected Alternatives

- Kept the interval's fail-closed rule for boundary point fits. Small fixtures repeatedly landed on the bounded search rail and therefore could not serve as success fixtures.
- Threaded the iteration cap into Brent instead of removing it from the interval API. The public keyword now controls the optimizer used by all supported interval families.
- Used a deterministic repeated-record fixture to check the successful interior path without introducing a simulation.

## 4. Files Touched

- `src/nongaussian.jl`
- `test/wave2_nongaussian_contracts.jl`
- `docs/dev-log/after-task/2026-09-28-wave2-profile-interval-guard.md`

## 5. Checks Run

- `julia --compiled-modules=no --project=. -e 'include("test/wave2_nongaussian_contracts.jl")'`: PASS, 94 assertions across the included Wave 2 suites.
- `git diff --check`: PASS.
- The standalone normal-path probe on an identity relationship matrix hit the boundary and did not verify the successful path.
- The deterministic repeated-record Poisson interval passed inside the focused suite with a converged point fit and endpoints bracketing the estimate.
- A direct fit of the existing 8-animal Poisson interval fixture returned `sigma_a2 = 0.0024787525` (`exp(-6)`) and `boundary = true` at both 200 and 1000 optimizer iterations. Calling the guarded interval on that fixture raised the expected boundary error. This exposes adjacent legacy test expectations that need review.
- Direct checks of the four existing cross-family fixtures found boundary fits for Poisson and Bernoulli, while binomial and probit returned intervals. The old Poisson and Bernoulli success expectations need verified interior fixtures or explicit rejection tests.
- A one-iteration inner Poisson likelihood evaluation returned `converged = false` and `loglik = NaN`; the new profile LRT helper raises `ArgumentError` before such a value reaches root finding.

## 6. Tests of the Tests

- Before the Brent fix, the `iterations = 1` test failed because the fit still converged, demonstrating that the old iteration keyword did not control the supported optimizer.
- Passing `Optim.Options` positionally to Brent produced a `MethodError`; the test caught this incorrect API use. The supported `iterations` keyword then made the one-iteration point fit nonconverged, and the interval raised the expected `ArgumentError`.
- The boundary fixture raises the boundary-specific `ArgumentError`. The repeated-record fixture confirms a normal converged interval is still returned.

## 7a. Issue Ledger

- Fixed: `iterations` was a silent no-op for the single-component optimizer used by every supported interval family.
- Fixed: the interval docstring omitted `:bernoulli_probit` from its supported-family list.
- Fixed: a failed inner profile evaluation could return `NaN` and be mistaken for an unclamped finite endpoint.
- Open: existing Poisson and Bernoulli interval fixtures use boundary point fits. The `test/runtests.jl` lease is expired, but the file remains modified in the shared worktree and no handoff is confirmed, so this slice leaves it untouched.
- Open: the interval coverage script drops thrown attempts from results and counts only retained results as replicates. Any new coverage needs attempt-level failure accounting; no campaign was run.

## 8. Consistency Audit

- Checked the shared single-component fit branch used by Poisson, Bernoulli, Bernoulli probit, and binomial intervals. It now forwards the limit to Brent for all four families.
- Checked the interval's family gate, iteration validation, convergence check, boundary check, and documentation together.
- Existing package tests contain Poisson, Bernoulli, probit, and binomial interval cases. Targeted checks confirmed the repeated eight-animal fixtures are boundary for Poisson and Bernoulli, but interior for binomial and probit. The full `test/runtests.jl` suite was not run.
- The shared `_profile_root` serves several interval, plot, and simulation paths. The non-Gaussian LRT target now throws on failed or non-finite profile evaluations before its values reach that shared root finder.

## 9. What Did Not Go Smoothly

- A positional `Optim.Options` argument is invalid for the installed Brent API. The first run exposed a `MethodError`; switching to the documented keyword form resolved it.
- The small Poisson examples landed on the search rail, so I constructed a repeated-record deterministic fixture to verify a valid interior interval.
- `closeout.py new` resolved its root to the Shinichi brain checkout, outside this task's writable roots. The report was created directly in this repo and will be checked with the available report validators.

## 10. Known Residuals

- Only focused Wave 2 tests and a whitespace check were run. Existing Poisson and Bernoulli interval expectations need reconciliation with their confirmed boundary fits. The interval coverage harness needs attempted-failure accounting before a new campaign. Full Julia package tests, documentation build, CI, R bridge parity, and the overall panel gate remain outstanding.
- `docs/dev-log/check-log.md` and `docs/dev-log/coordination-board.md` are held by another live lane and were not edited here.
- This change does not establish interval coverage or make the experimental interval a release candidate.

## 11. Team Learning

Memory receipt: the route tool found no LOAD-FIRST manifest for this managed worktree. I read the repo after-task protocol and the profile-interval source graph. The repo's lane preflight and live lease list showed that this slice owns `src/nongaussian.jl`, its Wave 2 tests, and this report; shared check-log and board files remain with another lane. No brain decision was used as technical evidence.

Golden Set: not run. This was a bounded optimizer-control regression and no matching Golden Set fixture was identified in the routed context.

Independent read-only reviews were run for the optimizer contract and the inference guard. The first finding led to forwarding the Brent iteration cap. Astra supported refusing search-rail fits and identified the NaN profile path; a second reviewer signed off on the new inner-convergence and finiteness checks. No simulation or GPU work was run.

## 12. Cross-Product Coverage

Covers: Julia `fit_laplace_reml` single-component Poisson, Bernoulli, Bernoulli probit, and binomial optimizer iteration limits; Julia `laplace_reml_interval` convergence and boundary guards.

This does NOT cover: R formula or bridge behavior, Gaussian FA, genetic GLLVM fits, interval coverage calibration, loading inference, GPU execution, or any release claim.
