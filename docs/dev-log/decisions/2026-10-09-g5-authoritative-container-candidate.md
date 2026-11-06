# G5 authoritative audit container candidate, 2026-10-09

## Status

Candidate for independent design review only. No implementation, seed admission, fit, study attempt, acceptance-threshold change, or gate credit is authorized by this note. The earlier two-file capsule candidate remains preserved and is on HOLD.

## Failure being addressed

The retained N=320 G5 development artifact is a 130,851,693-byte Julia Serialization file. Its one bounded read-only replay stopped at 900 seconds while `open(deserialize, path)` was reconstructing the object graph, before semantic rows were checked. That replay failed and receives zero G5 credit. Do not retry that old artifact with a larger timeout.

## Candidate direction

For a future admitted attempt, replace the paired JLS-plus-capsule authority with one versioned Arc1 container file. The container is the artifact. It contains a fixed header, a checked section directory, and typed sections for metadata, original data and design, raw point-fit and target diagnostics, result projection, embedded summary, profile event history, and tail-certificate inputs. Each directory entry records a schema identifier, exact byte range, record count, and content digest. The top-level attempt receipt binds the container digest, admission, source and environment identities.

The reader seeks and decodes individual sections. It does not deserialize a second copy of a producer-generated summary. Raw source sections and independently retained result and summary sections remain separate records in the same authoritative file, so the reader can compare their exact decoded values. The profile-history section is an ordered record stream that can be consumed one event at a time. Its digest is checked while streaming; the reader must still validate every event and every required field. The data/design sections retain all values needed to recompute semantic data identity, not producer-supplied identity hashes alone.

The encoding is typed and lossless. It must preserve Julia enum type and value, tuples, dictionaries and key types, array dimensions and column-major layout, `missing` versus `nothing`, nonfinite floating-point values, exact UInt64 seeds, rational numerator and denominator, and BigFloat exact value and precision. The raw `point_fit_candidate` and target diagnostic objects must be encoded so the existing exact UTF-8 `repr` identities can be independently recomputed. Any unsupported type fails closed.

The container records an object-reference table for history identity. Before writing, the producer must assert the original v3 and v4 history values are the same object with `===`. Both stored field references must then point to the same object ID. The reader validates key presence, absent versus empty, reference IDs, ordering, every event value, and the distinction among pre-entry failure, entered partial history, method refusal, and successful completion. It may reconstruct one Julia object for both fields only after it has validated the stored reference IDs and original reference table. Equal-but-copied histories must fail.

Certificate validation remains independent. The reader reconstructs the required context from retained `y`, `X`, `Z`, and pedigree values; recomputes determinant, residual degrees of freedom, design identity, and the certificate from raw point likelihood and cutoff; preserves the original rounding contracts; and requires exact `isequal` agreement. Missing design after interruption remains unavailable, never validated. Present but unreconstructable design is invalid.

Legacy JLS artifacts retain their old full reader. This candidate makes no claim that the timed-out legacy artifact can be converted cheaply or safely. If review determines that the original raw history cannot be independently checked in a single container without a separate semantic authority, HOLD the design and do not weaken existing checks.

## Required adversarial proof before implementation review

1. The format specification maps every current check in `inspect_artifacts.jl` and `arc1_receipt_check.py` to exact source sections and fields. It includes the raw-profile to result to embedded-summary comparison, source identity, semantic data identity, runtime identity, every refusal/failure state, and every certificate input.
2. A test-only writer and independent reader round-trip fixtures without running a model. Mutations to any required field fail closed. The checker must reject contradictory raw and summary sections even when the container's internal section digests and outer artifact digest are recomputed.
3. History tests cover copied-but-equal references, incorrect IDs, reordering, dropped events, absent versus empty histories, partial history, pre-entry failure, returned refusal, and successful completion.
4. Diagnostic tests alter only raw `point_fit_candidate` or target diagnostics while keeping result and summary unchanged; both must be detected. Native type tests cover enums, tuples, dictionaries, arrays and dimensions, missing/null, nonfinite values, UInt64 seeds, Rational{BigInt}, Float64, and BigFloat precision/value.
5. Certificate tests mutate point likelihood, cutoff, design correspondence, exact rational and BigFloat values, precision, and both rounding contracts. Interruption tests distinguish missing design from present but unreconstructable design.
6. Publication tests interrupt after each section and during directory publication. Readers reject truncated, reordered, duplicated, overlapping, or mismatched sections and mismatched attempt, seed, cell, source, admission, and environment bindings.
7. Measure writer time, reader time, peak memory, and output size on synthetic fixtures whose sizes bracket the retained artifact. Do not start a fit for this measurement.
8. Obtain exact-source Astra PASS for the frozen schema, writer, reader, tests, and checker. Then separately estimate and admit any future untouched development attempt under the frozen G5 allocation and criteria. The old outer-2 artifact remains diagnostic-only.
9. Refresh current-source Julia and required-live R checks after implementation. G5 and G8 remain open until the canonical acceptance ledger passes.

## Fixed boundaries

This candidate does not change the five interval targets, three variance triples, sample-size ladder, development/pilot/confirmation counts, formation or coverage criteria, all-attempt denominators, exact-zero diagnostics, or failure handling. It does not authorize pilot or confirmation work, replacement of a failed attempt, or capability promotion. G2's fresh development tranche remains subject to its separately recorded approval and run gates.

## Source pins reviewed for this proposal

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

Review is against these exact source hashes and this note's SHA-256. Any source or schema change requires a new candidate and review. The design is not approved until the independent reviewer returns PASS.
