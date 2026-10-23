# Likelihood input and finite result repair

## 1. Goal

Prepare the assigned Gaussian likelihood input repair in an isolated project copy. Parent review and composition are the next steps. Exact source review remains HOLD for the unresolved inference and boundary findings.

The live baseline is `src/likelihood.jl`, 4,613 lines, SHA256 `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30`. Parent HEAD at final verification is `6271cfd58651e69cd27a64dcf02cb8960a29e260`. Parent authorized adjacent source changes during this work; likelihood and iterative guard dependency pins remained unchanged.

## 2. Implemented

Added shared input validation for converted finite response, fixed design and random design arrays. Fixed designs use the existing sparse QR full-rank guard, with the zero-column case retained. REML evaluation requires fewer fixed columns than records. Supplied Henderson solves permit a saturated full-rank design and preserve the specification's method metadata.

Relationship precision matrices use the existing finite, symmetric, positive-definite canonicalizer. This preserves its accepted roundoff averaging contract. IDs must have the required count and be unique within each effect; K-effect ID vectors must also have the correct outer count. Dense explicit method overrides are recorded in the returned specification.

Variance values and starts are checked in their original Real domain and after Float64 conversion. Sparse precision paths also require a finite reciprocal. Dense covariance paths continue to accept positive subnormal variance when the resulting arithmetic is representable. Dense marginal covariance, sparse coefficient matrices, right-hand sides, likelihoods and extracted solutions are checked for finite values.

Dense objective proposals reject only the named factorization and numerical-range failures. Sparse final decoding and evaluation must produce finite variances and a finite likelihood. Scalar AI rejects a nonrepresentable positive variance update with a false convergence result and an explicit diagnostic reason. Direct-maternal initial values that contain neither documented start field now reject before fitting.

The sparse fitter docstring states the scope of its optimizer stopping flag and its positive log-variance domain. Exact zero boundaries and score stationarity are still outside that stopping flag's evidence.

## 3a. Decisions and Rejected Alternatives

Reused the signed sparse QR and precision checks from `src/iterative_solve.jl`, SHA256 `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132`. Introduced no dense rank computation. The finite covariance scan is quadratic on existing dense paths; no performance claim follows from these small checks.

Kept likelihood equations, covariance parameterizations, REML/ML targets and estimator result structures. Kept the existing direct-maternal correlation formula for the other assigned lane's disposition. Supplied MME validation uses the ML design dimension condition solely to allow full-rank saturated solves; it retains the specification's declared method.

The final unified patch is the reproducible delivery artifact. The saved preparation script documents an intermediate generation step; later corrections are present in the final patch and source snapshots.

## 4. Files Touched

All files belong to `/private/tmp/hsq-likelihood-input-fix-20260930/`. The isolated project contains copied Project/Manifest and source files, without a Git directory. The changed engine file is `src/likelihood.jl`, now 4,724 lines. The new regression file is `test/likelihood_input_guard_regression.jl`. `runner-append.txt` supplies one proposed test-runner include for parent composition.

Core delivery pins:

| File | SHA256 |
| --- | --- |
| Prepared source | `d098830fc70ee02f781b1b0838f3ea497b38688bdca6244af9d3d4fd21ab3c0c` |
| Regression | `84e555a68c4c6b4a360583c9fd5400ecb9af98adbc0e40e5baf9dd68f72659a9` |
| Unified patch | `bf52fa761fb392dd754ca3f316235676bf6fe8d860214a43a1e320c7c0f901a3` |
| Project | `37f0e6aaa6492c76519ed7771b226972cea531a7104866e5753890e31e163033` |
| Manifest | `c5940f2be0347f7ff987468aed67f17070f556a0aa99e0e5ec5317898cfa0fad` |

`SHA256SUMS` inventories the copied project, source, regression, patch, runner proposal and retained evidence. It excludes its own bytes, this receipt and the redundant patch-application copy.

`evidence/packaging-verification.json` lists all 75 changed baseline/prepared groups and verifies reserved baseline bodies are unchanged: 667–1161, 1437–1440, 1561–1645, 1686–1720, 1993–2357, 3169–3268, 3386–3427, 3446–4183 and 4350–4613. Input coercers 4185–4203 and 4229–4247 are owned by this packet. Sparse assembly checks at 4258–4279 and 4327–4341 are also owned here.

## 5. Checks Run

Estimated each tiny local run within two minutes initially and within one minute for the final run. The final run completed in 26.48 seconds. Julia was 1.10.0; both Julia and BLAS thread counts were one. Each actual fit used three records and at most one iteration. No simulation or statistical campaign was run.

Command, from the isolated root:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia \
/Users/z3437171/.juliaup/bin/julia --compiled-modules=no --startup-file=no \
--project=. -e 'include("test/likelihood_input_guard_regression.jl")'
```

Launches used a Python subprocess timeout, 180 seconds initially and 60 seconds finally, with child termination and waiting on timeout. All runs finished within their limit. No package resolution or dependency update was performed.

| Retained log | Result | Wall time |
| --- | --- | --- |
| `red-001.log` | 96 pass, 96 fail, total 192 | 30.05 s |
| `red-002.log` | 96 pass, 90 fail, total 186 | 29.19 s |
| `green-001.log` | 186 pass | 25.86 s |
| `compatibility-red-003.log` | 190 pass, 1 error | 26.79 s |
| `green-002.log` | 193 pass | 25.86 s |
| `green-final-003.log` | 194 pass | 26.89 s |
| `metadata-red-004.log` | 200 pass, 2 fail | 27.43 s |
| `green-final-004.log` | 202 pass | 26.48 s |

`git apply --check` passed against an isolated exact baseline. Applying that same patch to the packaging copy reproduced both tested files byte for byte. The patch changes no live source or test runner. Final live likelihood and iterative dependency hashes match their stated baseline pins.

## 6. Tests of the Tests

The baseline red checks reproduced missing finite/rank/precision/start/ID validation. Ordinary supplied dense/sparse controls already passed before the repair. The initial tiny-positive variance test was too restrictive for dense covariance arithmetic and was corrected with a separate precision-path fixture; both red logs remain available.

The saturated supplied-MME control caught a regression introduced by the shared REML dimension guard. The corrected helper permits the valid solve: fixed effects equal the responses, random effects are zero, and method metadata stays REML. That failed candidate remains in `likelihood.compatibility-failed-001.jl`.

Two late direct-maternal metadata checks first failed because a numeric start and an unknown-field NamedTuple were silently ignored. Both reject after the final narrow guard. A saved candidate and red log preserve this reproduction.

Golden Set: independent diagonal ML likelihood, dense/sparse REML equality, zero-, one- and two-column fixed designs, scalar/K-effect supplied BLUP equality, saturated supplied solve, valid dense positive subnormal variance and a finite one-iteration sparse result with false convergence status.

## 7a. Issue Ledger

| Finding | Disposition in this packet |
| --- | --- |
| LH01 sparse final finite/rank/boundary | Finite input, proposal, final-value and rank guards repaired; optimizer stationarity and closed-boundary inference remain HOLD |
| LH02 y/X/Z finite and rank | Repaired on all 14 targeted routes |
| LH03 supplied precision and finite solve | Canonical SPD, reciprocal, assembly and solution guards repaired on the owned MME paths; PEV work remains in the separate lane |
| LH04 two/K-effect dense inputs, IDs and starts | Repaired; resource and conditioning limits remain |
| LH10 K-effect supplied infinite likelihood | Variance domain and final finite checks repaired |
| LH15 raw direct-maternal/repeatability inputs | Model, precision, rank, IDs, controls and starts repaired; equations and allocation limits retained |
| LH05–09, LH11–14, LH16–17 | Reserved helpers and inference/provenance findings remain for separate disposition |

## 8. Consistency Audit

The shared validators apply before optimization or supplied solves. The zero-fixed-effect case is supported; MME precision checks reject unrepresentable reciprocals. Canonical precision values flow into both the stored specification and the actual calculation. Relationship diagonal metadata is kept only when the validated precision is unchanged.

The inherited unused cross-product y'y shortcut remains unchanged. The actual residual/prior quadratic calculation remains unchanged, preserving the prior intercept-shift repair. The dense and sparse valid mathematical controls agree to 1e-12.

The packet depends on the existing iterative guard implementation. Parent must compose this source patch with the selector/ratio/fd-step and profile/PEV/heritability/bootstrap proposals, then run their focused checks together. The regression helper has a packet-specific name to avoid test-runner collisions.

Memory receipt: operating guidance used for preflight and shared checkout preservation; repository pins and executed checks establish all numerical claims here. Graft callers and skeleton were consulted before editing; its lock-cache permission warning did not prevent exact source-coordinate checks. Graft reported a combined token-saving estimate of 567,490 for those queries.

## 9. What Did Not Go Smoothly

Two preparation-script assertions used incorrect return markers and stopped before writing the engine. Both failed scripts and the exact marker corrections are retained in `prepare-failures.log`. The initial regression conflated dense variance representability with precision reciprocal representability; the corrected contract was exercised in the next baseline run.

Shared REML shape validation initially rejected a valid saturated supplied solve. A meaningful control found it and the guard was narrowed. A final verification command tried to read the new regression in the live candidate; its absence is expected because this packet is isolated, and the file was subsequently read from the isolated root.

## 10. Known Residuals

This repair does NOT cover score-stationarity certification, closed variance boundaries, near-boundary accuracy, uncertainty calibration, PEV metadata/domain repairs, profile-root handling, finite-difference controls, ratio/correlation arithmetic, bootstrap success accounting or broad outer failure provenance. Those helpers remain under their assigned review lanes.

Sparse QR supplies a numerical rank decision; extreme rescaling and ill-conditioning have no new guarantee. Existing dense q²/Kronecker allocation limits remain. The K-effect result and positive interior covariance transforms retain their documented model domain. No public R formula or family route, GLLVM response-scale heritability or capability-status row is activated by this packet.

No full package suite, large fit, GPU run, benchmark or coverage campaign was run. Finite stopping results from these tiny fixtures establish the tested input and result contract only. Full likelihood approval remains HOLD.

## 11. Team Learning

Share one validated converted design and canonical precision contract at entry. Keep supplied equation solvability separate in the dimension guard: a full-rank saturated fixed design can produce a valid supplied MME solve. Distinguish representable covariance variance from representable precision reciprocal in regression fixtures.

Retain both failed implementation attempts and valid mathematical controls. They exposed a real compatibility regression and prevented an unnecessarily restrictive dense contract.

## 12. Cross Product Coverage

Fourteen targeted routes cover scalar dense/sparse likelihood, supplied Henderson, dense/sparse/scalar AI fit, two-effect supplied/fit, K-effect supplied/sparse likelihood/dense fit/sparse AI fit, direct-maternal fit and repeatability fit. Malformed models span nonfinite y/X/Z, conversion overflow, duplicate fixed columns, indefinite precision and material asymmetry. Variance and start cases span nonfinite values, nonpositive values, Float64 underflow/overflow and unrepresentable precision.

The 202 checks include effect-ID structure, arithmetic overflow, explicit method metadata, ordinary supplied models, saturated supplied models and finite/nonconverged fit status. This is targeted component evidence. Exact current whole-file coverage was established in the two earlier read-only receipts; their defect disposition remains HOLD pending the complete composed repair and independent review.
