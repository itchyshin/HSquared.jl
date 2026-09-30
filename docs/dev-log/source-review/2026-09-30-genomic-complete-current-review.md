# Complete current genomic source disposition, 2026-09-30

Verdict: **HOLD for whole-file approval; PASS for complete source coverage accounting.** This is the Karpinski source review applying Gauss, Karpinski and Noether lenses. All 2,934 current lines are accounted for below. Existing signed component approvals retain their bounded validity. This file alone does not close E1, approve genome-wide calibration, certify performance, or change a capability, release, GPU or R-public status.

## 1. Request and ownership

Review the complete frozen `src/genomic.jl`, reuse signed construction/postfit/metafounder components, inspect the remaining whole functions, and return source findings and performance measurement requirements. The only owned output is this scratch report. No source, tests, candidate documentation or other lane's files were edited.

PLATFORM: codex | ON BRANCH: codex/hsquared-fa-gllvm-20260927 | LANE: bounded genomic source review.

Preflight was read only and reported live FA-validator and pedigree-test leases. This review respects both. The candidate is the parent's active worktree, with substantial parent-owned dirty source/tests/docs. Worktree route lookup first failed because the router expects a repository name; `route.py HSquared.jl` returned the LOAD-FIRST manifest. The brain search and memory registry routed to bounded source evidence, not a release operation. No remote compute, GPU execution, fit, optimizer, external posting, commit or tag was performed by this review. The required preflight wrapper printed its usual PR/origin context; no separate GitHub or web request was made.

## 2. Exact candidate pins

Candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`.

| Artifact | SHA-256 or Git commit |
| --- | --- |
| HEAD, observed before and after review | `3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe` |
| Current `src/genomic.jl`, 2,934 lines | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` |
| Complete `src/` tree, independently recomputed with the FA driver's relative-path/NUL/content/NUL algorithm | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| Baseline Git commit | `faed40182cdbba2bf69f3e8dff0c5054be2dd214` |
| Baseline genomic bytes from that Git commit | `3bc1e80a18217f833c034f631cbfa5c0d0436b596c78ed127da7d083f7bda1ea` |
| Current `test/wave1_numerical_contracts.jl`, later observation | `a15c456451fc9a3a2c5f3c9aca80a58efc53550ae364c390060fbe2ac32594b2` |
| Current `test/test_212_engine_controls.jl` | `9c3b9d4bd8d075ff3931d59f3e909e9983c98ebe8bf02d7908d38be1950a7d6b` |
| Current `test/runtests.jl`, later observation | `b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24` |
| `sim/phase5_qtl_addone_design_sweep.jl` | `cc705e4e86cbba77d3d8c1bb3060bb5d608f30e93bf764d32201295e2427a5c2` |
| `sim/phase5_qtl_rebuild_production_gate.jl` | `6ce14ee023116e127235c060046d037bd40f3c97d19be47c0bb732decd24b466` |

The test pins differ from the older construction/postfit receipts because other authorised lanes are updating tests. No old full-suite result is represented as a fresh result on those later test bytes. The complete source tree and this source file stayed pinned. Historical component source pins are explicitly retained in section 4.

## 3. Exact disjoint line partition

Each current line belongs to exactly one row. Reused coverage totals 558 lines; fresh source inspection or explicit current reattestation totals 2,376 lines. Total 2,934, no gap and no overlap. A split at a historical receipt boundary is accounting only: the LOCO and common-scan whole definitions were inspected through their closing `end` when extending that receipt.

| Current lines | Count | Treatment and complete functions or associated prose |
| --- | ---: | --- |
| 1-14 | 14 | Fresh helper `_symmetrize_roundoff!`, 1-11, and adjoining doc opener. |
| 15-457 | 443 | Reuse exact-current signed construction receipt. Current definitions: `centered_markers` 27-53; GRM 94-138; inverse 157-172; provenance helpers 180-314; activation 324-350; APY 376-431; LOCO signature 452-457. Conditional construction approval and dense limits retained. |
| 458-677 | 220 | Fresh LOCO closing extension through 496, genomic fitter docs and all four fit wrappers 522-534, 558-571, 601-616, 633-651; direct-scan prose 653-677. This closes the receipt's mid-LOCO stop. |
| 678-897 | 220 | Fresh current reattestation of `single_marker_scan` 678-757, mixed public dispatch 780-804, LOCO public dispatch 824-871, and common input checks 873-897. Full common function 873-916 was read; existing core evidence accounts for 898-916. |
| 898-995 | 98 | Reuse exact-current signed postfit/core receipt: variance checks, remaining common helper, covariance cache 918-952 and GLS statistics 954-995. Prepared repair is not applied. |
| 996-1113 | 118 | Fresh result assembly 997-1014, payload 1034-1062, all three precision lookup methods 1064-1089, and marker plotting prose. |
| 1114-1493 | 380 | Fresh all Manhattan/map/HSData dispatches and core, marker ID/p validation, region dispatches/core, bounds/flank/alpha checks, and exact marker-map ordering. |
| 1494-1907 | 414 | Fresh QQ data, inflation, significance summary, scan-table dispatches/core, GWAS/QTL/eQTL wrappers, semantic analysis table and optional-label helper, including all associated prose. |
| 1908-2195 | 288 | Fresh marker-effects dispatches, variance-summary dispatches/core, frequency/total/scalar/marker-group checks and associated prose. |
| 2196-2373 | 178 | Fresh variance sort metrics, complete `_marker_effects`, scan-field checks, summary sorting, top-N and paired marker metadata checks. |
| 2374-2460 | 87 | Fresh reattestation of median, CDF/two-sided tail, p-value validation, Bonferroni/BH helpers and single-step formula prose. Prior W1-02 tail repair retained; no new tail-algebra campaign. |
| 2461-2530 | 70 | Fresh current reattestation of complete `_single_step_Hinv` and pairwise symmetry validator against the signed 09-29 repair. |
| 2531-2648 | 118 | Fresh public single-step alias/prose, supplied/reml wrappers, typed metafounder single-step wrapper and associated prose. |
| 2649-2665 | 17 | Reuse exact-current signed raw-array metafounder wrapper alignment, including input-row validation and caller-to-normalized mapping. |
| 2666-2738 | 73 | Fresh supplied/reml metafounder fit wrappers, all forwarding and threshold-mechanism prose. |
| 2739-2934 | 196 | Fresh current reattestation of maximum statistic, empirical quantile, supplied-null threshold, add-one p-value and complete per-dataset residual-permutation scan, with their prose. |

## 4. Reused evidence and historical deltas

Exact-current source reuse:

- `docs/dev-log/source-review/2026-09-30-genomic-matrix-construction-review.md`: current genomic SHA `76c4053d...`; explicitly recorded scope 15-457. Its embedded older function coordinates are stale. This review supplies current anchors and closing extension 458-496, plus the remaining fitter prose through 521.
- `docs/dev-log/source-review/2026-09-30-postfit-marker-scan-review.md`: current genomic SHA `76c4053d...`; explicit 898-995 core, interior GLS algebra conditional pass and three convenience-wrapper limitations.
- `docs/dev-log/source-review/2026-09-30-metafounder-wrapper-alignment.md`: current genomic SHA `76c4053d...`; raw wrapper 2649-2665 ordering/keyword contract. The typed wrapper and fitting delegates were freshly read here; no fitted-metafounder inference is added.

Historical signed evidence reattested by named current functions:

- Wave 1 packet 2026-09-27: partial genomic spans at baseline Git `faed401...`; W1-02 two-sided-tail cancellation repaired. Current 2397-2408 retains the direct negative-central tail and upper-gamma extreme tail, finite-z check and squared-z overflow branch. Current registered sign/relative-tail tests are at `test/wave1_numerical_contracts.jl:338-351`. The CDF and Bonferroni/BH bodies are byte-identical to the Git baseline; the two-sided tail body has the expected repair. No regression of that repair was found; historical passing algebra was not rerun.
- `2026-09-29-genomic-core-exact-review.md`: prior SHA `72423bd...`; prior scan functions 639-1157 now map to 678-1192. Projection/statistics equations still implement the same bounded supplied-variance GLS contract. Current input/symmetry changes and metadata interfaces were read here, preserving the already-approved tiny oracle evidence rather than rerunning it. Original six construction findings are not all closed by a scan signoff. The missing-group finding remains G2 below; APY scaling and inverse conditioning remain debts.
- `2026-09-29-wave4-genomic.md`: original `66403cf...`, repaired `d9ae83...`; finite inputs, lookup collision, scan variance conversion and single-step validation repairs. Current direct scan 694-696, lookup 1064-1075, threshold 2808-2810 and single-step 2461-2529 retain those guards. New Real conversion endpoint issues in G4 concern distinct threshold/p-value arguments.
- `2026-09-29-wave4-genomic-symmetry.md`: historical `72423bd...`; subsequently superseded for the validator by `2026-09-29-wave4-genomic-symmetry-overflow-followup.md` at `8fb4965...`. Current 2515-2529 retains the latter pairwise relative check and overflow-safe half-sum. Current H update uses the inverse of `A[g,g]`, validates finite symmetric PD inputs and final finite PD output, and preserves genotype-row ordering. Existing focused controls are registered in `test/test_212_engine_controls.jl:199-229`. No full-suite replay is claimed here.

The byte-comparison pass extracts complete top-level function bodies from the pinned Git baseline and current file. These named bodies are unchanged: `centered_markers`, activation, all four genomic fitters, both public mixed scans, common scan inputs, mixed statistics/result, marker payload, CDF, checked p-values, Bonferroni/BH, both ordinary single-step fitters, both metafounder fitters, max-statistic, empirical quantile, add-one p-value and genome-wide scan. Changed bodies: GRM/inverse/APY, direct scan, mixed cache, dictionary lookup, two-sided tail, H assembly, raw metafounder construction and supplied-null threshold; the symmetry helper is new. Existing signed 09-29 artifact hashes are historical pins, not asserted byte comparisons against an unavailable old working-tree snapshot. Current changed functions were inspected and explicitly reattested. No old line range is silently promoted to current full coverage.

## 5. Findings and dispositions

### G1, P2, prepared but unapplied: fitted convenience scan contracts

Carry signed core findings: live common helper 898-903 rejects the valid `sigma_a2 == 0` boundary; the fitted wrapper's convergence/status guard and visible positional observation-row alignment also need resolution. The corrected prepared patch in `docs/dev-log/prepared-fixes/2026-09-30-postfit-marker-contract/independent-review.md` has bounded independent PASS: 37 prior controls plus four negative-underflow controls. Patch SHA `67281094c94e34fd7a29414534f5304b1a5e5fb02a5598f547e909f37afff70c`, prepared genomic SHA `d99ab651d2be5e8612e1c97edcac8b3dcfbe98ee579bad0c71b452f04ad209d9`. That approval includes rejection of an original negative Real before conversion in both shared-helper callers. The initial failed proposal remains historical evidence. Do not reopen its repaired underflow as unknown, or mark the frozen source fixed. Integration after the freeze, registered tests and new source pins are still owed. Broader calibration and automatic ID alignment remain outside that repair.

### G2, P2, carried and reproduced: missing LOCO groups become a real label

Construction 462-469 and scan 846-850 string-convert groups before checking absence. `Any["a","b",missing]` is accepted and creates precision key `"missing"`; the scan then returns marker group `"missing"`. This is the earlier 09-29 construction finding, still live in the fresh closing extension. The same input class affects summary group/metadata helpers 2188-2194 and 2358-2365. Validate missing/empty labels before string conversion, or explicitly fence absence as unsupported; do not conflate absent data with a supplied literal string label.

### G3, P2, new and reproduced: finite summaries can overflow despite representable answers

Variance calculations 1716-1719 and 2091-2094 square effects before applying small allele variances. `marker_variance_explained((marker_ids=["m"], effects=[1e200], p=[1e-200]))` returns `[Inf]`, although `(2e-200 * 1e200) * 1e200` is finite `2e200`. Even-length median 2374-2380 forms a sum before halving: median of `[1e308,1e308]` becomes `Inf`. `marker_genomic_inflation((chisq=[1e308,1e308],); expected_median=2.0)` returns both infinite median and lambda, where the mathematical median is `1e308` and lambda is representable `5e307`.

Use arithmetic safe for the promised finite range, then validate derived outputs, or reject/document an explicit supported range. Add targeted representable-result controls to both variance-summary and scan-table callers and the median/inflation route. This does not require a fitting or calibration campaign.

### G4, P2, new and reproduced: probability-domain checks precede lossy conversion

Threshold 2801-2816 validates original `alpha::Real` but returns its Float64 conversion. `alpha=big"1e-1000"` is accepted and returns `alpha=0.0`, contradicting `(0,1)`; alpha rounding to one has the analogous endpoint risk. Add-one p-value 2828-2835 checks finite original observed, then uses its Float64 conversion for exceedances. With `observed=big"1e-1000"`, `nulls=[0.0,0.0]`, current p is `1.0`; the documented original-Real formula yields `1/3` because neither zero exceeds that positive observed value. This is a distinct supplied-null input issue; it is not the prepared additive-variance guard.

Normalize once and validate the actual computational domain, explicitly define Float64 rounding semantics, or retain sufficient precision for comparisons. If the contract rejects values that cannot preserve sign/domain, test negative/positive underflow and overflow separately. Do not classify original finite large observed values as automatically wrong: converting an observed value above every representable null to infinity can still produce the correct exceedance count.

### G5, P2, carried scope debt with fresh evidence: exact permutation language exceeds the design

Docstring 2843-2858 calls this an exact, calibrated fixed-effect test for intercept or supplied covariates. The named design-sweep and production harnesses explicitly use intercept-only `X` (`sim/phase5_qtl_addone_design_sweep.jl:16`; production harness 15 and 48). For general fixed effects, null residual covariance is proportional to `R=I-H_X`; a row permutation `T` preserves its distribution only if `T R T' = R` under the relevant exchangeability assumptions. A deterministic `X=[1,0;1,1;1,2;1,3]` and swap of the first two rows yields `norm(T*R*T'-R)=0.8485281374238572`. Add-one counting does not establish exchangeability of general regression residuals.

Fence the exactness/calibration claim to the evidenced intercept-only exchangeable Gaussian design. Keep supplied-covariate residual permutation experimental and separate from mixed-covariance calibration. This finding can be disposed by narrow visible prose and status boundaries; no large calibration campaign is required for this source audit. Existing passing intercept-only evidence remains usable.

### G6, P3, documentation conditions need precision

- `centered_markers` prose 20-23 says every column sums to zero even when frequencies are supplied. A small supplied-frequency example returned column sums `[2.4,1.8]`; zero sums require sample-estimated frequencies. The same condition limits the GRM all-ones-null/rank assertion in `fit_gblup` prose 505-509. Regularization advice is useful but the blanket rank claim needs its condition.
- Single-step reduction prose 2539, 2566 and 2589 omits knob conditions. With `A=Ainv=G=I2`, rows `[1,2]`, `tau=2`, current H inverse is `2I2`, not A inverse. State the ordinary default reduction (or the precise cancellation/ridge conditions). Formula and implementation are correct; this is a claim condition.
- Public ordinary single-step prose 2541-2543 says sorted pedigree-row order, while the kernel preserves the supplied `genotyped_rows` sequence and aligns G to that sequence. Raw metafounder prose already states the more precise caller-order contract. Keep the ordinary contract consistent.

## 6. Performance risks and measurement requirements

These are debts and hypotheses, not reasons to run a campaign during a static audit. Correctness and contract disposition precede optimisation.

| Risk | Current evidence | Measurement required before performance claim or optimisation |
| --- | --- | --- |
| Dense GRM/precision storage | Signed construction and current fitting/scan wrappers retain dense matrices; APY still returns dense precision. | Size ladder in animals, markers and APY core size; peak resident memory and allocations for construction, inversion and fit separately; include retained outputs and provenance buffers. Dense inversion remains cubic arithmetic and storage quadratic. |
| Dense SNP identity | 611 and 643 build dense `m x m` identity prior before model construction. | Measure marker-count scaling and downstream MME fill, factor storage and peak memory; no sparse advantage follows from the conceptual identity prior. |
| LOCO retention | Constructor keeps one dense precision per group; scan builds all covariance caches before scanning 858-868. | Vary groups and observations independently; report precision/cache peak memory, factorization counts and complete same-group scan time with at least two markers per group. |
| Type inference through lookup | Dictionary and NamedTuple lookups both return `Dict{String,Any}` 1064-1085. This is an abstract retrieval, not proof every downstream hot loop is unstable. | Inspect inferred concrete cache dictionary and closure return types for actual homogeneous/different matrix containers using `@code_warntype` or equivalent; isolate setup dispatch from per-marker lookup; measure allocations after warmup. |
| Fixed scan repeated work | 709-724 forms normal equations and solves XtX afresh inside every marker iteration; per-marker residuals allocate. | Separate factorization/setup and marker-loop costs; allocations per marker; compare projection residuals with an independent QR reference across condition/scale ladders before changing the kernel. |
| Dense mixed scan | 927-950 densifies precision, inverts it, constructs dense V, checks PD and then factorizes; per-marker solves/vectors allocate 964-966. | Peak memory and repeated factorization/setup counts; covariance/normal-equation conditioning and denominator residuals; confirm independent GLS agreement before workspace reuse or factorisation changes. |
| Absolute scan cutoff | Denominators use `sqrt(eps(Float64))` 726 and 968, independent of design/covariance scale. | Deterministic unit/scale and near-collinearity ladder, augmented QR comparison, classification stability; scaling caveat retained from the prior signed scan review. |
| Activation/provenance copies | Signed construction receipt records repeated centering, full hashes and dense retained objects; sparse supplied precision provenance can densify. | Measure complete activation, not GRM multiplication only; count copy passes and peak memory for dense/sparse/view inputs. |
| Metafounder repeated construction | 2640-2643 calls relationship and inverse construction separately, then single-step copies both matrices. | Profile construction/caching duplication at a fixed correct pedigree/Γ and row mapping before introducing reuse. |
| Permutation pipeline | 2891-2896 reruns full direct scan for every permutation, rebuilding centered markers, projection, tails and BH sorting. Per-marker p-values 2900 each recopy nulls. | Scaling in permutations, observations, markers and fixed-effect columns; end-to-end cold/warm wall time, allocation and RSS, RNG reproducibility. Validate each future reduced maximum-only or cached path against the unchanged statistic/null construction first. |
| Summary sorting/copies | Helpers validate and copy vectors, sort full marker sets even for top-N, then subset; Manhattan loops scan marker order for each chromosome. | Measure marker and chromosome ladders; distinguish `O(m log m)` ordering and `O(groups*m)` grouping, output ownership requirements and top-N tradeoff. |
| Broad matrix/backend surface | Constructors accept abstract matrix/backend inputs; full dispatch-specific return type and GPU behaviour have not been measured here. | Representative dense Float64, integer dosage, views, sparse input and declared backend cases; cold/warm timings and compiler inference on the actual package/environment. No GPU numerical agreement or speed claim from static dispatch. |

A valid comparison with ASReml or another engine needs the same data/model/variance estimator, matching convergence targets and numerical results, hardware and thread counts, cold/warm timing, allocations and peak memory, failure denominators and setup/inference costs. No measured speed or large-population feasibility is established by this review.

## 7. Runtime checks and evidence limits

Two tiny deterministic, no-fit probe invocations completed within the announced under-one-minute estimate per invocation. Environment: candidate Manifest, Julia launch with `--startup-file=no --compiled-modules=no --project=.`, `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. No package resolution was run. Results recorded in section 5 are actual outputs, not simulation conclusions. They cover LOCO missing labels, derived variance/median overflow with representable reference values, probability-conversion endpoints, single-step knob reduction, residual-projector nonexchangeability and supplied-frequency column sums.

No full package suite, fit wrapper, optimizer, benchmark, GPU execution or calibration harness was run here. Existing tiny GLS, p-tail, single-step symmetry and metafounder mapping controls are retained as historical component evidence at their source/test pins. Algebra passed in those components was not recertified as performance, uncertainty or population-wide inference.

## 8. Outcome and next action

Source coverage gap: closed for `src/genomic.jl`, 1-2934 only. Whole-file source disposition: HOLD for G1-G5; G6 is a low-priority visible claim correction. G1 is independently repaired in scratch and awaiting post-freeze integration. G2 remains carried from the earlier review. G3-G4 are new bounded numeric findings. G5 can be fenced without a calibration campaign. Performance/conditioning debts remain separately recorded above.

After the freeze, the coordinator can integrate approved G1 and narrowly dispose G2-G6 by repairs or explicit supported-input/design fences. Preserve original HOLD/red evidence, register targeted controls where source changes occur, rehash changed source/tests, and require the relevant numerical/claims lenses for those changed spans. This review does not request another whole-file read or any large campaign. Overall E1 and the programme remain the parent's decision.

## 9. Graft use and tally

Graft map, two genomic skeleton calls and one source query preceded targeted source inspection. Cache refresh attempts were read only and denied `graft/.cache/.sync.lock` with EPERM; the returned current genomic anchors were checked against numbered source. Truncated source output was reread at the exact missing 2579-2666 range before finalization.

Visible reported savings: map 771,008; first skeleton 28,091; ask 109,473. Total **908,572 estimated tokens saved**. The second skeleton was piped through `tail`, which omitted its savings line, so no additional amount is imputed for that call. These are Graft's whole-file baseline estimates, not actual context token accounting or a runtime measurement.

## 10. Memory provenance

The memory registry quick pass used `MEMORY.md:584-608` to recall the Gaussian/performance-claim boundary and then verified current source and repo receipts. It did not supply current release or capability status. Historical rollout ID: `01a07dd1-a2d3-71c2-811e-7c5749fd8712`. Current findings derive from pinned repo bytes and the tiny probes above.

## 11. Review boundary

This is a complete current file review with disjoint source accounting, not a global E1 signoff. No source is optimised. No capability, covered count, release, tag, R activation, GPU execution or live calibration claim is added. The owner's frozen source and FA run are preserved.
