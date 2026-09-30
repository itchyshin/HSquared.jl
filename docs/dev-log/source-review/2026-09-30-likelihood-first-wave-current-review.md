# Likelihood first-wave exact-current source review

## 1. Goal

Read-only Gauss numerical engineer review, with Karpinski and Noether lenses, of current src/likelihood.jl lines 1-2398. Complete first-half source coverage and finding dispositions. Whole-file approval is not granted.

Candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`.

| Pin | Value |
|---|---|
| HEAD at review | `6271cfd58651e69cd27a64dcf02cb8960a29e260` |
| Frozen source tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| Current likelihood.jl, 4613 lines | `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30` |
| Historical baseline | `faed40182cdbba2bf69f3e8dff0c5054be2dd214` |
| Historical likelihood.jl, 4237 lines | `a94078f3ddd55e429e4468106f3e116b3d0ca7ab8b9292de878fcafd40d412c0` |

Verdict: first-half **coverage PASS, approval HOLD**. Whole-file coverage is **INCOMPLETE**: 2399-4613, 2215 lines, remains outside this wave. Inspected later dependencies do not convert that remainder into covered source.

## 2. Implemented

Only this report was created. No source or test was edited, and no fit, optimizer, simulation, GPU, remote compute, package-wide suite, commit, push, or contact occurred.

### Disjoint current coverage ledger

All endpoints are inclusive. Partition has 2398 lines, zero gaps, and zero overlaps.

| Current span | Lines | Contract examined |
|---|---:|---|
| 1-173 | 173 | Constructors, dense Gaussian ML/REML, and input domains |
| 174-269 | 96 | Sparse REML component, current control/contract attestation; approved algebra reused |
| 270-340 | 71 | Dense Gaussian fit wrapper and its input/failure contract |
| 341-412 | 72 | Sparse REML fitter component, current control/contract attestation |
| 413-445 | 33 | AI-REML and warm-start documentation |
| 446-665 | 220 | AI wrapper/diagnostics, stationarity, streamed-boundary trigger, final status |
| 666-1088 | 423 | Genomic boundary precheck, profile, classifier, representability, and catch boundary |
| 1089-1173 | 85 | REML projections, stable score helpers, stationarity and Newton fallback |
| 1174-1436 | 263 | Supplied MME/metafounder/repeatability and likelihood convention utilities |
| 1437-1645 | 209 | Dense two-effect fit, variance transform, ratio helper, finite differences |
| 1646-1943 | 298 | Two-effect interval, K-effect MME and dense objective/fitter |
| 1944-2147 | 204 | K-effect interval and covariance/standard-error wrappers |
| 2148-2366 | 219 | Covariance-derived ratios, summed interval, combined uncertainty |
| 2367-2398 | 32 | Sparse block assembler and workspace introduction |

The 174-269 and 341-412 components account for 168 lines. Their previously approved REML algebra is reused; current source control flow and findings are explicitly reattested. The other 2230 lines have current residual/delta disposition, including reused historical text. The ledger records source reading. Numerical approval follows the scoped finding dispositions.

### Historical byte mapping

The real Wave 1 baseline read examined 106-208,395-563,1302-1379,2094-2375 and later spans. It explicitly held the file and recorded missing regions. A deterministic whole-file SequenceMatcher with autojunk disabled maps 350 current first-half lines to byte-identical portions of those actually examined baseline spans. These intersections are subtracted from the historical delta inventory; their current surrounding contracts were checked. Baseline HOLD is not promoted to approval.

| Current byte-identical span | Examined baseline span | Lines |
|---|---|---:|
| 106-122 | 106-122 | 17 |
| 150-152 | 123-125 | 3 |
| 153-158 | 127-132 | 6 |
| 159-199 | 134-174 | 41 |
| 202-207 | 179-184 | 6 |
| 244-246 | 186-188 | 3 |
| 247-247 | 193-193 | 1 |
| 250-250 | 195-195 | 1 |
| 258-269 | 197-208 | 12 |
| 470-475 | 395-400 | 6 |
| 477-479 | 401-403 | 3 |
| 483-483 | 404-404 | 1 |
| 487-502 | 407-422 | 16 |
| 505-526 | 423-444 | 22 |
| 528-548 | 446-466 | 21 |
| 550-551 | 468-469 | 2 |
| 575-577 | 474-476 | 3 |
| 582-592 | 478-488 | 11 |
| 594-626 | 489-521 | 33 |
| 630-632 | 526-528 | 3 |
| 633-635 | 534-536 | 3 |
| 638-660 | 538-560 | 23 |
| 663-665 | 561-563 | 3 |
| 1567-1568 | 1302-1303 | 2 |
| 1570-1645 | 1304-1379 | 76 |
| 2367-2398 | 2094-2125 | 32 |

350 matched lines plus 2048 current lines needing direct residual/delta attestation equals 2398. These counts describe the same partition and are not added to the 168-line component count above. Function fragments are listed honestly; no claim of whole-function byte identity is made where later guards or formulas changed.

A search across all 93 reachable commits changing likelihood.jl did not recover complete blobs with the later dirty-source pins 19974d..., cd36e0..., 1c47fc..., or bb81d.... Consequently, those receipts supply their exact signed scope and mathematics, and current source inspection reattests their control placements. They are not claimed to be byte-identical full snapshots. The baseline faed401 blob is reproducible from Git.

## 3a. Decisions and Rejected Alternatives

### Objective contracts

Dense Gaussian 140-188 evaluates the profiled fixed-effect ML objective with `n*log(2pi)+log|V|+y'Py`, or REML with `(n-p)*log(2pi)+log|V|+log|X'V^-1X|+y'Py`. The method branch really distinguishes ML and REML. The residual quadratic is computed from fitted residuals rather than subtracting two large quadratic forms.

Sparse 228-269 uses the signed MME determinant identity and full Gaussian REML constant. Its residual-plus-prior quadratic preserves the previously repaired large-intercept behavior. The previous derivation and dense/hand-value cells are reused; no determinant proof or fitted optimum was repeated here.

Two/K-effect dense objectives 1442-1459 and 1817-1835 are REML with the same fixed-effect determinant and residual quadratic, omitting only `(n-p)*log(2pi)`. Metadata and comparable_loglik at 1375-1431 correctly provide the additive full-constant offset. This does not make REML values for different fixed-effect spaces comparable for arbitrary LRTs. The utility checks metadata presence rather than proving compatible data/model spaces.

### Reattested prior repairs

- W1-06 residual-form quadratic: present in sparse single-effect 252-257; inherited dense objective and profile residual forms remain present. Approval stays at the prior tested intercept-shift cells.
- W1-07 small-step stationarity: 578-584 requires both a small prior relative change and a dimensionless score at the evaluated point before setting converged=true. Scale-normalized Newton fallback remains at 1147-1161. The previous false-convergence finding is closed at this stated scope; exact-zero/KKT fitting is separate.
- W1-09 cancellation-aware scores: 547-570 switches the additive-boundary trace subtraction to the streamed score, with a 512-column work cap and boundary_score_unresolved refusal. 1104-1133 uses the full stacked projector and sparse precision solves. Prior independent math/point tests are reused; residual variance approaching zero and arbitrary-model timing remain unproved.
- Fixed precision validation/cache: 214-226 canonicalizes sparse precision; fit_sparse_reml caches its factor logdet once. Current ordinary callers pass a matching canonical spec, precision, and determinant. The internal helper still relies on their consistency.
- Genomic boundary amendments: exact profiled endpoint derivatives at 891-918, retained refined candidate, endpoint-adjacent strict improvement at 957-961, and representability checks at 701-709,996-999,1041-1043 remain in the current algorithm. Typed numerical catch at 1062-1071 preserves user/programming errors. Prior scoped repairs remain closed; the frozen July holdout does not validate the amended algorithm.
- boundary_tol: exact-current 1561-1565 validation is present and used by the uncertainty routes. Its current receipt and test hash match. Negative/NaN/Inf tolerance repair is closed; valid arbitrary classification thresholds do not fix the denominator inconsistency below.

Workspace pattern/precision repairs remain scoped to their prior component. To establish the covariance caller's ownership and input path, later dependency 2502-2584 was inspected: it creates a fresh local workspace, copies/converts inputs, checks finite y/X/Z, requires p<n, canonicalizes each finite SPD precision, and builds the stored-support union. The uncertainty call at 2079 does not retain/share this workspace across public calls. This dependency check does not clear the later workspace/AI wave.

## 4. Files Touched

Created only `/private/tmp/e1-likelihood-first-wave-current-review-20260930.md`. The source already appeared modified relative to Git at preflight; its frozen SHA remained unchanged. No foreign edits were reset or amended. Scope ownership covers this report.

## 5. Checks Run

Graft skeleton and precise objective/caller queries preceded source inspection. All truncated definitions relevant to this wave were expanded at their current spans. Tool-reported savings total 559436 tokens; these are Graft estimates, not runtime measurements. Cache refresh had EPERM; exact hashes and current coordinates supplied technical truth.

Lane preflight identified the primary/report lanes and historical handover/ref divergence; the parent explicitly owns this source-neutral review programme. No source-path ownership was claimed. route.py found no LOAD-FIRST manifest for the managed worktree. The memory quick pass supplied the global preflight-script fallback only; current repo receipts determine all numerical findings.

Static tests inspected: wave1_numerical_contracts; wave1_stationarity_contracts; sparse finite variance controls; workspace/input controls; genomic endpoint controls; post-fit covariance reuse/boundary controls; selected H7 scalar/multieffect registrations. No test campaign was rerun.

One deterministic direct-helper/supplied-MME probe was estimated below one minute before launch and exited 0. Julia 1.10.0, `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1`, compiled modules and startup disabled, candidate project, depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. It called no fitter, optimizer, or statistical mode. Outputs are recorded below.

| Receipt/test | Current SHA256 |
|---|---|
| 09-30 sparse REML component | `631408f98173544bf1ce90e535430f60ddb527cefa745fd15c2570f21e551fbc` |
| 09-29 optimizer covariance boundaries | `b34767c9457316ac8279cbe2233f7745d2f7a6a842b21cda56dbc83ebfcfabf6` |
| 09-27 Wave 1 report | `bead3d7ae94d4c65b8590893af327a64a5bc0b63dec5db97be24e27a367558e3` |
| 09-29 genomic classifier follow-up | `a7741a912157cd802943748887af6412bf996b078a17154f6454a6dcb50dbddb` |
| 09-29 endpoint underflow/ties source review | `491e9a70f4c3f7cfdf3b3414e24f9234873fef6173b8434805f18487742acb28` |
| 09-29 sparse multi-effect input review | `cea701fd028df73e27dcb22094d47c8e6d57c28cff167540456d9b7d5322104f` |
| 09-30 boundary tolerance after-task | `f39019982986ea2b8f03bd416303f32477487e62e288a260c8c018d92b762a03` |
| test_post_fit_uncertainty_reuse.jl | `e7b816f8636d0dd611fd684f5c2719a74aebd0d3bd3d0d57f366729738f91539` |
| wave1_stationarity_contracts.jl | `f1b44f60d4f1980df8c5e55a84f76b513d1b140baf539bd1debdca5440215743` |
| wave1_numerical_contracts.jl | `a15c456451fc9a3a2c5f3c9aca80a58efc53550ae364c390060fbe2ac32594b2` |
| test_sparse_reml_finite_variances.jl | `8a513c4f87d640ab89fe5364654a8a80ec82714864a4b3c06f20c343d1958bc2` |
| test_aireml_workspace_reuse.jl | `350e6498d9147742c2597a5cd9405b30a4c410e183fc873ff6dd385e17420856` |
| wave4_genomic_boundary_near_endpoint.jl | `702a2a34e9d893907ce5a8a5f02e8417e0c73f41eab008fcfc129e09e15c89cf` |
| model_spec.jl dependency | `d49de74e3990e18e73db37bab9b3019f46dcaa29c4f7102fc3f53fe60fa9f5fb` |
| iterative_solve.jl precision/rank helpers | `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132` |

## 6. Tests of the Tests

Existing tests prove p=0 sparse evaluation on a finite three-record fixture, matching fixed-precision caches, repeated workspace ordering, stored support stability, converted finite/SPD workspace inputs, stationarity point controls, endpoint signs/refusal, and the boundary_tol ingress repair. They do not validate all first-half input domains or provide broad near-boundary interval calibration.

The new probes use exact supplied matrices and analytic ratio derivatives, so a nonconverged statistical fit cannot explain the failures:

| Probe | Observed current result | Independent check |
|---|---|---|
| Repeated selection idx=[1,1], theta=[1,9], covariance=I2 | estimate=.2, SE=.08246211251235322 | If repetitions count in the numerator, gradient is [.18,-.02], SE=.18110770276274832. If idx is a set, estimate must be .1. Current output mixes these meanings. |
| Dropped component, theta=[2,1,3], info=I3, keep_num=1, boundary_tol=.2 | estimate=1/3, SE=.14422205101855956 | For the reported full-denominator ratio with component 2 held fixed, gradient over kept coordinates is [4,-2]/36; SE=.12422599874998833. Reduced-denominator ratio would instead have estimate=.4. |
| _reml_fd_information of -sum(theta.^2)/2, theta=[1,1] | fd_step=0 or NaN gives NaN diagonal; -1e-4 is accepted with finite near-unit diagonal | Invalid finite-difference controls are not classified before arithmetic. The negative-step numerical symmetry does not document a valid negative-step API. |
| two_effect_mme, n=2, X=ones, Z1=Z2=I2, Q1=diag(-1,1), Q2=I2, variances=(.1,.1,1), y=[1,2] | finite beta and first-effect values | Q1 is indefinite and cannot be a proper Gaussian relationship precision. A solvable LU system is insufficient. |
| gaussian_loglik, valid-shape X/Z/Q, y=[Inf,2], variances=(1,1) | GaussianLikelihoodResult with loglik=NaN and beta=[NaN] | animal_model_spec checks shape, not finite fitted-input values; the evaluator returns no failure classification. |

The first two are numerical contract counterexamples, not interval coverage estimates. Empty/noninteger selection and early malformed-variance exits were established from exact source, without expanding the probe campaign.

## 7a. Issue Ledger

| ID / priority | Exact-current finding and disposition |
|---|---|
| LH-01, P2: sparse final status/rank/boundary | OPEN from the signed sparse component. 369-386 rejects invalid decoded proposals and catches PosDefException, but returns a raw negative likelihood without isfinite mapping. 396-399 recomputes the final likelihood without validating its finiteness or decoded proposal. Convergence is only Optim.converged; no final score, Hessian, or boundary diagnostic exists. 199-212/228-244 require p<n but not full fixed rank. The p=0 control is present in the existing test at 6-31, so absence of a p=0 test is not carried. |
| LH-02, P2: scalar dense/AI fitted-input ingress | OPEN. Dense y/X/Z conversions 150-152 lack finite/rank checks; reproduced y=Inf returns NaN output. Dense Gaussian starts 294-301 only require positivity; objective exp/proposal and final result 305-330 lack finite failure mapping. Sparse canonical precision guards do not validate y/X/Z or rank. AI 489-502 likewise builds cross-products without those checks. model_spec 52-92 is structural; its validated-input prose does not close numeric validity. |
| LH-03, P2: supplied MME numeric/model domain | OPEN. henderson_mme 1174-1197 and _sparse_mme_system dependency 4258-4279 only use positivity/conversion and a generic linear solve. two_effect_mme 1246-1308 and multi_effect_mme 1746-1810 check shapes/positive inputs but not finite converted variances/reciprocals, finite y/X/Z, full fixed rank, or canonical SPD precision. Reproduced indefinite Q returns finite output. repeatability_mme inherits that contract; metafounder wrapper delegates through the same supplied solver. |
| LH-04, P2: two/K-effect dense model ingress | OPEN. 1510-1515/1892-1895 invert a Symmetric view of raw precision without validating finite/symmetry/SPD; indefinite random covariance can be masked by a positive residual covariance. Numeric y/X/Z, p<n/rank, iterations, and converted starts are not uniformly guarded. The optimizer-boundary repair at 1516-1534/1909-1925 remains effective but does not validate the model domain. fit_multi_effect_reml 1931-1932 also collects ids without validating per-effect lengths/uniqueness, unlike its supplied MME sibling. |
| LH-05, P2: repeated/noninteger/empty which | OPEN. 2229-2232 and 2333-2335 permit duplicate selectors; helper 2173-2177 counts duplicates in the numerator but uses set membership in the gradient. Numerical counterexample above. Fractional index values can pass range tests and fail during indexing. The combined route accepts an empty idx and returns a zero-ratio rail result after computing covariance; standalone 2230 rejects emptiness, contradicting their claimed matching argument contract. Require a declared nonempty unique integer selection or a consistent multiplicity model. |
| LH-06, P2: estimate/gradient denominator mismatch | OPEN. _ratio_delta_ci 1570-1600 estimates using total=sum(theta), then differentiates with subtotal over kept components. The mismatch is small only when dropped values are actually negligible. It is reproduced for an accepted finite boundary_tol=.2. Define one estimand and use its denominator for estimate and derivative; near-zero conditional subblock approval does not justify arbitrary-threshold model changes. |
| LH-07, P2: uncertainty input/failure classification | OPEN. _reml_fd_information 1633-1645 and public dense interval entries do not require finite positive fd_step before fitting/arithmetic. Covariance 2059-2075 checks positivity and a near-zero FD condition without original/converted finite variance controls or finite-positive fd_step. Sum interval 2233-2240 can return a boundary row for NaN/Inf/invalid totals before reaching covariance validation. Require invalid-input errors to be distinguished from unavailable boundary information. |
| LH-08, P2: unconverged uncertainty and failed-point diagnostics | OPEN. two_effect_ratio_interval 1696-1720 and multi_effect_ratio_interval 2010-2038 calculate information and intervals even when the fit is unconverged, returning the flag afterward. The visible convergence flag mitigates silent use; these calculations are conditional quantities at the supplied returned point, and the documentation should state their usability when convergence failed. No uncertainty failure or coverage counterexample from an unconverged fit was reproduced in this wave. AI converged=true is now evaluated-point guarded, but an iteration-limit exit after 632 returns updated variances with score fields from the prior point. The latter is a failed-fit diagnostic provenance issue, not recurrence of the repaired converged=true bug. |
| LH-09, lower priority: documentation/model wording | AI help 429-433 claims average information matches observed information; average information is not generally observed information. Current 591 is the usual half working-variate quadratic. K-effect MME help 1736 writes covariance blocks A_i/sigma_i where the precision should be Ainv_i/sigma_i. Dense K-fit prose 1860-1864 says a nonidentified ridge shows converged=false; Optim.converged alone does not certify identifiability. These need precise wording and remain separate from confirmed formula bugs. |

### Accepted repairs and numerical limits

- Sparse standalone variance ingress and finite converted starts, canonical precision, and cached determinant are accepted at the current control placements. The prior finite-input finding is closed only for those fields; LH-01/02 remain open.
- Two/K-effect invalid transformed optimizer proposals, finite minimum/final decoded variances, and finite total checks from the optimizer-covariance receipt are reattested. Missing numeric/model ingress is separate.
- AI W1-07 and bounded W1-09 repairs remain accepted. Finite-step plus finite-old-variance addition can still overflow at 607-608; positivity-only halving does not reject positive infinity. The static source identifies this extreme-input risk; an actual-fit failure was not reproduced in this wave. Final sparse validation can throw rather than return the documented finite failed-fit result.
- Genomic endpoint/provenance/representability/catch amendments remain scoped PASS. No broad upper-endpoint, near-singular, tiny-response, or matched R calibration transfer is made.
- Post-fit covariance reuse/FD upper-triangle hoist remains value preserving on the prior tested valid points. Reuse does not repair LH-05/06/07/08.

## 8. Consistency Audit

Sparse caches are internally consistent on the ordinary caller path. _sparse_reml_loglik accepts Ainv/logdet separately while building C from spec; an inconsistent external/internal cache or mutated spec can change the model. AnimalModelSpec and AnimalModelFit retain caller array references, not immutable snapshots; original input/model matrices must remain unchanged for a fit and its follow-up quantities. This ownership limit was already identified by the model-spec review and is not silently converted into thread-safe mutation support.

The covariance path creates a private workspace per call, reusing its own symbolic factor only among FD points for fixed data. That resolves the examined public-call state ownership question. Thread sharing of a mutable internal workspace, factor recovery and later fitter state are assigned to 2399-2999.

Dense Gaussian guards total n/q cells before inversion. Dense K-effect checks n*n only while also forming every dense relationship inverse; large q can exceed the apparent response-covariance ceiling. Two-effect dense fit has no size-cap keyword. Sparse fill, repeated inverse/precision solves in boundary scoring, fixed-design dense conversion in scalar AI, and sampled FD cancellation remain scale/numerical debts. No allocation or fill benchmark was run, and these validation-scale routes are not promoted to production scale.

## 9. What Did Not Go Smoothly

Later component pins referred to dirty snapshots absent from Git's reachable source history. This report therefore separates reproducible baseline byte mapping from fresh current component reattestation and mathematical reuse. Graft cache permissions prevented refresh; current coordinates/hash checks remained reliable. Some broad tool outputs were truncated, so the affected definitions were reread in bounded ranges before closing coverage.

## 10. Known Residuals

This work does NOT cover source 2399-4613 as a complete numerical review, package-wide E1, whole-file likelihood approval, post-freeze integration, FA or GLLVM acceptance, unusual inheritance, GPU/device behavior, remote scale, release readiness, or public capability activation. Supplied MME solves are not variance estimation; a finite linear solve is not a valid random-effect precision or calibrated inference.

Next wave remains: workspace/AI 2399-2999; direct-maternal/repeatability 3000-3445; dispatch/extractors/PEV 3446-3810; information/profile 3811-4069; plots/payload/coercion 4070-4257; MME/PEV/selected inverse 4258-4516; bootstrap 4517-4613. Dependency reads cited above do not close those scopes.

Existing signed tiny/interior objective checks and numerical repairs remain conditional on their represented models. Near-boundary Hessian/ratio behavior, singular designs, model identifiability, and large-sample approximations need their own evidence. No campaign is requested from this read-only slice.

## 11. Team Learning

A common covariance matrix does not ensure a common estimand: selector multiplicity and denominator filtering must agree between the reported estimate and its gradient. Input rejection, numerical unavailable information, and statistical nonconvergence need distinct contracts. Signed algebra and exact source coverage are different statuses.

Memory receipt: the local memory registry supplied the preflight-path fallback only; source, current hashes, Git baseline mapping, repo receipts, test source, and direct probes establish all numerical claims. No memory files were edited. Golden Set: full inclusive first-half partition; historical byte mapping; sparse variance/cache/rank status; AI stationarity; genomic endpoint refusal; supplied indefinite precision; nonfinite response; duplicate selector gradient; boundary-filtered denominator; FD control classification; covariance ownership and valid-control reuse.

## 12. Cross Product Coverage

Current 1-2398 has complete source disposition with zero coverage gaps. First-half approval remains HOLD for the concrete findings above. No full-file PASS, whole E1 signoff, broader-order recovery, near-boundary calibration, or performance claim follows.

Next parent action: retain this exact first-half pin/ledger, assign the unreviewed remainder, and select isolated fixes for the confirmed input/uncertainty contracts. Re-review any changed likelihood source under a new pin; the existing frozen reviews are not substitutes for that check.
