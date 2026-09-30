# Non-Gaussian finite ingress: isolated repair receipt

Date: 2026-09-30. Owner: Gauss numerical lane. Status: isolated implementation and focused checks complete; independent review and parent integration pending.

## 1. Goal

Reject nonfinite or unrepresentable family parameters and nonfinite converted responses before numerical kernels. Scope is the named constructors and count ingress only. No heritability formula, VA stationarity, transport-field expansion, or numerical model equation changes are included.

## 2. Implemented

In isolated src/nongaussian.jl, GaussianResponse.sigma_e2, NegativeBinomialResponse.theta, and GammaResponse.shape retain their original Real positivity checks and error text. They now require original finiteness, then check the converted Float64 field for finiteness and strict positivity. Positive values that overflow to Inf or underflow to zero are rejected. Representable positive subnormal fields remain accepted.

The actual ordinal type is OrderedProbitResponse, with thresholds::Vector{Float64}. It retains original length/ordering checks, adds original and converted finiteness checks, and checks strict ordering after conversion. Singleton NaN/Inf and finite high-precision endpoints that collapse to duplicate Float64 cutpoints are rejected. A finite singleton that rounds to zero remains valid because cutpoints need not be strictly positive.

New _check_finite_responses checks finite numeric response values. The generic _check_counts fallback and all nine concrete validators invoke it. Existing nonnegative/integer/binary/category/positive response domains stay in force. BinomialVectorResponse preserves its denominator-length check before response validation. Numerical callers already convert responses to Float64 before calling _check_counts, so overflow in conversion is detected before the proper-integral guard and mode work.

## 3a. Decisions and Rejected Alternatives

Use explicit constructor checks to retain existing positivity and ordering messages and preserve conversion exceptions. The changed family fields require only finite positivity; no stricter inverse-variance criterion was introduced. BetaBinomialResponse constructor n_trials/rho constraints were left unchanged and their existing invalid-bound/nonfinite controls pass. No additional constructor had the named positive-field Inf acceptance pattern beyond Gaussian, NB and Gamma. This receipt does not certify all extreme-Real conversion behavior in unrelated constructors.

The response helper validates the converted numeric vector supplied by existing kernels. It does not add another Float64 allocation. Direct low-level callers are responsible for supplying the same converted-response representation. No equations or solver behavior were changed.

## 4. Files Touched

All writes are confined to /private/tmp/hsq-nongaussian-finite-ingress-fix-20260930/: source/project copy without Git directories or campaign artifacts, isolated src/nongaussian.jl, new test/nongaussian_finite_ingress_regression.jl, red/green logs, unified patch, SHA inventory, and this receipt.

Base source: /Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl. Copied under parent-authorized HEAD 9c10f09c1bdc7f7ab19cb07c339d1dc83179f429. Parent may advance HEAD for a source-neutral local documentation checkpoint; source hashes remain the review boundary.

Frozen nongaussian SHA-256: `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`.

Isolated nongaussian SHA-256: `e96694a2dbd6cb1c416833a073fe0d38928eeb1ad2deeb0bc19a692cc351bd0a`.

Frozen source tree: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.

Isolated source tree: `4f4ae6a15862b7afb85c21e7025e26ad0d6100810d5ddd5aaaf1dd0122951eb7`.

Test SHA-256: `1947ae4f703436392d0a3556fefdfeec69bfd7eee5e704db833c021e366f9ab3`.

Unified patch SHA-256: `2e3aa1fac2f1a5b1567113bd9e986992315b756faf3350df83678d657aa102db`.

The inventory pins Project/Manifest and both run logs. Whole-source comparison confirms only src/nongaussian.jl differs. genetic_gllvm.jl remains at 0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca. No live source, primary driver, existing test, schema, C1/C4 or C3/C5 scratch copy was changed.

## 5. Checks Run

Estimate before launch: less than one minute per no-fit run on the Mac. Julia 1.10.0, OPENBLAS_NUM_THREADS=1, JULIA_NUM_THREADS=1, depot /private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia. Existing Manifest used; no package update or GPU.

Command from isolated root: `julia --compiled-modules=no --startup-file=no --project=. test/nongaussian_finite_ingress_regression.jl`.

Red frozen source: 114 passed / 27 failed / 0 errors, exit 1; test summary time 3.4 seconds. Green patched source: 141/141, exit 0; test summary time 3.0 seconds. Each process completed within the one-minute estimate including module loading. No optimizer, statistical fit, score iteration, or mode solve ran.

Direct Laplace, Gaussian VA, and GLLVM rejection controls use a temporary method that invokes the actual proper-integral guard, then throws a sentinel. A missing response guard therefore causes a test failure before statistical mode work. Existing relationship validation and guard checks can perform their usual matrix operations. The temporary method is deleted in finally, and dispatch restoration is asserted.

Graft caller query preceded the source read/edit. It reports ambiguous overload edges and an EPERM cache-refresh warning; exact source pins/call sites supply the impact evidence. Reported context savings: 24,784 tokens. git apply --numstat parses 37 additions / 5 deletions in nongaussian.jl and 87 additions in the new test. Final prose check: zero hits.

## 6. Tests of the Tests

The 27 baseline failures comprise nine positive-field Inf/overflow/underflow assertions; seven ordinal finite/conversion-order assertions; six response-finiteness assertions; and five kernel-entry rejection assertions. Existing-invalid values and ordinary finite controls pass on the baseline. The same 141 assertions pass after the patch. The smallest representable positive Float64 is included to catch an overstrict repair. Constructor tests cover original Real and converted Float64 domains explicitly.

## 7a. Issue Ledger

| Finding | Disposition |
| --- | --- |
| Gaussian/NB/Gamma admit Inf or converted zero/Inf fields | Isolated repair; original-domain and converted-field red/green evidence |
| Ordinal singleton NaN/Inf and collapsed ordering | Isolated repair; red/green evidence with finite controls |
| Nonfinite Gaussian/Gamma converted responses reach kernels | Isolated repair; direct validator and pre-mode rejection evidence |
| Existing count domains and BB bounds | Preserved; focused positive/negative controls pass |
| Complete NG-04 finite ingress | Partial repair only; finite X/Z, outer initial values and other unresolved contracts remain carried |

## 8. Consistency Audit

Base changed spans: constructors 32–35,85–88,151–157,172–175; count validators 559–607. The numerical equations below these boundaries are unchanged. Current call-site impact: scalar Laplace calls _check_counts at base 668, scalar VA at 876, and GLLVM at 246/249 per scalar or per-trait family. Fitter-constructed family objects also inherit the constructor guards; no outer catch or failure policy changed.

Integration compatibility: prepared /private/tmp/hsq-gllvm-input-fix-20260930/test/gllvm_input_guard_regression.jl lines 32 and 34 construct GaussianResponse(Inf) while building a fixture collection before an assertion runs. After this repair those constructors reject immediately. Parent must adapt those cases to assert constructor rejection and remove the impossible legal-family fixtures from that collection. This receipt does not use an invalid bit pattern to bypass the new invariant, and leaves the prepared C1/basic C4 tests unchanged.

C3/C5 genetic_gllvm patch is unchanged. The separate endpoint patch edits _check_flat_effect_integral in the same nongaussian file; its logical change is disjoint from these constructors/validators, although line offsets move. Parent should retain both after the freeze and run their focused regressions together. No endpoint patch was stacked in this isolate.

## 9. What Did Not Go Smoothly

Graft could not refresh its cache because the sync lock was denied. Its current function coordinates were used for navigation and confirmed against pinned source. No source ownership conflict or runtime overrun occurred. The actual ordinal name and count-checker name differ from shorthand in the brief; the patch uses OrderedProbitResponse and _check_counts.

## 10. Known Residuals

This slice does NOT cover finite design matrices/outer starts, all malformed metadata, general separation, consistent outer failure handling, logistic VA covariance stationarity, objective provenance, payload fields, predictor-variance heritability semantics, multiple-trial h2 handling, numerical tail robustness, calibration, or capability promotion. Constructor acceptance of finite positive subnormal fields does not establish successful kernel evaluation for those extremes. Independent 141-check review and parent integration remain pending.

## 11. Team Learning

Check family parameters both before and after conversion. Preserve valid subnormal values while refusing conversion to a forbidden zero or infinity. An ordered vector also needs ordering checked in its stored precision. Retest early-error fixture construction when tightening a constructor invariant.

Memory receipt: no durable memory edits; current technical evidence comes from the frozen source and isolated tests.

## 12. Cross-Product Coverage

Golden Set: Inf/NaN/nonpositive family fields; high-precision overflow/underflow; representable subnormal fields; ordinal singleton/nonfinite/collapsed cutpoints; all ten count-dispatch paths; existing integer/binary/trial/category/Gamma domains; preserved BB bounds; no-mode scalar Laplace, Gaussian VA and GLLVM entry checks.

Parent next action: review the patch/receipt and independent check, integrate after the source freeze, adapt the two C1/basic C4 constructor fixtures, and run the combined focused files. No public source or capability row was changed.
