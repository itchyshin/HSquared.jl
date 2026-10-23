# Independent endpoint guard review

Date: 2026-09-30. Reviewer: Curie. Verdict: **PASS for the two shared-guard conditions in isolation**. Post-freeze integration and test registration remain open. No live files changed and no fit, optimizer, statistical mode iteration, score or Hessian evaluation ran.

## Reviewed artifact and pins

Prepared root: `/private/tmp/hsq-flat-integral-endpoints-fix-20260930`.

| Artifact | SHA-256 |
| --- | --- |
| Unified patch | `377949339080913493db2a6c48916b4eae7aae9c15f5c54c5d859c1f139c1e9e` |
| Regression test | `0897e4b8cdc7c9579886d006ce8465a985969390888c528b268997caa0cb110b` |
| Frozen nongaussian source | `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00` |
| Proposed nongaussian source | `c609b2a58de819ad8a96b74525895a92cd5f2b9517c080a5ec678ae348d87e9f` |
| Frozen source tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| Proposed source tree | `340c3724679c13e5203976cb481d92a79d75ba2091f433f95afa23884463d2ee` |

All entries in the supplied SHA inventory independently match, including Project, Manifest, genetic_gllvm, receipt and original logs. Source trees use sorted src-relative path, NUL, bytes, NUL. Frozen source/tree and prepared patch/test hashes match before and after review. Candidate HEAD is `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`; `git apply --check` passes without applying the patch.

## Logic and placement

Only two conditions change in prepared `src/nongaussian.jl:620–629`. NegativeBinomialResponse joins Poisson all-zero detection; BetaBinomialResponse joins scalar Binomial all-zero/all-success detection. Constructor fields at 83–89 and 107–116 match the predicates: NB has theta, beta-binomial has scalar n_trials and rho. No constructor or kernel fields change.

For finite positive NB theta, the probability of zero tends to one as the intercept tends to minus infinity. For scalar beta-binomial trials and rho in (0,1), the endpoint mass tends to one as the mean tends to zero or one. Thus a flat fixed-effect measure has a nondecaying tail whenever col(X) contains an intercept direction. The shared helper at 612–638 retains rank validation, rescaled intercept detection, p=0 exemption and existing ArgumentError text. Passing this necessary check does not establish propriety for arbitrary designs.

Scalar Laplace invokes the helper at nongaussian:669 before beta/u initialization. GLLVM invokes it per trait at genetic_gllvm:259–262 before record-design and mode work. VA invokes it at nongaussian:877 before prior/mode work; that route was inspected only. GLLVM outer negloglik at genetic_gllvm:635–643 catches only GLLVMParameterEvaluationError, so the new ArgumentError still propagates. Outer failure handling remains open.

## Independent deterministic checks

Owned copy and logs: `/private/tmp/e1-flat-integral-endpoint-independent-20260930`. Estimate before running: both runs together under one minute, Julia 1.10.0, JULIA_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1. Supplied tests were wrapped in one outer testset so cleanup is counted.

| Source | Core assertions | Cleanup | Overall | Testset time | Exit |
| --- | --- | --- | --- | --- | --- |
| Frozen | 20 pass / 15 fail | 1 pass | 21 pass / 15 fail / 0 error | 7.0 s | 1 |
| Proposed | 35 pass | 1 pass | 36 pass / 0 fail / 0 error | 6.4 s | 0 |

The receipt's 35 core assertions plus one cleanup assertion are confirmed. The nested red core took 3.4 s; wrapper timings include loading. Baseline failures cover six direct helper assertions and nine scalar/GLLVM kernel assertions. These would fail if either new family were omitted, beta-binomial all-success were omitted, or the kernel bypassed the guard.

Test lines 8–15 invoke the true generic helper before throwing a sentinel on a successful guard visit. Mixed-family tests at 60–62 place the endpoint family second and wait for two visits, avoiding a stop at the preceding Gaussian trait. Cleanup at 79–84 removes the temporary method and confirms restoration. Guards still perform rank/least-squares operations and kernels validate precision before reaching the sentinel.

## Controls and residuals

Tests at 40–51 cover ordinary and rescaled intercepts, p=0 exemption, mixed endpoint/non-endpoint counts, interior counts, and retained Poisson/binomial rejection. Kernel controls at 63–74 reach the sentinel for p=0 and selected non-endpoint responses. They establish availability through the shared guard; subsequent fitting behavior is untested.

No new control uses a nonempty design without an intercept; the unchanged has_intercept early return was inspected. General separation along other columns, complete integral propriety, constructor-domain hardening, outer optimizer error conversion, VA runtime behavior, per-record beta-binomial trials, inference/calibration and capability promotion remain outside this slice. Test entry-point registration and post-freeze integration are still required.

Minimal next validation: register this exact regression file after landing; retain the 15-failure frozen-source comparison and 36-assertion green result. Add a nonempty no-intercept control when extending the design-level propriety checks. No additional numerical run is required for this bounded guard verdict.

Graft reported approximately 128,173 tokens saved relative to reading its eight returned files in full. Technical review used the exact bounded source spans above. All review writes are confined to this report and the owned independent scratch directory.
