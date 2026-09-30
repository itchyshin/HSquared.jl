# Isolated random-regression descriptor repair, 2026-09-30

## 1. Goal

Repair reproduced RR-C1/RR-C2 descriptor failures in an isolated copy, preserving the frozen source and the fitted objective. Implementer: Gauss. No additional agents were spawned.

## 2. Implemented

`standardize_covariate` rejects nonfinite bounds and values, checks Float64 representability, divides before multiplying by two, and halves opposing extreme bounds when their difference would overflow. A separate offset fallback preserves finite extrapolation outside caller-specified bounds. Unrepresentable standardized values produce an input error. The affine map and normalized-Legendre convention retain their existing meaning.

`rr_heritability` normalizes each genetic/residual variance pair by its larger value before adding. It explicitly rejects an unrepresentable genetic variance trajectory. `rr_eigenfunctions` normalizes eigenvalues by their maximum before computing shares; zero covariance still returns zero shares. Descriptor result fields, eigenfunctions, and covariance units are unchanged. Plot helpers inherit the corrected ratios through existing delegation.

## 3a. Decisions and Rejected Alternatives

Grounded expected heritability in the basis: `phi0 = sqrt(1/2)`, so `phi0^2 = 1/2`. With coefficient covariance `K_g = [1.6e308]`, the genetic variance is `0.8e308`; residual variance `1.2e308` gives `0.8/(0.8+1.2) = 0.4`. The regression checks both the basis factor and the computed variance before checking the ratio. Using the coefficient variance directly would give 4/7 and would change the estimand.

Used test-driven development: wrote and ran the failure fixtures before source edits. Restricted changes to standardization and the two descriptor ratios. An overflowing genetic variance is rejected by the heritability wrapper; the underlying variance/covariance descriptor algebra remains unchanged. The MME, REML/GLS helpers, fitter, optimizer, and shared covariance guards were preserved byte-for-byte.

## 4. Files Touched

All artifacts are under `/private/tmp/hsq-rr-descriptor-fix-20260930/`:

- Copied `src/`, `Project.toml`, and `Manifest.toml`, with only `src/random_regression.jl` modified.
- `test/rr_descriptor_scale_regression.jl`.
- `rr-descriptor-fixes.patch` and `sha256-inventory.json`.
- `red.log`, `green.log`, `green-final.log`, and this `receipt.md`.

No Git directories or unrelated repository artifacts were copied. No live source, driver, schema, test runner, primary artifact, or remote state was changed. Other lanes were preserved.

## 5. Checks Run

Graft callers were inspected before editing. Its cache refresh could not acquire a lock, so the current numbered source supplied coordinates. Estimated runtime before the test: under one minute. Each Julia process used one Julia thread and one BLAS thread.

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --project=/private/tmp/hsq-rr-descriptor-fix-20260930 --startup-file=no /private/tmp/hsq-rr-descriptor-fix-20260930/test/rr_descriptor_scale_regression.jl
```

Red: 17 passed, 24 failed, zero errors, exit 1; test execution 0.8 seconds. Green: 41/41 passed, exit 0; test execution 0.2 seconds. After the final documentation clarification, the exact final source passed 41/41 again in 0.2 seconds, recorded in `green-final.log`. Every process completed within the estimate.

Fixtures cover infinite/NaN bounds and values; large same/opposing-sign endpoints through floatmax; finite extrapolation; ordinary standardization; scalar/vector heritability at large and ordinary scales; zero genetic variance; explained-variance shares for equal and unequal extreme eigenvalues; zero/rank-one covariance; and plot-helper delegation.

Patch parsing via `git apply --numstat` passed: 38 additions/7 deletions in source and 55 added test lines. No fits, full suite, simulation, GPU, remote compute, dependency update, or package installation ran.

## 6. Tests of the Tests

The red run independently reproduced all three failures. It also retained passing ordinary controls. Tests assert scale invariance against moderate inputs and explicit expected shares, so an overflowing sum yielding zero shares cannot pass. The heritability oracle uses the normalized basis factor rather than copying the faulty denominator calculation.

## 7a. Issue Ledger

RR-C1 standardization boundary: fixed in the isolated candidate. RR-C2 heritability and eigenvalue-share overflow: fixed for finite representable descriptor variances/eigenvalues. Derived genetic variances that exceed Float64 are rejected in the heritability path. Rank/conditioning, dense allocation, basis-provenance, broader-order, and inference findings remain carried.

## 8. Consistency Audit

Frozen RR SHA-256: `761151eb0297bece4c859db8a504a244a26510d320f123f85a9a9295621e7a5c`.

Patched RR SHA-256: `91992a87f0c6b20101154ed000b1f993b062c73e9c032effa54923eda5ee6c33`.

Frozen source-tree SHA-256: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.

Patched source-tree SHA-256: `985bb88ddeb64b37ac6859fcbeff5864716d1f01ac8a9c0ded4340bba9a90c3f`.

Test SHA-256: `f92c48de5a8c1b67d03b01dcad5b44ff3d3cd0ff200ca162ee753f6ed2dd1c41`.

Patch SHA-256: `ec27b69dc016d5cd1f9cd18a757da78eddc7115ce27767c129469105433f4290`.

The inventory records exact Project/Manifest and run-log pins. Whole-source comparison confirms only random_regression.jl differs. The parent explained its authorized HEAD advance to `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429` as completed FA artifacts; the frozen source-tree pin remains unchanged.

## 9. What Did Not Go Smoothly

Graft cache refresh failed with EPERM. The shared frozen source was preserved, and current source supplied the exact function boundaries.

## 10. Known Residuals

The patch is isolated and awaits parent review and landing. The standalone regression needs a test-runner include when landed. Basis/trait units remain caller-defined through the existing standardized-Legendre contract. Higher-order/scaling limits of raw variance/covariance construction and the dense fitter remain outside this repair.

## 11. Team Learning

Finite inputs can yield an overflowing sum even when the desired ratio is bounded and representable. Normalizing the positive terms before summation protects that ratio. Expected random-regression variance must include the basis factor.

Memory receipt: the exact-current RR review, current source, and red/green execution supplied the evidence. Golden Set: no broad campaign was run for these descriptor-only fixes. No memory was updated.

## 12. Cross-Product Coverage

This repair covers standardization and the supplied-descriptor ratios with existing plot delegation. It does NOT cover fitted-objective changes, MME/GLS/fitter rank or conditioning repairs, arbitrary covariance construction overflow, general R bridge parity, broader-order recovery, sparse scaling, uncertainty calibration, GPU behavior, E1 approval, capability promotion, or release readiness.

Next parent action: review the unified patch and pinned logs, retain the frozen primary candidate until acceptance work ends, then land the reviewed patch and test include in the parent's owned lane. Update only the RR-C1/RR-C2 dispositions and measure new landed source pins.
