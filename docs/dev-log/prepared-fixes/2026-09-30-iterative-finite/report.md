# Iterative finite-contract repair proposal, 2026-09-30

## 1. Goal

Repair the bounded I1-I4 numerical/input contracts from the separate independent read-only receipt `/private/tmp/e1-iterative-complete-current-review-20260930.md` (SHA-256 `ae8514b075f36fbee3a9044184757bd73238c8743ac230cf557c9a2fccbf4448`). That receipt remains an assessment of the original source; this document is the author's repair evidence, not independent approval.

Base `src/iterative_solve.jl`: `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132`, candidate HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260`. Work remains entirely within this scratch directory.

## 2. Implemented

- I1: `_matrix_free_float64_data` rejects nonfinite y/X/Z before and after Float64 conversion. Single supplied PCG validates all three before either assembled or matrix-free products. Multi solve, trace, fit, likelihood and information entry paths validate their applicable data before rank/products. Ratio/single-fit wrappers inherit these checks through their existing delegates.
- I2: PCG rejects nonfinite rhs, rhs norm, preconditioned residual, curvature, step/direction arithmetic and final solution/residual; positive inner-product underflow also fails explicitly. Finite unconverged standalone iterates remain available. Likelihood rejects nonfinite joint quadratics/final likelihood, and information rejects nonfinite final entries. Failed SLQ now throws an explicit ArgumentError rather than returning a numeric unavailable likelihood; the public docstring describes this change.
- I3: MC-fit ratios normalize components by their largest value before summing; boundary flags use these same ratios. A finite total no longer needs to be representable in unscaled Float64.
- I4: `_matrix_free_probe_summary` scales samples before computing the mean and sample-MCSE, retaining denominator n-1 and the existing n=1 NaN convention. Both trace modes and SLQ summary use it. Nonfinite sample/summary output throws a range error.
- Documented intentional NaNs: skipped fit likelihood and one-probe MCSE. No public field, estimator, method, variance-domain or capability expansion.

## 3a. Decisions and Rejected Alternatives

Symbolic contracts and primary tests were frozen before source edits. Scaling preserves the original ratio, mean and sample-MCSE formulas; BigFloat is solely the independent oracle, not a production dependency. Unsupported PCG/quadratic/information arithmetic fails clearly rather than claiming arbitrary dynamic-range support. This can reject a mathematically representable problem whose current unscaled intermediates do not fit Float64; no full rescaling algorithm is promised.

Signed `_require_full_fixed_effect_rank`, `_canonicalize_matrix_free_precision`, and `_validate_matrix_free_precision` bodies remain byte-identical. They are shared with the other likelihood-input proposal. No sparse factorization/rank semantics, solver estimator, stochastic probes, convergence thresholds or calibration claims were changed.

## 4. Files Touched

Only scratch: `baseline-iterative_solve.jl`, proposed `src/iterative_solve.jl`, repository-relative `iterative.patch`, `contracts.md`, primary `test/iterative_finite_contracts.jl`, independent `test/iterative_summary_controls.jl`, unchanged copied `test/wave1_numerical_contracts.jl` and `test/test_matfree_reml_inci_pins.jl`, `package/` execution snapshot (source/Project/Manifest with proposed iterative source substituted), `red.log`, `green.log`, `existing-green.log`, `pins.json`, this report. Live source, registered runner/tests, Git state, R twin, and other workers' scratch trees remain untouched.

## 5. Checks Run

Julia 1.10.0, compiled modules/startup disabled, JULIA_NUM_THREADS=1, OPENBLAS_NUM_THREADS=1; both measured 1. Existing dependency files/depot used without update or resolve. Primary red and green runs each estimated under two minutes; existing regressions estimated under three minutes before launch. No campaign, GPU or remote compute. Existing integration tests include small deterministic fits; these are requested regression checks, not new recovery studies.

| Check | Result |
| --- | --- |
| Frozen primary on original source | exit 1, 58 passed / 47 failed / 105 total, 6.3 s test body |
| Same frozen primary on proposal | exit 0, 105/105, 4.6 s |
| Independent probe-summary oracle | exit 0, 18/18 |
| Existing wave1 numerical contracts | exit 0, 167/167, 14.3 s |
| Neighboring testsets in copied wave1 file | exit 0, 37/37 |
| Existing matrix-free integration pins | exit 0, 22/22, 2.3 s |

Total green assertions: **349/349** across the two green invocations. No package-wide suite or benchmark claim. `git apply --check iterative.patch` against the live a4ad source exited 0. Source stayed a4ad after these checks. Scope/pins and protected-helper identity were checked programmatically.

Reproduction (each green run separately):

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --compiled-modules=no --startup-file=no --project=/private/tmp/hsq-iterative-finite-contracts-fix-20260930/package -e 'using LinearAlgebra; println("Julia=",VERSION," JuliaThreads=",Threads.nthreads()," BLASThreads=",BLAS.get_num_threads()); include("/private/tmp/hsq-iterative-finite-contracts-fix-20260930/test/iterative_finite_contracts.jl"); include("/private/tmp/hsq-iterative-finite-contracts-fix-20260930/test/iterative_summary_controls.jl")'
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --compiled-modules=no --startup-file=no --project=/private/tmp/hsq-iterative-finite-contracts-fix-20260930/package -e 'using LinearAlgebra; println("Julia=",VERSION," JuliaThreads=",Threads.nthreads()," BLASThreads=",BLAS.get_num_threads()); include("/private/tmp/hsq-iterative-finite-contracts-fix-20260930/test/wave1_numerical_contracts.jl"); include("/private/tmp/hsq-iterative-finite-contracts-fix-20260930/test/test_matfree_reml_inci_pins.jl")'
```

## 6. Tests of the Tests

Primary test hash `63c1a90b9a30ab5336f2033881dc92ff7e0ab46251eee6b7571dcfa6885550c0` was recorded before implementation and remains unchanged. Original-source failures are exactly 36 hidden-response assertions, 3 unsupported-result assertions, 4 oversized-trace assertions, and 4 fitted-ratio/diagnostic assertions. The 42 converted-design cases already rejected under original indirect rank/diagonal checks; the new explicit guards improve ingress consistency without claiming these were silent-acceptance counterexamples.

Ordinary oracle: with p=0, Z=0 and Q=1, unit variances give u=0, P=I, AI=diag(0,sum(y²)/2), and ℓ=-0.5[n log(2π)+sum(y²)]. A separate hand-assembled four-record Henderson system checks both PCG routes. A starved one-iteration solve still returns finite unconverged diagnostics. Summary oracle uses 256-bit arithmetic for signed, unequal, huge and subnormal sample sets; it checks the same sample-MCSE convention independently.

The one-update extreme fit now uses nprobe=2, exercising the repaired trace mean as well as ratios. At y=[1.2e154,0], initial components [1.2e308,.8e308], iterations=1 and tol=.2, the analytic update is additive≈1.2e308, residual≈7.2e307, ratio=.625, boundary=false, and trace MCSE=0. This deliberately simple unidentifiable-incidence fixture tests arithmetic only. Its convergence flag is the existing legal relative-change criterion, not evidence of a statistical optimum.

## 7a. Issue Ledger

I1-I4 are repaired in the isolated proposal and require independent review/integration before any live closure. The original read-only receipt stays pinned to a4ad and HOLD.

- I1: finite-response hiding by structural zeros now rejects, including BigFloat values that overflow conversion; X/Z validation is explicit across shared routes.
- I2: nonfinite final information/likelihood and nonfinite PCG arithmetic fail; finite unconverged PCG remains supported. SLQ failure now explicitly throws, with documentation updated.
- I3: stable returned ratios and boundary flags verified at the reproduced oversized total.
- I4: both trace modes produce the finite analytic mean and zero MCSE; unequal/signed summaries agree with the BigFloat oracle.
- Preserved: exact/current rank/precision proofs, MME operators, Lanczos recurrence, fixed-probe mechanism, final-variance trace reevaluation, optional exact single-wrapper likelihood, and finite-dimensional integration checks.

## 8. Consistency Audit

All data-conversion sites for y/X/Z in this file were checked; no raw `Float64.(y)`, `Float64.(X)` or `Float64.(Zi)` conversion remains outside the helper. The existing wrappers delegate to guarded paths. Precision conversion/validation remains in its signed helpers. The PCG guard sits below every consuming solve, and likelihood/information check arithmetic after the solve rather than treating a converged rhs solve as sufficient.

Final beta/effects and trace diagnostics still reevaluate at the returned variance components. The patch does not return stale pre-update effects as current ones. If a finite-input fixed-point proposal yields an invalid variance update, the existing path retains the previous validated components and sets converged=false; final effects and trace metadata are recomputed there. This is consistent state, but the result still lacks a per-failure reason field. That provenance limitation is explicitly carried rather than hidden or expanded into a new schema.

## 9. What Did Not Go Smoothly

The independent review found trace accumulation overflow while checking the original three assigned defects, so I4 was reported and included within the authorized finite-output scope. Signed intermediate dirty pins were reconciled in the separate review; this proposal starts only from the exact a4ad source. No implementation/test failures occurred after the first green proposal. The broad parent programme remains unfinished; this is a bounded repair proposal.

## 10. Known Residuals

No arbitrary conditioning/range support, global-optimum guarantee, calibration, biological recovery, full-suite freshness, performance/memory claim or source-wide approval. Finite data may still trigger an explicit unsupported arithmetic error even when a more extensively scaled algorithm could solve the problem. Positive-curvature breakdown can still reflect conditioning or underflow; no numerical condition number is inferred. Sparse QR near-collinear classification and precision-fill/resource costs are unchanged.

The fit still reports only its existing convergence flag when a finite variance update is invalid or iterations expire; no richer failure-reason metadata was added. nprobe=1 MCSE and disabled likelihood retain documented NaNs. The single-effect wrapper still omits low-level trace MCSE. Likelihood `_ratio_delta_ci` fixes and other files' input contracts belong to other lanes. No public inference/calibration or R parity expansion.

## 11. Team Learning

Memory receipt: inherited route/lane guidance, symbolic alignment, test-driven development and verification disciplines; exact current source and prior receipts are numerical truth. Golden Set: original four reproduced findings, independent zero-incidence and dense Henderson controls, signed protected helper bodies, current registered wave1/matrix-free regressions. Memory files were not edited.

Scale the consumed scalar estimand before adding large finite terms; otherwise a correct inner solve can still produce an incorrect summary. Validate original data before sparse products, since structural zeros can hide a nonfinite observation.

## 12. Cross-Product Coverage

Covers the iterative file's single/multi supplied solves, shared/per-block trace summaries, MC-fit scalar ratio outputs, matrix-free likelihood and AI finite-output contracts, plus direct wrappers via their guarded delegates. This **does NOT cover** the whole twin programme, independent approval of this proposal, full-package testing, arbitrary range/conditioning, stochastic calibration, R bridge/schema, GPU, performance or releases.

Proposed registration: copy `test/iterative_finite_contracts.jl` and `test/iterative_summary_controls.jl` into the repository and include each once near the existing wave1 numerical contract include. Keep existing wave1 and matrix-free integration test files/includes unchanged. Parent owns composition, runner registration and independent review. Apply only `iterative.patch`; do not replace another lane's whole source snapshot.

| Artifact | SHA-256 |
| --- | --- |
| proposed src/iterative_solve.jl | 91317fe23ab913767b3f4ed44f74b69b9d5e0f5a5ce46fa09ed442047f361769 |
| iterative.patch | 04e0e3e903a073632e0f286376e48cc34ae013a24ef42e2e6721f7040a859943 |
| contracts.md | cc87f4071dfef909682218b5be120b1765ca08de07efec204b4f96e0f68ecd1a |
| frozen primary test | 63c1a90b9a30ab5336f2033881dc92ff7e0ab46251eee6b7571dcfa6885550c0 |
| independent summary controls | 98b317d0f28746cb2f9c1232696fa69c8a110ac34d57b16159f2d4ffb66d7b86 |

`pins.json` retains every execution-snapshot source, dependency and test/log hash. Protected function bodies match the independent review's exact body pins: rank a2fd38cd..., canonical precision 24b0d5f1..., SPD validation eb8c787b....
