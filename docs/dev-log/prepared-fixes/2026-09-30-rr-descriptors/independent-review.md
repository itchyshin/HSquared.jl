# Independent RR descriptor repair review

Date: 2026-09-30. Reviewer: Curie. Reviewed the isolated patch and receipts under /private/tmp/hsq-rr-descriptor-fix-20260930. No live source, test registration, driver, Git state, or biological campaign was changed. No fit, simulation, or RNG draw ran.

## Verdict

PASS for RR-C1 finite-bound/standardization ingress and RR-C2 heritability/eigenvalue-share sum overflow on finite representable descriptor inputs. The affine map, normalized Legendre basis, and fitted objective retain their intended meaning. Whole-file approval, E1, rank/conditioning, basis provenance, broader-order recovery, and inference remain carried. The patch is scratch-validated and awaits post-freeze landing and test registration.

## Source and oracle checks

Patched random_regression.jl:76-97 rejects nonfinite values/bounds, checks Float64 conversion, and requires distinct increasing bounds after conversion. Division before multiplication protects same-sign large endpoint maps. Halving endpoints when width overflows preserves the affine fraction for opposing extremes. The offset fallback handles finite extrapolation with an overflowing subtraction. Unrepresentable standardized values explicitly reject.

Lines 177-190 normalize each nonnegative genetic/positive residual variance pair by its maximum before summation, preserving the bounded ratio without an overflowing denominator. The finite genetic-trajectory check rejects an unrepresentable variance. Lines 221-237 normalize finite nonnegative eigenvalues before summing their shares and retain zero-matrix shares. Shared PSD/eigenvalue guards are unchanged. Only these descriptor calculations and their documentation change; Legendre recurrence, covariance construction, MME, likelihood, GLS, fitter, optimizer, and plot delegation remain unchanged.

The heritability oracle is grounded independently in normalized phi0 squared = 1/2. Thus coefficient covariance 1.6e308 gives genetic variance 0.8e308; residual 1.2e308 yields 0.4. The tests verify the basis factor and genetic variance before asserting the ratio, compare with moderate scaling, test vector residuals and zero genetic variance, and test rejection of an overflowing genetic trajectory. Equal/unequal eigenvalue controls assert explicit shares, sum one, scale invariance, zero/rank-one cases, and plot-helper delegation. These controls fail the old zero-ratio/zero-share result.

## Independent execution and pins

Estimate before execution: under one minute, one Julia thread and one BLAS thread. Independent patched run: 41/41 PASS in 0.1 seconds of test time. Six supplemental controls also PASS in 0.1 seconds: BigFloat covariate overflow, BigFloat bound overflow, bounds collapsing in Float64, and three BigFloat affine-oracle comparisons for extreme/opposing endpoints and extrapolation. Log: /private/tmp/e1-rr-descriptor-independent-test-20260930.log. The supplied red receipt records 17 passes, 24 failures, and zero errors before the repair.

All inventory artifacts match. Independently recomputed source-tree fingerprints and file comparison confirm that only random_regression.jl differs. Patch, source, and test fingerprints match before and after review:

- Frozen source tree: d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a
- Patched source tree: 985bb88ddeb64b37ac6859fcbeff5864716d1f01ac8a9c0ded4340bba9a90c3f
- Patched RR source: 91992a87f0c6b20101154ed000b1f993b062c73e9c032effa54923eda5ee6c33
- Patch: ec27b69dc016d5cd1f9cd18a757da78eddc7115ce27767c129469105433f4290
- Test: f92c48de5a8c1b67d03b01dcad5b44ff3d3cd0ff200ca162ee753f6ed2dd1c41

## Residuals and minimal landing checks

The raw genetic-variance/covariance descriptor algebra is unchanged; arbitrary covariance construction overflow remains outside this repair. Empty inputs, arbitrary conversion failures, broader-order coordinates, and general ill-conditioning are not comprehensively tested. Bounds/convention provenance is still absent from fitted outputs. Fixed-effect rank ingress, finite final coefficients, dense allocation, permanent-environment modeling, bridge parity, and calibration remain separate requirements.

After the source freeze, land the reviewed patch with a test-runner include, record new source pins, and run focused integrated descriptor/basis checks. Update only RR-C1/RR-C2 dispositions. No recovery campaign is needed to close these arithmetic defects.

Graft was consulted for descriptor context; current numbered scratch source supplied exact spans because its graph cache was stale. Graft reported 96,106 tokens saved for this review.
