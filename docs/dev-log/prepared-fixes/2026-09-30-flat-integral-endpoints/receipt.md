# Flat-integral endpoint guard fix: isolated receipt

Date: 2026-09-30. Owner: Gauss numerical lane. Status: isolated implementation and focused checks complete; parent review and integration pending.

## 1. Goal

Reject negative-binomial all-zero and beta-binomial all-zero/all-success responses when the fixed-effect design contains an intercept. The existing numerical review and objective derivation establish these improper flat-measure tails. This slice implements the necessary endpoint checks without extending the general separation test.

## 2. Implemented

Only two conditions in `src/nongaussian.jl` changed. At line 620, the Poisson all-zero branch now also handles `NegativeBinomialResponse`. At line 628, the scalar binomial endpoint branch now also handles `BetaBinomialResponse`. The helper remains at inclusive lines 612–638, with explanatory comments at 609–611. Its existing rank check, rescaled-intercept detection, zero-column return, and error text are preserved.

The actual family fields are `NegativeBinomialResponse.theta::Float64` (83–89) and `BetaBinomialResponse.n_trials::Int`, `rho::Float64` (107–116). Negative-binomial endpoint detection needs only all-zero responses; beta-binomial all-success detection compares every response with the common scalar `n_trials`. Constructors, theta/rho estimation, family kernels, and numerical objectives are unchanged.

## 3a. Decisions and Rejected Alternatives

Reuse the existing branches and error classification. No new family type or dispatch layer is needed. A test-only overload calls the original generic helper through `invoke`, then throws a sentinel after the expected successful guard visit. This lets direct scalar and GLLVM kernel controls prove that input reached the guard without executing a statistical mode iteration. The overload is removed in `finally`; a separate assertion checks restoration of generic dispatch.

For mixed-family GLLVM, a Gaussian first trait passes and the endpoint family is the second trait. The sentinel waits for two visits, so a premature stop at the Gaussian trait cannot make the rejection test pass. General separation along other columns remains outside this guard.

## 4. Files Touched

All writes are confined to `/private/tmp/hsq-flat-integral-endpoints-fix-20260930/`: copied `src/`, `Project.toml`, `Manifest.toml`; isolated `src/nongaussian.jl`; new `test/flat_integral_endpoint_regression.jl`; red/green logs; patch; SHA inventory; this receipt. No Git directory, campaign artifacts, live source, primary driver, or existing repository test entry point was changed.

Frozen base: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`.

Frozen nongaussian SHA-256: `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`.

Isolated nongaussian SHA-256: `c609b2a58de819ad8a96b74525895a92cd5f2b9517c080a5ec678ae348d87e9f`.

Frozen source-tree SHA-256: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.

Isolated source-tree SHA-256: `340c3724679c13e5203976cb481d92a79d75ba2091f433f95afa23884463d2ee`.

Patch SHA-256: `377949339080913493db2a6c48916b4eae7aae9c15f5c54c5d859c1f139c1e9e`.

Test SHA-256: `0897e4b8cdc7c9579886d006ce8465a985969390888c528b268997caa0cb110b`.

`sha256-inventory.json` records all exact Project/Manifest/log pins and the tree algorithm: sorted src-relative UTF-8 path, NUL, bytes, NUL. Whole-source comparison finds only `src/nongaussian.jl` differs. The parent's authorized HEAD advance to `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429` contains FA artifacts; source remains at the frozen pin.

## 5. Checks Run

Estimate stated before checks: less than one minute on the Mac, two-record fixtures, one Julia thread and one BLAS thread, no GPU. Julia 1.10.0; launch environment `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`.

Command from the isolated root: `julia --project=. test/flat_integral_endpoint_regression.jl`.

Red: frozen implementation, 20 passed / 15 failed / 0 errored, exit 1, 3.6 seconds. Green: patched implementation, 35 / 35 passed, exit 0, 3.2 seconds. The final green file also passes one cleanup assertion outside the named testset; the summary reports the 35 core assertions. No fit, optimizer, score, statistical mode, or Hessian solve ran. The shared guard itself still uses rank and least-squares operations to detect an intercept, and kernels validate relationship precision before reaching it.

Graft literal search and caller lookup preceded the edit. Returned caller coordinates match current source. Reported context savings total 68,491 tokens. `git apply --numstat` parsed the unified patch: 2 additions / 2 deletions in nongaussian.jl, and 84 additions in the new regression file. Final prose check: zero hits.

## 6. Tests of the Tests

The baseline fails all 15 new rejection assertions: six direct helper assertions (ordinary and rescaled intercepts), three scalar Laplace calls, three scalar-family GLLVM calls, and three mixed-family GLLVM calls. None depends on a fit converging. Passing controls preserve zero fixed-effect columns and non-endpoint responses. Existing Poisson-zero and binomial-all-success guards also remain exercised. The only post-red test addition is removal/restoration of the temporary method in `finally`; the 35 core assertions are unchanged.

## 7a. Issue Ledger

| Finding | Disposition |
| --- | --- |
| Negative-binomial all-zero intercept tail omitted | Fixed in isolated helper; red/green direct helper and kernel evidence |
| Beta-binomial all-zero/all-success intercept tails omitted | Fixed in isolated helper; red/green direct helper and kernel evidence |
| General separation on other design directions | Carried; this necessary endpoint guard does not diagnose it |
| Outer failure handling | Carried; no fitter/optimizer catch or conversion changed |
| GLLVM per-record binomial family handling | Carried from prior review; no new support |

## 8. Consistency Audit

Current caller classifications:

| Caller | Exact shared-guard call | What this receipt establishes |
| --- | --- | --- |
| Scalar `laplace_marginal_loglik`, nongaussian 650–736 | 669 | New endpoint rejection after input/count/precision checks, before beta/u initialization and the mode loop; directly tested |
| Scalar `variational_marginal_loglik`, nongaussian 853–950 | 877 | Shares helper after input/count/precision checks and before prior/mode work; source inspection only, no new VA family support or runtime approval |
| `gllvm_laplace_marginal_loglik`, genetic_gllvm 219–429 | 261, per trait | Scalar and family-vector inputs reject before record design/mode work; directly tested |

GLLVM `negloglik` at genetic_gllvm 635–643 catches only `GLLVMParameterEvaluationError`; the helper throws `ArgumentError`, which is rethrown. This receipt proves input rejection in direct kernels and does not resolve outer failure handling. The scalar outer fitter is also unchanged and untested here. Its family-specific fitting paths are not promoted by a shared-helper pass.

## 9. What Did Not Go Smoothly

The first inventory used paths relative to the project root, producing a different aggregate hash. Recomputing with the established src-relative algorithm reproduced the frozen `d3c2...` pin exactly; there was no source movement. Test instrumentation required two successful guard visits for mixed-family controls and explicit method cleanup for reuse in a test process.

## 10. Known Residuals

This slice does NOT cover general separation, complete integral propriety for arbitrary designs, outer optimization failure handling, inference/calibration, broad non-Gaussian fitting, per-record beta-binomial trials, or capability promotion. No package-wide test suite ran. The passing controls show that selected proper-input guard paths stay available; they do not prove subsequent fitting behavior.

## 11. Team Learning

For a necessary input guard shared by multiple numerical kernels, a temporary dispatch method can invoke the true implementation and stop at a sentinel before numerical work. Include dispatch cleanup and a mixed-family endpoint after a valid first trait, so test ordering cannot hide a missing rejection.

Memory receipt: no durable memory edits; exact technical evidence comes from the frozen source and scratch logs. Prior numerical and objective reviews were reused only for the already-established improper-tail finding.

## 12. Cross-Product Coverage

Golden Set: two-record negative-binomial zero response; beta-binomial zero/all-success responses with five trials; ordinary and rescaled intercepts; no fixed effects; mixed endpoint/non-endpoint responses; Gaussian-first mixed-family GLLVM; retained Poisson/binomial endpoint rejection.

Only Julia's shared necessary-integral guard was changed in isolation. No R bridge, user contract, documentation claim, fitted-capability row, or validation-debt row was changed. Parent next action: review this unified patch and receipt, then integrate after the source freeze is released and wire the new regression file into the chosen test entry point.
