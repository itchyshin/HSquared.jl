# Bounded profile v2 engineering replay

Status: preparation only. Implementation and independent source review are pending. No replay has launched and no study admission is created by this plan.

## Purpose and prerequisites

Replay the two retained engineering datasets whose v1 results contained unresolved targets: N=160 near-zero additive variance and N=320 near-zero additive variance. Use the identical serialized inputs, explicitly request `arc1_profile_v2`, and retain every target, nuisance candidate, continuation certificate and failure. Keep the original v1 artifacts unchanged. A successful replay proves only those two fixture results.

Before launch, require passing focused numerical and method-identity tests, an independent Astra review of the exact numerical source and tests, an inspected replay driver and supervisor, and a frozen transitive source inventory. The public v1 request must still select v1. Any source change invalidates the replay freeze. No allocated development, pilot or confirmation seed may be used.

## Inputs and execution bound

The retained N=160 input SHA-256 is `5fbc81067b1c9fe72c8af8f02dd3955e4cf5f3717b66b3f8b81016d0d4728d2b`; the N=320 input SHA-256 is `54c2b18a7c7094b02c687dbdce2be98973faf0113c74c76c739845a648178061`. Resolve their exact existing paths from the prior six-case receipt and verify the bytes before deserialization. Do not generate replacements.

The prior v1 cases took 130.26 and 178.28 seconds end to end on Totoro. The candidate-only v2 feasibility refinements each required one additional iteration, but a complete v2 profile may visit a different set of coordinates. Estimate 3 to 5 minutes for the paired replay after package loading, with a hard five-minute process-group limit per case and six-minute batch limit. Stop and retain results if either bound is reached; do not retry automatically. This bound is for two engineering fixtures, not a campaign estimate.

Use two Totoro workers, four Julia threads per worker, BLAS one, the existing ControlMaster connection, exact Julia 1.10.0, and a private writable depot followed by the existing offline depot. Bound the preliminary package-load probe separately to 30 seconds. Pin the Julia executable, source inventory, input files, driver and supervisor before execution. The supervisor must reap all launched children and retain exit, timeout and signal state.

## Retained result and interpretation

Write to a new output directory. Retain lossless input/result objects, stdout/stderr, wall time, profile-call time, peak memory, source-before/source-after hashes, exact command and environment, and a collection verification. Confirm method identity and inspect all five target statuses in each result. For every new continuation, check fixed coordinates, original plus continuation iterations, native original history, terminal/projection/face score spread, gradients, physical-zero probes, and superior-history guards. Refusals remain visible and are never replaced.

Compare v2 target formation with the preserved v1 records. Record any newly visited unresolved candidates, disconnected sets, point-fit guards or numerical failures. Even ten formed targets do not establish formation rates or coverage, qualify a pilot, close G5, or authorize a study campaign. Larger studies remain subject to matched-source admission, pilot qualification and the separate measured campaign approval above three hours.
