# E1 exact-current coverage reconciliation, 2026-09-30

Verdict: **blocked for E1 closure**. Component approvals remain usable within their pins and scopes. This report reconciles source-review coverage; it is not new engine, inference, recovery, bridge, release, or capability approval. GPU execution is excluded from completion criteria; the GPU source remains static-only.

## Candidate and method

Initial measurement: candidate `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, branch `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` with dirty source/tests/docs. Measured UTC `2026-09-30T15:07:21.371884+00:00`. All 24 tracked `src/*.jl` were enumerated with `git ls-files`, hashed, and compared with every September source-review/check-log.d/after-task Markdown receipt. Exact pins are necessary, but a hash appearing in an inventory, test log or after-task report does not establish full-file review.

Graft map/skeleton were consulted before source inspection. Its cache refresh failed with EPERM and skeleton line maps were stale, so current function anchors were measured directly. No source, tests, GATES, claim/status rows were edited, and no Julia/R/GPU runtime was launched. The only deliverables are this scratch report and a scratch hash inventory. Source lines quoted by old receipts are historical coordinates unless a current function anchor is explicitly given.

Update 2026-09-30: the same parent made source-neutral scoped local commits `27fcf3ef` and `9c10f09c`; the current HEAD is `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`. The frozen source tree remains `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. Graft metadata was subsequently refreshed successfully, with `graft check` exit 0; receipt `docs/dev-log/recovery-checkpoints/2026-09-30-current-graft-refresh.md`. The original failed refresh remains historical process evidence.

## Complete current inventory

| File | Lines | SHA-256 |
|---|---:|---|
| `src/HSquared.jl` | 258 | `5c6c4c84e372e9adb75dd43d326e7603243286313c788cd3c98a599d1468eaf0` |
| `src/backends.jl` | 167 | `b22f118ea8aeba5dceb80918ee40a3f7d698211c69e91ee6c7e6c5b718b10cf9` |
| `src/bridge_payload_v2.jl` | 880 | `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0` |
| `src/control.jl` | 107 | `c466b4cf9e33fcafe8b4821791af54cc559a2dab78755fa759f387f6601e6b3f` |
| `src/data.jl` | 1251 | `39efaac183375e0f735836e5c3d398a1b8f59fffb5b7e7f3b616678b01d727b8` |
| `src/errors.jl` | 22 | `6ebb3635c308097213b1581fae26e94089969f34a07cbf5b735a5ee945d44fba` |
| `src/evolvability.jl` | 314 | `fd49987ee69c1f9b6e3335bdb6e4f8c73b6f0cdab3da4b7263cf4e87b6577ff3` |
| `src/genetic_gllvm.jl` | 682 | `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca` |
| `src/genomic.jl` | 2934 | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` |
| `src/gpu_ext.jl` | 90 | `b5bfbe73e12363cb7c9d518841006554c220d93038294a1826faefc1a1b2767f` |
| `src/iterative_solve.jl` | 1408 | `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132` |
| `src/likelihood.jl` | 4613 | `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30` |
| `src/model_spec.jl` | 104 | `d49de74e3990e18e73db37bab9b3019f46dcaa29c4f7102fc3f53fe60fa9f5fb` |
| `src/multivariate.jl` | 1868 | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| `src/nongaussian.jl` | 1803 | `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00` |
| `src/pedigree.jl` | 889 | `522741349ecfca48afc29d06f04bf4f6a0206fbc84648606e1ebf9f5444267d4` |
| `src/placeholders.jl` | 26 | `e95f47efb13018fa8fc2fb7cbf6b08d4c4a1add8ca3b9c95b43ead259bf9955b` |
| `src/planned_terms.jl` | 359 | `a47d953d72565f347db805b5d0c7bdc86d5440dedaa6454c674f6e48c9607d5c` |
| `src/plotting_ext.jl` | 61 | `e38c4d436d59bce93315eebc0296e6227fdd71990b25f2b4f608f302c458a569` |
| `src/postfit.jl` | 58 | `d065d525ccdca8c8d881432f3c312141929571d52629f38bf72cfc513bdbf71f` |
| `src/random_regression.jl` | 533 | `761151eb0297bece4c859db8a504a244a26510d320f123f85a9a9295621e7a5c` |
| `src/sparse_bridge.jl` | 87 | `f8a681b7491a002577747775fef26f486d53ab2b4b8def6f6071e7a5eb4c2427` |
| `src/takahashi_selinv.jl` | 453 | `38a07e2e34da2f4a295e52e25b1f1d067a0b7e1b2893bdef8c73f1f78c704782` |
| `src/validation_status.jl` | 610 | `95f90c3a166f7ead65afc4205d5139155f86c002c697045388a1b2d383d14010` |

## Per-file reviewed scope and actionable remainder

Receipts below live under `docs/dev-log/source-review/` unless another directory is named. **Historical complete read** means the reviewer read the whole then-current file; it is not whole-file approval of changed current bytes. **Uncovered** means no explicit current span disposition was found. Earlier inspections are retained as history. Reattestation means a reviewer states the old approved component is unchanged or reviews its precise delta and records current pins; preserve old findings as fixed, carried, or fenced.

### `src/HSquared.jl`

Reviewed: Full historical file review, baseline unchanged, 1–258 (Wave 3); 09-29 inventory current pin.

Next scope: No new source span. Reaffirm export/include scope in final Wave 3 panel receipt.

### `src/backends.jl`

Reviewed: Full baseline metadata source review 1–167 (Wave 4), unchanged; 09-30 exact component 1–21,69–167.

Next scope: No uncovered source body inferred solely from component receipt: baseline full read remains applicable. Carry custom subtype acceptance/MethodError and Auto observability policy; panel ratification only. No threaded/GPU execution claim.

### `src/bridge_payload_v2.jl`

Reviewed: Complete exact-current1–880 source disposition is retained in `docs/dev-log/source-review/2026-09-30-bridge-payload-complete-current-review.md` at `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0`. The earlier complete baseline read and approved current maternal/ID components are reused, with explicit current parser, dispatcher and serialization coverage. Active Rdirty reader atfa98c262 matches the paired maternal producer; bounded90-assertion live transport/parity evidence remains valid and was not rerun. Coverage PASS; bilateral contract HOLD.

Next scope: No unread Julia bridge source span remains. Integrate the independently74-pass coefcov field proposal after the freeze; repair BP02 dedicated R MVrepeatability label validation and BP03–04 schema drift. Current MVreader accepts inconsistent/reversed traits or animal IDs without permuting values; strict ordered request/result and effect-label agreement is required. Schema must reflect the active dedicated correlated maternal route, distinguish covariance `kron(G_dm,A)` from precision `kron(inv(G_dm),Ainv)`, and qualify MVpedigree/IID/residual ordering. Generic matrix-valued MVv2 output remains fenced from scalar Rreaders; dedicated Rmatrix/trait normalization is separate. Preserve current maternal correction during landing. Wider calibration and generic family transport remain explicit debts.

### `src/control.jl`

Reviewed: Complete unchanged 1–107 Wave 3; 09-30 dependency 14–63,75–89 had after-read-only pin.

Next scope: No missing source span beyond final panel attestation; do not use after-read pin to strengthen 09-30 review reproducibility. Metadata-only controls remain planned execution.

### `src/data.jl`

Reviewed: Complete current 1–1251 disposition is retained in `docs/dev-log/source-review/2026-09-30-data-complete-current-review.md` at `39efaac183375e0f735836e5c3d398a1b8f59fffb5b7e7f3b616678b01d727b8`. Its disjoint partition has zero gaps and zero overlaps, with 893 fresh residual lines and 358 baseline or exact-component reattestations. The current row-count repair remains accepted; its known malformed inferred-ID ingress limits are explicit.

Next scope: No unread data source span remains. D1 P2 dictionary missing-cell count can omit a physical string-key marker column when a Symbol key has the same label. Its two-line isolated repair has 29/29 independent assertions in `docs/dev-log/prepared-fixes/2026-09-30-data-dict-missing-count/`, with seven red failures on the frozen implementation. Live source remains frozen and D1 is held pending integration and new pins. Preserve duplicate-name diagnostics, configured ID exclusion and original container values. Carry constructor-only ID hygiene, delayed rectangular-table checks, ID-first positional pedigree fallback, and mutable metadata limits; clarify the existing positional reader convention in docs. Do not infer blanket malformed-table or fitted-input validation from this metadata source review.

### `src/errors.jl`

Reviewed: Exact-current complete 1–22 scoped PASS in errors/planned-terms receipt.

Next scope: No source coverage gap; carry low-severity operation-string showerror assertion gap and register final panel disposition.

### `src/evolvability.jl`

Reviewed: Baseline full 1–267 read; exact fd499… guard/stability follow-up with Gauss/Noether. Metric definitions 91–235 and PSD/PD boundaries 31–79,101–149 inspected historically.

Next scope: Map changed guards and appended 268–314 against final review; obtain explicit span/panel attestation for unchanged metric/plot helpers. Carry trait-coordinate/unit limitations, condition ceiling, extreme-scale and inverse-metric uncertainty. Do not rerun approved stability guard merely because whole E1 remains open.

### `src/genetic_gllvm.jl`

Reviewed: Full current 1–682 source coverage is accounted for by `/private/tmp/e1-gllvm-residual-contract-review-20260930.md`: 310 lines reuse the exact approved objective/trait-effect spans and 372 newly inspected residual lines complete the file with no gap or overlap. Source SHA remains `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca`. Full-file approval remains HOLD for C1–C5; prior component approvals remain valid in their bounded scopes.

Next scope: No additional source read is required to close a coverage gap in this file. Dispose the reviewed findings: C1 P1 invalid mode tolerance/negative budget; C2 P1 incomplete proper-integral endpoints/general separation; C3 P2 accepted BinomialVectorResponse lacks per-record dispatch; C4 P2 malformed family/numeric/initial input classification; C5 P2 synthetic descriptor uniqueness/rank metadata validity. The isolated C1/basic-C4 patch in `/private/tmp/hsq-gllvm-input-fix-20260930/receipt.md` has 50/50 focused scratch assertions and red controls, with an independent 50/50 pass now retained in `docs/dev-log/prepared-fixes/2026-09-30-gllvm-input-guards/independent-review.md`; it is not in the live candidate. Patched file SHA `44e871db58417273e04d4e76b00db6d81edb28e6fddef21505e9248af0fd0a15` must not replace the frozen `0727459…` pin or mark live C1/C4 fixed. C2/C3/C5 remain carried in that input-only patch. A separate C3 explicit varying-trial rejection/C5 metadata proposal now has independent50/50 checks in `docs/dev-log/prepared-fixes/2026-09-30-gllvm-descriptor-record/`; independent frozen controls on the final test show23 passes/27 failures, including four later fitter-entry checks. Merge must preserve both input and descriptor guard sets; arbitrary synthetic decomposition certification remains carried. The shared NB/beta-binomial endpoint omission has a separate prepared independent 36/36 repair in `docs/dev-log/prepared-fixes/2026-09-30-flat-integral-endpoints/`; general separation and outer failure handling remain open. Preserve R bounded-route parity and keep generic family/design approval withheld until findings are repaired or explicitly fenced.

### `src/genomic.jl`

Reviewed: Complete current 1–2934 disposition is retained in `docs/dev-log/source-review/2026-09-30-genomic-complete-current-review.md` at `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f`. Sixteen disjoint spans account for every line, with 558 reused and 2376 fresh inspection or current reattestation lines, zero gaps and overlaps. The earlier construction receipt's mid-LOCO stop is closed by the new complete review. Coverage PASS; whole-file approval HOLD.

Next scope: Dispose G1–G6 without rereading all 2934 lines: integrate the independently accepted 41-assertion marker variance/convergence proposal; reject missing LOCO and summary labels before string conversion; stabilize representable variance and median calculations; define probability conversion semantics; fence general-covariate permutation exactness; qualify sample-centering and single-step reductions. Dense resource, allocation and calibration debts remain explicit. No broad performance or inference claim follows from static coverage.

### `src/gpu_ext.jl`

Reviewed: Full 1–90 static interface read in Wave 4 plus wording-only14–18 repair; unchanged from 09-29 inventory pin.

Next scope: No GPU runtime work is required for E1. Final static interface attestation can cover all 1–90; extension device behavior, numerical agreement and speed remain UNVERIFIED outside completion criteria.

### `src/iterative_solve.jl`

Reviewed: Current a4ad… receipt is scoped wording PASS plus confirmation of selected prior fixes, not whole-file numerical signoff. Historical Wave 1 read all bodies1–1151; subsequent scoped PCG/precision/rank fixes use older pins.

Next scope: First delta/pin reattestation of _require_full_fixed_effect_rank56, diagonal122, precision303–340, MC fit725, likelihood956–1093 and wrapper1267–1363. Then residual numerical review1–55,69–121,184–302,378–561,562–724,871–955,1094–1266,1364–1408 after subtracting signed historical spans by symbol. Carry finite extreme-input/PCG breakdown, allocation/fill, shared-probe uncertainty and near-collinear rank limits. Fresh boundary_tol repair receipt predates final doc pin; attest unchanged helper calls, do not infer whole-file PASS.

### `src/likelihood.jl`

Reviewed: No current full source-review receipt at90cc…. Current boundary_tol after-task audit names exact hash for one guard only. 09-30 sparse REML component174–269,341–412 pins19974…, help correction pinsddc937…, optimizer/boundary and AI/workspace scopes have older hashes.

Next scope: Prioritize delta attestations rather than repeat passed algebra: sparse174–269,341–412; optimizer covariance/AI stationarity, workspace/cache, selected-inverse caller, bootstrap and genomic boundary amendment. Fresh current review slices: constructors/dense objective1–173; fit wrappers270–445; AI/boundary446–1173; supplied MME1174–1436; two/multi-effect objectives/uncertainty1437–2398; sparse workspace/AI2399–2999; direct-maternal/repeatability3000–3445; dispatch/extractors/PEV3446–3810; information/profile intervals3811–4069; plots/payload/coercion4070–4257; MME/PEV/selinv helpers4258–4516; bootstrap4517–4613. Within each subtract explicitly attested historical symbols before reading. Resolve sparse final finite-status/rank/boundary debt and scan-to-fit input validation; no whole-file clearance from boundary_tol or Pkg.test.

### `src/model_spec.jl`

Reviewed: Complete unchanged1–104 Wave3; exact09-30 structural helper38–92. Adjacent likelihood validation had no likelihood hash pin.

Next scope: No missing model-spec source body; carry structural helper ID uniqueness/order, array-by-reference ownership, constructor bypass and route-specific numeric-validity decisions. Document or explicitly fence these before final contract signoff; separate MME fitted-input review.

### `src/multivariate.jl`

Reviewed: Baseline full1–1652 HOLD; exact fc41… covariance/optimizer plus T4K1 FA component PASS, information/identifiability tests. No current full-file/panel PASS.

Next scope: Explicitly attest bounded FA constructor362–472, objective/admissibility726–873 and fitter972–1166 from component reviewers, preserving expected-information and absolute-floor limits. Residual scopes: correlation/extractors/payload20–286; guard/construction287–361; supplied MME473–627; transforms/starts628–725; missing-record/gls762–872 if outside FA receipt; MV-repeatability1167–1414; gamma/chisq/nested-LRT1415–1529; Hessian/Jacobian/covariance uncertainty1530–1734; parameter-count/structured LRT1735–1868. Reconcile E4-02 exact genetic-correlation guard and W2 LRT/uncertainty findings; fix/carry seeded-RNG docstring939–940. FA component PASS is not whole-engine/A2.

### `src/nongaussian.jl`

Reviewed: Complete exact-current 1–1803 source disposition is retained in `docs/dev-log/source-review/2026-09-30-nongaussian-complete-current-review.md` at `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`. Baseline faed401 source matches its historical full-read pin; 1533 current lines are byte-identical mapped baseline lines and 270 current delta lines are accounted for. The last historical47 lines map unchanged to1757–1803. The signed mathematical components are reused without repeating their derivations. Coverage PASS; full-file approval HOLD.

Next scope: No source-read gap remains. Findings require explicit repair or scoped contract disposition: VA objective-kind/lower-bound metadata loss, generic payload boundary/restart omissions, necessary proper-integral endpoints/general separation, finite converted input/family constructors including singleton ordinal cutpoints, outer failure/restart handling, finite-quadrature VA covariance stationarity, and inherited heritability predictor/trial-count/invalid-input contracts. Shared enumerated endpoint repair has independent36/36 checks in `docs/dev-log/prepared-fixes/2026-09-30-flat-integral-endpoints/`; it remains unapplied and leaves general separation open. The approved objective derivation and separate docstring proposal qualify fixed-effect flat integration. Preserve exact profile/rank/precision repairs and historical approvals at their stated scope. These no-fit source/probe checks supply no broad family recovery or calibration approval.

### `src/pedigree.jl`

Reviewed: Exact5227… final receipt explicitly re-reviewed175–183,337–367,868–878 and known-parent regression. Core09-30 faccb… receipt is older and mentions anchors, not complete spans. Wrapper receipt alsofaccb…. Wave3 originally1–100,288–345.

Next scope: Attest unchanged normalization/inverse/wrappers from faccb… to5227…; current span ownership: direct construction1–72; normalize73–136; denseA/MS137–208; heap/inbreeding209–328; inverse329–376; maternal/cytoplasm377–451; clones452–501; dominance/epistasis502–577; group/Gamma recursion578–685; wrappers/precision686–837; parent/toposort838–867; MS/markers868–889. Subtract exact337–367,868–878 and approved historical functions; remaining inheritance/relationship primitives need explicit review. Carry terminal-ramet parent defect and group-label order; deep12,000-chain test is recorded in Wave3 so do not re-request it as absent.

### `src/placeholders.jl`

Reviewed: Emmy complete current 1–26 review is clean at e95f… in `/private/tmp/e1-placeholder-exact-review-20260930.md`, with source hashes unchanged before/after. Supporting helper/export/dispatch/help spans are listed in that receipt. The help mismatch is closed.

Next scope: No remaining placeholder source gap or source defect. Focused help/binding and unsupported-fallback checks passed on current pins; concrete method enumeration was inspected at runtime. These checks provide no estimator, fitted-result, full fitter-suite, R-bridge or campaign approval.

### `src/planned_terms.jl`

Reviewed: Exact complete1–359 scoped PASS in errors/planned-terms.

Next scope: No source coverage gap. Carry exact-typed-row table mismatch and all-row wording test debt; final whole-wave panel only.

### `src/plotting_ext.jl`

Reviewed: Complete unchanged1–61 Wave4 stub/doc scope; current inventory pin.

Next scope: No src body gap. Makie extension implementation not in this trackedsrc inventory; exclude drawing-runtime approval or explicitly open a separate extension audit.

### `src/postfit.jl`

Reviewed: Complete unchanged1–58 Wave4 delegate scope; exact09-30 source component30–37,43–58 with new contract findings.

Next scope: No unread src body claimed. The isolated convergence/zero-additive contract repair and visible positional-order requirement have bounded independent approval in `docs/dev-log/prepared-fixes/2026-09-30-postfit-marker-contract/`. The first proposal failed original-Real negative-underflow controls; its corrected raw-sign guard passes37 prior controls plus four independent underflow checks. Preserve initial HOLD evidence. Apply after the source freeze, register tests and reattest new source pins. Dense experimental scan calibration remains separate debt.

### `src/random_regression.jl`

Reviewed: Full exact-current source coverage 1–533 is accounted for in `docs/dev-log/source-review/2026-09-30-random-regression-exact-review.md` at `761151eb0297bece4c859db8a504a244a26510d320f123f85a9a9295621e7a5c`. It reuses the approved optimizer proposal guards and reviews the remaining descriptor, supplied design/MME, GLS and fitter bodies. Full approval remains HOLD pending findings disposition.

Next scope: No source-read gap remains in this file. The descriptor bounds/affine overflow and variance/eigenshare overflow findings have a prepared isolated repair in `docs/dev-log/prepared-fixes/2026-09-30-rr-descriptors/`, independently passing 41 regressions plus six conversion/affine oracle controls. These are scratch checks, and live source remains unchanged. Apply after the source freeze and record new pins. Carry fixed-effect rank, conditioning, basis provenance, dense supplied-MME, covered k2-cell/broader-order and inference limits explicitly; require final panel disposition. The fitter and objective were untouched by this proposal.

### `src/sparse_bridge.jl`

Reviewed: Complete1–87 Wave1 CSC marshalling source review; unchanged baseline pin.

Next scope: No unread source span. Require inventory-mandated panel acceptance, while cross-language real bridge use remains separate integration evidence.

### `src/takahashi_selinv.jl`

Reviewed: Baseline full1–399; later Gauss/Karpinski explicit component94–205,256–365,387–422 at2c435…. Exact current38a07… finite-range guard PASS both recursion return paths.

Next scope: Use delta attestation of previous full kernel and failed-pivot guard, then final exact source/trace wrapper tail423–453 and support errors323–453 to dispose support-error timing/finite trace product-accumulation overflow. Preserve severe-conditioning/high-fill/type-stability limitations; finite-result guard alone is not full current kernel review.

### `src/validation_status.jl`

Reviewed: Full exact-current static source coverage 1–610 is accounted for in `docs/dev-log/source-review/2026-09-30-validation-status-exact-review.md` at `95f90c3a166f7ead65afc4205d5139155f86c002c697045388a1b2d383d14010`. All 56 rows, normalization and returned metadata helpers have a span disposition. Current wording approval remains HOLD until the approved proposal reaches all required reader surfaces.

Next scope: No source-read gap remains in this file. The combined 22-string correction and removal of obsolete Ordinal/Gamma mapper branches has independent wording approval in `docs/dev-log/source-review/2026-09-30-validation-status-independent-wording-review.md`. Astra's objective derivation is retained in `docs/dev-log/source-review/2026-09-30-legacy-objective-labels-astra-review.md`. All IDs, capability names, phases and status labels remain unchanged; public count stays 7. The proposed patch is retained in `docs/dev-log/prepared-fixes/2026-09-30-validation-status/` and is unapplied during the source freeze. The full capability/debt, numerical docstring and dated interpretation-note proposal also has independent wording approval in `docs/dev-log/prepared-fixes/2026-09-30-validation-ledger-sync/`. Synchronize the generated page after source/document integration. Historical covered labels and numerical comparisons remain visible; same-objective comparator parity and calibration remain unestablished. Historical S5 ran and passed on 2026-09-01; that result is not current candidate recovery.

### A. Missing read-only coverage or exact-current attestation

- Bridge. finish exact-current parser/result scope ledger across `bridge_payload_v2.jl:1–880`; incorporate the completed active-twin maternal receipt, preserve its prepared R reader correction, and concentrate remaining review on coefcov/MV-repeatability and carry already reviewed ID/parser guards by delta attestation. Obtain Hopper/Boole/Emmy bilateral producer/schema/extractor signoff.
- Large numerical files. Gauss/Karpinski/Noether attest previously approved solver/kernel components on current bytes, then inspect residual likelihood slices and non-Gaussian source families/payload/outer-fit paths listed above. Source gaps are a concrete E1 blocker; missing broad performance measurements are a separate debt.
- Pedigree/genomic. Henderson reattests old core/wrapper spans and reviews residual inheritance primitives; the numerical reviewer covers genomic fitter, public scan, marker summaries and threshold/permutation blocks. Data full coverage is complete, with the independent D1 proposal held for post-freeze integration. Preserve the current row-count and known-parent repair approvals. Extend or clarify construction receipt spans through the full LOCO closing `end`.
- Multivariate/evolvability. Start with bounded exact component scope declarations and symbol deltas; inspect remaining supplied-MME/extractor/uncertainty/repeatability sections. RR full 533-line coverage is complete, with an independently checked descriptor proposal and carried findings; it needs integration and panel disposition. GLLVM current source coverage is complete; require disposition of C1–C5 and independent review of the isolated patch, without repeating the source read or approved objective derivation.
- Support/status. The current complete status source read and independent-approved combined wording proposal are retained. Rose audits their later synchronized integration and generated reader surface; final wave panels reaffirm unchanged complete source reads (`HSquared`, controls, backends, errors, planned_terms, plotting stub, sparse_bridge) and accept current repaired kernel scopes.
- Placeholders complete. Emmy/Sol6.1 High reviewed current 1–26 at e95f… and found the documented placeholder/fallback contract clean. Receipt `/private/tmp/e1-placeholder-exact-review-20260930.md` includes current help/fallback checks and method enumeration; no numerical fitter testset was run. Incorporate this receipt; do not repeat that source review.

### B. Known behavioral defects requiring fix, rejection fence, or explicit scoped disposition

1. Promised-but-unvalidated `coefcov` fields (**P2**). The historical direct-maternal shape mismatch is fixed in the current dirty R candidate, with exact paired-reader, synthetic extractor and 90-pass bounded live transport/fitted-parity evidence; preserve the prepared correction when integrating.
2. Non-Gaussian omitted proper-integral endpoints/general separation (**P1**), inconsistent outer failure handling (**P2**), and older fit/payload objective-kind/boundary/finite-input findings without an explicit current disposition. Logistic finite-quadrature covariance stationarity needs its targeted derivative check before approving that update contract. GLLVM C1–C5 now have a complete current source-read receipt and require explicit repair/fence dispositions. C1/basic-C4 isolated scratch patch independently passes 50/50 and does not change the live frozen candidate; C2/C3/C5 are unchanged.
3. Mixed scan convenience wrapper hides failed-fit provenance, assumes positional marker-row order, and rejects the valid zero-additive boundary. Decide and document the API contract with targeted fixtures; existing interior algebra PASS does not cover these cases.
4. Sparse REML final finite-objective/failure/rank handling needs bounded resolution under its stated supported domain, while stronger boundary-optimum claims remain separately fenced.
5. Clonal ramet-as-parent construction is known wrong and currently documented as requiring terminal ramets. E1 may accept an explicit experimental terminal-only fence; a breeding-through-ramets capability requires a new recursion and fixtures. No fitted clonal capability may be inferred.
6. Structural model-spec IDs/order/array ownership, direct-constructor bypass, metafounder group labels, custom backend extension behavior, and exposed malformed-input routes need explicit contract dispositions. A reviewer may accept a documented caller responsibility where appropriate; silent ambiguity cannot be signed off as general validation.

The NamedTuple column-length defect is **fixed in the latest exact-current receipt** and is not an unresolved blocker. Current stub help mismatch is repaired and independently confirmed by the clean complete-file placeholder review.

### C. Evidence debts that do not require broad campaigns for this source audit

Conditioning/large-fill resource behavior, warmed allocation/type stability, production scaling, near-collinear rank sensitivity, inverse-metric extreme scales, external fitted-output comparators, genome-wide/interval calibration, broad maternal model/pedigree calibration, FA ordinary-start recovery/identifiability, and GLLVM independent acceptance remain debts under their limited public claims. They block a stronger capability/performance/inference claim, **not automatically E1 source-review completion**, when final reviewers explicitly accept the tested scope and fence the debt. The bounded deep-pedigree stress check and tiny algebra/repair tests already have receipts; do not rerun them without a concrete source change or remaining risk. GPU runtime/device agreement/performance stays outside E1 completion criteria.

## Economical completion sequence

1. Freeze a content snapshot/hash manifest for review. Ask prior component reviewers for current-pin delta/unchanged-symbol attestations; do not send whole large files back just because E1 is open. Each receipt must supply explicit inclusive spans, source/test/schema pins, finding disposition and review lens.
2. Integrate the completed active-twin maternal receipt and retain the R reader correction, then finish remaining bridge contract defects and source↔R/schema mapping: coefcov, multivariate-repeatability, generic non-Gaussian result objective labels and failure boundaries. Reconcile owner lanes before edits. Dedicated FA/GLLVM bridge parity is not generic-v2 parity.
3. Finish engine residuals in bounded numerical slices from the per-file list: likelihood objectives/MME and inference; non-Gaussian proper integral/outer-failure/VA stationarity; pedigree nonstandard primitives; genomic scan/summary/threshold code; data diagnostics. Subtract reattested historical components from each brief.
4. Finish status/evidence and tests registration audit on the frozen final bytes. GLLVM already has a complete current source ledger with a HOLD disposition; resolve its C1–C5 findings without rereading its 682 lines. Independent wave panels must expressly accept each file-scope ledger and carry or fence limits. Only then can E1 close. Keep A2/V3 acceptance separate.
5. Include the entire GPU source as static interface review, with runtime/device performance UNVERIFIED. Neither request nor run a GPU test as an E1 prerequisite.

## Receipt corpus and exact-pin occurrences

The following appendix records every matching hash occurrence in source-review/check-log.d/after-task receipts. Each occurrence identifies a source pin. Approval requires the associated scope and verdict. The complete corpus was scanned for exact pins; scope history was reconciled from the wave packets, current inventory, relevant follow-ups, and all 09-30 source-review packets. Older mismatched pins remain historical.

- `src/HSquared.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- `src/backends.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-30-backend-control-contract-review.md`
- `src/bridge_payload_v2.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-30-payload-v2-direct-maternal-and-coefcov-review.md`; `docs/dev-log/source-review/2026-09-29-coefcov-error-wording.md`; `docs/dev-log/check-log.d/2026-09-29-coefcov-error-wording.md`; `/private/tmp/e1-exact-twin-maternal-recheck-20260930.md` (Julia807–843; active R reader2090–2103 and normalizer2280–2388, paired-shape contract fixed in dirty work). `docs/dev-log/source-review/2026-09-30-exact-twin-maternal-live-recheck.md` (90-pass bounded live transport/fitted parity).
- `src/control.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-30-backend-control-contract-review.md`
- `src/data.jl`: `docs/dev-log/source-review/2026-09-29-dictionary-row-count-contract.md`
- `src/errors.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-29-errors-planned-terms.md`; `docs/dev-log/check-log.d/2026-09-29-errors-planned-terms.md`
- `src/evolvability.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-29-evolvability-current-review.md`; `docs/dev-log/check-log.d/2026-09-29-evolvability-stability.md`
- `src/genetic_gllvm.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-29-gllvm-current-exact-candidate.md`; `docs/dev-log/source-review/2026-09-29-gllvm-trait-effects.md`; `docs/dev-log/check-log.d/2026-09-29-gllvm-trait-effects.md`; `/private/tmp/e1-gllvm-residual-contract-review-20260930.md` (full current1–682 coverage, approval HOLD C1–C5).
- `src/genomic.jl`: `docs/dev-log/source-review/2026-09-30-genomic-matrix-construction-review.md`; `docs/dev-log/source-review/2026-09-30-postfit-marker-scan-review.md`; `docs/dev-log/source-review/2026-09-30-metafounder-wrapper-alignment.md`
- `src/gpu_ext.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- `src/iterative_solve.jl`: `docs/dev-log/source-review/2026-09-30-iterative-solver-doc-followup.md`; `docs/dev-log/check-log.d/2026-09-30-iterative-solver-doc-followup.md`; `docs/dev-log/after-task/2026-09-30-iterative-solver-doc-followup.md`
- `src/likelihood.jl`: `docs/dev-log/after-task/2026-09-30-boundary-tol-validation.md`
- `src/model_spec.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-30-postfit-marker-scan-review.md`; `docs/dev-log/source-review/2026-09-30-model-specification-contract-review.md`
- `src/multivariate.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-29-fa-likelihood-information-design.md`; `docs/dev-log/source-review/2026-09-29-fa-exact-current-review.md`; `docs/dev-log/source-review/2026-09-30-fa-exact-current-component-review.md`; `docs/dev-log/source-review/2026-09-29-optimizer-covariance-boundaries.md`; `docs/dev-log/check-log.d/2026-09-29-fa-exact-current-review.md`; `docs/dev-log/after-task/2026-09-29-fa-exact-current-review.md`; `docs/dev-log/after-task/2026-09-29-optimizer-covariance-boundaries.md`
- `src/nongaussian.jl`: `docs/dev-log/source-review/2026-09-30-nongaussian-current-review.md`; `docs/dev-log/check-log.d/2026-09-30-nongaussian-current-review.md`; `docs/dev-log/check-log.d/2026-09-30-va-schur-recheck.md`; `docs/dev-log/after-task/2026-09-30-va-schur-recheck.md`
- `src/pedigree.jl`: `docs/dev-log/source-review/2026-09-30-pedigree-review.md`
- `src/placeholders.jl`: `docs/dev-log/source-review/2026-09-30-fit-animal-model-help-correction.md`; `/private/tmp/e1-placeholder-exact-review-20260930.md` (complete 1–26, current exact pin).
- `src/planned_terms.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-29-errors-planned-terms.md`; `docs/dev-log/check-log.d/2026-09-29-errors-planned-terms.md`; `docs/dev-log/after-task/2026-09-29-julia-formula-status-contract.md`
- `src/plotting_ext.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- `src/postfit.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-30-postfit-marker-scan-review.md`
- `src/random_regression.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-29-optimizer-covariance-boundaries.md`; `docs/dev-log/after-task/2026-09-29-optimizer-covariance-boundaries.md`
- `src/sparse_bridge.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`
- `src/takahashi_selinv.jl`: `docs/dev-log/source-review/2026-09-29-exact-current-coverage-audit.md`; `docs/dev-log/source-review/2026-09-29-selinv-finite-range.md`
- `src/validation_status.jl`: `docs/dev-log/source-review/2026-09-30-metafounder-wrapper-alignment.md`

## Closeout

Read-only scratch draft, pending parent integration and final frozen-candidate panel decision. Existing dirty work was preserved. The parent freeze matches the live approved FA source pin, and no source hash moved during the reconciliation check. Recheck the manifest immediately before integration to preserve that observation. No repo-visible approval, capability promotion, covered-count change, commit, push, external contact, or GPU completion claim is made.

## Support attestation and completed primary, 2026-09-30

`2026-09-30-support-source-reattestation.md` and its JSON independently verify ten support-file pins against historical signed baseline components. Seven full files are byte-identical. GPU source remains static-only, with no device execution or completion claim. Postfit requires integration of its reviewed marker guard; support coverage alone is not full panel signoff.

The primary FA campaign is complete, with all 200 rows preserved in `docs/dev-log/recovery-checkpoints/fa-primary-complete-20260930/`. It reports 110 recovered, 20 G errors, 11 R errors and 59 nonconverged. Source tree d3c2de... and driver216144... remain frozen evidence pins. New prepared finite-ingress and R-label repairs have independent 141/141 and 67/67 checks. Their isolated artifacts are not live-source approval. Source freeze ended after the final artifacts and exit witness were preserved; composed repair checks are separate.
