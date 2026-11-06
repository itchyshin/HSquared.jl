# G5 authoritative-container field-to-check map, v4

Superseded working copy. The v4 bytes reviewed at SHA-256 `a22d10e5dec0469aca0c83e7af2c2d2aadbc9369df059ce1f94c6b8209605a18` were edited during correction and are not preserved byte-for-byte. Current partial map: `2026-10-09-g5-authoritative-container-field-check-map-v5.md`, Astra PASS at SHA-256 `7272f73738207968823b8aeadfaf6a2cc8b35e0ff6289f4a1070ef20de52272a`.

Status: draft for independent review. Astra's exact-source review of the implementation passed; the exact v3 map was held at SHA-256 a2292a12cd84db90409e0ebf2f1694e4dea53c24521a76085d413848b5379793. This revision corrects row semantics and test attribution and adds missing G5-reachable predicates. The map covers artifact/container and G5 receipt predicates listed below. It does not replace the separate admission protocol and inspector subprocess-boundary audits; those remain prerequisites for any G5 run. G2/G3 selector scoring and FA interval bootstrap selection are outside this G5 slice. A mapped predicate is not a passed gate.

## Frozen source and evidence identity

| Path | SHA-256 |
|---|---|
| `sim/arc1/artifact_container.jl` | `147b281f726f40820184ba31d2c97e525550654aff88100d3ca9e077a21feee7` |
| `sim/arc1/execute_attempt.jl` | `484cff8b70c71931df3c5e392bb85d6456583a862bf07c91e4d6929b65ffd812` |
| `sim/arc1/engine_io.jl` | `cbe3bc314793a4532f70111d42ff904fd1125e600d6cd091cf81cc4a6d4dd474` |
| `sim/arc1/inspect_artifacts.jl` | `d14a5eca4f39e833409031cab6c76f6227678010205357ec19475648c9e99e9e` |
| `sim/arc1/runner.py` | `752cc16c8542ac99da0a266857775436e0355984cec4227d79111ef3cbeaca2d` |
| `tools/arc1_manifest.py` | `0c437d8b4950dbaad7df0cd1f745e0ef5e15ff55c3e2720772211a2a7f481c55` |
| `tools/arc1_receipt_check.py` | `3ff6d5dfcd860db4fc1ccb717df460bbb78868bf63d15c35f8b278d145c87db8` |
| `test/arc1_simulation_executor.jl` | `35b50b7ae1b67bac2c3a3c5fdad64360869016a34259b4cd4aafd7ac40ec9b8b` |
| `test/test_arc1_receipt_adversaries.py` | `4449126f21077400897d321216ae464f7639c1d997f79cce15dd2d77fff571be` |
| Architecture candidate | `docs/dev-log/decisions/2026-10-09-g5-authoritative-container-candidate.md`, SHA-256 `26cbc4041ba8f387c767763e1328d88f5aaafe5ae0ce07f79b29ee82b5892a26` |

Admission recursively discovers the declared Arc 1 source extensions under `sim/arc1` (`tools/arc1_manifest.py:33-53`), excluding `manifest-revisions.md`; it does not inventory literally every file in that directory. It hashes the discovered source set during admission (`:481-542`) and requires the same discovered files and bytes during validation (`:701-772`). The attempt loader includes `artifact_container.jl` (`execute_attempt.jl:521`); the inspector includes it (`inspect_artifacts.jl:14`). The exact run admission receipt remains authoritative for a run's complete hash set. This map covers artifact/container and G5 receipt predicates listed below. It does not replace the separate admission protocol and subprocess-boundary audits; those are explicitly outside this map and remain prerequisites for any G5 run.

Evidence labels used below:

- **Historical Julia positive:** `/private/tmp/arc1-container-decoder-final-verified.log`, SHA-256 `0d155182d61e1a997b304c870710e61efd5a631a77b859039708746259484c13`, exit 0; 194/194 executor, 10/10 admission and 15/15 diagnostic-identity assertions. This is from the earlier source/test generation and does not validate the current pinned hashes.
- **Current Julia positive:** `/private/tmp/arc1-container-julia-current-source-rerun.log`, SHA-256 `a8edd5e20650970f8adfa8e047e5b90e9cf6cdacf14feb4e70cd425f7d76fd3d`, exit 0; 194/194 executor, 10/10 admission and 15/15 diagnostic-identity assertions. Command and source pins are recorded in the closeout below.
- **Julia mutation:** a specific negative/mutation case is named with its test lines below; current-source cases ran in the current Julia suite above.
- **Source only:** implementation condition exists, but no dedicated negative mutation test was identified in the retained suite.
- **Python unverified:** the receipt adversary process printed 23 progress dots and was stopped with exit 130. No Python assertion gets pass credit. A diagnostic focused run was reported as passing, but no exact completed runner log/hash is retained; it earns no acceptance credit.
- The focused three-case Julia probe `/private/tmp/arc1-container-adversary-green.log`, SHA-256 `5f8bf97eaae5abe477f5f7358b65fefb15c13e75c0fdf04ae42a20560d77355e`, was reported 3/3. It is supplemental; the full Julia suite is the retained test evidence.

## One-predicate-per-row map

Each row below maps one independently enforced condition. “Absent/state” records where the predicate applies and the permitted omission. “Failure” states the checker outcome. A test is named only where it directly exercises that condition; a passing general suite is not treated as proof of an untested mutation.

### Container bytes and section shape

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| C01 | Refuse existing destination, `artifact_container.jl:156-158` | Container output path | Applies to every write | Throw before replacing prior bytes | Julia mutation existing-path rejection, line 578. |
| C02 | Writer sorts names, then rejects duplicate converted names, `:159-163` | Section-name strings | At least one section is required by reader | Duplicate converted name throws; unsorted input is normalized | Source only for direct duplicate-name writer mutation. |
| C03 | Header magic matches, `:201-202` | Fixed magic bytes | Always required | Reject before decoding directory | Source only; no dedicated bad-magic test identified. |
| C04 | Header version matches, `:203-204` | UInt16 version | Always required | Reject unsupported version | Source only; no dedicated bad-version test identified. |
| C05 | Directory section count is positive, `:205-206` | UInt16 count | Empty container invalid | Reject zero sections | Source only; no dedicated zero-count test identified. |
| C06 | Directory names are unique, `:206-217` | String names | Always required | Reject duplicate name | Source only; no dedicated duplicate-name test identified. |
| C07 | Schema equals `ARC1_CONTAINER_SCHEMA * ":" * name`, `:207-223` | String schema and section name | Always required; no section-name allowlist is implied | Reject schema/name mismatch | Source only; no dedicated schema mutation test identified. |
| C08 | Directory names are strictly ordered, `:207-223` | Consecutive names | Always required | Reject reorder | Source only; no dedicated reorder test identified. |
| C09 | Record count fits host `Int`, `:223` | UInt64 record count | Always required | Reject unrepresentable count | Source only; no dedicated overflow mutation test identified. |
| C10 | Section offsets are contiguous, `:224-230` | UInt64 offset and length pairs | All sections required | Reject gap, overlap, or reordered range | Source only; no direct offset mutation test identified. |
| C11 | Non-history section count equals one, `:230-231` | `records` field for singleton sections | Every section other than `history` | Reject a count other than one | Julia mutation `rejects malformed identity and serialization`, lines 449-454; changes one record to two. No zero-count mutation is identified. |
| C12 | Whole-file length equals final extent, `:232-238` | Directory end plus section lengths | Always required | Reject truncated/trailing container bytes | Julia mutation `typed sections and alias topology`, truncation fixture/assertion lines 580-582. |
| C13 | Exact section bytes are read, `:239-256` | Declared byte range | Every section | Reject short section read | Source only; the truncated-file fixture fails the earlier whole-file extent guard, not this branch. |
| C14 | Section SHA-256 matches, `:251-252` | Directory digest and exact section payload | Every section | Reject digest mismatch before decoding/returning section | Julia corruption fixture/assertion, lines 583-586. |
| C15 | Singleton deserializer consumes all payload bytes, `:150-154`, `:268-269` | One native serialized value | Every non-history section | Reject a second serialized value or junk bytes | Julia mutation `native-trailer`, lines 456-460. |
| C16 | History record size is representable and nonnegative, `:257-260` | UInt64 length prefix converted to `Int` | Each history record | Reject invalid conversion or negative result | Source only for conversion/negative-specific mutation. |
| C17 | Returned history byte count equals declared size, `:259-263` | Declared record length and returned byte vector | Each history record | Reject short/overstated record | Julia overlong-record fixture/assertion, lines 479-492. The source checks after `read`; it makes no pre-read memory bound claim. |
| C18 | Event deserializer consumes all record bytes, `:150-153`, `:262` | One event record payload | Each history record | Reject trailing serialized object or junk bytes in a record | Julia mutation `history-trailer`, lines 462-477. |
| C19 | History section has no trailing undeclared bytes, `:264` | Remaining history section | After declared records | Reject trailing bytes | Source only; event-trailer mutation is rejected earlier by record-payload exhaustion. |

### Original object identities and profile history

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| R01 | Reference table registers selected evidence/history/event-array paths and two fixture dictionary paths, `artifact_container.jl:40-103` | String path to logical UInt64 ID derived from original `objectid` | Only listed identity-bearing objects | IDs support later alias checks; this is not arbitrary graph traversal | Julia positive alias round-trip, `typed sections and alias topology`, lines 544-585. |
| R02 | One ID cannot cross semantic categories, `:292-313`, reader `:483-492` | Reference paths for evidence, history, event arrays | Applies when those references exist | Reject evidence/history/event category collision | Julia mutation `cross-category-object-id`, lines 486-527. |
| R03 | Entered history value is a reference marker, `:315-325`, `:396-422` | `evidence.arc1_profile_v3_evaluations` | Key absent before history entry remains absent | Reject native array substituted for marker | Julia mutation `no_reference`, lines 435-437, and suite pre-entry case, lines 630-640. |
| R04 | v3 marker ID matches reference table, `:396-422` | v3 marker and `references["evidence.arc1_profile_v3_evaluations"]` | Applies if v3 key exists | Reject absent/mismatched identity | Julia positive v3/v4 alias case, lines 598-624; no separate mismatched-v3-ID fixture identified. |
| R05 | v4 marker ID matches reference table, `:396-422` | v4 marker and `references["evidence.arc1_profile_v4_evaluations"]` | Applies if v4 key exists | Reject absent/mismatched identity | Julia positive v4 alias case, lines 598-624; no separate mismatched-v4-ID fixture identified. |
| R06 | Original v3/v4 history values are identical by `===`, `:66-73` | Original v3/v4 arrays | Applies when both history keys are present | Writer rejects distinct arrays before encoding | Julia negative writer rejection, lines 626-629; this is not a decoded-reference-table test. |
| R06a | Decoded v3/v4 markers carry the same ID, `:409-414` | v3/v4 history markers | Applies when both history keys exist | Reject split IDs | Source only for a contradictory decoded marker-ID mutation; missing counterpart is checked by R07. |
| R07 | Reader restores both v3/v4 aliases when either history key triggers restoration, `:494-504` | Reconstructed history arrays | Applies when either v3/v4 history key exists | Reject absent counterpart; restored aliases resolve to the same object | Julia positive assertion `v3 === v4`, lines 618-622. |
| R08 | Writer extracts three declared event fields, `:327-350` | `events`, `producer_history`, `provenance_failures` row fields | Missing event keys remain missing; other dictionary keys remain ordinary row data | Extract only those declared fields | Julia positive typed history, lines 585-624. Unknown-group rejection is separate at reader `:389-392`; no direct mutation identified. |
| R08a | Reference table is a dictionary, `:293` | Reference table value | Always required | Reject invalid reference-table shape | Source only. |
| R08b | Writer history row is a dictionary, `:334` | Each history row | Every stored row | Reject invalid row shape | Source only. |
| R08c | Restored history row collection is a vector, `:354` | Decoded history rows | Whenever rows are restored | Reject invalid collection shape | Source only. |
| R08d | Restored event-stream collection is a vector, `:355` | Decoded event streams | Whenever streams are restored | Reject invalid collection shape | Source only. |
| R08e | Event record contains required fields, `:358-360` | Event-record row/field/index/value fields | Every event record | Reject missing required fields | Source only. |
| R09 | Present event field is a vector, `:329-351` | Each native event field | Key may be absent | Reject non-vector field | Source only; no dedicated wrong-type mutation identified. |
| R10 | Present event vector has recorded original ID, `:329-351` | `references["evaluation.<row>.<field>"]` | Key absent means no corresponding event records | Reject missing ID | Julia positive ID assertions, lines 598-616; no dedicated missing-ID mutation identified. |
| R11 | History row marker is a reference, `:353-394` | `history_rows[row].<event-field>` | Only fields originally present have markers | Reject native value in marker position | Source only for this row-level marker. The `no_reference` test at lines 431-435 covers the top-level history marker. |
| R12 | Event marker ID equals row/field ID, `:353-394` | Marker ID and reference table entry | Applies for each present event field | Reject mismatched ID | Source only; the cross-category mutation fails before marker-ID equality is tested. |
| R13 | Event index starts at one and has no gaps/reordering, `:353-366` | `(row_index, field, event_index)` records | Empty vectors have zero event records | Reject noncanonical sequence | Source only; no dedicated gap/reorder mutation identified. |
| R14 | Event stream row/field belongs to retained history rows, `:386-394` | Grouped event keys | No extra row/field groups allowed | Reject unknown row or field | Source only; no dedicated unknown-group mutation identified. |
| R15 | Reused event ID has `isequal` contents, `:368-384` | Reconstructed event vectors | Reuse allowed only for same semantic object/content | Reject one ID with different values | Julia mutation conflicting event IDs, lines 439-447. |
| R16 | Reused event ID resolves to the same vector object, `:368-384` | Reconstructed event vector registry | Same ID/equal content uses one vector | Reject incompatible object meaning | Source only; no direct test of repeated event-vector identity identified. |
| R17 | Writer sees result evidence is original evidence object, `:425-481` | `result.v3_profile_evidence` and top-level sink | Field may be absent or `nothing` | Reject detached evidence copy | Julia positive alias assertion, lines 602-624; no dedicated copied-result mutation identified. |
| R18 | Writer sees summary evidence is original evidence object, `:425-481` | `summary.v3_profile_evidence` and top-level sink | Field may be absent or `nothing` | Reject detached evidence copy | Julia positive alias assertion, lines 602-624; no dedicated copied-summary mutation identified. |
| R19 | Reader result marker points to evidence ID, `:510-523` | `result.v3_profile_evidence` | Absent/`nothing` is preserved | Reject malformed marker or wrong ID | Julia positive alias assertion, lines 618-624; no marker-mismatch mutation identified. |
| R20 | Reader summary marker points to evidence ID, `:524-535` | `summary.v3_profile_evidence` | Absent/`nothing` is preserved | Reject malformed marker or wrong ID | Julia positive alias assertion, lines 618-624; no marker-mismatch mutation identified. |
| R21 | Invalid evidence sink is retained only as diagnostic raw evidence, `execute_attempt.jl:630-643` | `v3_profile_evidence_raw` on writer failure | Only failure fallback | Preserve malformed sink; do not treat it as valid evidence | Julia split-history failure-retention test, lines 959-974. |

### G5 metadata, identity, result, and profile-state checks

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| M01 | Outer field is present, `inspect_artifacts.jl:166-179` | Expected representation: integer `metadata.outer` | Required on every attempted artifact | Inspector error if absent | Julia fake-engine positive, `fresh-process fake-engine wiring and evidence`, lines 723 onward; no missing-outer mutation identified. |
| M02 | Exact seed field is present, `:166-179` | Expected representation: string `metadata.seed_string` | Required | Inspector error if absent | Same positive suite; no missing-seed mutation identified. |
| M03 | Cell field is present, `:166-179` | Expected representation: mapping `metadata.cell` | Required | Inspector error if absent | Same positive suite; no missing-cell mutation identified. |
| M04 | Execution identity field is present, `:166-179` | Expected representation: mapping `metadata.execution_identity` | Required | Inspector error if absent | Same positive suite; no missing-identity mutation identified. |
| M05 | Driver/protocol identity field is present, `:173-179` | Expected representation: `metadata.driver_protocol_identity` | Required | Inspector error if absent | Same positive suite; no missing-driver-identity mutation identified. |
| M06 | Semantic identity is recomputed from retained data/design, `inspect_artifacts.jl:188-196` | Native `data`, `design`, declared identity hash/method | If either source object is absent, both declarations must be absent | Identity mismatch or false presence state | Julia fake-engine positive; data-identity mutation is Python-only and unverified. Canonical data/design contents originate in `execute_attempt.jl:129-136`. |
| M07 | Data seed equals metadata seed, inspector `:197-199` | `data.seed`, `metadata.seed_string` | Requires retained data | False match state | Julia positive; no direct seed mutation result retained. |
| M08 | Raw result projection difference and Boolean match are derived, inspector `:199-204`; raw projection helper `execute_attempt.jl:328-379` | `raw_result_projection_difference`; `raw_result_matches_derived_receipt` | Without a result, difference is `nothing` and match is `summary === nothing` | Difference retained as diagnostic; match is Boolean | Focused current-source Python cross-language fixture passed the FA selector, repeatability and interval raw-projection checks, including mutations at `test/test_arc1_receipt_adversaries.py:615-655`; full Python suite remains unrun. The separate result/summary contradiction test is not this predicate. |
| M09 | Reference scale matches retained response, inspector `:199-204`; helper `execute_attempt.jl:384-400` | Reference traits/scale and retained response | Ordinary G5 result follows helper's non-reference-audit branch, which returns true | False diagnostic when required audit fails | Source-reviewed; no dedicated negative case identified. |
| M10 | Embedded summary exists iff a result exists, inspector `:181-190` | `receipt_summary`, retained result | Both absent allowed; summary alone or result without summary follows false branch | Summary/result inconsistency | Julia positive matching summary at `test/arc1_simulation_executor.jl:794`; Python contradiction test unverified. |
| M11 | Embedded summary equals derived result receipt, inspector `:181-190` | Canonically rendered summary and result | Applies when both exist | False match diagnostic | Same Julia positive test only checks equality; Python rehashed contradiction test at `test/test_arc1_receipt_adversaries.py:1686-1731` is unverified. |
| M12a | Embedded-summary representation hash is exposed, inspector `:335-344` | Exact UTF-8 JSON representation of summary | Hash is `nothing` when summary is absent | Independent checker can compare hash | Source-reviewed; 15/15 tests native `repr` hashes, not this JSON summary hash. |
| M12b | Retained-result representation hash is exposed, inspector `:335-344` | Exact UTF-8 JSON representation of result | Hash is `nothing` when result is absent | Independent checker can compare hash | Source-reviewed; 15/15 tests native `repr` hashes, not this JSON result hash. |
| M13 | Loaded engine source identity is established by inspector call, `:215`; histories/certificates are read at `:223-225` | Loaded engine source root/identity | Required for profile evidence | Identity false/error | Julia source-bound fake-engine suite positive; no source-root mutation result retained. |
| M14 | Result source identity equals loaded engine identity, inspector `:260-312` | `result.source_identity` | For profile methods; error/interruption may have no result | Evidence identity false | Julia source-bound fake-engine suite positive. |
| M15 | Reference source identity equals loaded engine identity, `:260-312` | `result.reference_source_identity` | Same as M14 | Evidence identity false | Julia source-bound fake-engine suite positive. |
| M16 | Requested method controls whether profile evidence is required and whether no-profile sink is absent, `:232-233`, `:281-291` | Requested profile-method metadata and evidence sink | No requested profile method requires absent sink | Evidence identity false | Julia fake-engine suite positive; no independent mutation test identified. |
| M17 | Evidence requested method matches request, `:260-312` | `evidence.requested_method_version` | Required for profile evidence dictionary | Evidence identity false | Julia positive fixture; Python native/submitted comparison unverified. |
| M18 | Evidence actual method matches request, `:260-312` | `evidence.actual_method_version` | For v3 pre-entry, histories may be empty; for requested v4, both history keys must be absent, along with null source and metadata method | Evidence identity false | Julia pre-entry container preservation, lines 630-639; this does not directly test inspector sink-identity acceptance. |
| M19 | Evidence returned method matches request if present, `:260-312` | Optional `returned_method_version` | The implemented condition permits absence whenever the key is absent | Evidence identity false on contradictory value | Source-reviewed; no dedicated mutation test identified. |
| M20 | Metadata/result profile-method fields agree, `:306-314` | Metadata method, retained method, mismatch flag | Missing retained method is allowed when metadata method equals request; absent metadata method instead requires error/interrupted state | Method identity false | Julia error/interruption fake-engine suite positive; per-field mutation not identified. |
| M21 | `not_run` point-fit fields are null, checker `tools/arc1_receipt_check.py:186-224` | Point status and point-fit diagnostic fields | Applies when `point_fit_status == "not_run"` | Receipt error for non-null fields | Python checker run incomplete; no G5 live receipt. |
| M21b | `not_run` target-diagnostic fields are null, checker `:186-224` | Target diagnostic identity fields | Applies when `point_fit_status == "not_run"` | Receipt error for partial diagnostics | Python checker run incomplete. |
| M21c | All diagnostic keys are absent, checker `:186-224` | Key membership for the complete diagnostic field set | Accepted only for failed attempts with every target unformed; all keys present with null values follows status checks instead | Receipt error outside that branch | Python checker run incomplete. |
| M21d | Requested/admitted profile method agrees, checker `:192-198` | Requested and admitted method | Every profile attempt | Receipt error | Python checker run incomplete. |
| M21e | Point-fit status belongs to allowed set, checker `:199` | `point_fit_status` | Every profile attempt | Receipt error | Python checker run incomplete. |
| M21f | `not_run` method/source conditions hold, checker `:202-216` | Method and source identity fields | `not_run` only | Receipt error | Python checker run incomplete. |
| M21g | Failed/unformed outer-fit targets are refused, checker `:221-224` | Target formation and refusal fields | Failed point-fit only | Receipt error | Python checker run incomplete. |
| M21h | Actual method agrees with request, checker `:227` | `actual_method_version` | Required when point fit entered | Receipt error | Python checker run incomplete. |
| M21i | Point-optimality field is Boolean, checker `:229` | `point_fit_not_optimal` | Required when point fit entered | Receipt error | Python checker run incomplete. |
| M21j | Source/reference identities agree and have required hashes, checker `:231-236` | Source identity and reference identity | When a reference fit exists | Receipt error | Python checker run incomplete. |
| M21k | Point and reference likelihoods are finite, checker `:243-245` | Point/reference likelihood | When fits exist | Receipt error | Python checker run incomplete. |
| M21l | Optimal `ok` point fit reports success, checker `:253-255` | Status and success fields | `point_fit_status == "ok"` and not nonoptimal | Receipt error | Python checker run incomplete. |
| M21m | Unconverged point fit reports failure and null diagnostics, checker `:257-262` | Status, success, diagnostics | Unconverged only | Receipt error | Python checker run incomplete. |
| M22 | Optimality comparison applies when `point_fit_status == "ok"`, checker `:237-262` | `point_fit_status` | Other statuses follow their own refusal branch | Reject inconsistent status/guard combination | Python checker run incomplete. |
| M23 | Maximum constrained loglik is compared with point loglik plus `1e-7`, checker `:237-262` | `max_constrained_loglik`, `point_loglik` | A greater maximum is permitted as a nonoptimal diagnosis when consistent | Do not require inequality to be false | Python checker run incomplete. |
| M24 | Point-optimality flag agrees with likelihood comparison, checker `:237-262` | `point_fit_not_optimal` | Applies when status is `ok` | Reject flag/comparison disagreement | Python checker run incomplete. |
| M25 | Nonoptimal point fit requires all targets unformed with refusal status, checker `:237-262` | Target formation/status/refusal | Applies when `point_fit_not_optimal` is true | Reject any formed target or inconsistent refusal | Python checker run incomplete. |
| M26 | Profile likelihood method is frozen, checker `:1150-1152` | `profile_method` | Required for G5 formed/refused intervals | Receipt error on another method | Python checker run incomplete. |
| M27 | Likelihood-ratio cutoff equals `3.841458820694124`, checker `:1150-1152` | `profile_lr_cutoff` | Required for G5 interval outputs | Receipt error on mismatch | Python checker run incomplete. |
| M28 | No evidence-retention error is reported, checker `:965-981` | `v3_evidence_retention_error` | For entered v3/v4 evidence | Receipt error if non-null | Python checker run incomplete. |
| M29 | Submitted evidence equals the complete native evidence sink, checker `:965-981` | Attempt `v3_profile_evidence` and inspected native evidence | For entered v3/v4 evidence | Receipt error on missing, malformed, or unequal sink | Python checker run incomplete. |
| M30 | Submitted profile source identity equals loaded source identity, checker `:965-981` | `profile_source_identity`, metadata `loaded_arc1_source_identity` | For entered v3/v4 evidence | Receipt error on mismatch | Python checker run incomplete. |
| M31 | Native v4 aliases are affirmed by inspector, checker `:975-981` | Inspector `v4_evidence_aliases_match` | v4 only | Receipt error unless true | Julia alias tests pass; receipt-level Python validation incomplete. |
| M31a | Inspector accepts required evidence identity, checker `:965-969` | Evidence presence and combined identity flag | Entered profile evidence | Receipt error if absent, false or mismatched | Python checker run incomplete. |
| M31b | Pre-entry evidence flag matches absence state, checker `:988-990` | Pre-entry identity fields and acceptance flag | Pre-entry only | Receipt error on contradictory presence/acceptance | Python checker run incomplete. |
| M32 | Point-fit diagnostic hash is recomputed from exact native `repr`, executor `:203-245`, `:368-376` | `repr(point_fit_candidate)` | Hash is computed when the receipt is derived, including `repr(nothing)` when that is the value | Identity mismatch | Julia positive assertions `test/arc1_simulation_executor.jl:1111-1115`; mutation coverage not identified. |
| M33 | Target diagnostic hash is recomputed from exact native `repr`, executor `:203-245`, `:368-376` | `repr(targets)` | Hash is computed when the receipt is derived, including `repr(nothing)` when that is the value | Identity mismatch | Julia positive assertions `test/arc1_simulation_executor.jl:1111-1115`; mutation coverage not identified. |
| M34 | Loaded package UUID equals loaded module UUID and expected package UUID, inspector `:40-49` | Runtime `engine_package_uuid`, module package ID, `ARC1_HSQUARED_UUID` | Every inspector identity check | Runtime identity false | Source reviewed; no per-conjunct mutation test identified. |
| M35 | Loaded module path equals runtime pin and expected source path, inspector `:40-49` | Runtime `engine_module_path`, `pathof(module)` | Every inspector identity check | Runtime identity false | Source reviewed; no per-conjunct mutation test identified. |
| M36 | HSquared module is in loaded-module names, inspector `:40-49` | `loaded_module_names` | Every inspector identity check | Runtime identity false | Source reviewed; no per-conjunct mutation test identified. |
| M37 | Source snapshots at load, after load, and current source agree, inspector `:40-49` | `source_sha256_at_load`, `source_sha256_after_load`, `runtime.loaded_engine_source_sha256`, current snapshot | Every inspector identity check | Runtime identity false | Source reviewed; no per-conjunct mutation test identified. |
| M38 | Environment pins equal current environment snapshot, inspector `:40-49` | `environment_sha256` | Every inspector identity check | Runtime identity false | Source reviewed; no per-conjunct mutation test identified. |
| M39 | Active project equals expected Project.toml path, inspector `:40-49` | Runtime active project | Every inspector identity check | Runtime identity false | Source reviewed; no per-conjunct mutation test identified. |
| M40 | Dependency environment is verified exactly true, inspector `:40-49` | Runtime Boolean | Every inspector identity check | Runtime identity false | Source reviewed; no per-conjunct mutation test identified. |
| M41 | Metadata loaded source identity equals module source identity, inspector `:40-49` | Metadata identity and module constant | Every inspector identity check | Runtime identity false | Source reviewed; Julia source-bound suite is positive only. |

### G5 target and certificate predicates

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| T01 | Target key set equals frozen five targets, receipt checker `:134-154`, `:1146-1178` | Profile target map | For G5 profile attempt | Receipt error on missing/extra target | Python checker run incomplete; no G5 receipt. |
| T02 | Target formula matches expected formula, checker `:148-174`, `:1146-1178` | Each target formula string | Each target required | Receipt error | Python checker run incomplete. |
| T03 | Segment set is nonempty when formed, checker `:584-607` | Segment list | Refused/unformed intervals have no formed set | Receipt error | Python checker run incomplete. |
| T03a | Every segment has exactly two endpoints, checker `:584-607` | Each segment pair | Applies to formed set | Receipt error | Python checker run incomplete. |
| T03b | Endpoints are numeric, finite, and ordered lower-to-upper, checker `:584-599` | Each lower/upper pair | Applies to each formed segment | Receipt error | Python checker run incomplete. |
| T03c | Successive segments are strictly separated and ordered, checker `:584-607` | Consecutive segment pairs | Applies when multiple segments exist | Receipt error | Python checker run incomplete. |
| T03d | Segments obey target-specific bounds, checker `:601-607` | `h2`/repeatability [0,1] or nonnegative variance parameter | Each formed target | Receipt error | Python checker run incomplete. |
| T04 | Target row is a mapping, checker `:162-174` | Target row mapping | Each frozen target | Receipt error | Python checker run incomplete. |
| T04a | Target formation flag is Boolean, checker `:162-174` | `formed` | Each target row | Receipt error | Python checker run incomplete. |
| T04b | Target status belongs to the allowed set, checker `:162-174` | `status` | Each target row | Receipt error | Python checker run incomplete. |
| T04c | Formation flag agrees with formed/refused status, checker `:162-174` | `formed`, `status` | Each target row | Receipt error | Python checker run incomplete. |
| T04d | Refused target has empty segments and a nonempty refusal string, checker `:162-174` | `segments`, `refusal` | Refused rows only | Receipt error | Python checker run incomplete. |
| T05 | Point identity has status-specific presence/value, checker `:177-262` | `point_identity` | Null for `not_run` or unconverged; for `ok`, SHA-256 and equal to reference identity | Receipt error | Python checker run incomplete. |
| T05a | Reference-point identity has status-specific presence/value, checker `:177-262` | `reference_point_identity` | Null for `not_run` or unconverged; for `ok`, SHA-256 and equal to point identity | Receipt error | Python checker run incomplete. |
| T05b | Point and target diagnostic hashes match their exact native representations, checker `:177-262`, executor `:203-245`, `:368-376` | `repr(point_fit_candidate)`, `repr(targets)` and projected hashes | Hashes are recomputed from recorded native values | Receipt error on mismatch | Julia positive assertion `test/arc1_simulation_executor.jl:1111-1115`; Python validation incomplete. |
| T06 | Entered v4 certificate evidence is a native list, checker `:358-360` | Native `v4_tail_certificates` | Required when v4 evidence is entered, including empty list | Receipt error if missing or wrong type | Python checker run incomplete. |
| T06a | Stripped evidence cannot retain inline certificate inputs, `artifact_container.jl:507-509` | Inline certificate key and separate section | Applies when certificate section owns the values | Reject inline duplicate | Julia mutation `certificate-authority-conflict`, lines 527-540; no orphan-section mutation identified. |
| T06aa | Certificate section cannot be orphaned, `artifact_container.jl:510-511` | `tail_certificate_inputs` section | Requires evidence section | Reject orphan section | Source only; no orphan-section mutation identified. |
| T06b | v4 certificate key presence follows entered method state, `artifact_container.jl:425-481`, checker `:358-368` | Evidence certificate key and separate section | v4 evidence must restore a list; no-profile state may omit the entire evidence sink | Receipt error on absent entered-v4 collection | Python checker run incomplete. |
| T07 | Certificate record has correct target and nested mapping, checker `:265-300` | Target `residual_variance`, certificate object | Applies when certificate row exists | Receipt error | Python checker run incomplete. |
| T08 | Certificate status is `excluded_tail`, checker `:285-300` | Certificate status | Each present row | Receipt error | Python checker run incomplete. |
| T09 | `certified` is exactly true, checker `:285-300` | Boolean certificate field | Each present row | Receipt error | Python checker run incomplete. |
| T10 | Certificate precision is 256, checker `:285-300`, `:324-330` | Integer precision | Each present row | Receipt error | Python checker run incomplete. |
| T11 | Rounding mode label matches allowed mode, checker `:285-300`, inspector `:83-120` | Rounding string | Every certificate | Receipt error on mismatch | Python checker run incomplete. |
| T11a | First exact rounding-contract tuple matches, inspector `:83-120` | Native rounding tuple fields | Every certificate | Structural validation fails | Julia v4 positive fixture; no negative tuple mutation identified. |
| T11b | Second exact rounding-contract tuple matches, inspector `:83-120` | Native rounding tuple fields | Every certificate | Structural validation fails | Julia v4 positive fixture; no negative tuple mutation identified. |
| T12 | Determinant identity matches frozen identity string, checker `:285-300` | Determinant identity | Each certificate | Receipt error | Python checker run incomplete. |
| T13 | Design identity is a valid SHA-256, checker `:285-301` | Design identity | Each certificate | Receipt error | Python checker run incomplete. |
| T14 | Determinant uses exact rational object and exact key/type set, checker `:300-323` | Rational numerator, denominator, type tag | Each certificate | Receipt error | Python checker run incomplete. |
| T15 | Exact determinant denominator is positive and value is positive, checker `:312-323` | Rational determinant | Each certificate | Receipt error | Python checker run incomplete. |
| T16 | Residual df is a positive exact integer, checker `:321-325` | `residual_df` | Each certificate | Receipt error | Python checker run incomplete. |
| T17 | Likelihood convention equals `omit_2pi`, checker `:321-325` | Convention string | Each certificate | Receipt error | Python checker run incomplete. |
| T18 | Gap uses exact numerator/denominator/precision representation, checker `:328-347` | Encoded BigFloat gap | Each certificate | Receipt error | Python checker run incomplete. |
| T19 | Exact gap clears strict threshold, checker `:338-347` | Decoded exact gap | Each certificate | Receipt error unless strictly greater than frozen bound | Python checker run incomplete. |
| T20 | Boundary value is finite and positive, checker `:345-346` | `E` | Each certificate | Receipt error | Python checker run incomplete. |
| T21 | Raw point likelihood agrees with recomputed certificate, inspector `:136-157` | Native `point_loglik` and recomputed certificate point likelihood | Required for certificate validation | Certificate invalid | Julia wrong-point-likelihood mutation, lines 805-825; this tests recomputation correspondence, not finite-type validation. |
| T21a | Raw profile cutoff is finite positive Float64, inspector `:136-157` | `profile.cutoff` | Required for certificate validation | Certificate invalid | Source only; no cutoff-type mutation identified. |
| T21b | Receipt cutoff equals frozen `3.841458820694124`, checker `:1150-1152` | `profile_lr_cutoff` | Required for G5 interval outputs | Receipt error on mismatch | Python checker run incomplete. |
| T22 | Retained design inputs pass structural validation, inspector `:55-76`, `:83-159` | Design context and raw design fields | Required for matched design correspondence | Certificate invalid or unavailable only under interruption rule | Julia v4 positive fixture; no direct design mutation identified. |
| T22a | Context/design status and determinant validity are checked, inspector `:127-131` | Design context and determinant | Required for matched validation | Design correspondence fails | Julia v4 positive fixture; negative mutations not identified. |
| T22aa | Residual df corresponds to retained design, inspector `:132` | Recomputed residual df | Required when raw design inputs are available | Design correspondence fails | Julia v4 positive fixture; no negative mutation identified. |
| T22ab | Determinant corresponds to retained design, inspector `:133` | Recomputed determinant | Required when raw design inputs are available | Design correspondence fails | Julia v4 positive fixture; no negative mutation identified. |
| T22ac | Design identity corresponds to retained design, inspector `:134` | Recomputed design identity | Required when raw design inputs are available | Design correspondence fails | Julia v4 positive fixture; no negative mutation identified. |
| T22b | Required raw profile/reference inputs are retained, inspector `:136-148` | Raw profile/reference inputs | Missing inputs yield `valid=false, design=:matched`; they do not qualify for interrupted unavailability | Certificate invalid | Julia v4 positive fixture; negative mutation not identified. |
| T22bb | Interrupted unavailable design requires missing design inputs and absent context, inspector `:246-250` | Design inputs/context and status | Genuine interruption only | Reject other unavailable combinations | Julia interruption fixture positive. |
| T22c | Recomputed native certificate equals retained certificate, inspector `:143-159` | Full recomputed certificate object | Required when design inputs are available | Certificate invalid | Julia mutation changes gap at test:807-810; this tests recomputation rejection, not structural gap threshold. |
| T23 | Empty certificate collection reports `no_certificate`, checker `:365-368` | Native empty list and inspector status fields | Empty list only | Require no_certificate, not_applicable, evidence-valid true | Python checker run incomplete. |
| T24 | Valid certificate reports `validated` and `matched`, checker `:370-373` | Native validation and design status | Allowed only when fully recomputed | Reject mismatching combined flags | Python checker run incomplete. |
| T25 | Design unavailable is accepted only for interrupted, structurally valid certificate, inspector `:246-259`, checker `:374-380` | Attempt and metadata status, structural validity, design correspondence | Interruption only; requires missing design inputs and absent context; never label as validated | Reject other unavailable/invalid combinations | Julia interruption fixture positive; Python status matrix incomplete. |
| T26 | Native certificate contains every required field, inspector `:83-95` | `status`, `reason`, `certified`, `precision`, `rounding`, `determinant`, `residual_df`, `design_identity`, `convention`, `E`, `upper_bound`, `threshold_lower`, `gap_lower`, `point_loglik`, `cutoff`, `separation_tolerance`, both rounding contracts, determinant identity | Each certificate row | Structural validation fails | Julia test removes `E` at :811 and verifies invalidity at :814-825; not a full missing-field matrix. |
| T27 | Native certificate status is `:excluded_tail`, inspector `:97-120` | `status` symbol | Each certificate | Structural validation fails | Julia positive v4 fixture; no status mutation identified. |
| T28 | Native certificate reason is exactly `nothing`, inspector `:97-120` | `reason` | Each certificate | Structural validation fails | Julia positive v4 fixture; no reason mutation identified. |
| T29 | Native `certified` flag is exactly true, inspector `:97-120` | Boolean | Each certificate | Structural validation fails | Julia positive v4 fixture; no flag mutation identified. |
| T30 | Native precision is exactly 256, inspector `:97-120` | Integer precision | Each certificate | Structural validation fails | Julia positive v4 fixture; no precision mutation identified. |
| T31 | Native rounding symbol is `:directed_mpfr`, inspector `:97-120` | Rounding symbol | Each certificate | Structural validation fails | Julia positive v4 fixture; no rounding mutation identified. |
| T32 | Native determinant is positive `Rational{BigInt}`, inspector `:97-120` | Exact determinant | Each certificate | Structural validation fails | Julia positive v4 fixture; Python type checks incomplete. |
| T33 | Native residual df is a positive integer and not Bool, inspector `:97-120` | `residual_df` | Each certificate | Structural validation fails | Julia positive v4 fixture; no df mutation identified. |
| T34 | Native design identity is a lowercase SHA-256 string, inspector `:97-120` | `design_identity` | Each certificate | Structural validation fails | Julia positive v4 fixture; no design-identity mutation identified. |
| T35 | Native convention is `:omit_2pi`, inspector `:97-120` | Convention symbol | Each certificate | Structural validation fails | Julia positive v4 fixture; no convention mutation identified. |
| T36 | Native boundary E is finite positive Float64, inspector `:97-120` | `E` | Each certificate | Structural validation fails | Julia positive v4 fixture; no E-type/value mutation identified. |
| T37 | Native upper bound is finite BigFloat, inspector `:97-120` | `upper_bound` | Each certificate | Structural validation fails | Julia positive v4 fixture; no per-field mutation identified. |
| T38 | Native threshold lower bound is finite BigFloat, inspector `:97-120` | `threshold_lower` | Each certificate | Structural validation fails | Julia positive v4 fixture; no per-field mutation identified. |
| T39 | Native gap lower bound is finite BigFloat and strictly above `BigFloat(1e-8)`, inspector `:97-120` | `gap_lower` | Each certificate | Structural validation fails | Julia mutation at test:807-810 changes the gap upward and tests recomputation rejection, not the structural threshold. |
| T40 | Native point likelihood is finite Float64, inspector `:97-120` | `point_loglik` | Each certificate | Structural validation fails | Source only for finite-type guard; wrong-likelihood mutation at test:805-825 remains finite and tests recomputation correspondence. |
| T41 | Native cutoff is finite positive Float64, inspector `:97-120` | `cutoff` | Each certificate | Structural validation fails | Julia positive fixture; no cutoff-type/value mutation identified. |
| T42 | Native separation tolerance is exactly `1e-8`, inspector `:97-120` | `separation_tolerance` | Each certificate | Structural validation fails | Julia positive fixture; no tolerance mutation identified. |
| T45 | Native determinant identity equals the frozen identity symbol, inspector `:97-120` | `determinant_identity` | Each certificate | Structural validation fails | Julia positive fixture; no identity mutation identified. |

### Admission, receipt, accounting, and compatibility predicates

| ID | Predicate and source | Native field / encoded location and type | Absent/state rule | Failure | Direct evidence |
|---|---|---|---|---|---|
| A01 | Receipt schema is supported, checker `:822` | Receipt schema | Every receipt | Receipt error | Python checker run incomplete. |
| A01a | Source hash map is nonempty and well-formed, checker `:799-825` | Expected source path/hash map | Every receipt | Receipt error | Python checker run incomplete. |
| A02 | Receipt source hashes equal expected exact pins, `:817-825` | `receipt.source_hashes` | Every receipt | Receipt error | Python checker run incomplete. |
| A03 | Protocol digest equals expected protocol, `:801-852` | Protocol SHA-256 | Every receipt | Receipt error | Python checker run incomplete. |
| A04 | Stored row admission digest is conditionally compared with computed expected digest, `:876-885` | `stored_row.admission_sha256` and expected admission digest | Only when admission is supplied and row has an artifact path or contains `admission_sha256` | Receipt error on mismatch | Python checker run incomplete. |
| A05 | Expected cell has exact required keys, `:827-832` | Programme/phase/N/signal mapping | Every receipt | Receipt error | Python checker run incomplete. |
| A05a | Receipt cell equals expected cell, `:827-832` | Receipt cell mapping | Every receipt | Receipt error | Python checker run incomplete. |
| A05b | Expected outer seed partition is canonical, `:829-867` | Programme/phase/N/signal and seed list | Every cell receipt | Receipt error | Python checker run incomplete. |
| A06 | Bootstrap inner seed partition is canonical, `:852-867` | Outer-to-inner seed mapping | FA interval only; outside G5 study scope | Receipt error if applicable | Outside this G5 repeatability/boundary slice; no bootstrap claim. |
| A07 | Planned attempt count equals frozen allocation, `:867-871` | `planned_attempts` | Every receipt | Receipt error | Python checker run incomplete. |
| A08 | Actual attempt list length equals planned count, `:867-871` | Ordered attempts | Every receipt; no replacement | Receipt error | Python checker run incomplete. |
| A09 | Attempt outer index equals canonical 1-based order, `:912-930` | Attempt outer field | Each attempt | Receipt error | Python checker run incomplete. |
| A10 | Attempt seed equals canonical seed as an exact integer, `:920-922` | `seed` | Each attempt after canonical ordering | Receipt error on mismatch or wrong type | Python checker run incomplete. |
| A10a | Attempt ID is nonempty and unique, `:913-918` | `attempt_id` string | Each attempt | Reject missing/duplicate ID | Python checker run incomplete. |
| A10b | Attempt status is a nonempty string, `:923-928` | `status` | Each attempt | Reject missing/empty status | Python checker run incomplete. |
| A10c | Attempt success has Boolean type, `:923-928` | `success` | Each attempt | Reject missing/non-Boolean value | Python checker run incomplete. |
| A10d | Status agrees with success flag, `:923-928` | `status`, `success` | `ok`/`success` must correspond exactly to true | Reject disagreement | Python checker run incomplete. |
| A10e | Artifact metadata schema matches, `:937-941` | `metadata.schema` | When an artifact is inspected | Receipt error | Python checker run incomplete. |
| A10f | Artifact metadata outer matches attempt, `:937-941` | `metadata.outer` | When an artifact is inspected | Receipt error | Python checker run incomplete. |
| A10g | Artifact metadata seed string matches attempt, `:937-941` | `metadata.seed_string` | When an artifact is inspected | Receipt error | Python checker run incomplete. |
| A10h | Artifact metadata cell matches expected cell, `:937-941` | `metadata.cell` | When an artifact is inspected | Receipt error | Python checker run incomplete. |
| A11 | Artifact path/root claims meet required conditions, `:874-900` | Artifact path, expected root, source admission | Root/path confinement is applied when claims and roots are supplied | Receipt error before inspection | Python checker run incomplete. |
| A11a | Inspected artifact exists, `:934-935` | Artifact path | Every row that claims an artifact | Receipt error | Python checker run incomplete. |
| A12 | Artifact is inspected, then its byte hash is checked, `:902-903`, `:1064-1075` | Artifact path and `artifact_sha256` | Applies after artifact path is admitted | Receipt error on mismatch; hash follows inspection | Python checker run incomplete. |
| A13 | Summary claim requires safe path, digest and existence, `:1076-1088` | `receipt_summary_path`, digest, artifact summary claims | Required for success or either summary claim | Receipt error | Python checker run incomplete. |
| A14 | Summary bytes match retained SHA-256, `:1086-1088` | Sidecar bytes/hash | Each claimed durable summary | Receipt error | Python checker run incomplete. |
| A14a | Summary bytes decode as UTF-8 JSON, `:1083-1095` | Sidecar bytes | Each durable summary | Receipt error | Python checker run incomplete. |
| A15 | Sidecar summary equals durable Julia result mapping, `:1096-1099` | JSON sidecar and durable row/wrapper | Each attempt | Receipt error | Python checker run incomplete. |
| A15a | Sidecar summary equals embedded native summary, `:1099-1100` | JSON sidecar and artifact metadata summary | Each attempt | Receipt error | Python checker run incomplete. |
| A15b | Flattened durable fields equal retained summary fields, `:1101-1104` | Each flattened field | Each attempt | Receipt error | Python checker run incomplete. |
| A15c | Failed retained-summary branch agrees with attempt failure state, `:1054-1060` | Retained summary status/success and attempt status/success | Failed summaries only | Receipt error on mismatch | Python checker run incomplete; does not directly check every successful retained-result flag. |
| A15d | Retained data identity matches durable row, `:1006-1046` | Data-identity hash and method | When retained data exists | Receipt error | Python checker run incomplete. |
| A15e | Retained semantic identity matches durable row, `:1006-1046` | Semantic-identity hash | When retained data/design exist | Receipt error | Python checker run incomplete. |
| A15e2 | Retained runtime execution identity matches durable row, `:1006-1046` | Execution identity | When runtime identity exists | Receipt error | Python checker run incomplete. |
| A15f | Successful artifact contains canonical embedded summary, `:1044-1063` | Embedded `receipt_summary` | Successful attempts only | Receipt error if absent or malformed | Python checker run incomplete. |
| A15g | Failed retained summary matches failed result status/success, `:1052-1063` | Failed artifact summary/result status | Applies when a failed artifact contains summary | Receipt error on mismatch | Python checker run incomplete. |
| A15h | Embedded summary path/hash equals external receipt pins, `:1044-1063` | Metadata summary path/digest and receipt row path/digest | When summary is retained | Receipt error | Python checker run incomplete. |
| A15i | Driver identity is a mapping and its source pins match, `:991-996` | `driver_protocol_identity`, source hashes | Each inspected attempt | Receipt error | Python checker run incomplete. |
| A15j | Protocol identity matches expected digest, `:991-996` | Protocol digest | Each inspected attempt | Receipt error | Python checker run incomplete. |
| A15k | Driver environment pins match admission when supplied, `:991-996` | Environment hashes | Admission-conditional | Receipt error | Python checker run incomplete. |
| A15l | Runtime identity mapping is required for successful attempt, `:1105-1113` | Execution identity | Success requires mapping; failed attempt may omit it | Receipt error on missing success identity | Python checker run incomplete. |
| A15m | Present runtime identity is verified against admission, `:1105-1113` | Attempt identity, expected root and admitted pins | Whenever identity exists | Receipt error on missing/mismatch | Python checker run incomplete. |
| A15n | Failed attempt has nonempty failure reason, `:1114-1117` | `failure_reason` | Failed attempts only | Receipt error | Python checker run incomplete. |
| A15o | G5 receipt contains no rank-selection evidence, `:1128-1129` | Rank-candidate fields | G5 repeatability/boundary receipt | Receipt error on rank evidence | Python checker run incomplete. |
| A15p | Failed outer attempt targets remain unformed, `:1162-1164` | Target formation states | Failed attempts only | Receipt error | Python checker run incomplete. |
| A16 | Rank-specific candidate error denominator, `:569-581` | FA rank attempt list | Outside G5 repeatability/boundary scope | Not used for G5 acceptance | Explicitly outside this map; Python checker run incomplete. |
| A17 | Interval formation/coverage counts use `len(attempts)`, `:614-641` | Interval attempt outcomes and truth values | Every target in an interval summary | Summarizes all-attempt denominators; allocation enforcement occurs earlier | Python checker run incomplete; no G5 campaign run. |
| A18 | Failed bootstrap inner attempts are retained, `:682-796` | Ordered inner attempt rows | FA interval only; outside G5 slice | Reject missing/replaced attempt | Outside this G5 slice; no bootstrap campaign run. |
| A19 | Typed JSON projection is performed by `arc1_json`/`arc1_receipt_json`, `engine_io.jl:26-112` | Supported typed values and receipt projection | When transport is requested | Serialization/projection error; no universal native-type allowlist is claimed | Julia typed transport testset `test/arc1_simulation_executor.jl:642-723`; Python round-trip validation incomplete. |
| A20 | Legacy JLS magic dispatch remains available, `inspect_artifacts.jl:17-23` | Legacy JLS header versus new container magic | Existing artifacts only | Dispatch to legacy reader or fail on malformed bytes | Old 130,851,693-byte artifact timed out before semantic checks; diagnostic only, no pass credit. |

## Evidence state and remaining work

### Explicitly excluded prerequisites

The following paths are not covered by this artifact/container map, and this document gives them no pass credit:

| Excluded path | Source range | Required evidence before G5 run |
|---|---|---|
| Inspector subprocess boundary | `tools/arc1_receipt_check.py:24-65` | Verify subprocess/timeout failure, JSON result/list shape, row shape, unique artifact paths, and exact requested-path set. |
| Runtime dependency identity | `tools/arc1_manifest.py:647-665` | Verify dependency record shape and unique UUIDs, Julia version, Julia/BLAS thread counts, environment pins, and BLAS vendor. |
| Admission verifier | `tools/arc1_manifest.py:701-772` | Verify source/environment/manifest pins, canonical allocations/seeds, mandatory v4 policy, and empty bootstrap partition against the admitted source tree. |
| Confirmation authorization and receipt cross-bindings | `tools/arc1_receipt_check.py:843-860` | Verify the authorized confirmation state and exact thread/admission binding before any confirmation attempt. |

These omissions are intentional scope boundaries, not claims that the omitted code or checks pass. G5 remains blocked on retained evidence for each prerequisite.

- Exact final-source Julia command: `JULIA_DEPOT_PATH=/private/tmp/arc1-container-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no -e 'using Test, HSquared; include("test/arc1_simulation_executor.jl")'`.
- Exact Julia log: `/private/tmp/arc1-container-decoder-final-verified.log`, SHA-256 `0d155182d61e1a997b304c870710e61efd5a631a77b859039708746259484c13`, exit zero; 194/194, 10/10, 15/15.
- The initial unmodified Python run was stopped after 23 progress dots and has no pass credit. The isolated cross-language integration fixture then exposed a raw-selector overwrite, which was fixed by retaining `raw_selection`; a focused rerun with only the helper definitions and the current end-to-end fixture passed, with output retained under `/private/tmp/arc1-json-store-checker-7d_d40ly`. The canonical full suite still must be run.
- The 7.677-second large-artifact report lacks a retained, reproducible measurement and is not performance evidence. A versioned final-source Totoro benchmark with elapsed time, RSS, output bytes and the complete inspector-to-Python path is still open.
- This v4 map needs Astra's exact map review. G5 remains open; no campaign, seed, gate transition, threshold or denominator change is made here.
