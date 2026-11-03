# G5 N320 outer-2 post-run review

## Review scope

This read-only review covers the retained G5 repeatability development attempt at N=320, near-zero additive variance, outer index 2. It is bound to admission SHA-256 `95b806468958a01e3727615f49b22993f3aa5aee81f1e59d936a17a2dae024ac` and plan SHA-256 `e0a6b34b81caa2ebf368c01b41af2cfee4da29bb2ed6af8fb74de74a94bd33f9`.

## Result

**PASS for the retained record's integrity and reported target outcomes.** The result is one development attempt only. It does not qualify G5 or authorize pilot or confirmation work.

The reviewed run used outer 2, seed `688524427072088691`, 640 records, Julia 1.10.0, four Julia threads, and BLAS one. The child exited zero. The result reports `success=true`, `status=ok`, and method `arc1_profile_v4`. The point fit is `ok`, `point_fit_not_optimal=false`, and the profile likelihood-ratio cutoff is `3.841458820694124`. Source and environment identities match the admitted hashes.

All five targets are marked formed with explicit formulas and ordered finite intervals:

| Target | Formula | Interval |
| --- | --- | --- |
| Additive variance | `Va` | [0, 0.1737097674] |
| Permanent-environment variance | `Vpe` | [0.0132283170, 0.3015970943] |
| Residual variance | `Ve` | [0.6939664903, 0.9462693695] |
| Heritability | `Va/(Va+Vpe+Ve)` | [0, 0.1675143433] |
| Repeatability | `(Va+Vpe)/(Va+Vpe+Ve)` | [0.0878969727, 0.2986093140] |

For this one generated dataset, the residual-variance and repeatability intervals exclude their generating values. This is a single-attempt outcome and provides no coverage-rate estimate.

## Integrity and limits

The independent reviewer verified the canonical admission identity, all 194 remote source pins, runtime identity, point and interval receipt checks, and the result, JLS, Julia log, and summary hashes. The locally retained compact projection is `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/outer2-verification.json` (SHA-256 `6e108a8301b1fcb7d2090f7abc1234b4f383f91213c7fcb9cad17253a8b436a4`). The exact full output remains on Totoro at `/home/snakagaw/hsq_work/arc1-g5-n320-dev-prerun-v2-20261007/results/attempt-v2/repeatability/development/N320/near_zero_additive/attempts/`.

The reviewer did not deserialize the JLS artifact or independently reconstruct raw-profile/tail-certificate correspondence. Timeout cleanup was not exercised. The JSON result and Julia log are each about 1.37 GB; the run used a maximum of 9,554,532 KiB RSS. Do not multiply this one-run cost into a campaign estimate without an allowance for variation.

## Decision

Retain outer 1 as a consumed timeout and outer 2 as a consumed successful development attempt. Change no seed, denominator, criterion, capability status, or gate state. G5 remains open until the frozen development, pilot, and confirmation evidence satisfies its full requirements.
