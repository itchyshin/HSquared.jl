# Exact-current validation-status source and claim review

Date: 2026-09-30. Reviewer: Rose. Disposition: **BLOCKED for claim approval; static source review complete at the pin below.** E1 remains open. No source, tests, capability status, covered count, or campaign was changed.

## 1. Result

This review accounts for all 610 lines of `src/validation_status.jl`, including all 56 raw evidence records, three normalization branches, typed row/container definitions, collection methods, and the returned diagnostic table. Full source coverage does not approve every claim or the numerical engines referenced by those records. Current wording needs corrections before a clean claim disposition.

The exact metafounder component receipt supplies 9 reviewed lines, 101-109. This pass supplies the remaining 601 lines, 1-100 and 110-610, as a static record/claim review. Historical scopes were used to focus the review and retain valid narrow conclusions. No historical component PASS was treated as full-file approval.

## 2. Scope and boundaries

Compare current source with `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`, the generated validation page, the matrix-free documentation follow-up, and the relevant dated comparator/recovery receipts. Review the distinction among construction, supplied-variance solves, fitted point estimates, transport, uncertainty, calibration, and public claims.

The review covers source and evidence records. It does not independently replay every historical fit or validate all referenced numerical kernels. GPU runtime is excluded from E1 completion criteria; GPU findings here remain static/historical only. No fit, simulation, benchmark, GPU execution, remote operation, external contact, or package test was run.

## 3. Exact state and pins

Candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`. Review-start HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`. Closing HEAD: `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`. The parent authorized this advance for 30 completed FA unit/order artifacts, receipts, and reviews; it changed no source, driver, schema, or runtests. Branch: `codex/hsquared-fa-gllvm-20260927`, with existing dirty work. Parent is running the approved FA campaign against its frozen source tree. This review measured unchanged source pins and wrote scratch files only.

| Artifact | Lines | SHA-256 |
| --- | ---: | --- |
| `src/validation_status.jl` | 610 | `95f90c3a166f7ead65afc4205d5139155f86c002c697045388a1b2d383d14010` |
| `docs/design/capability-status.md` | 170 | `daf32aaaa16834a148d2240336990ef835befe8a6df298be6007ce91288b3e01` |
| `docs/design/validation-debt-register.md` | 127 | `df409aab18c1de885acdabcbc84eacebac6956bc3bb2ef0ce936da1f5a41f46e` |
| `docs/src/validation-status.md` | 174 | `c7c89e62f6b6c8639e34361036c35f2aa5bdc003a086df6826f9bb5ef0719600` |
| `src/iterative_solve.jl` | 1408 | `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132` |
| `src/nongaussian.jl` | 1803 | `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00` |
| `src/genetic_gllvm.jl` | 682 | `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca` |

## 4. Method and reuse

Graft was queried before source inspection. It could not refresh its cache because `.cache/.sync.lock` access returned EPERM. Cached spans sometimes differed from current line numbers. Current numbered source and exact receipts supplied technical truth; the cached graph supplied navigation only. The three calls reported savings of 123,175, 132,917, and 192,918 tokens: **449,010 total**, a tool estimate using a whole-file baseline. Actual review-work savings were not measured.

Reuse:

- `2026-09-30-metafounder-wrapper-alignment.md` pins the current status hash and covers the V1-METAFOUNDER row at 101-109. Its partial, supplied-Γ construction/MME/wrapper and no-R/no-comparator boundary remains valid. These 9 lines were subtracted from the fresh review.
- `2026-09-29-validation-status-review.md` pins older source `8778dd2513603115c43f51b4e57fb6d87495a8c8061b66195f58c00a90a4df28`. Its FA/GLLVM/count claim component remains useful history, but its pin does not authorize the present entire file.
- `2026-09-27-wave4.md` records inspected candidate spans 349-384, 507-560, 562-610 and expressly excludes evidence bodies 1-348 and 385-506. Its status disposition is HOLD. Baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214` has 615 source lines and SHA `192a77da44b59c41a74acd4235d3648da1409487e02c0a51a4a2e43d0640d72d`. Matching baseline text supplies context; exact current signed spans require a receipt at the current pin; a baseline line range cannot be copied onto the candidate unchanged by assumption.
- `2026-09-30-iterative-solver-doc-followup.md` pins current solver source and explicitly identifies the outstanding ledger wording review. Its wording corrections are the contract used for matrix-free claims below.

The static parser checks all 56 unique records have seven string fields, including joined multivariate and marker-threshold evidence bodies. Label counts are 15 `covered`, 3 `covered_external`, 37 `partial`, and 1 `planned`. These engine/evidence labels are not the R-public model count. The current R-public count remains 7.

## 5. Complete coverage ledger

All entries below were reviewed for source-record consistency and claim boundaries; their retained status is not a new approval. Metafounder 101-109 is reused exact component coverage. All other entries belong to this fresh static pass.

| Current span | Returned row ID | Retained label |
| --- | --- | --- |
| 2-10 | `V0-LOAD` | covered |
| 11-19 | `V1-PED` | covered |
| 20-28 | `V1-AINV-TINY` | covered |
| 29-37 | `V1-AINV-MRODE9` | covered_external |
| 38-46 | `V1-LIK` | partial |
| 47-55 | `V1-SPARSE-REML` | partial |
| 56-64 | `V1-SPARSE-REML-OPT` | partial |
| 65-73 | `V1-MME` | partial |
| 74-82 | `V1-SIRE-FIT` | partial |
| 83-91 | `V1-DENSE-OUT` | partial |
| 92-100 | `V1-SELINV-PEV` | partial |
| 101-109 | `V1-METAFOUNDER` | partial |
| 110-118 | `V1-PCG` | partial |
| 119-127 | `V1-AI-REML` | covered |
| 128-136 | `V1-MATFREE-REML` | partial |
| 137-145 | `V1-MRODE-FIT` | covered_external |
| 146-154 | `V1-COMPARATORS` | covered_external |
| 155-163 | `V1-HERIT-CI` | partial |
| 164-172 | `V2-GRM` | partial |
| 173-181 | `V2-GINV` | partial |
| 182-190 | `V2-GRM-GPU` | partial |
| 191-199 | `V2-GBLUP` | partial |
| 200-208 | `V2-APY` | partial |
| 209-217 | `V2-SNPBLUP` | partial |
| 218-226 | `V2-SSHINV` | covered |
| 227-235 | `V2-GREML` | covered |
| 236-244 | `V3-REPEAT` | partial |
| 245-253 | `V3-REPEAT-REML` | partial |
| 254-262 | `V3-TWOEFFECT` | partial |
| 263-271 | `V3-TWOEFFECT-REML` | covered |
| 272-280 | `V3-NEFFECT-REML` | covered |
| 281-289 | `V3-NEFFECT-SPARSE` | partial |
| 290-298 | `V3-NEFFECT-MATFREE-FIT` | partial |
| 299-307 | `V3-RR-REML` | covered |
| 308-316 | `V4-MULTIVARIATE` | partial |
| 317-325 | `V4-DIRECT-MATERNAL` | covered |
| 326-347 | `V4-MV-REML` | covered |
| 348-356 | `V4-FA` | covered |
| 357-365 | `V4-BRIDGE` | partial |
| 366-374 | `V4-EVOLVE` | partial |
| 375-383 | `C10-LRT` | partial |
| 384-392 | `V5-MARKER-FIXED` | partial |
| 393-401 | `V5-MARKER-MIXED` | partial |
| 402-410 | `V5-MARKER-LOCO` | partial |
| 411-433 | `V5-MARKER-THRESHOLD` | covered |
| 434-442 | `V5-GENOMIC-QTL` | planned |
| 443-451 | `V6-LAPLACE` | partial |
| 452-460 | `V6-NBINOM` | partial |
| 461-469 | `V6-BETABINOMIAL` | partial |
| 470-478 | `V6-PROBIT` | partial |
| 479-487 | `V6-ORDINAL` | covered |
| 488-496 | `V6-GAMMA` | covered |
| 497-505 | `V6-NS-H2` | partial |
| 506-514 | `V6-GGLLVM-DESC` | partial |
| 515-523 | `V6-GGLLVM-MARGINAL` | partial |
| 524-532 | `V6-GGLLVM-LAPLACE` | partial |

Remaining source spans: line 1 defines the raw constant; 533-560 close and normalize the records; 561-578 document and define `ValidationStatusRow`; 579-587 document and define `ValidationStatus`; 588-593 provide collection delegation; 594-610 document and build a fresh diagnostic table. The normalization changes the historical GLLVM ID, prefixes its qualified integrated objective, and rewrites ordinal/Gamma evidence wording. It does not execute fits or infer approval. All 610 lines are accounted for. There is no remaining read-only span gap in this file at the stated pin.

## 6. Findings that hold claim approval

### VS-1. Matrix-free algorithm, stopping, and uncertainty wording is stale

Severity: P1 for claims. Source: 116, 133, 135, 295-297. Related current documents: capability table 87-88; debt register 113-114. These strings still call the procedure EM, claim fixed probes make it convergent, identify its fixed point with the exact REML optimum plus Monte Carlo error, and describe `trace_mcse` as fit/parameter noise. The exact solver follow-up states a stochastic REML score fixed-point iteration, relative variance-change stopping, and trace-probe uncertainty excluding PCG error. Small parameter changes do not establish score stationarity or a unique/global optimum. A fixed seed gives repeatability, not convergence or correctness.

Source 295 fails to qualify `loglik` as NaN when disabled. Source 296 calls the non-logdet terms exact even though the quadratic term uses PCG; calls AI construction exact without its solve-accuracy limit; and gives a general equal-budget shared-probe precision guarantee where evidence is bounded to fixtures. SLQ MCSE excludes finite-Lanczos bias and PCG error. Capability 88 additionally says exact single-effect loglik is evaluated at the converged estimate, whereas the wrapper evaluates the returned estimate whether or not convergence was reported.

Resolution: align all three ledgers with the signed current solver docstrings. Retain historical measurements with dates and pins; require fresh evidence for any new current-source recovery claim. The correction changes wording and preserves the algorithm and statuses.

### VS-2. The multi-effect ledger erases an explicitly open comparator debt

Severity: P1 for evidence completeness. Source 296-297 says coverage intervals are the only remaining debt and that every external REML tool is incapable of the exact-infeasible regime by construction. Capability 87 and debt 114 retain that at-scale external comparator leg. The recorded q=4060 comparison is real historical evidence but does not establish performance/parity at q much greater than 50,000 or a universal impossibility theorem about external software.

Resolution: retain q=860/q=4060 agreement, restore the exact-infeasible comparator debt, and remove the universal claim. No new comparator run is requested by this source-review slice.

### VS-3. Six current source strings report an obsolete public count

Severity: P2, explicit current-state contradiction. Source 417, 432, 484, 486, 493, 495 says public-covered fitting is 1/v0.1 Gaussian. Current capability header 12-16 and 43-51 says 7. The three returned claim boundaries, 432/486/495, are rendered as current statements; their evidence strings 417/484/493 also present the old count without a historical qualifier. Related stale current wording: capability 131, 151-152; debt 94 says count 1, debt 113 says live count 6. Ordinal and Gamma remain internal; updating the count to the already recorded 7 does not activate either family or promote a row.

Historical references to the fourth/fifth public surface at source 306/324 and the explicit dated genomic count 5 in capability 27-41 can retain historical provenance. They are not new claims that the live count is 4 or 5.

### VS-4. Ordinal/Gamma comparator labels exceed the demonstrated objective agreement

Severity: P1 for comparator-discharge wording; no automatic status reversal. Source ordinal 484-486 and Gamma 493-495, plus mapper 546-557, describe the July `ordinal::clmm`/`glmmTMB` comparisons as same-estimand Laplace-ML evidence, completed comparator prerequisites, and variance differences explained by an ML-versus-REML convention. Current mapping removes the REML label but retains Laplace-ML/same-estimand discharge wording. Debt 107-108 also retains this account; Gamma 108 still says engine REML-ish and an expected ML-versus-REML gap.

The current engine explicitly flat-integrates fixed effects: `src/nongaussian.jl:640-646` documents this, and 722-735 forms the joint fixed/random Hessian determinant with the `p*log(2π)/2` term. The July comparator receipts themselves state that clmm/glmmTMB profile fixed effects while the engine integrates them. Matching random-effect parameterization and numerical proximity do not establish equality of optimized objectives or justify attributing the variance difference to REML. Their target population parameters may correspond; the strong same-objective/parity and prerequisite-discharge claims are the unsupported part.

Independent mathematical disposition: `/private/tmp/e1-legacy-objective-labels-astra-review-20260930.md` passes numerical comparison of corresponding model parameters under different objectives and holds same-objective parity or prerequisite-discharge claims. It demonstrates the joint-Hessian normalization and the extra fixed-effect integration term; the observed variance/intercept gaps have no established general ML-versus-REML cause, sign, or magnitude. The combined isolated proposal now uses its nine replacement paragraphs, distinguishes K−2 free ordinal spacings from K−1 returned cutpoints, removes the obsolete Ordinal/Gamma mapper branches, and carries the same integrated-Laplace/proper-integral fence in adjacent legacy rows. Historical covered labels and all family capabilities are preserved. Same-objective comparator validation remains explicit debt. The proposal awaits bounded independent wording review and current-ledger integration; no new campaign or count change is authorized.

### VS-5. Adjacent construction/fit and status statements contradict present rows

Severity: P2. Source 179-180 says genomic inverse is not wired into model fitting and owes GBLUP wiring/H blending; adjacent rows 191-199, 218-235 and current genomic code already expose those routes. Current `src/genomic.jl:324-348` constructs marker-derived `Q` using `genomic_relationship_inverse`, and fitted GBLUP/single-step entrypoints are at 522-584 and 2546-2608. The construction row should limit its own evidence, rather than deny the existence of separately implemented routes.

Source 242 says REML estimation is covered by V3-REPEAT-REML, whose actual status at 249 is partial. Change the cross-reference to separately implemented and partial. This review does not extend R `permanent()` grammar or infer validation from adjacent model families.

### VS-6. FA and GLLVM status claims need the current limits kept visible

Severity: P2 for omission/overbroad wording. FA source 355 says fit-level uniqueness information is unassessed. Current `2026-09-30-fa-exact-current-component-review.md` and `2026-09-30-fa-weak-direction.md` document bounded plug-in expected-information rank checks, while observed curvature, inference, calibration, and ordinary-start acceptance remain unproven. Replace the blanket absence with that distinction. S4's covered point-estimate cell and no-loading/no-uniqueness-inference fence remain unchanged; the parent FA campaign is not evidence of completion until its receipt exists.

GLLVM 511/520/529/531 retains valid supplied-loadings reductions and the exact-current 50/50 one-cell Poisson replay. `/private/tmp/e1-gllvm-residual-contract-review-20260930.md` adds full 682/682 static review at the pinned source but HOLD for C1-C5: invalid solver controls, incomplete proper-integral guards, unsupported vector-binomial record dispatch, finite-input/family validation, and synthetic descriptor metadata/uniqueness validation. Source 511's delegated guards apply to supplied loadings and do not prove synthetic-result ingress is complete. Source 520's broad family shorthand must not imply the vector-binomial subtype has a working record kernel. The isolated C1/basic-C4 patch has an independent 50-passed disposition, as reported by the parent, and remains outside the frozen candidate. Its bounded control/ingress repair does not close C2/C3/C5 or the remainder of C4. The 50/50 valid Poisson replay stays valid; it does not close those malformed-input contracts, mixed-family recovery, general grammar, or calibration.

## 7. Evidence retained without promotion

- Historical S5 result at `2026-09-01-f6-matfree-tail-recovery-result.md` exists and passed its frozen fixture: q=25,000, 48/48 converged, zero cap/non-graceful failures; its exact-estimator anchor used eight seeds at q=2,000. It explicitly leaves S6 and S7 open. Its Julia 1.12.6 arm uses a different RNG realization, not independent evidence for the same 1.10.10 dataset. It must not be relabelled unrun based on the stale AGENTS phase snapshot. It must not become a current-source recovery receipt merely because the package suite passes.
- The multi-effect July recovery/scale and external q=860/q=4060 comparator results remain historical measurements, not source-current proof at every advertised scale.
- The parent reports isolated random-regression repair review passing 41+6 checks and isolated `coefcov` repair independently passing 74 checks. Neither repair is live. These are bounded repair receipts; they do not transfer approval to the unchanged candidate or establish broad calibration.
- The parent separately accepted five FA unit/order cases from one fixture. The 200-seed primary campaign is still running. Fixture transformations, partial campaign progress, and completed campaign acceptance are separate evidence. No new covered claim follows from those states.
- The exact 90-assertion maternal live receipt at `2026-09-30-exact-twin-maternal-live-recheck.md` closes paired transport, extractors, and variance parity on its six-animal/eight-record fixture. Broad calibration and generic bridge evidence remain open. It supersedes the old wrong-twin mismatch for the active dirty R reader; it is not a new broad recovery or R CI claim.
- FA source 353-355 retains the failed broader calibration and S4 8/10 point-estimate gate; neither failure nor ordinary-start evidence may be discarded from its denominator. Loading rotations and sparse-loading rank defects remain visible.
- Marker-threshold source 411-433 preserves quantile and reuse-shortcut negatives alongside the per-dataset add-one rule. Dated statements that rows stayed partial record earlier stages. The current scoped label is preserved. No mixed-model/LOCO significance extension is earned here.
- GPU source 182-190 records historical device work and remains partial. This review supplies no new device execution, compatibility, or timing evidence. Static-only limits are retained.

## 8. Isolated wording proposal

Artifact: `/private/tmp/e1-validation-status-wording-20260930.patch`. It was generated in memory from the exact source above; no live file was edited. Patch SHA-256: `e2d76592dc28faa99c36808d063619e2cc80e25da107f2ef9794687a08cba042`. Proposed resulting source SHA: `1d1d444bea3a5dc7a2dfccf5549b4d3082acfe3bf48761fe203a9d5f993c5316`.

Changed string lines at the frozen base: 116, 133, 135, 179-180, 242, 295-297, 355, 417, 432, 450, 459, 468, 477, 484-486, 493-495. The 22 strings comprise the prior 16 plus six additional legacy-objective/missing-field strings. The Ordinal/Gamma mapper branches at base 546-557 are removed; the GLLVM normalization remains unchanged. The proposed source has 598 lines. It addresses matrix-free algorithm/stopping/uncertainty/debt wording, genomic construction and repeatability cross-references, obsolete counts, expected-information limits, and the independently specified VS-4 qualifications. All 56 IDs, capability names, phases, and status labels are preserved. The current R-public count stays 7. Existing target identifiers such as `:matrix_free_mc_em_reml` remain compatible.

The combined patch awaits bounded independent wording review and integration; the live pin is unchanged. The VS-4 mathematical qualification is complete at the component receipt scope, while same-objective comparator parity remains unestablished. The patch does not repair GLLVM C1-C5, synchronize capability/debt documents, extend the numerical kernel docstring, or regenerate the page. These are explicit integration work after the primary source freeze permits edits. Long string lines make the unified diff large; review the 22 changed strings and the removed mapper branches against the exact base. The numerical `laplace_marginal_loglik` docstring proposal remains with its engine owner; this status patch owns no numerical source.

## 9. Checks performed

- Static parser: 56 unique seven-field records; 15 covered, 3 covered_external, 37 partial, 1 planned. Joined evidence strings and source normalization branches inspected.
- Combined proposed patch: all 56 ID/capability/phase/status fields preserved; line count is 598 after the 12 obsolete mapper lines are removed. All nine Astra replacement paragraphs are composed with the earlier wording proposal; no stale same-objective discharge or ML-versus-REML attribution remains in the proposed Ordinal/Gamma strings. No fitting code or exported signature changes.
- Python emulation of the existing table writer compared all 56 rendered row strings from live source against the current generated page: exact match. The check emulates the renderer statically. Julia and Documenter were not run. The generated page has no independent evidence value: it carries the source's stale claim boundaries faithfully.
- Current exact pins remeasured before reporting. Live source unchanged; scratch artifacts only.
- Prose checker and patch applicability results are recorded at closeout below. No tests or fits were required to diagnose these string-level contradictions; no runtime status is inferred from static checks.

## 10. Limits and disposition

**BLOCKED** for clean claim approval while VS-1 through VS-5 and current component qualifications are unresolved. **Full static source coverage** at current status pin 95f90 is complete. Do not request another full read of this 610-line file as a missing-coverage task at that pin. The independent VS-4 mathematical component disposition is complete. Independent review of the combined changed wording and later integration are approval work; there are no unexamined status-source spans.

E1 remains open for other current source gaps and unresolved numerical/bridge findings. No public covered count changes; the recorded count is 7. The table does not run validators, check receipt freshness, or promote rows. Runtime GPU testing is excluded from completion criteria, with static-only limitations retained. No claimed file owner is blocked merely because other refs carry divergent history.

## 11. Next bounded actions

1. Independently review the 22 proposed string lines and removal of base 546-557 against this exact base, the solver/FA receipts, and the Astra VS-4 replacement paragraphs; keep the patch isolated until the parent releases the primary source freeze.
2. Use the completed Astra mathematical disposition for ordinal 479-487, Gamma 488-496, and mapper 546-557. The proposed visible comparator qualification retains historical approval and carries same-objective parity debt. No new fit is required for this wording integration.
3. Once wording is approved, synchronize capability lines 87-88, 131, 151-152 and debt lines 94, 107-108, 113-114. Preserve historical receipts verbatim and amend their use by current claim notes; do not rewrite old failures or promote rows.
4. Generate the status page from the corrected source and compare it to the generated result. Attest new exact pins only for touched strings plus unchanged record/container behavior; do not repeat historical campaigns.
5. Preserve the isolated independently tested C1/basic-C4, RR, and `coefcov` repairs until their approved integration. Retain the unresolved GLLVM C2/C3/C5 and remaining C4 contracts. Preserve the completed 50/50 valid Poisson replay and bounded maternal live parity cell. Isolated repair PASS does not change the live source disposition.
6. Continue remaining E1 files using the existing per-file span inventory. Current status-file read-only coverage is complete; behavioral fixes, broader calibration, generic bridge evidence, and source integration remain separately tracked.

### Closeout

The combined `git apply --check` passed without applying the proposal. Static parsing preserved all 56 ID/capability/phase/status fields, composed all nine Astra replacement paragraphs, and verified removal of only the Ordinal/Gamma mapper branches. Earlier static live-page emulation passed and remains tied to the unchanged live source. `slop_check.py` passed with 0 hits, 0 findings, and no em dashes. Scratch only. Parent integration owns repo-visible status and E1 closeout.
