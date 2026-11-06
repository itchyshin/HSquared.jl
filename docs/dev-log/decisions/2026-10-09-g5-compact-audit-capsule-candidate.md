# G5 compact audit capsule candidate, 2026-10-09

## Status

Candidate for independent design review only. No implementation, seed admission, fit, study attempt, acceptance-threshold change, or gate credit is authorized by this note.

## Problem and evidence

The retained G5 N=320 development artifact is 130,851,693 bytes. The exact reviewed v6 inspector replay reached its 900-second bound while `open(deserialize, path)` was reconstructing that artifact, before any row checks completed. The supervisor's postchecks and cleanup passed, but the replay failed and has zero G5 credit. The old artifact is not to be retried by simply raising its timeout.

Current source stores the repeatability attempt as an artifact payload containing `data`, `design`, raw `profile`, `result`, and `v3_profile_evidence`. The result and evidence carry the complete v4 history and certificate provenance. `inspect_artifacts.jl` currently deserializes the full artifact, then recomputes semantic data identity, the result projection, the profile-v4 tail certificate, and runtime/source identity. The v4 receipt checker also requires exact v3/v4 history aliasing, source and method identity, lossless rational/BigFloat certificate values, and a strict separation gap. Those checks must remain.

Relevant current source pins:

| File | SHA-256 |
| --- | --- |
| `sim/arc1/inspect_artifacts.jl` | `fc58f9444affe63c21ec854212ae00220728bf2f933735fd73e4cf71faf6b206` |
| `sim/arc1/execute_attempt.jl` | `8df0da58cb81ea52d6f1d603307c0a14d8cd042cf8a04e96bfd4ded94bdf524d` |
| `sim/arc1/engine_io.jl` | `4e301816d85da6beae5051352f85a4072e3bbbbf9625402c079ae70f01198443` |
| `sim/arc1/runner.py` | `60d312f48abb3c3f8fc17bf4316c042fb89bc1127319caa34e38f84e68eaae9d` |
| `src/arc1_profiles.jl` | `454eabdaf74af022d9fce9b4e38cf00a54287754b06f0efcb1d88d01b55930a8` |
| `src/arc1_interfaces.jl` | `d1f8435d1ff3b3ae5dec011fc277a660d0728334f87200cbc22c00596f5ae792` |
| `tools/arc1_receipt_check.py` | `d7e4981edcd12c57184632665f451ec0173e031a8f363372a68eb050c39f0ce2` |
| `tools/arc1_manifest.py` | `0c437d8b4950dbaad7df0cd1f745e0ef5e15ff55c3e2720772211a2a7f481c55` |

## Proposed design to challenge

For future G5 attempts, add a versioned, compact audit capsule emitted from the live completed attempt alongside the existing full JLS artifact. The capsule would be a canonical, typed projection of the exact source values needed by the current inspector: data/design identity inputs; profile point fit and five target results; v4 event/provenance history in a compact ordered representation; lossless tail-certificate inputs; requested/actual method and loaded source/environment identities. Preserve all existing refusal, interruption, and failure states. Do not delete or truncate the full artifact or evidence history.

The final attempt receipt would bind both the unchanged full-artifact SHA-256 and the capsule SHA-256, together with the same admission, source, environment, and execution identity. The receipt checker would first validate both hashes, then perform the current independent identity, projection, v4 history, and certificate checks from the capsule without deserializing the full high-allocation object graph. Legacy artifacts keep their current reader. This is a new artifact-inspection schema, not a change to the statistical estimand or acceptance thresholds.

This design remains a candidate: the reviewer must determine whether a producer-emitted projection preserves enough independent evidence to justify the same G5 claims. If it does not, hold this design and specify a stronger alternative rather than weakening a check.

## Required proof before any study use

1. Exact field map from the current inspector and Python receipt checker to capsule fields, with no omitted statuses, failures, identities, history events, or certificate inputs.
2. Deterministic schema, order, numeric encoding, missing-value handling, and alias semantics. Rational and BigFloat certificate values remain lossless.
3. Test-only fixtures proving capsule generation equals the current full-artifact projection for complete, refused, interrupted, singular, and malformed cases; mutations to any field required today must fail closed.
4. Adversarial checker tests for capsule omission/reordering, history alias breaks, altered source/environment hashes, changed data/design identity, modified artifact or capsule hashes, altered rational/BigFloat values, and a false success status.
5. Measured output size, peak memory, and validation time on a synthetic fixture. No new seed or fit is needed for this stage.
6. Independent exact-source review, then a separately admitted bounded G5 development replay on an untouched allocated attempt. The old outer-2 artifact remains diagnostic-only and receives no credit.
7. Current-source package and required-live R parity refresh after any source/transport change; update capability and gate evidence only after the canonical ledger checks pass.

## Boundaries

G2's fresh development allocation remains pending user approval. This note authorizes no G5 pilot or confirmation work, no seed/denominator replacement, no change to the fixed G5 targets/cells/criteria, and no capability-status promotion. G5 and G8 stay open.
