# E1 exact-current bridge source disposition

Date: 2026-09-30. Review lenses: Hopper, Boole, Emmy. Reviewer owns this scratch report only.

## 1. Verdict and scope

Source coverage is complete. Contract disposition is **HOLD**. Every line of current `src/bridge_payload_v2.jl:1-880` has a disposition below, with no gaps or double counts. The live coefficient parser still discards required metadata. The relevant R multivariate repeatability normalizer has a newly reproduced label-validation gap. The schema has stale correlated-maternal claims and an incorrect precision formula. These findings do not reopen the completed current maternal parity check or authorize a covered-status change.

This review covers the Julia parser, dispatch wrapper, and result serialization, plus the R producer/readers/extractors required to interpret those outputs. It does not review the rest of the R package, establish estimator correctness, or ratify a generic production bridge. No fit, simulation, campaign, GPU work, source edit, test edit, documentation edit, or status promotion was performed.

## 2. Exact candidate and input pins

Julia root: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`. HEAD before and after: `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`.

R root: `/private/tmp/hsquared-fa-gllvm-20260927`. HEAD before and after: `fa98c262eb21694d672e671c9672491ce3369cec`. The current R bridge reader is dirty relative to its committed base. Its reviewed bytes are the active reader below.

| Input | SHA256 |
| --- | --- |
| Julia `src/bridge_payload_v2.jl`, 880 lines | `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0` |
| Julia `docs/design/21-payload-v2-multiblock-schema.md` | `02fe6d274d83b2c62ae972f11d32186c507e083ef19fcb1dd6702b514adb3e80` |
| Julia `docs/design/03-engine-contract.md` | `6566ef7d37709324993ec8b6eabe84277c89bed4d92a840b912fd8a78491de55` |
| Julia `src/multivariate.jl` | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| R `R/julia-bridge.R` | `4cb8074949c8b843727cd4d6acf8ef720113967e5820f135c5170bc3496e24c2` |
| R `R/bridge-payload.R` | `a18645b6445069fef8f9c8202a9e08d59c26a3f84f8923c3b6105a6c19539ef9` |
| R `R/model-spec.R` | `894ad7d2eccee2c1a3eef4416a737916ffb03f39e0e189c6d5e4115fb5a07149` |
| R `R/extractors.R` | `d2a4c73453eb3e7c384ad656c0c046452a20a958a7cb61691b013393257ab163` |
| R `R/fit-object.R` | `a450dcc39b42189e91a264139b83c8af5fac564fccd46bc6e55dcd4ccddb1b0e` |
| R `docs/design/03-engine-contract.md` | `b1a5a59f29e6c3f6defc98027580034f93f6cf8c706b51060f2ae8887b7672f3` |

The Julia source-tree hash is `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`: sorted paths relative to `src/`, each followed by NUL, file bytes, and NUL. It matches the primary-run freeze.

## 3. Method and reused evidence

Read-only lane preflight completed. PLATFORM: codex. ON BRANCH: `codex/hsquared-fa-gllvm-20260927`. LANE: exact-current bridge scratch review. Other lanes include the primary campaign and pedigree-test owners. Their files were untouched.

Graft skeletons and literal-symbol searches preceded source reads. Historical complete coverage is `docs/dev-log/source-review/2026-09-27-wave3.md`, baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214`, bridge lines 1-677. Its HOLD is preserved. The current diff from that baseline was inspected, and new or changed definitions were read at their current spans. Exact unchanged substrings include current 32-40 = baseline 32-40; 47-65 = 47-65; 99-107 = 85-93; 428-434 = 338-344. These were reattested, not rerun.

Current maternal evidence is `docs/dev-log/source-review/2026-09-30-exact-twin-maternal-recheck.md` and `2026-09-30-exact-twin-maternal-live-recheck.md`. The synthetic receipt and subsequent live receipt close the named active-reader pairing gap: 90 assertions passed, zero failures/warnings/skips, 20.18 seconds, six animals and eight records. The earlier R `f5c0d46...` mismatch is superseded by this exact dirty-reader evidence. No maternal, common-dispatch, coercion, or pedigree-order suite was rerun here.

The Wave 3 follow-ups record the 29-assertion pedigree/alias/dispatch regression and 35-assertion structured-result repair. They support the named fixes; they are not new full-current package evidence.

## 4. Disjoint full-file source ledger

Each row includes comments and blank lines within its interval. Line count sums to 880.

| Current span | Count | Disposition |
| --- | ---: | --- |
| 1-70 | 70 | Reattested struct/helper implementations and reviewed header/docstring delta. Contract-only and ratification-pending fences remain. Internal field-name doc drift is listed below. |
| 71-96 | 26 | Current pedigree normalization, permutation, and relationship diagonal inspected. Reuse W3-01 repair and current follow-up evidence; no order rerun. |
| 97-110 | 14 | Exact unchanged field accessor and helper alias reattested. String keys take priority over symbol keys; conflicting dual-key dictionaries are outside the exercised wire representation. |
| 111-210 | 100 | Current relationship resolution, common block guards, correlated partner fields inspected. Coefficient-specific fields remain absent: BP-01. |
| 211-318 | 108 | Current dispatch decisions and parser documentation inspected. Unsupported correlated mixtures are rejected; single iid animal labeling is rejected; standalone multivariate and coefcov fits stay unwired. |
| 319-425 | 107 | Current version/response/X checks, block uniqueness, dimensions, partner collisions, MV repeatability identical-ID/incidence guards inspected. `ParsedPayloadV2` omits original trait names and family; generic reuse requires the existing Gaussian caller precondition. |
| 426-538 | 113 | Unchanged list coercion reattested; current legacy lift inspected, including first-block IDs, relationship diagonal and second-pedigree permutation. Reuse prior negative/positive regressions. |
| 539-577 | 39 | Current public fit wrapper and control-forwarding docstring inspected. Initial/iteration controls only forward to multi-effect/direct-maternal. |
| 578-682 | 105 | Every current fit-dispatch arm inspected. Dense versus auto forwarding is explicit. Sparse inputs can be densified by `Matrix` conversion; no scalable-memory claim follows from this wrapper. MV repeatability uses the direct fitted route with default traits/controls; other MV and coefcov branches raise explicit errors. |
| 683-711 | 29 | Current serializer documentation inspected. Scalar univariate and matrix MV exception remain distinct. Paired maternal effects need a documentation exception to the generic `(name,ids,values)` description. |
| 712-751 | 40 | Current df/nobs/convention/stochastic metadata inspected. Stochastic loglik requires MCSE and sets comparability false. This does not provide parameter uncertainty or calibration evidence. |
| 752-806 | 55 | Animal full-result delegation and ordered scalar two/multi-effect serialization inspected. Animal requires `AnimalModelFit`; partial flat tuples cannot masquerade as complete legacy results. |
| 807-843 | 37 | Current paired maternal serialization reattested against the exact live twin receipt. Shared direct/partner ID order is guarded. Original two-record R-reader mismatch is closed. |
| 844-880 | 37 | Current MV repeatability serialization fully inspected, including covariance/effect matrices, df, nobs, conventions, retained helper fields, and component names. Julia extension is coherent within its documented pedigree/IID/residual ordering; generic R normalization remains fenced. |

## 5. Bilateral producer and result contract

The actual payload/result v2 proposal is Julia schema 21, sections 2 and 5. The R twin has its separate initial flat contract in `docs/design/03-engine-contract.md:6-30,70-108`; it has no same-named schema-21 document. Neither a matching filename nor universal generic-v2 ratification is inferred.

Single-animal serialization delegates to the complete legacy result. R `hs_normalize_julia_result` at 6431 onward consumes fixed effects, animal IDs/values, predictions, df/nobs/loglik and optional PEV/reliability. R reliability and repeatability extractors at 1056-1058 and 696-698 require their corresponding normalized fields. Missing fields are not capabilities.

Current scalar multi-effect R assembly/readers at 2500-2605 and 2735-2825 check expected block names/order, effect lengths and df. Julia two/multi serializers preserve request block order and carry scalar variances. The paired maternal path at R 2000-2103 and 2280-2388 has its separate exact live proof.

Julia MV repeatability result fields at 844-878 and helper `src/multivariate.jl:1358-1401` comprise trait covariance/correlation matrices, h2/repeatability vectors, trait fixed/effect matrices, IDs, traits, parameter counts and experimental status. `nobs` counts observed trait records and df is `p*t + 3*t*(t+1)/2`. Component ordering is pedigree, IID, residual, explicitly documented by schema 21:232-233 even when the request list is reversed. The schema's broad stable-order sentence needs this explicit MV exception.

The generic MV dispatcher does not receive original request trait names or MV initial/iteration controls. The active R dedicated caller at 3161-3296 sends traits/controls directly to `fit_multivariate_repeatability_reml`, then reads named fields. Its normalizer at 3298-3436 does not consume `result_payload_v2`'s matrix-valued variance blocks. Passing the generic result to scalar multi-effect readers is therefore unsupported. The dedicated R path preserves the intended producer labels, but malformed output labels lack reader validation: BP-02.

The R permanent block at `R/bridge-payload.R:134-150` shares the animal incidence yet constructs IDs from observed permanent values. With unobserved pedigree ancestors, the incidence has more columns than those IDs. Julia generic parsing requires equality at 141-142 and identical pedigree/IID IDs at 415-416. The generic emitter therefore has a carried roundtrip limitation; the dedicated R MV caller builds and checks pedigree-aligned inputs separately. Do not claim arbitrary emitted permanent payloads roundtrip through this generic parser.

## 6. Findings and dispositions

### BP-01, P2, carried: live coefcov parser discards its required fields

Current source 149-210 retains only common block fields. Required `basis`, `order`, `Phi`, `covariate`, `bounds`, and `cov_structure` are neither read nor validated. Schema 21:108-113 promises them. This is already reproduced and repaired in `docs/dev-log/prepared-fixes/2026-09-30-coefcov-fields/`.

Corrected patch SHA256: `ea88557d2533bc8bb5e2f0270eb825967e8622d32543188fedf959808403f72f`. Corrected parser: `9d389444008a25ddfb3ba140836bab5a3d2c8ebfb94052424d8d1ac6c0c5a3e9`. Independent revised receipt records 74/74 assertions passed in 2.1 seconds and dry apply-check success. The original sparse-wrapper bypass finding is fixed in those scratch artifacts. The live parser remains unchanged. **Disposition: prepared fix PASS, integration carried, live contract HOLD.** Coefcov fitting remains unwired after that repair.

### BP-02, P2, new: MV repeatability reader does not validate returned trait/ID order

R 3299-3306 takes `raw$traits`, `raw$breeding_ids`, and `raw$pe_ids` as authoritative without comparing them to request names/order. It also ignores separately returned `breeding_traits` and `pe_traits` from the dedicated caller. Lines 3351-3374 assign these global labels to covariance columns and effect values. This permits internally inconsistent output labels to pass into public tables.

No-fit reproduction: parse the exact R bridge file into expressions; evaluate only `hs_normalize_multivariate_repeatability_result`, `hs_matrix_from_julia`, and `hs_long_matrix` in a base environment with `%||%`. Request traits `height,mass`, IDs `a,b`, two traits, one fixed column. Supply covariance diagonals and a 2-by-2 effect matrix with columns `(101,102)` and `(201,202)`. Supply effect trait labels `mass,height` while global traits remain `height,mass`: the normalizer ignores the conflict. Next reverse global traits and breeding IDs, keeping request and values unchanged: the normalizer accepts them and returns reversed labels with the original values. Four assertions confirmed both behaviors in 0.263 seconds, exit zero. Estimate stated before running: under one minute; BLAS threads capped at one; no Julia or fit started.

The probe verifies missing defensive validation. The dedicated producer's ordinary output uses request order. **Disposition: carried for isolated R reader repair.** Require exact request trait and ID order, and agreement with returned effect traits; alternatively perform explicit verified permutations. Add malformed-label regressions while preserving the working dedicated route. Generic MV result parity remains fenced.

### BP-03, P2, new schema drift: active correlated maternal route described as frozen

Schema 21:154-170,360-364,390 still calls `maternal_genetic()` independent and correlated R dispatch nonexistent/frozen. The current dedicated R adapter emits a correlated request at 2000-2068 and reads its paired result at 2090-2103; the exact live 90-assertion receipt supports this cell. Schema 21:354 also says bare `(1|g)` is not parsed, despite the active emitter's arbitrary iid-block loop from R 155 onward. **Disposition: carried wording synchronization, preserve all route/status fences and cite only the specific validated cells.** This review does not validate all formula grammar or make those routes covered.

### BP-04, P2, new schema math error: covariance called precision

Schema 21:136 says precision `kron(G_dm,A)` on stacked direct/maternal effects. The expression gives the covariance when `G_dm` is the 2-by-2 component covariance and `A` the relationship matrix. The corresponding precision is `kron(inv(G_dm),Ainv)` for nonsingular matrices. **Disposition: carried narrow documentation repair.** No fitter change or numerical rerun is indicated by this wording error.

### BP-05, P3, source documentation qualifications

`ParsedPayloadV2` documentation at 27-28 calls the retained partner design `partner_incidence`, but the parsed tuple uses `Zm` at 204-205. Dispatch comments at 217-219 mention identity animal and optional independent correlated blocks although the resolver rejects them. Result documentation at 702 describes all effects as `(name,ids,values)` although paired maternal output uses `direct,partner`. The multi-effect comment at 613-616 says the sparse route reduces exactly to the dense optimum, which needs the finite-optimizer qualification used by the separate VS1 wording work. **Disposition: carried docstring/comment synchronization; functional decisions come from the inspected branches.**

## 7. Existing fixes and honest fences

W3-01 pedigree order, W3-03 legacy second-pedigree order, W3-04 iid animal labeling, and W3-05 structured metadata have inspected current implementations and named earlier receipts. Current maternal pairing is closed at the exact R/Julia pins. The prepared coefficient repair is not applied. General multivariate payload fitting and coefcov fitting raise `Phase0NotImplementedError`; dedicated fitter availability does not wire those generic branches.

Generic payloads are required to satisfy the existing Gaussian caller precondition. `family`, `ntrials`, and original trait metadata are not parsed/retained here, despite schema 21 inheriting top-level v0.1 fields. No family-general or request-label-preserving generic fit claim is supported. Incoming non-Gaussian requests need caller rejection or a future explicit parser guard before generic reuse. No new family probe or fitting was warranted for this bounded contract review.

## 8. Verification

One new synthetic R reader probe ran, with four assertions and no fit. Existing approved maternal/order/coercion tests were reused. The full Julia source-tree pin and all report input pins were checked at close. The span partition was mechanically checked for 880 covered lines, zero gaps, zero overlaps. No current package test, documentation build, or live generic MV bridge fit was performed.

## 9. Risks and remaining work

HOLD is confined to the listed source/parser and bilateral contract findings. Resolve the prepared coefficient integration in an authorized source window; repair defensive MV reader label checks; synchronize schema/source wording. Keep generic matrix-result normalization fenced until an explicit matrix/trait contract and same-input parity evidence exist. The primary source freeze stays in force.

## 10. Changed files and coordination

Only `/private/tmp/e1-bridge-payload-complete-current-review-20260930.md` was written by this lane. No live source, test, docs, lease-owned file, capability label, validation row, or `public_covered_count` changed. This scratch report is handed to the parent coordinator; no commit, push, release, or external message was made.

## 11. Retrieval and prose checks

Graft savings tally for this bridge task: 182,204 estimated tokens saved (Julia skeleton 10,064; R payload skeleton 3,601; Julia helper grep 36,704; R normalizer grep 60,776; R dedicated-caller grep 71,059). One R helper grep returned no hits. These are tool estimates, not measured total usage.

Completion verification passed: ten input pins, both HEAD pins, the frozen source-tree hash, 880 lines with zero partition gaps/overlaps, and zero em dashes. The absolute-path slop checker returned zero findings. No coverage status is promoted by this receipt.
