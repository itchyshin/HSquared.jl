# Independent post-fit marker contract review

Date: 2026-09-30. Verdict: **HOLD: negative Real additive variance can underflow through the new zero boundary**. Both convergence checks and ordinary zero-additive mixed/LOCO results pass the bounded checks. No live edits, fitting or optimizer ran.

## Exact reviewed pins

Prepared root: `/private/tmp/hsq-postfit-marker-contract-fix-20260930`.

| Artifact | SHA-256 |
| --- | --- |
| Patch | `85cd8b1b2fe6a08714edfde46b5079f3b5321ac29473e5610ea8909c0340db8e` |
| Frozen postfit | `d065d525ccdca8c8d881432f3c312141929571d52629f38bf72cfc513bdbf71f` |
| Prepared postfit | `28486afa2c11adf38aeda6149d9b858f7968f751dbea34ef09174243d721adc3` |
| Frozen genomic | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` |
| Prepared genomic | `0b68901b2a7f1e5cd72d5046f6ae46ec9c9ab70dfb7f927012f046cfe333e40e` |
| Prepared registered test | `051fdc873c692989cbc1e93bc5e55f9db895d457e2eabcf18d9cab520b76daf9` |
| Prepared docs | `d499c33d4805abcbb2b55a0579b32ae26673b689502726590b960c32668a3a26` |
| Supplied runtime script | `aced423e1374171269f62132ece49bbe4eda752c02cfe08743a2088959cc7ba2` |

These source/prepared/runtime-script pins independently match the supplied inventory. Manifest matches `c5940f2be0347f7ff987468aed67f17070f556a0aa99e0e5ec5317898cfa0fad`. The unchanged live source tree remains `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`; candidate HEAD is `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`. `git apply --check` passes without applying the patch. All writes are in this report and `/private/tmp/e1-postfit-marker-contract-independent-20260930`.

## Finding requiring repair

Prepared src/genomic.jl:857–860 converts sigma_a2::Real to Float64, then checks sa2 >= 0. Set `negative_tiny = -BigFloat(10)^(-1000)`. The original value is negative, but its conversion is -0.0, which passes the new nonnegative guard. Both explicit mixed_model_marker_scan and loco_mixed_model_marker_scan therefore return results for a negative supplied variance.

Independent underflow.jl:5–8 confirms the negative sign and zero conversion, then expects ArgumentError from both scans. Result: **2 pass / 2 fail / 0 error**, 3.5 seconds, exit 1. The ordinary -eps() control cannot expose this conversion loss. The original strictly-positive converted guard rejected that zero result; this bypass arises when the domain widens to include zero.

Minimal repair: validate the original Real's nonnegative sign before conversion, retain finite/nonnegative checks on the converted additive value and finite/strict-positive converted residual checks, and add negative-underflow controls for both routes. No change to negative signed zero as a numerical zero is required. This review leaves the implementation to its owner.

## Passing bounded checks

Prepared src/postfit.jl:34 and 56 check fit.converged before either fitted convenience method delegates. Explicit supplied scans do not require a fit object. The shared helper src/genomic.jl:832–880 serves mixed and LOCO routes; its other input guards are unchanged. Covariance formation at 897–901 still uses sigma_a2*Z*A*Z' + sigma_e2*I, so true zero additive variance with positive residual variance has the required GLS boundary.

Independent red.jl constructs a synthetic six-argument AnimalModelFit; no optimizer runs. Four frozen-source witnesses pass: both fitted scans accept a nonconverged fixture, and both explicit mixed/LOCO scans independently throw the old positive-additive error at true zero. These separate checks repair the supplied red script's evidence gap, which stopped at its first convergence failure.

Independent green.jl includes the exact supplied runtime script (13 assertions) and adds 24 independent controls: a nonconstant fixed-effect column, augmented QR OLS coefficients, QR projection for marker information and Wald errors, two distinct LOCO precisions/groups, and both-route invalid additive/residual controls. **37/37 pass**, 5.0 seconds, exit 0. For zero additive variance the oracle uses ordinary linear algebra without any marker-cache or scan helper: coefficients come from QR([X,w])\y, information from the residual marker norm, and SE from sqrt(sigma_e2/information). Effects, errors, z-scores and denominator scaling agree within 1e-12.

Runtime estimates were stated before each run: under one minute, Julia 1.10.0, one Julia thread and one BLAS thread, copied Manifest, --startup-file=no --compiled-modules=no and the approved depot order. No simulation ran. Exact own scripts/log hashes are saved in independent-pins.json in the owned check directory.

## Documentation and evidence limits

The mixed fitted-method docstring at postfit:24–28 and visible docs at docs/src/genomics-qtl-gpu-hpc.md:420–425 state that both fitted scans require convergence and marker rows must follow fit.spec.y observation order; the scans have no ID-alignment information. Experimental dense validation-scale and uncalibrated Wald limits remain visible. The single fitted-method docstring itself does not repeat the new row-order text; the shared visible page supplies it.

The inventory fields called red_baseline_postfit_sha256 and red_baseline_genomic_sha256 equal the prepared hashes, so they describe restored files rather than frozen runtime state. Do not use those two labels as proof of the red source. This review's own frozen-source copy and separate witnesses provide that proof; relabel the metadata when updating the receipt.

Existing test/runtests.jl receives the focused assertions, so this patch includes registration. Package-wide tests, fitting/calibration, marker-row ID alignment, correlated-marker thresholds, R formula activation and capability promotion remain unproven. After fixing the conversion bypass, rerun the supplied/QR controls and the new two-route negative-underflow controls at changed exact pins; then review for post-freeze integration.

Graft caller lookup reported 30,649 tokens saved. Returned helper coordinates were stale; the exact prepared helper and its two direct callers were inspected at their current spans. No whole-source audit was repeated.
