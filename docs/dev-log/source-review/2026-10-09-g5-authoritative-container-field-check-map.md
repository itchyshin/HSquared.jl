# G5 authoritative-container field-to-check map

Status: review aid for the exact G5 source set below. This is not gate evidence or a G5 acceptance claim. Astra's exact-source repair review passed; overall acceptance remains on hold until this map and the Python adversarial validation are reviewed and complete. No scientific threshold, estimand, seed allocation, denominator, or gate state is changed here.

## Exact source set

| Path | SHA-256 |
|---|---|
| `sim/arc1/artifact_container.jl` | `147b281f726f40820184ba31d2c97e525550654aff88100d3ca9e077a21feee7` |
| `sim/arc1/execute_attempt.jl` | `5ee18d920ca7c557fb44904b4979ef8c0dc00768ac8090cecc8a01ce2f2e582a` |
| `sim/arc1/inspect_artifacts.jl` | `d14a5eca4f39e833409031cab6c76f6227678010205357ec19475648c9e99e9e` |
| `sim/arc1/runner.py` | `752cc16c8542ac99da0a266857775436e0355984cec4227d79111ef3cbeaca2d` |
| `tools/arc1_manifest.py` | dynamically inventoried by admission; verify against the exact admission receipt before use |
| `tools/arc1_receipt_check.py` | `3ff6d5dfcd860db4fc1ccb717df460bbb78868bf63d15c35f8b278d145c87db8` |
| `test/arc1_simulation_executor.jl` | `411618a09c72b5fe573696ecdd12fe94b4ed04c169d77febfe11d4d22a0d54c0` |
| `test/test_arc1_receipt_adversaries.py` | `a902b5b73fc8d73d95c9608122e75e2d543ee9d8c75ef675f1af156a340d3c70` |
| design candidate | `docs/dev-log/decisions/2026-10-09-g5-authoritative-container-candidate.md`, SHA-256 `26cbc4041ba8f387c767763e1328d88f5aaafe5ae0ce07f79b29ee82b5892a26` |

The executor's dynamic source inventory recursively includes `sim/arc1` files (`tools/arc1_manifest.py:33-53`); admission hashes the discovered files and validation requires their presence and matching bytes (`:481-542`, `:701-772`). The executor includes `artifact_container.jl` (`sim/arc1/execute_attempt.jl:521`); the inspector includes it (`sim/arc1/inspect_artifacts.jl:14`). The exact run admission remains the final authority for the complete source hash set.

## Predicate overview

The tables in this section are an index only. The authoritative mapping is the one-predicate-per-row table under **Predicate-level map** below.

Each row names the source predicate, the native value and encoded path, the independent check or failure behavior, and the current test evidence. `Julia suite` means the retained exact-source log `/private/tmp/arc1-container-decoder-final-verified.log`, SHA-256 `0d155182d61e1a997b304c870710e61efd5a631a77b859039708746259484c13`: 194/194 executor tests, 10/10 reference-admission checks, and 15/15 diagnostic-identity checks. The focused current-source three-adversary probe was reported 3/3 in `/private/tmp/arc1-container-adversary-green.log`, SHA-256 `5f8bf97eaae5abe477f5f7358b65fefb15c13e75c0fdf04ae42a20560d77355e`; it is supplemental to, not a replacement for, the full suite. The Python adversary script was stopped after 23 progress dots, exit 130; all rows depending on it remain unverified.

### Container integrity and publication

| ID | Existing predicate and source | Native value and container representation | Independent check, failure, and evidence |
|---|---|---|---|
| C1 | Writer refuses replacement and stages complete sections before publication (`artifact_container.jl:156-197`). | Output path, sorted section names, serialized native values. | Existing destination is rejected; staged bytes are moved into place only after writing. Suite: container writer/round-trip tests pass. Failure-injection and crash-durability behavior beyond these checks are not separately validated. |
| C2 | Header magic, format version, positive section count, and per-section schema are checked (`:199-222`). | Eight-byte magic, version, directory entries. | Reader rejects incompatible header/version/schema and zero sections. Suite: malformed identity/serialization tests pass; exhaustive format-version mutation inventory is not independently reported. |
| C3 | Section names are unique and ordered; schema binds each name (`:207-222`). | Name, schema, offset, length, record count, SHA-256. | Duplicate, reordered, and unknown-schema entries fail closed. Suite: malformed-container cases pass. |
| C4 | Directory ranges are contiguous, non-overlapping, and consume the complete file (`:224-238`). | Section offsets and byte lengths, total artifact size. | Rejects gaps, overlap, truncation, and trailing container bytes. Suite: malformed-section rewrite/adversarial cases pass. |
| C5 | Section bytes are read exactly and SHA-256 checked before decoding (`:239-256`). | Every native section's complete byte range. | Short reads, wrong digests, and incorrect lengths fail before publication. Rehashed semantic attacks are included in the Julia suite. |
| C6 | Non-history sections declare exactly one record; decoded serialization must consume the payload (`:230-231`, `:150-154`, `:264-268`). | Singleton metadata/data/design/profile/evidence/result/summary/reference sections. | Zero/multiple record claims and trailing serialized objects or bytes are rejected. Suite passes the added singleton count and trailing-byte adversaries. |
| C7 | Exact event read length is checked after `read` returns; each serialized event consumes its record, and no bytes remain (`:253-271`). | Length-prefixed event stream. | Rejects short reads and trailing record/section bytes. The reader does not establish a pre-read allocation bound from remaining section bytes; this map makes no bounded-memory claim. Suite and green probe pass exact-length and trailing-byte cases. |

### Object identity, aliasing, and native history

| ID | Existing predicate and source | Native value and container representation | Independent check, failure, and evidence |
|---|---|---|---|
| R1 | Original object identities are collected before projection (`artifact_container.jl:40-103`, `:425-481`). | Native evidence, v3/v4 history, evaluation event vectors, result and summary references. | `objectid`-derived IDs are retained in the `references` section before values become markers. Suite passes original alias-topology and typed round-trip tests. |
| R2 | Reference IDs have one compatible semantic category (`:292-313`). | Evidence dictionary, profile-history arrays, per-evaluation event arrays. | Rejects one ID reused across evidence/history/event categories. Suite and green probe pass rehashed cross-category collision tests. |
| R3 | Entered v3/v4 history fields must be reference markers with recorded IDs; absent pre-entry keys remain absent (`:315-325`, `:396-422`, `:483-535`). | `evidence.arc1_profile_v3_evaluations` and `evidence.arc1_profile_v4_evaluations`. | Native array substitution or missing references fail before reconstruction. The suite covers native substitution and pre-entry absence. |
| R4 | v3 and v4 history use the same original object when both are present (`:40-103`, `:396-422`, `:483-535`; inspector `:234-239`). | Two native history keys and their reference markers. | ID equality is required before restoration and restored values must be `===`. Suite passes alias round-trip and split-alias rejection cases. |
| R5 | Event fields are restricted to the declared fields; references must match the exact row and field (`:327-351`, `:353-394`). | `events`, `producer_history`, `provenance_failures` arrays encoded as row markers plus ordered history records. | Rejects missing/wrong markers, malformed row fields, reordered/gapped indices, and events for unknown fields. Suite passes event-stream and identity adversaries. |
| R6 | Reused event IDs must resolve to one object with consistent values (`:353-394`). | Reconstructed event arrays for each row/field. | Equal decoded values under the same valid ID share one vector; conflicting values fail. Suite passes same-ID conflict and alias-topology cases. |
| R7 | Raw result and embedded summary must reference the original evidence object (`:425-481`, `:483-535`). | `result.v3_profile_evidence`, `summary.v3_profile_evidence`, and top-level evidence section. | Writer checks original object identity; reader checks reference markers and restores the common evidence object. Suite passes result/summary/evidence alias round-trip. |
| R8 | Malformed native evidence remains diagnosable but cannot become accepted evidence (`execute_attempt.jl:630-643`; inspector `:286-315`). | `v3_profile_evidence_raw` fallback plus error/interruption metadata. | Fallback preserves the raw malformed graph separately from admissible `v3_profile_evidence`; status remains failure. Suite passes retained split-history fallback test. |

### Data, result, summary, identity, and profile-method predicates

| ID | Existing predicate and source | Native value and container representation | Independent check, failure, and evidence |
|---|---|---|---|
| D1 | Required metadata binds outer index, exact seed, cell, execution identity, and admitted driver/protocol identity (`inspect_artifacts.jl:166-179`). | `metadata.outer`, `seed_string`, `cell`, `execution_identity`, `driver_protocol_identity`. | Inspector refuses missing required metadata; external admission later compares cell/seed/source/protocol pins. Julia suite covers fake-engine admission and metadata. |
| D2 | Complete data and design are retained separately (`artifact_container.jl:425-481`; inspector `:187-196`). | `data`, `design`, including response, X/Z, IDs and pedigree inputs. | These remain native sections, not a summary projection. Semantic identity is recomputed from retained values. Suite covers typed-section round-trip; complete source-field adversarial coverage remains part of Python validation. |
| D3 | Data seed equals the admitted exact seed (`inspect_artifacts.jl:197-199`; receipt checker `:918-946`). | `data.seed`, metadata `seed_string`, external canonical outer seed. | Inspector compares data and metadata; receipt checker independently compares attempt, artifact metadata, cell, seed, and 1-based order. Julia admission suite passes; Python adversarial validation is incomplete. |
| D4 | Semantic data identity matches retained data/design and the declared identity method (`inspect_artifacts.jl:193-206`, `:346-353`). | `data`, `design`, semantic identity hash/method metadata. | Inspector recomputes the identity and rejects absent/incorrect declarations; receipt checker pins exact source and admission identity. Suite passes ordinary identity checks; Python corruption checks are incomplete. |
| D5 | Raw result projection reproduces the independently derived receipt and reference scale (`inspect_artifacts.jl:185-212`, `:335-344`). | Native `result`, reference traits/scale, JSON projection. | Inspector compares raw result to its derived receipt, reports projection differences, and checks reference scale. The result/summary contradiction test is Python at `test/test_arc1_receipt_adversaries.py:1686-1731`; Python run incomplete. |
| D6 | Stored receipt summary equals the retained result's derived receipt (`inspect_artifacts.jl:181-190`, `:335-344`). | Native `result`, embedded `receipt_summary`, rendered JSON and SHA-256 identities. | Summary/result mismatch fails; both exact rendered identities are exposed to the receipt checker. The Python contradiction test at `test/test_arc1_receipt_adversaries.py:1686-1731` remains unverified. |
| D7 | Requested, actual, returned, metadata, and retained result profile-method versions agree (`inspect_artifacts.jl:216-221`, `:251-312`; receipt checker `:177-262`, `:265-346`). | Metadata method fields, evidence sink method fields, result method version. | Mismatches fail identity validation. Explicit error/interruption states may lack a completed result under the stated branch conditions. Julia fake-engine suite passes; Python version-specific audit remains incomplete. |
| D8 | Loaded engine and retained result/reference source identities agree (`inspect_artifacts.jl:25-53`, `:223-225`, `:260-312`). | Current loaded engine identity, result `source_identity`, `reference_source_identity`, evidence source identity. | Inspector recomputes loaded identity and requires exact equality for requested profile methods; source-root mismatch fails. Suite tests source-bound executor; independent Python run incomplete. |
| D9 | Native submitted profile evidence equals the complete retained evidence sink (`inspect_artifacts.jl:320-330`; receipt checker `:265-346`). | Native `v3_profile_evidence`, submitted evidence record, requested/actual/returned versions, ordered histories and certificates. | Python checker compares submitted and native evidence and validates method identity, history aliases, and certificate provenance. Julia suite passes source-bound executor; Python validation is explicitly incomplete. |
| D10 | Status, success, partial evidence, interruption, and failure remain distinct (`inspect_artifacts.jl:213-221`, `:246-312`; receipt checker `:177-262`). | Retained result status/success, metadata status, history presence, error/interruption. | Inspector emits separate status, success, identity and partial-presence diagnostics; receipt checker requires consistent status-specific interval/selection outcomes. Julia executor tests pass; Python status-corruption tests remain incomplete. |

### Profile diagnostic identities, estimands, and certificates

| ID | Existing predicate and source | Native value and container representation | Independent check, failure, and evidence |
|---|---|---|---|
| P1 | Native `point_fit_candidate` and `targets` are retained in the attempt payload (`execute_attempt.jl:203-245`, `:368-376`) and identity fields are exposed by the inspector (`inspect_artifacts.jl:320-344`). | Native diagnostic values, source/reference identity, point-fit and target records. | Checker verifies diagnostic identity strings and point/target guards. Suite passes exact representation hash tests 15/15; Python adversary test file is incomplete. |
| P2 | Required repeatability targets and formulas match the frozen target set (`tools/arc1_receipt_check.py:134-174`, `:1146-1178`). | Five targets and formula labels in profile output. | Checker validates target names, formulas, interval segments, statuses, finiteness and ordering. Julia suite does not establish coverage; Python evidence remains incomplete. |
| P3 | Rank candidates and decision guards are independently checked (`tools/arc1_receipt_check.py:452-566`). | Candidate scores, eligibility, uniqueness/nesting/refusal and selected rank. | Checker recomputes candidate-score eligibility and enforces refusal behavior. Python adversary run incomplete; no G2/G3 study credit follows from this map. |
| V1 | v4 certificate structure and target are constrained (`inspect_artifacts.jl:78-159`, `:223-259`; checker `:265-346`). | `tail_certificate_inputs` section restored as `evidence.v4_tail_certificates`. | Separate certificate section is sole authority; inline duplicate is rejected by reader (`artifact_container.jl:483-535`). Julia suite and green probe pass the rehashed contradiction case. |
| V2 | Exact determinant uses the declared lossless rational shape and is positive (`inspect_artifacts.jl:78-159`; checker `:300-323`). | `Rational{BigInt}` numerator/denominator/type. | Inspector reconstructs and recomputes; Python checker validates exact keys, types, positive denominator and value. Julia fake-engine certificate test passes; Python checker execution incomplete. |
| V3 | Gap uses exact BigFloat representation at 256-bit precision and exceeds strict separation threshold (`inspect_artifacts.jl:78-159`; checker `:324-347`). | Gap numerator, denominator, precision, boundary and exact precision claim. | Rejects malformed precision/denominator and a gap not strictly above threshold. Julia certificate fixture passes; Python checker execution incomplete. |
| V4 | Certificate convention, residual df, rounding, determinant identity, design identity, target and certification status agree (`inspect_artifacts.jl:78-159`, `:240-259`; checker `:265-346`). | Certificate fields inside the separate certificate input section. | Inspector reconstructs certificate against retained design and loaded engine; checker validates field-level provenance. Julia v4 certificate tests pass; Python execution incomplete. |
| V5 | Missing design inputs after an actual interruption are distinguished from invalid reconstruction (`inspect_artifacts.jl:71-76`, `:246-259`; checker `:349-381`). | Metadata status, retained design inputs, structural certificate status and design correspondence. | Only interrupted plus structurally valid evidence receives `unavailable_interrupted`; other missing/invalid design correspondence fails. Julia interruption tests pass; Python execution incomplete. |

### Provenance, admission, accounting, compatibility, and transport

| ID | Existing predicate and source | Native value and container representation | Independent check, failure, and evidence |
|---|---|---|---|
| A1 | Complete source inventory is discovered and pinned (`tools/arc1_manifest.py:33-53`, `:481-542`, `:701-772`). | Source paths and SHA-256 map, including every `sim/arc1` file. | Admission creation and validation require complete discovered set and current bytes. Exact current admission hash set must be captured before any run; no new run authorized here. |
| A2 | Runtime, environment, protocol, and execution identity match (`execute_attempt.jl:510-535`; inspector `:25-53`, `:223-225`). | Julia/runtime, BLAS/thread settings, project identity, source/environment/protocol hashes. | Attempt execution and inspector bind loaded code to admitted identities. Suite passes fake engine source-bound checks; no campaign receipt was produced. |
| A3 | Cell, canonical outer-seed allocation, bootstrap seeds, and attempt order match external pins (`tools/arc1_manifest.py:626-772`; receipt checker `:799-930`). | Programme, phase, N, signal, seed strings, outer indices, bootstrap prefixes. | Checker recomputes canonical expected seeds and requires exact attempt count/order with no replacements. Python test run incomplete; no allocation denominator has changed. |
| A4 | Artifact path is confined to expected root and artifact bytes match the pinned hash (`tools/arc1_receipt_check.py:872-910`, `:930-946`, `:1073-1104`). | Artifact path and `artifact_sha256`, receipt summary path/hash. | Artifact inspection occurs before the later durable-summary byte hash; both checks are required before acceptance. Python adversarial test run incomplete. |
| A5 | Summary bytes equal both Julia durable result mapping and embedded native summary (`tools/arc1_receipt_check.py:1074-1104`). | Sidecar JSON, durable row/wrapper, embedded receipt summary. | Valid UTF-8 JSON and exact mappings are checked; flattened fields must equal retained summary. Python run incomplete. |
| A6 | All-attempt denominators and failures remain included (`tools/arc1_receipt_check.py:569-581`, `:614-641`, `:867-920`). | Planned attempts and every attempted outer/inner result. | Missing/replacement attempts fail; failure rates and interval formation/coverage use all attempts. No campaign run; denominators remain frozen and unaltered. |
| A7 | Bootstrap seeds, nested prefixes, usable counts, and selector reruns are retained (`tools/arc1_receipt_check.py:682-796`). | Ordered inner attempts, seed list/digest, prefix values and rerun selector outputs. | Checker validates each seed, attempt count, prefix budget, usable denominator and selected-rank rerun diagnostics. Python execution incomplete; no bootstrap samples run in this repair. |
| A8 | Legacy JLS input dispatch remains available (`inspect_artifacts.jl:17-23`). | Existing JLS magic and native Serialization artifact. | Inspector selects the old reader for legacy format. The old 130,851,693-byte artifact timed out during deserialization and remains diagnostic-only; no acceptance credit. |
| A9 | Unsupported serialization, malformed graphs, and write failures fail closed while preserving diagnostics where possible (`artifact_container.jl:105-154`, `:156-197`; executor `:630-643`). | Native values, invalid evidence sink, writer staging and error metadata. | Unsupported leaf or malformed graph cannot pass evidence identity; malformed sink is copied to explicit raw diagnostic field. Julia suite passes fallback test; crash durability and every unsupported leaf remain outside this source map's positive test evidence. |
| A10 | JSON transport preserves supported exact and exceptional native values (`sim/arc1/engine_io.jl` transport helpers; `tools/arc1_receipt_check.py:24-66`). | Rationals, BigFloats, tuples/enums, dictionaries, exceptional values, vectors. | Typed reconstruction and exact native/JSON comparison are required before acceptance. Julia typed-transport tests pass; Python adversary suite incomplete. |

## Retained evidence and open rows

## Predicate-level map

One row below represents one independently enforced condition or one status branch. Where a source condition combines several fields, each field has its own row. Source line references name the exact implementation/checker span; the evidence column says whether a direct test is retained. `Suite` refers to the exact Julia suite identified above. `Python incomplete` means no pass credit.

### Container format predicates

| Predicate | Checker/source | Native input and encoded location | Required semantics and failure | Direct test/evidence |
|---|---|---|---|---|
| C-01 | Writer destination guard, `artifact_container.jl:156-158` | Destination path | Existing destination is refused; do not overwrite prior artifact. | Julia container writer tests, Suite. |
| C-02 | Writer section-name order/uniqueness, `:159-163` | Section names | Names are unique and sorted before directory emission. | Julia container writer tests, Suite. |
| C-03 | Reader magic, `:199-201` | Container header | Magic must equal `ARC1_CONTAINER_MAGIC`. | Malformed container suite. |
| C-04 | Reader version, `:201-203` | Container header | Version must equal `ARC1_CONTAINER_VERSION`. | Malformed container suite. |
| C-05 | Reader section count, `:203-205` | Directory count | Count must be positive. | Malformed container suite. |
| C-06 | Reader unique section names, `:206-217` | Directory names | A section name may occur once only. | Malformed container suite. |
| C-07 | Reader section schema, `:207-223` | Directory schema/name | Schema must equal the versioned schema bound to that name. | Malformed container suite. |
| C-08 | Reader section ordering, `:207-223` | Directory names | Names must be in strictly increasing order. | Malformed container suite. |
| C-09 | Record count representability, `:213-219` | Directory record count | Count must fit the host integer used by decoding. | Malformed container suite; no resource-limit claim. |
| C-10 | Contiguous offsets, `:224-230` | Directory offsets and lengths | Each section begins exactly where the previous section ends. | Rehashed layout adversaries, Suite. |
| C-11 | Singleton record cardinality, `:230-231` | Every section other than `history` | Record count must equal one. | Rehashed zero/multiple-count adversaries, Suite. |
| C-12 | Whole-file extent, `:232-238` | File size and final section extent | File size must equal directory plus section extents; reject truncation/trailing bytes. | Container extent adversaries, Suite. |
| C-13 | Exact section reads, `:239-256` | Section byte range | Empty/short reads fail; all declared section bytes are copied before decode. | Truncation adversaries, Suite. |
| C-14 | Section digest, `:252-256` | Directory SHA-256 and section payload | Digest must match the complete section bytes. | Rehashed semantic adversaries ensure checks are not checksum-only; Suite. |
| C-15 | Exact singleton deserialization, `:150-154`, `:264-268` | Serialized singleton section | One value must deserialize and consume all bytes. | Rehashed appended-object and junk-byte cases, Suite. |
| C-16 | Event size conversion and nonnegative check, `:257-260` | Length-prefixed event record | Invalid/negative or unrepresentable size fails. | Short and malformed record adversaries, Suite. |
| C-17 | Event exact byte count, `:259-263` | Declared event size and returned bytes | Returned byte count must equal declared size; no pre-read remaining-byte allocation bound is claimed. | Overstated final length, Suite and 3/3 probe. |
| C-18 | Exact event deserialization, `:263-267` | One event record payload | Exactly one serialized event consumes its complete record. | Rehashed trailing-event-object/byte cases, Suite. |
| C-19 | Event-section exhaustion, `:267-271` | Remaining history section bytes | No undeclared record or trailing section bytes remain. | Trailing history bytes adversary, Suite. |

### Reference identity and history predicates

| Predicate | Checker/source | Native input and encoded location | Required semantics and failure | Direct test/evidence |
|---|---|---|---|---|
| R-01 | Reference walk, `artifact_container.jl:40-103` | Original artifact object graph | Record object identities before projection to markers. | Alias topology round-trip, Suite. |
| R-02 | Reference categories, `:292-313` | `references` paths and IDs | A single ID cannot name evidence, history, and event categories incompatibly. | Rehashed cross-category ID collision, Suite and 3/3 probe. |
| R-03 | Evidence history stripping, `:315-325` | `evidence.arc1_profile_v3_evaluations` | If present, replace only the original array with a marker for its recorded ID. | Native-substitution and pre-entry tests, Suite. |
| R-04 | Evidence history stripping, `:315-325` | `evidence.arc1_profile_v4_evaluations` | Same rule as R-03 for v4. | Native-substitution and pre-entry tests, Suite. |
| R-05 | History marker validation, `:396-422`, `:483-500` | Entered history keys and `history_rows` | Present native keys must be reference markers and must match the reference table. | Empty-reference and native-array substitution, Suite. |
| R-06 | v3/v4 shared identity, `:40-103`, `:396-422`, `:483-500` | Both v3 and v4 history markers | If both histories are entered, IDs must match before reconstruction. | Split alias fixture, Suite. |
| R-07 | Restored v3/v4 object alias, `:483-510` | Reconstructed evidence histories | When both keys are present, restored arrays must be the same object (`===`). | Alias round-trip, Suite. |
| R-08 | Event-field whitelist, `:327-351` | Each native history row | Only `events`, `producer_history`, `provenance_failures` are extracted as event arrays. | Typed-history and malformed-field tests, Suite. |
| R-09 | Event field type, `:329-351` | Each present event field | Present value must be a vector and have an original object ID. | Wrong-type/missing-ID fixture, Suite. |
| R-10 | Event marker identity, `:353-394` | `history_rows` marker and `references` path | Marker ID must equal the row/field's recorded original ID. | Rehashed wrong-ID fixture, Suite. |
| R-11 | Event order/gaps, `:353-366` | `history` records | Row/field event indices start at one and increase without gaps or reordering. | Event-order adversary, Suite. |
| R-12 | Event row/field membership, `:353-394` | Grouped event stream and history rows | Every stream group must correspond to a field actually present in a row. | Unknown-field/row adversary, Suite. |
| R-13 | Same-ID value consistency, `:368-384` | Repeated event references | Same ID with conflicting decoded values fails. | Rehashed conflicting-value fixture, Suite and 3/3 probe. |
| R-14 | Same-ID object reconstruction, `:368-384` | Consistent repeated event references | Same ID and equal content reuses the same reconstructed vector. | Shared alias round-trip, Suite. |
| R-15 | Result's evidence identity, `:425-481`, `:510-523` | Native `result.v3_profile_evidence` | Writer requires identity with top-level original evidence; reader resolves only a matching marker. | Typed result/evidence alias fixture, Suite. |
| R-16 | Summary's evidence identity, `:425-481`, `:524-535` | Native `summary.v3_profile_evidence` | Writer requires identity with top-level original evidence; reader resolves only a matching marker. | Typed summary/evidence alias fixture, Suite. |
| R-17 | Malformed evidence retention, `execute_attempt.jl:630-643` | Invalid native sink after writer refusal | Preserve malformed sink under `v3_profile_evidence_raw`; it does not become admissible evidence. | Split-history fallback assertion, Suite. |

### Data, metadata, and result predicates

| Predicate | Checker/source | Native input and encoded location | Required semantics and failure | Direct test/evidence |
|---|---|---|---|---|
| D-01 | Required outer field, `inspect_artifacts.jl:166-179` | `metadata.outer` | Must exist for each artifact. | Fake-engine admission tests, Suite. |
| D-02 | Required seed field, `:166-179` | `metadata.seed_string` | Exact seed string must exist. | Fake-engine admission tests, Suite. |
| D-03 | Required cell field, `:166-179` | `metadata.cell` | Cell identity must exist. | Fake-engine admission tests, Suite. |
| D-04 | Required execution identity, `:166-179` | `metadata.execution_identity` | Execution identity field must exist. | Fake-engine admission tests, Suite. |
| D-05 | Required driver/protocol identity, `:173-179` | `metadata.driver_protocol_identity` | Full admitted identity must exist. | Fake-engine admission tests, Suite. |
| D-06 | Retained data/design availability, `:181-196` | Native `data` and `design` sections | Retain source objects for semantic recomputation; absent inputs cannot claim a recomputed semantic identity. | Typed-section round-trip, Suite. |
| D-07 | Data-seed correspondence, `:197-199` | `data.seed` and metadata seed | Stringified data seed must equal exact metadata seed. | Seed mismatch/admission fixtures, Suite. |
| D-08 | Semantic identity declaration, `:193-206` | Identity hash and method in metadata | With retained data/design, both method and hash must exist and match recomputation; without them both declarations must be absent. | Identity fixtures, Suite; independent Python adversary run incomplete. |
| D-09 | Raw result projection, `:185-212`, `:335-344` | Native result versus derived receipt | Derived projection must match and any difference is retained for diagnosis. | Julia suite does not independently pass the Python contradiction test; that test is incomplete. |
| D-10 | Reference-scale correspondence, `:203-212`, `:335-344` | Reference scale and retained response | Must match the independently retained response scale. | Fake-engine scale tests, Suite. |
| D-11 | Result/summary presence rule, `:185-190` | Native result and `receipt_summary` | Summary absent is valid only when retained result is absent; otherwise summary comparison is required. | Python result/summary adversary `test/test_arc1_receipt_adversaries.py:1686-1731`, incomplete. |
| D-12 | Result/summary equality, `:181-190`, `:335-344` | Derived result JSON and embedded summary JSON | Canonical rendered values must match. | Same Python adversary, incomplete. |
| D-13 | Result summary representation hashes, `:335-344` | Rendered result and summary JSON | Exact UTF-8 representation hashes are exposed for receipt checking. | Diagnostic hash suite 15/15. |
| D-14 | Source-root loaded-engine identity, `inspect_artifacts.jl:25-53`, `:223-225` | Current engine source and metadata | Inspector independently checks loaded source identity. | Source-bound fake-engine tests, Suite. |

### Profile-method and evidence-state predicates

| Predicate | Checker/source | Native input and encoded location | Required semantics and failure | Direct test/evidence |
|---|---|---|---|---|
| P-01 | Requested profile method, `inspect_artifacts.jl:216-221`, `:251-312` | Metadata request | Profile evidence is required exactly for v3/v4 requests. | Fake-engine method tests, Suite. |
| P-02 | Sink requested method, `:260-312` | `evidence.requested_method_version` | Must equal admitted requested method. | Method mismatch tests, Suite. |
| P-03 | Sink actual method, `:216-221`, `:260-312` | `evidence.actual_method_version` | When present, must equal the requested method. | Method mismatch tests, Suite. |
| P-04 | Sink returned method, `:260-312` | `evidence.returned_method_version` | If present, must equal requested method; absence follows the explicit legacy/status branch. | Method mismatch tests, Suite. |
| P-05 | Metadata/result method equality, `:260-312` | Metadata and retained result `profile_method_version` | Completed results must agree with the requested method; error/interruption branches may lack a completed result only as specified. | Error/interruption fake-engine tests, Suite. |
| P-06 | Result source identity, `:260-312` | Result `source_identity` | Must equal loaded engine source identity for profile evidence. | Source-identity tests, Suite. |
| P-07 | Reference source identity, `:260-312` | Result `reference_source_identity` | Must equal loaded engine source identity for profile evidence. | Source-identity tests, Suite. |
| P-08 | v4 history key presence and types, `:234-239` | v3/v4 evidence arrays | Both keys must exist and be vectors for v4. | Alias tests, Suite. |
| P-09 | v4 alias identity, `:234-239` | v3/v4 history arrays | Arrays must be `===`, not merely equal. | Alias tests, Suite. |
| P-10 | Empty/pre-entry evidence state, `:260-312` | Requested method, actual/returned method, source identity, histories | A not-yet-entered or interrupted state must follow its explicit absence branch; contradictory partial data fails. | Pre-entry/interruption tests, Suite. |
| P-11 | Partial evidence status, `:303-312` | Retained requested history | Presence is reported separately from evidence validity. | Partial sink/failure tests, Suite. |

### Certificate predicates

| Predicate | Checker/source | Native input and encoded location | Required semantics and failure | Direct test/evidence |
|---|---|---|---|---|
| V-01 | Writer certificate extraction, `artifact_container.jl:425-481` | `evidence.v4_tail_certificates` | When present, move exactly to `tail_certificate_inputs` and remove from stripped evidence. | Typed certificate round-trip, Suite. |
| V-02 | Reader single authority, `:483-535` | Stripped evidence and certificate section | Reject inline duplicate; a separate certificate section requires an evidence dictionary. | Rehashed contradiction fixture, Suite and 3/3 probe. |
| V-03 | Certificate collection type, inspector `:223-245` | Restored certificate collection | v4 certificates must be a vector to be checked; malformed type cannot validate. | Malformed certificate tests, Suite. |
| V-04 | Certificate target/shape, `inspect_artifacts.jl:78-159`; checker `:265-300` | Per-certificate record | Target must be residual variance and contain a certificate mapping. | Fake-engine certificate tests, Suite; Python validation incomplete. |
| V-05 | Certificate status/rounding identity, checker `:285-300` | Status, certified flag, precision, rounding and determinant identity | Exact declared values must match the certificate contract. | Python certificate checks incomplete. |
| V-06 | Exact rational determinant shape, checker `:300-323` | Numerator, denominator, type tag | Lossless `Rational{BigInt}` encoding; keys/types exact; denominator positive and determinant positive. | Julia certificate fixture, Suite; Python checks incomplete. |
| V-07 | Residual df/convention/precision, checker `:324-330` | `residual_df`, convention and precision | Integer residual df positive; convention `omit_2pi`; precision 256. | Python checks incomplete. |
| V-08 | Exact BigFloat gap shape, checker `:330-347` | Gap numerator, denominator, precision | Lossless rational encoding at precision 256 with positive denominator. | Python checks incomplete. |
| V-09 | Strict separation threshold, checker `:338-347` | Exact gap value | Must be strictly greater than the frozen threshold. | Python checks incomplete. |
| V-10 | Boundary value, checker `:324-330` | Certificate boundary E | Must be finite and positive. | Python checks incomplete. |
| V-11 | Design reconstruction, inspector `:55-159` | Retained design inputs and loaded engine | Recompute certificate using the design and determinant/df context; exact reconstructed certificate must match. | Julia v4 certificate fixture, Suite; Python comparison incomplete. |
| V-12 | Certificate validation state, inspector `:240-259`; checker `:349-381` | Certificate checks and design correspondence | Validated requires matched design and valid evidence; no certificate is an explicit state. | Julia v4 tests, Suite; Python checker incomplete. |
| V-13 | Interrupted design-unavailable branch, inspector `:246-259`; checker `:349-381` | Interrupted metadata, absent design, structurally valid certificate | Only a genuine interruption may report design unavailable; it is not reported as validated. | Julia interruption tests, Suite; Python check incomplete. |

### Receipt, provenance, and denominator predicates

| Predicate | Checker/source | Native input and encoded location | Required semantics and failure | Direct test/evidence |
|---|---|---|---|---|
| A-01 | External source hashes, `tools/arc1_receipt_check.py:799-825` | Receipt source hashes and caller pins | Non-empty, valid SHA-256 map must equal expected source hashes. | Python adversary run incomplete. |
| A-02 | Protocol hash, `:801-852` | Receipt protocol SHA and expected protocol | Exact protocol hash must match. | Python adversary run incomplete. |
| A-03 | External cell and expected seed construction, `:829-867` | Programme/phase/N/signal and canonical seeds | Seeds are recomputed from the frozen manifest and any source admission. | Python adversary run incomplete. |
| A-04 | Planned denominator, `:867-871` | Planned attempts and actual attempt list | Both equal the full frozen cell allocation; no missing or replacement attempts. | Python adversary run incomplete. |
| A-05 | Artifact/summary path fields and confinement, `:872-910` | Artifact and summary paths | Required fields exist; paths remain under the approved artifact root. | Python adversary run incomplete. |
| A-06 | Artifact hash, `:930-946` | Artifact bytes and `artifact_sha256` | Artifact bytes are hashed and checked after the artifact-inspection call at `:902`; never describe this as hash-before-inspection. | Python adversary run incomplete. |
| A-07 | Attempt order and metadata pins, `:912-946` | Outer index, seed, cell, status, artifact metadata | 1-based order, exact expected seed, cell and metadata correspondence. | Julia admission suite passes; Python adversary incomplete. |
| A-08 | Sidecar summary hash and decoding, `:1073-1095` | Summary bytes, path and hash | Exact SHA-256; valid UTF-8 JSON. | Python adversary run incomplete. |
| A-09 | Durable/embedded summary equality, `:1096-1104` | JSON sidecar, durable result mapping, embedded summary | All views must agree; flattened fields must equal the retained summary. | Python result/summary contradiction test, incomplete. |
| A-10 | All-attempt candidate error denominator, `:569-581` | Complete attempt list | Error rates retain every attempted dataset in the denominator. | No campaign run; checker tests incomplete. |
| A-11 | All-attempt interval formation and coverage denominators, `:614-641` | Attempt outcomes and target truths | Formation and coverage denominators equal all attempts, with formed-only coverage reported separately. | No campaign run; checker tests incomplete. |
| A-12 | Bootstrap attempt count and seed order, `:682-796` | Inner attempt list, expected seeds/prefixes | Every planned inner attempt is retained in order; usable count does not replace denominator. | No bootstrap campaign; Python tests incomplete. |
| A-13 | Root confinement/source identity, `tools/arc1_manifest.py:626-772`; receipt checker `:799-867` | Admission root, source map, cell/seeds | Reject paths outside root and any source/admission mismatch. | No new admission/run; Python tests incomplete. |

### Transport and legacy compatibility predicates

| Predicate | Checker/source | Native input and encoded location | Required semantics and failure | Direct test/evidence |
|---|---|---|---|---|
| T-01 | Native/JLS to JSON transport, `engine_io.jl` serializer/projection helpers and `tools/arc1_receipt_check.py:24-66` | Tuples, enums, dictionaries, vectors, exact numeric values, exceptional values | Preserve supported type/identity information and fail closed on unsupported values; compare submitted representation to retained native evidence. | Julia typed transport tests pass; Python adversary suite incomplete. |
| T-02 | Legacy JLS dispatch, `inspect_artifacts.jl:17-23` | Existing JLS magic versus new container magic | Legacy JLS reader remains selected for legacy artifacts. | Legacy artifact inspection attempt timed out before semantic checks; diagnostic-only, no gate credit. |

## Review state

The predicate map above is a draft after Astra's source review. The reviewer must verify the one-predicate-per-row completeness, exact source references, and evidence attribution before this file is treated as complete. Python adversarial validation and the final-source Totoro timing/RSS/output-size benchmark remain open. The historical 7.677-second report is not accepted evidence. No campaign, seed, gate change, or threshold change is authorized by this map.

- Exact Julia command: `JULIA_DEPOT_PATH=/private/tmp/arc1-container-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no -e 'using Test, HSquared; include("test/arc1_simulation_executor.jl")'`.
- Exact Julia log: `/private/tmp/arc1-container-decoder-final-verified.log`, SHA-256 `0d155182d61e1a997b304c870710e61efd5a631a77b859039708746259484c13`, exit 0; 194/194, 10/10, 15/15.
- Current-source focused probe: `/private/tmp/arc1-container-adversary-green.log`, SHA-256 `5f8bf97eaae5abe477f5f7358b65fefb15c13e75c0fdf04ae42a20560d77355e`, reported 3/3. The complete source-bound Python adversary suite remains unverified: it stalled at 23 progress dots and was stopped with exit 130.
- The previous large-artifact figure (7.677 seconds) has no retained reproducible measurement and used a Mac process with high combined memory. It does not pass the performance requirement. A versioned Totoro end-to-end timing, RSS, and output-byte benchmark remains open.
- This map requires independent review before it is considered complete. Its row coverage is a reviewable claim, not proof that the corresponding Python predicates passed.
- No fit, seed, campaign, G5 gate change, G2 allocation, public claim, or source freeze was made by this map.
