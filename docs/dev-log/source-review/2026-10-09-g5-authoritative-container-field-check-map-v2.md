# G5 authoritative-container field-to-check map, v2

Status: draft for independent review. Astra's exact-source review of the implementation passed; the first map was held for bundled predicates and inaccurate test attribution. This v2 narrows to the G5 repeatability/boundary receipt path and shared container predicates. G2/G3 selector scoring and FA interval bootstrap selection are explicitly outside this map. A mapped predicate is not a passed gate.

## Frozen source and evidence identity

| Path | SHA-256 |
|---|---|
| `sim/arc1/artifact_container.jl` | `147b281f726f40820184ba31d2c97e525550654aff88100d3ca9e077a21feee7` |
| `sim/arc1/execute_attempt.jl` | `5ee18d920ca7c557fb44904b4979ef8c0dc00768ac8090cecc8a01ce2f2e582a` |
| `sim/arc1/engine_io.jl` | `cbe3bc314793a4532f70111d42ff904fd1125e600d6cd091cf81cc4a6d4dd474` |
| `sim/arc1/inspect_artifacts.jl` | `d14a5eca4f39e833409031cab6c76f6227678010205357ec19475648c9e99e9e` |
| `sim/arc1/runner.py` | `752cc16c8542ac99da0a266857775436e0355984cec4227d79111ef3cbeaca2d` |
| `tools/arc1_manifest.py` | `0c437d8b4950dbaad7df0cd1f745e0ef5e15ff55c3e2720772211a2a7f481c55` |
| `tools/arc1_receipt_check.py` | `3ff6d5dfcd860db4fc1ccb717df460bbb78868bf63d15c35f8b278d145c87db8` |
| `test/arc1_simulation_executor.jl` | `411618a09c72b5fe573696ecdd12fe94b4ed04c169d77febfe11d4d22a0d54c0` |
| `test/test_arc1_receipt_adversaries.py` | `a902b5b73fc8d73d95c9608122e75e2d543ee9d8c75ef675f1af156a340d3c70` |
| Architecture candidate | `docs/dev-log/decisions/2026-10-09-g5-authoritative-container-candidate.md`, SHA-256 `26cbc4041ba8f387c767763e1328d88f5aaafe5ae0ce07f79b29ee82b5892a26` |

Admission dynamically inventories all `sim/arc1` files (`tools/arc1_manifest.py:33-53`), hashes the discovered source set during admission (`:481-542`), and requires the same discovered files and bytes during validation (`:701-772`). The attempt loader includes `artifact_container.jl` (`execute_attempt.jl:521`); the inspector includes it (`inspect_artifacts.jl:14`). The exact run admission receipt remains authoritative for a run's complete hash set.

Evidence labels used below:

- **Julia positive:** exact source-bound Julia suite `/private/tmp/arc1-container-decoder-final-verified.log`, SHA-256 `0d155182d61e1a997b304c870710e61efd5a631a77b859039708746259484c13`, exit 0; 194/194 executor, 10/10 admission and 15/15 diagnostic-identity assertions.
- **Julia mutation:** a specific negative/mutation case is named with its test lines below; these ran in that exact suite.
- **Source only:** implementation condition exists, but no dedicated negative mutation test was identified in the retained suite.
- **Python unverified:** the receipt adversary process printed 23 progress dots and was stopped with exit 130. No Python assertion gets pass credit.
- The focused three-case Julia probe `/private/tmp/arc1-container-adversary-green.log`, SHA-256 `5f8bf97eaae5abe477f5f7358b65fefb15c13e75c0fdf04ae42a20560d77355e`, was reported 3/3. It is supplemental; the full Julia suite is the retained test evidence.

## One-predicate-per-row map

Each row below maps one independently enforced condition. “Absent/state” records where the predicate applies and the permitted omission. “Failure” states the checker outcome. A test is named only where it directly exercises that condition; a passing general suite is not treated as proof of an untested mutation.

### Container bytes and section shape

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| C01 | Refuse existing destination, `artifact_container.jl:156-158` | Container output path | Applies to every write | Throw before replacing prior bytes | Julia mutation `typed sections and alias topology`, lines 544-585. |
| C02 | Writer emits sorted unique names, `:159-163` | Section-name strings | At least one section is required by reader | Throw on duplicate/unsorted writer input | Source only for direct writer-input mutation. |
| C03 | Header magic matches, `:199-201` | Fixed magic bytes | Always required | Reject before decoding directory | Source only; no dedicated bad-magic test identified. |
| C04 | Header version matches, `:201-203` | UInt16 version | Always required | Reject unsupported version | Source only; no dedicated bad-version test identified. |
| C05 | Directory section count is positive, `:203-205` | UInt16 count | Empty container invalid | Reject zero sections | Source only; no dedicated zero-count test identified. |
| C06 | Directory names are unique, `:206-217` | String names | Always required | Reject duplicate name | Source only; no dedicated duplicate-name test identified. |
| C07 | Schema equals name-bound schema, `:207-223` | String schema and section name | Always required | Reject unknown/mismatched schema | Source only; no dedicated schema mutation test identified. |
| C08 | Directory names are strictly ordered, `:207-223` | Consecutive names | Always required | Reject reorder | Source only; no dedicated reorder test identified. |
| C09 | Record count fits host `Int`, `:213-219` | UInt64 record count | Always required | Reject unrepresentable count | Source only; no dedicated overflow mutation test identified. |
| C10 | Section offsets are contiguous, `:224-230` | UInt64 offset and length pairs | All sections required | Reject gap, overlap, or reordered range | Source only; no direct offset mutation test identified. |
| C11 | Non-history section count equals one, `:230-231` | `records` field for singleton sections | Every section other than `history` | Reject zero or multiple records | Julia mutation `rejects malformed identity and serialization`, lines 430-543; zero/multiple count case at 441-444. |
| C12 | Whole-file length equals final extent, `:232-238` | Directory end plus section lengths | Always required | Reject truncated/trailing container bytes | Julia mutation `typed sections and alias topology`, lines 544-585; truncated fixture around 570-576. |
| C13 | Exact section bytes are read, `:239-256` | Declared byte range | Every section | Reject short section read | Julia mutation truncated fixture, lines 570-576. |
| C14 | Section SHA-256 matches, `:252-256` | Directory digest and exact section payload | Every section | Reject digest mismatch before decoding/returning section | Julia mutation corrupted fixture, lines 576-581. |
| C15 | Singleton deserializer consumes all payload bytes, `:150-154`, `:264-268` | One native serialized value | Every non-history section | Reject a second serialized value or junk bytes | Julia mutation `native-trailer`, lines 446-452. |
| C16 | History record size is representable and nonnegative, `:257-260` | UInt64 length prefix converted to `Int` | Each history record | Reject invalid conversion or negative result | Source only for conversion/negative-specific mutation. |
| C17 | Returned history byte count equals declared size, `:259-263` | Declared record length and returned byte vector | Each history record | Reject short/overstated record | Julia mutation `short-event-record`, lines 470-486. The source checks after `read`; it makes no pre-read memory bound claim. |
| C18 | Event deserializer consumes all record bytes, `:263-267` | One event record payload | Each history record | Reject trailing serialized object or junk bytes in a record | Julia mutation `history-trailer`, lines 454-468. |
| C19 | History section has no trailing undeclared bytes, `:267-271` | Remaining history section | After declared records | Reject trailing bytes | Julia mutation `history-trailer`, lines 454-468. |

### Original object identities and profile history

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| R01 | Reference table records original object IDs before projection, `artifact_container.jl:40-103`, writer `:425-481` | Artifact object graph, string path to UInt64 ID | IDs only for identity-bearing objects | Reject repeated path or invalid shared topology | Julia positive alias round-trip, `typed sections and alias topology`, lines 544-585. |
| R02 | One ID cannot cross semantic categories, `:292-313`, reader `:483-492` | Reference paths for evidence, history, event arrays | Applies when those references exist | Reject evidence/history/event category collision | Julia mutation `cross-category-object-id`, lines 486-527. |
| R03 | Entered history value is a reference marker, `:315-325`, `:396-422` | `evidence.arc1_profile_v3_evaluations` | Key absent before history entry remains absent | Reject native array substituted for marker | Julia mutation `no_reference`, lines 431-435, and suite pre-entry case, lines 630-640. |
| R04 | v3 marker ID matches reference table, `:396-422` | v3 marker and `references["evidence.arc1_profile_v3_evaluations"]` | Applies if v3 key exists | Reject absent/mismatched identity | Julia positive v3/v4 alias case, lines 598-624; no separate mismatched-v3-ID fixture identified. |
| R05 | v4 marker ID matches reference table, `:396-422` | v4 marker and `references["evidence.arc1_profile_v4_evaluations"]` | Applies if v4 key exists | Reject absent/mismatched identity | Julia positive v4 alias case, lines 598-624; no separate mismatched-v4-ID fixture identified. |
| R06 | Entered v3 and v4 keys share one original ID, `:396-422` | v3/v4 history markers | Applies when both keys exist | Reject split IDs before restoration | Julia mutation `split_v4_alias` path in fake-engine suite, around lines 269-323. |
| R07 | Restored v3/v4 arrays are the same object, `:483-510` | Reconstructed history arrays | Applies when both keys exist | Reject equal-but-distinct reconstructed arrays | Julia positive assertion `v3 === v4`, lines 618-622. |
| R08 | Event keys are from the fixed whitelist, `:327-351` | `events`, `producer_history`, `provenance_failures` row fields | Missing event keys remain missing | Reject unsupported event-field path/type | Julia positive typed history, lines 585-624; no per-key unsupported mutation identified. |
| R09 | Present event field is a vector, `:329-351` | Each native event field | Key may be absent | Reject non-vector field | Source only; no dedicated wrong-type mutation identified. |
| R10 | Present event vector has recorded original ID, `:329-351` | `references["evaluation.<row>.<field>"]` | Key absent means no corresponding event records | Reject missing ID | Julia positive ID assertions, lines 598-616; no dedicated missing-ID mutation identified. |
| R11 | History row marker is a reference, `:353-394` | `history_rows[row].<event-field>` | Only fields originally present have markers | Reject native value in marker position | Julia mutation native-history substitution, lines 431-435. |
| R12 | Event marker ID equals row/field ID, `:353-394` | Marker ID and reference table entry | Applies for each present event field | Reject mismatched ID | Cross-category mutation rehashes reference and row marker consistently, lines 486-527; direct mismatch-alone test not identified. |
| R13 | Event index starts at one and has no gaps/reordering, `:353-366` | `(row_index, field, event_index)` records | Empty vectors have zero event records | Reject noncanonical sequence | Source only; no dedicated gap/reorder mutation identified. |
| R14 | Event stream row/field belongs to retained history rows, `:386-394` | Grouped event keys | No extra row/field groups allowed | Reject unknown row or field | Source only; no dedicated unknown-group mutation identified. |
| R15 | Reused event ID has `isequal` contents, `:368-384` | Reconstructed event vectors | Reuse allowed only for same semantic object/content | Reject one ID with different values | Julia mutation conflicting event IDs, lines 435-440. |
| R16 | Reused event ID resolves to the same vector object, `:368-384` | Reconstructed event vector registry | Same ID/equal content uses one vector | Reject incompatible object meaning | Julia positive alias topology, lines 598-624. |
| R17 | Writer sees result evidence is original evidence object, `:425-481` | `result.v3_profile_evidence` and top-level sink | Field may be absent or `nothing` | Reject detached evidence copy | Julia positive alias assertion, lines 602-624; no dedicated copied-result mutation identified. |
| R18 | Writer sees summary evidence is original evidence object, `:425-481` | `summary.v3_profile_evidence` and top-level sink | Field may be absent or `nothing` | Reject detached evidence copy | Julia positive alias assertion, lines 602-624; no dedicated copied-summary mutation identified. |
| R19 | Reader result marker points to evidence ID, `:510-523` | `result.v3_profile_evidence` | Absent/`nothing` is preserved | Reject malformed marker or wrong ID | Julia positive alias assertion, lines 618-624; no marker-mismatch mutation identified. |
| R20 | Reader summary marker points to evidence ID, `:524-535` | `summary.v3_profile_evidence` | Absent/`nothing` is preserved | Reject malformed marker or wrong ID | Julia positive alias assertion, lines 618-624; no marker-mismatch mutation identified. |
| R21 | Invalid evidence sink is retained only as diagnostic raw evidence, `execute_attempt.jl:630-643` | `v3_profile_evidence_raw` on writer failure | Only failure fallback | Preserve malformed sink; do not treat it as valid evidence | Julia split-history failure-retention test, lines 892-907. |

### G5 metadata, identity, result, and profile-state checks

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| M01 | Outer index exists, `inspect_artifacts.jl:166-179` | Integer `metadata.outer` | Required on every attempted artifact | Inspector error | Julia fake-engine positive, `fresh-process fake-engine wiring and evidence`, lines 723 onward; no missing-outer mutation identified. |
| M02 | Exact seed exists, `:166-179` | String `metadata.seed_string` | Required | Inspector error | Same positive suite; no missing-seed mutation identified. |
| M03 | Cell exists, `:166-179` | `metadata.cell` mapping | Required | Inspector error | Same positive suite; no missing-cell mutation identified. |
| M04 | Execution identity exists, `:166-179` | `metadata.execution_identity` mapping | Required | Inspector error | Same positive suite; no missing-identity mutation identified. |
| M05 | Driver/protocol identity exists, `:173-179` | `metadata.driver_protocol_identity` | Required | Inspector error | Same positive suite; no missing-driver-identity mutation identified. |
| M06 | Semantic identity is recomputed from retained data/design, `inspect_artifacts.jl:188-196` | Native `data`, `design`, declared identity hash/method | If either source object is absent, both declarations must be absent | Identity mismatch or false presence state | Julia fake-engine positive; data-identity mutation is Python-only and unverified. Canonical data/design contents originate in `execute_attempt.jl:129-136`. |
| M07 | Data seed equals metadata seed, inspector `:197-199` | `data.seed`, `metadata.seed_string` | Requires retained data | False match state | Julia positive; no direct seed mutation result retained. |
| M08 | Raw result projection equals derived receipt, inspector `:199-204`; raw projection helper `execute_attempt.jl:368-376` | Native result and receipt projection | If result absent, projection state is `nothing` | Mismatch retained as false diagnostic | Python rehashed contradiction test `test/test_arc1_receipt_adversaries.py:1686-1731`, unverified. |
| M09 | Reference scale matches retained response, inspector `:199-204`; helper `execute_attempt.jl:203-245` | Reference traits/scale and retained response | If result absent, state follows its explicit `true` branch | False diagnostic | Source-reviewed; no dedicated negative case identified. |
| M10 | Embedded summary exists iff a result exists, inspector `:181-190` | `receipt_summary`, retained result | Both absent allowed; summary alone or result without summary follows false branch | Summary/result inconsistency | Julia positive matching summary at `test/arc1_simulation_executor.jl:794`; Python contradiction test unverified. |
| M11 | Embedded summary equals derived result receipt, inspector `:181-190` | Canonically rendered summary and result | Applies when both exist | False match diagnostic | Same Julia positive test only checks equality; Python rehashed contradiction test at `test/test_arc1_receipt_adversaries.py:1686-1731` is unverified. |
| M12 | Retained-result and embedded-summary representation hashes are exposed, inspector `:335-344` | Exact UTF-8 JSON representations | Hash is `nothing` when corresponding result is absent | Independent checker can compare hashes | Julia diagnostic hash suite 15/15; no claim that it tests summary contradiction. |
| M13 | Loaded engine source identity matches metadata, inspector `:25-53`, `:223-225` | Loaded engine source root/identity | Required for profile evidence | Identity false/error | Julia source-bound fake-engine suite positive; no source-root mutation result retained. |
| M14 | Result source identity equals loaded engine identity, inspector `:260-312` | `result.source_identity` | For profile methods; error/interruption may have no result | Evidence identity false | Julia source-bound fake-engine suite positive. |
| M15 | Reference source identity equals loaded engine identity, `:260-312` | `result.reference_source_identity` | Same as M14 | Evidence identity false | Julia source-bound fake-engine suite positive. |
| M16 | Requested method is v3/v4 exactly when profile evidence is required, `:216-221`, `:251-260` | Requested profile-method metadata | No requested profile method means no profile evidence | Evidence identity false | Julia fake-engine suite positive; no independent mutation test identified. |
| M17 | Evidence requested method matches request, `:260-312` | `evidence.requested_method_version` | Required for profile evidence dictionary | Evidence identity false | Julia positive fixture; Python native/submitted comparison unverified. |
| M18 | Evidence actual method matches request, `:260-312` | `evidence.actual_method_version` | May be absent only in explicit no-completion branch | Evidence identity false | Julia positive fixture; no direct mutation result retained. |
| M19 | Evidence returned method matches request if present, `:260-312` | Optional `returned_method_version` | Optional only on documented legacy/error path | Evidence identity false on contradictory value | Julia positive fixture; direct mutation status unverified. |
| M20 | Metadata/result profile-method fields agree, `:303-312` | Metadata method, result method, mismatch flag | Missing result permitted for error/interrupted states under explicit branch | Method identity false | Julia error/interruption fake-engine suite positive; per-field mutation not identified. |
| M21 | Absent diagnostics are distinct from partial diagnostics, checker `tools/arc1_receipt_check.py:186-224` | `point_fit_status`, diagnostic identity fields and target diagnostics | `not_run` branch requires explicit null diagnostic fields; partial set is not equivalent to absent set | Receipt error | Python checker run incomplete; no G5 live receipt. |
| M22 | Point-fit constrained maximum must not exceed point likelihood plus frozen tolerance, checker `:237-262` | `max_constrained_loglik`, `point_loglik` | Applies when point fit is marked formed | Refuse formed targets | Python checker run incomplete; no current attempt receipt. |
| M23 | Matching point-fit optimality flag agrees with likelihood guard, checker `:237-262` | `point_fit_not_optimal` and point-fit diagnostics | Applies to formed point fit | Refuse formed targets on inconsistent/nonoptimal state | Python checker run incomplete. |
| M24 | All formed targets are refused if point-optimality guard fires, checker `:237-262` | Target interval formation/status | Only formed targets enter this branch | Reject any formed target after guard failure | Python checker run incomplete. |
| M25 | Profile likelihood method is frozen, checker `:1150-1152` | `profile_method` | Required for G5 formed/refused intervals | Receipt error on another method | Python checker run incomplete. |
| M26 | Likelihood-ratio cutoff equals `3.841458820694124`, checker `:1150-1152` | `profile_lr_cutoff` | Required for G5 interval outputs | Receipt error on mismatch | Python checker run incomplete. |

### G5 target and certificate predicates

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| T01 | Target key set equals frozen five targets, receipt checker `:134-154`, `:1146-1178` | Profile target map | For G5 profile attempt | Receipt error on missing/extra target | Python checker run incomplete; no G5 receipt. |
| T02 | Target formula matches expected formula, checker `:148-174`, `:1146-1178` | Each target formula string | Each target required | Receipt error | Python checker run incomplete. |
| T03 | Segment endpoints are finite and ordered, checker `:584-611` | Confidence-set segment list | Refused intervals have no formed segment set | Receipt error | Python checker run incomplete. |
| T04 | Interval status/form fields agree, checker `:162-174`, `:177-262` | `formed`, status, refusal, segments | Every target receives explicit formed/refused status | Receipt error | Python checker run incomplete. |
| T05 | Native point fit and confidence-set diagnostics are linked to identities, checker `:177-262` | `point_identity`, `reference_point_identity`, diagnostic hashes | Absent/not_run uses required nulls; formed state requires point identity | Receipt error | Python checker run incomplete. |
| T06 | Certificate section is the only certificate authority, `artifact_container.jl:425-481`, `:483-535` | `evidence.v4_tail_certificates`; separate `tail_certificate_inputs` section | Section absent means no certificates; present requires evidence dictionary | Reject inline duplicate or orphan section | Julia mutation `certificate-authority-conflict`, lines 528-543. |
| T07 | Certificate record has correct target and nested mapping, checker `:265-300` | Target `residual_variance`, certificate object | Applies when certificate row exists | Receipt error | Python checker run incomplete. |
| T08 | Certificate status is `excluded_tail`, checker `:285-300` | Certificate status | Each present row | Receipt error | Python checker run incomplete. |
| T09 | `certified` is exactly true, checker `:285-300` | Boolean certificate field | Each present row | Receipt error | Python checker run incomplete. |
| T10 | Certificate precision is 256, checker `:285-300`, `:324-330` | Integer precision | Each present row | Receipt error | Python checker run incomplete. |
| T11 | Rounding contract matches allowed declared rule, checker `:285-300` and native inspector `:78-159` | Rounding metadata | Applies to every certificate | Receipt error on wrong/unknown rounding | Python checker run incomplete; both rounding paths lack direct checker execution evidence. |
| T12 | Determinant identity matches frozen identity string, checker `:285-300` | Determinant identity | Each certificate | Receipt error | Python checker run incomplete. |
| T13 | Design identity is a valid SHA-256, checker `:285-300` | Design identity | Each certificate | Receipt error | Python checker run incomplete. |
| T14 | Determinant uses exact rational object and exact key/type set, checker `:300-323` | Rational numerator, denominator, type tag | Each certificate | Receipt error | Python checker run incomplete. |
| T15 | Exact determinant denominator is positive and value is positive, checker `:312-323` | Rational determinant | Each certificate | Receipt error | Python checker run incomplete. |
| T16 | Residual df is a positive exact integer, checker `:324-330` | `residual_df` | Each certificate | Receipt error | Python checker run incomplete. |
| T17 | Likelihood convention equals `omit_2pi`, checker `:324-330` | Convention string | Each certificate | Receipt error | Python checker run incomplete. |
| T18 | Gap uses exact numerator/denominator/precision representation, checker `:330-347` | Encoded BigFloat gap | Each certificate | Receipt error | Python checker run incomplete. |
| T19 | Exact gap clears strict threshold, checker `:338-347` | Decoded exact gap | Each certificate | Receipt error unless strictly greater than frozen bound | Python checker run incomplete. |
| T20 | Boundary value is finite and positive, checker `:324-330` | `E` | Each certificate | Receipt error | Python checker run incomplete. |
| T21 | Raw point likelihood and cutoff agree with certificate inputs, inspector `:78-159`, checker `:349-381` | Point likelihood, LR cutoff and native certificate | Required where design inputs are retained | Certificate invalid | Python checker run incomplete; no direct isolated mutation test identified. |
| T22 | Reconstructed design/determinant/df and recomputed certificate equal retained values, inspector `:55-159` | Native design, certificate inputs, loaded engine | Required when design inputs are retained | Invalid certificate/design correspondence | Julia v4 fixture is positive; Python/native exact comparison incomplete. |
| T23 | Empty certificate collection reports `no_certificate`, checker `:358-365` | Native certificate list and inspector status fields | Allowed for v4 with no certificate | Reject contradictory status/correspondence/evidence-valid fields | Python checker run incomplete. |
| T24 | Valid certificate reports `validated` and `matched`, checker `:365-370` | Native validation status and design status | Allowed only when fully recomputed | Reject mismatching combined flags | Python checker run incomplete. |
| T25 | Design unavailable is accepted only for interrupted, structurally valid certificate, checker `:371-380` | Attempt and metadata status, structural validity, design correspondence | Interruption only; never label as validated | Reject other unavailable/invalid combinations | Julia interruption fixture positive; Python status matrix incomplete. |

### Admission, receipt, accounting, and compatibility predicates

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| A01 | Source hash map is nonempty and well-formed, checker `:799-825` | Expected source path/hash map | Every receipt | Receipt error | Python checker run incomplete. |
| A02 | Receipt source hashes equal expected exact pins, `:817-825` | `receipt.source_hashes` | Every receipt | Receipt error | Python checker run incomplete. |
| A03 | Protocol digest equals expected protocol, `:801-852` | Protocol SHA-256 | Every receipt | Receipt error | Python checker run incomplete. |
| A04 | Durable admission digest is present and valid, `:876-885` | Receipt admission digest | Required for admitted source/cell/seed record | Receipt error on missing/mismatch | Python checker run incomplete. |
| A05 | Expected outer seed partition is canonical, `:829-867` | Programme/phase/N/signal and seed list | Every cell receipt | Receipt error | Python checker run incomplete. |
| A06 | Bootstrap inner seed partition is canonical, `:852-867` | Outer-to-inner seed mapping | FA interval only; outside G5 study scope | Receipt error if applicable | Outside this G5 repeatability/boundary slice; no bootstrap claim. |
| A07 | Planned attempt count equals frozen allocation, `:867-871` | `planned_attempts` | Every receipt | Receipt error | Python checker run incomplete. |
| A08 | Actual attempt list length equals planned count, `:867-871` | Ordered attempts | Every receipt; no replacement | Receipt error | Python checker run incomplete. |
| A09 | Attempt outer index equals canonical 1-based order, `:912-930` | Attempt outer field | Each attempt | Receipt error | Python checker run incomplete. |
| A10 | Attempt seed/cell/status match external pins and metadata, `:918-946` | Attempt row and artifact metadata | Each attempt | Receipt error | Python checker run incomplete. |
| A11 | Artifact path is confined to approved root, `:898-900` | Relative/absolute artifact path | Each attempt | Receipt error before inspection | Python checker run incomplete. |
| A12 | Artifact is inspected, then its byte hash is checked, `:902-903`, `:1064-1075` | Artifact path and `artifact_sha256` | Each attempt | Receipt error on mismatch; hash follows inspection | Python checker run incomplete. |
| A13 | Summary path is confined and exists, `:1064-1075` | `receipt_summary_path` | Each attempt with durable summary | Receipt error | Python checker run incomplete. |
| A14 | Summary bytes have exact digest and valid UTF-8 JSON, `:1073-1095` | Sidecar bytes/hash | Each attempt | Receipt error | Python checker run incomplete. |
| A15 | Durable summary equals Julia result mapping and embedded summary, `:1096-1104` | JSON sidecar, durable row and native summary | Each attempt | Receipt error on any disagreement | Python contradiction test `test/test_arc1_receipt_adversaries.py:1686-1731`, unverified. |
| A16 | Every attempt contributes to candidate error denominator, `:569-581` | Full attempt list | Every attempted dataset, including failures | Reject empty/missing denominator; report all-attempt rate | Python checker run incomplete; no campaign run. |
| A17 | Formation and coverage denominators include every attempt, `:614-641` | Attempt outcomes and truth values | Every target/cell | Denominator mismatch rejected/reported | Python checker run incomplete; no campaign run. |
| A18 | Failed bootstrap inner attempts are retained, `:682-796` | Ordered inner attempt rows | FA interval only; outside G5 slice | Reject missing/replaced attempt | Outside this G5 slice; no bootstrap campaign run. |
| A19 | Unsupported JSON transport leaves fail closed, `engine_io.jl` transport functions; checker `:24-66` | Supported typed values and projection | When transport is requested | Serialization/projection error; no universal native-type allowlist is claimed | Julia typed transport testset `test/arc1_simulation_executor.jl:642-723`; Python round-trip validation incomplete. |
| A20 | Legacy JLS magic dispatch remains available, `inspect_artifacts.jl:17-23` | Legacy JLS header versus new container magic | Existing artifacts only | Dispatch to legacy reader or fail on malformed bytes | Old 130,851,693-byte artifact timed out before semantic checks; diagnostic only, no pass credit. |

## Evidence state and remaining work

- Exact final-source Julia command: `JULIA_DEPOT_PATH=/private/tmp/arc1-container-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no -e 'using Test, HSquared; include("test/arc1_simulation_executor.jl")'`.
- Exact Julia log: `/private/tmp/arc1-container-decoder-final-verified.log`, SHA-256 `0d155182d61e1a997b304c870710e61efd5a631a77b859039708746259484c13`, exit zero; 194/194, 10/10, 15/15.
- Python adversarial suite: `/private/tmp/arc1-container-receipt-direct.log`, stopped after 23 progress dots, exit 130. No Python test result is accepted from that run.
- The 7.677-second large-artifact report lacks a retained, reproducible measurement and is not performance evidence. A versioned final-source Totoro benchmark with elapsed time, RSS, output bytes and the complete inspector-to-Python path is still open.
- This v2 map needs Astra's exact map review. G5 remains open; no campaign, seed, gate transition, threshold or denominator change is made here.
