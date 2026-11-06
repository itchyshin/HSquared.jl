# G5 authoritative audit container candidate v2, 2026-10-09

## Status and decision

Design revision for independent review only. It supersedes candidate v1 as the current proposal, while preserving v1 and its review. This revision authorizes no implementation, fit, seed admission, study attempt, threshold change, or gate credit. G5 remains open.

The retained 130,851,693-byte legacy artifact timed out during Julia deserialization at 900 seconds. Do not retry it with a longer timeout. The synthetic N=16 preflight is engineering evidence only; it proves neither scaling nor memory bounds nor calibration.

## Current-source review findings addressed

The v1 source pins were stale. This proposal binds to the current files listed below. The independent review also found that the present reader collects every history event and then builds grouped copies, so record framing alone does not establish bounded memory. It found no independently enforced expected event count: deleting the final event and recomputing section counts/digests can leave the remaining indices sequential. It also found that native Julia Serialization has no explicit supported-type boundary, and that history/reference/schema and publication cases remain source-only rather than adversarially exercised.

Accordingly, this proposal makes no bounded-RSS promise. The format and tests must identify the concrete retained structures and measure peak RSS on synthetic sizes bracketing the legacy artifact. A measured result may support an operational limit for the inspected implementation; it cannot be generalized to constant memory. Any future claim of bounded memory needs an implementation that streams without retaining duplicate full histories, plus tests and measurement of the final returned object.

## Proposed artifact contract

Use one versioned, sectioned artifact for newly admitted attempts. Its directory binds each required section's schema, byte range, record count, and digest. The run receipt binds the whole artifact to the exact admission, source, seed, cell, and runtime identities. Each record is decoded and type-checked against a written schema before semantic validation. Julia Serialization may remain only inside explicitly enumerated record types; unsupported types, unexpected fields, invalid dimensions, invalid enum values, and trailing bytes fail closed.

Keep raw inputs/design, raw fit and target diagnostics, result projection, embedded summary, profile rows, ordered event records, reference metadata, and tail-certificate inputs as distinct sections. Recompute semantic data identity and exact raw-profile/result/summary comparisons from decoded fields. Do not trust a producer-supplied identity digest as a substitute for these comparisons.

For each event vector, retain a required expected length and identity in the profile-row section, independently of the event records. Require exactly indices `1:n`, including the terminal event, and reject missing, extra, duplicate, reordered, or unknown row/field events. Preserve absent versus empty vectors and all four states: pre-entry failure, entered partial history, method refusal, and successful completion. Validate original v3/v4 `===` alias identity before writing; preserve both stored references and reconstruct a shared object only after both IDs and the full event set pass. State the threat boundary precisely: the container and its hashes detect corruption relative to the externally retained, admission-bound receipt; if an adversary may rewrite the artifact, receipt, and admission together, hashes alone cannot establish authenticity.

Certificate verification remains independent: rebuild context from retained `y`, `X`, `Z`, and pedigree data; recompute determinant, residual degrees of freedom, design identity, and certificate from raw point likelihood and cutoff; check exact rational and BigFloat values, precision, both rounding contracts, and final `isequal`. Missing design after interruption remains unavailable. Present but unreconstructable design is invalid.

Keep the legacy JLS reader unchanged. This proposal does not migrate the timed-out artifact or reinterpret its failed replay.

## Required adversarial and performance proof before implementation review

1. Publish a field map from every current check in `inspect_artifacts.jl` and `arc1_receipt_check.py` to its section, decoded type, validation function, and failure state. Include result/summary comparisons, source and runtime identity, semantic data identity, reference identity, failure/refusal distinctions, and every certificate input.
2. Build test-only writer/reader fixtures with no model fit. Mutate one field at a time, recompute section digests and the artifact digest, and prove semantic contradictions still fail. Bind the expected whole-artifact digest to an immutable test receipt when testing receipt/admission consistency.
3. Add history mutations for terminal-event deletion with a recomputed section record count and digest, middle-event deletion, insertion, duplication, reordering, wrong row/field, absent versus empty, partial history, pre-entry failure, refusal, success, copied-but-equal aliases, wrong IDs, and conflicting values under a shared ID. The terminal deletion must fail against the separately retained expected length.
4. Specify and test the supported serialized type set, including enum type/value, tuples, dictionaries and key types, arrays/dimensions/order, missing versus nothing, nonfinite values, exact UInt64 seeds, `Rational{BigInt}`, Float64, and BigFloat value/precision. Every unsupported type must fail closed.
5. Mutate raw `point_fit_candidate` and target diagnostics while leaving result and summary fixed. Mutate certificate likelihood, cutoff, design, exact values, precision, rounding, and interruption state. Each test must assert the exact failure classification.
6. Interrupt publication after every section and during directory publication. Test truncated, reordered, duplicated, overlapping, and mismatched sections and mismatched attempt, seed, cell, source, admission, and environment bindings.
7. Measure synthetic writer time, reader time, peak RSS, and artifact size across sizes below and above the retained legacy size. Record methodology, host, Julia version, thread limits, and whether construction and inspection peak RSS are combined. Do not run a fit. Report observed measurements only; do not claim bounded memory from record framing.
8. Freeze the complete changed-source and test hashes, then obtain independent exact-source review of the field map, schema, reader/writer, adversaries, and measurements. Any changed pin restarts review.
9. Only after that review, separately estimate and request admission for an untouched G5 development attempt under the frozen allocation and criteria. Refresh Julia and required-live R checks after implementation. Pilot, confirmation, and capability promotion remain separate gates.

## Scope that remains frozen

This work does not change the five interval targets, three variance triples, sample-size ladder, development/pilot/confirmation counts, formation or coverage criteria, all-attempt denominators, exact-zero diagnostics, or failure handling. It does not authorize pilot or confirmation, replacement of failed attempts, or promotion from experimental status. G2 has separate admission and compute gates.

## Exact current-source pins

SHA-256 at candidate creation:

| File | SHA-256 |
| --- | --- |
| `sim/arc1/artifact_container.jl` | `147b281f726f40820184ba31d2c97e525550654aff88100d3ca9e077a21feee7` |
| `sim/arc1/inspect_artifacts.jl` | `d14a5eca4f39e833409031cab6c76f6227678010205357ec19475648c9e99e9e` |
| `sim/arc1/execute_attempt.jl` | `f12a0805ef49ab795f4b04d22dbae9e24015d03866565ef3d4dce29fc1072016` |
| `sim/arc1/runner.py` | `2035fdedaa7c7fe553a0a3efcf022df62f811d437c44ebb9d73d763a1d9b4b8f` |
| `tools/arc1_manifest.py` | `ad42f93728c12d3df17fd2be307561ec08b320d550271bdc6f456e408e99f64f` |
| `tools/arc1_receipt_check.py` | `b1880621b3ba6feab951e3cc141706dc1d06b9255a526411f33af8aee3217da6` |
| `test/test_arc1_receipt_adversaries.py` | `a2847ea3ac3833ae56b904d7c4d9dc7ee5ee7d831feda8332f3b85260ada4551` |
| `test/arc1_profiles_v4.jl` | `8d868194e0632dbb0743b283c32e3243d2515001881ea4fd088c224f470af0ba` |
| v1 proposal | `26cbc4041ba8f387c767763e1328d88f5aaafe5ae0ce07f79b29ee82b5892a26` |

These pins identify the review target; they are not evidence that its tests or scientific gates pass. Any source or proposal edit invalidates the review target. The earlier synthetic preflight pins four files that have since changed, so it cannot serve as current-source equivalence evidence.

## Required next step

Independent reviewer: assess whether this contract closes the v1 findings, whether the stated authenticity boundary is coherent with the receipt/admission design, and whether the exact-source test matrix is sufficient. Return PASS or HOLD with source references. Until PASS, do not implement or run a G5 study attempt.
