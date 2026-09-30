# E1 likelihood second-wave exact-current source review, 2026-09-30

## 1. Goal

Complete read-only source coverage of `src/likelihood.jl:2399-4613` at SHA-256 `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30` in `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`.

Second-wave coverage PASS, source approval HOLD. This receipt covers all 2,215 requested lines. Together with the accepted first-wave receipt it gives complete current-file coverage, 1-4613. Complete coverage does not approve the file: the first-wave defects and the remaining contracts below are open.

Reviewer: Gauss, one actual reviewer applying numerical, Julia storage, and equation/contract lenses. No independent Karpinski or Noether agent was spawned. No statistical fit, optimizer, simulation, benchmark, GPU work, or source edit occurred.

Candidate HEAD was `6271cfd58651e69cd27a64dcf02cb8960a29e260` before and after this slice. The parent announced source-neutral checkpoints and then applied 23 independently reviewed targets at 19:51:16 UTC, changing the source tree from `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` to `2ec4bdfe2d1ecc36a6cf73bbc834c9016fef2ffd960bae2d799038cc24c3685c`. `likelihood.jl` remained at the exact hash above. This known same-task movement does not invalidate this file review. Tests/dependencies were separately measured after that integration.

## 2. Implemented

Only this scratch receipt was written. All current bodies in the requested interval were read, including adjacent comments and documentation. Existing objective derivations, valid sparse identities, permutation proofs, and tests were reused with the limits of their signed receipts. The following is a disjoint inclusive partition, with no gaps or overlaps.

| Current lines | Examined contract and disposition |
| --- | --- |
| 2399-2584 | Workspace storage, support union, index maps, assembly, symbolic-factor reuse, converted finite inputs and canonical sparse SPD precision. Scoped existing input repair remains present. Full-rank fixed design and finite cross-product range remain open. |
| 2585-2692 | Sparse K-effect supplied likelihood and generic AI step. Full-constant REML identity and residual-plus-prior quadratic are preserved. Supplied finite/converted variance domain and nonfinite final output remain open. |
| 2693-2999 | Sparse K-effect AI fitting, EM warm start, starts/control validation, stationary evaluated point, streamed boundary scores, final result metadata. Scoped signed guards remain present; no boundary KKT or broad range approval. |
| 3000-3268 | Direct-maternal dense GLS/BLUP objective, log-Cholesky optimizer, final decode, delta/Fisher-z/Willham interval calculations. True REML up to the documented Gaussian constant; raw model input, scaling, information and status gaps remain. |
| 3269-3445 | Repeatability reduction, optimizer and interval. Reuses the two-independent-effect objective and signed parameter guards. Rank/precision/input and interval controls/convergence gaps remain. |
| 3446-3773 | Target coercion/dispatch and stored/result extractors through accuracy. Supplied MME remains a solve rather than estimation. Reused PEV alignment and finite denominator guards are incomplete. |
| 3774-3873 | Normal quantile, analytic average information, covariance/SE and h2 delta gradient. Average information is not the observed Hessian; current docstrings distinguish it. Inference uses an unchecked inversion and does not require convergence. |
| 3874-4048 | Profile nuisance searches, bisection, h2 and variance-component intervals. Finite-target/bracket/final-search checks are incomplete; numeric endpoints can conceal failed profile evaluations. |
| 4049-4183 | Plot-data inference fallback, EBV/PEV fields, legacy result payload. Current field shape is tested; broad catches and missing richer provenance are carried separately. |
| 4184-4369 | Initial/target/supplied coercions, raw dense covariance, sparse MME and cached cross-products, dense cell-count guard. MME finite/SPD defects extend first-wave LH03; cell-count multiplication can overflow. |
| 4370-4516 | Dense and selected-inverse PEV, method resolution, relative-pivot check, relationship diagonal and optional precomputed diagonal. Selected-inverse component repairs remain effective; dense paths retain input/resource limits. |
| 4517-4613 | Bootstrap usable-refit predicate, simulation construction, counted acceptance and percentile outputs. Historical convergence defect is closed at the current source; total-range/original-fit validation and broad failure classification remain. |

Partition arithmetic: 2,215 lines, endpoints 2399 and 4613, each current line counted exactly once.

### Historical coverage and exact deltas

Historical Wave1 baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214` contains 4,237 likelihood lines, SHA-256 `a94078f3ddd55e429e4468106f3e116b3d0ca7ab8b9292de878fcafd40d412c0`. Its actual examined spans are those listed in `docs/dev-log/source-review/2026-09-27-wave1.md`, with only those examined spans credited. Comparing line arrays with `SequenceMatcher(autojunk=False)` maps 768 requested current lines to byte-equal lines within those examined old spans. The remaining 1,447 current lines were residual/delta coverage in this slice. Equality of fragments, including isolated `end` lines, is not a whole-function approval; current control flow was read directly.

Mapped byte-equal reviewed current lines:

`2399-2508, 2510, 2513-2524, 2534-2548, 2552-2557, 2564-2572, 2574-2581, 2584-2619, 2628-2670, 2763-2772, 2776-2832, 2836-2866, 2869-2876, 2879-2890, 2895-2896, 2899-2926, 2932-2940, 2943, 2946-2957, 3674-3772, 3811-3872, 3928-3953, 3994-4013, 4259-4359, 4563-4595, 4597-4613`

Disjoint complement, newly covered or changed current lines:

`2509, 2511-2512, 2525-2533, 2549-2551, 2558-2563, 2573, 2582-2583, 2620-2627, 2671-2762, 2773-2775, 2833-2835, 2867-2868, 2877-2878, 2891-2894, 2897-2898, 2927-2931, 2941-2942, 2944-2945, 2958-3673, 3773-3810, 3873-3927, 3954-3993, 4014-4258, 4360-4562, 4596`

The current workspace/input guards reuse the signed 09-29 sparse multi-effect contracts receipt. Its full likelihood SHA `1c47fc86...` differs and was a dirty snapshot not recovered as an exact Git blob during the first-wave 93-commit source-history search. Its proof and scoped guard decisions are reused; exact-current source reattestation supports this receipt. The same limitation applies to the optimizer covariance-boundary receipt at `cd36e0...`.

The selected-inverse dependency is an exact match to the signed finite-range component: current `src/takahashi_selinv.jl` SHA `38a07e2e34da2f4a295e52e25b1f1d067a0b7e1b2893bdef8c73f1f78c704782`, test SHA `ac0cc9a8d371093c6aa8719ef612f794486db6e55c7470c01af800b5a7eb4a05`. No recurrence, determinant identity, Gaussian reduction, or general boundary proof was rederived.

## 3a. Decisions and Rejected Alternatives

- Keep statistical objectives and supported estimator choices unchanged. The scope is source review; fitting design remains with the parent.
- Reuse conditional signed algebra and component tests, while checking current guards and caller ownership directly.
- Run one deterministic direct probe for concrete remaining contract questions. No fitted fixture or optimizer was needed.
- Classify undocumented extreme-range arithmetic, malformed-input acceptance, provenance omissions, and uncalibrated inference separately. A small control passing does not establish general conditioning, boundary inference, or memory safety.
- Parent owns later repairs and integration. This child owns this report only and will not edit live likelihood source.

## 4. Files Touched

Written: `/private/tmp/e1-likelihood-second-wave-current-review-20260930.md` only. Source, tests, dependencies, primary driver, schema, package metadata, Git index, commits, remotes, and other agents' scratch directories were preserved.

Primary source and dependency/test inventory appears in section 12. First-wave receipt `/private/tmp/e1-likelihood-first-wave-current-review-20260930.md` SHA-256 `c7b69cc10def95c1c15992acc79fbb018e9ec5a18337b93af346d0ae30a0d705` is the accepted companion. It covers 1-2398 and remains approval HOLD.

## 5. Checks Run

Graft was queried first for the file skeleton and exact `_profile_root`, `reliability`, and `_bootstrap_usable_refit` callers. Source ranges were then opened as needed. Graft ambiguity over overloaded reliability prevents treating its caller list as exhaustive. The cached non-Gaussian line coordinates became stale after the announced integration; no numerical claim uses those coordinates. Exact likelihood coordinates and hashes were read from current files.

Static checks included the engine contract, Wave1 historical coverage, sparse multi-effect input receipt, optimizer boundary receipt, selected-inverse repair/factor/finite-range receipts, and workspace reuse report. Registered tests were read: workspace/input guard file, bootstrap convergence helper test, selected-inverse test, and bounded relevant sections of `test/runtests.jl` (dispatch, extractor/payload, PEV, information and profile controls). This did not rerun their historical full-suite results.

One local direct Julia check was estimated below one minute, including package startup, before launch. Julia 1.10.0, `--compiled-modules=no --startup-file=no`, `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, existing Project/Manifest, depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. Measured thread counts were both 1. Exit code 0; six ordinary controls passed, test body 0.2 seconds. No package update or resolve. Process startup wall time was not separately timed.

Exact retained output from the direct checks:

```text
Julia=1.10.0 JuliaThreads=1 BLASThreads=1
profile_NaN=1.0e-6
profile_bad_anchor=0.5000000000000284
profile_interior_NaN=0.5000000000000284
reversed_pev_rel=(ids = ["c", "b", "a"], values = [0.9, 0.5999999999999999, -0.19999999999999996])
aligned_expected_rel=[0.6, 0.6, 0.7]
negative_pev_rel=(ids = ["a", "b", "c"], values = [1.1, 0.5999999999999999, -0.19999999999999996])
nonfinite_pev_rel=(ids = ["a", "b", "c"], values = [-Inf, 0.5999999999999999, -0.19999999999999996])
huge_h2=0.0 expected=.6
huge_bootstrap_usable=true
supplied_Inf_loglik=-Inf beta=Float64[] us=[[1.0, 2.0, 3.0]]
dense_guard_overflow=-9223372036709301616
direct_maternal_correlation_arithmetic=0.0 expected=.5
payload_fields=(:variance_components, :heritability, :breeding_values, :fixed_effects, :random_effects, :loglik, :df, :nobs, :predictions, :prediction_error_variance, :reliability, :diagnostics, :converged)
payload_diagnostic_fields=(:converged, :optimizer_status, :iterations, :method, :dense_validation_path)
Test Summary: ordinary direct controls | Pass 6 Total 6 Time 0.2s
```

Reproduction definitions: `y=[1.,2.,3.]`, `X=ones(3,1)`, `Z=sparse(I,3,3)`, `Q=spdiagm(0=>[1.,2.,4.])`, IDs `["a","b","c"]`. Construct the valid spec, evaluate `gaussian_loglik(spec,1.,1.)`, then construct `AnimalModelFit` with those supplied variances, `converged=true`, status `constructed_nofit`, iterations 0. This fixture is explicitly a supplied-variance result container, not evidence of a converged statistical fit.

Profile inputs: constant NaN target, `(x->x+1,bound=1.,anchor=.5)`, and a target returning 1 at bound 1, -1 at anchor .5, NaN elsewhere. PEV inputs: reversed IDs `["c","b","a"]` with values `[.1,.2,.3]`, then spec-order values `[-.1,.2,.3]` and `[Inf,.2,.3]`. The reversed-ID denominator should be `[.25,.5,1.]`, matching the animals named in the result, rather than `[1.,.5,.25]`.

Huge h2 input: a directly constructed finite variance container `(sigma_a2=1.2e308,sigma_e2=.8e308)`; exact scale-safe ratio is .6. Supplied K-effect probe: zero fixed columns, `effects=[(Z,Z)]`, `sigmas=[Inf]`, residual variance 1. Dense cap probe: `_check_dense_validation_size(3037000500,0,1)`. Correlation probe evaluates the exact current scalar expression `5e307/sqrt(1e308*1e308)`; it establishes overflow in that expression; no extreme-scale fitted result was produced.

## 6. Tests of the Tests

The six ordinary direct controls checked roots at .3 and .7 for `10(x-.5)^2-.4`, legitimate all-negative target clamping, ordinary h2=.5, selected-inverse PEV agreement with an independent dense MME inverse, and rejection of an unconverged finite-positive bootstrap refit. These exercise the supported neighboring behavior while the counterexamples expose missing guards. These checks reproduce defects; implementation and red/green repair evidence remain pending.

Existing `test/runtests.jl:6607-6611` checks ordinary crossings and clamping, without nonfinite targets. `test/bootstrap_convergence_contract.jl:4-16` checks good, stalled, zero and NaN component cases. Its include is at current runtests line 11193. The workspace test include is at 11176, and selected-inverse test at 10. Historical workspace 51/51 and selected-inverse 33/33 results are reused only for their pinned component scope.

Coverage arithmetic and baseline equality mapping were computed rather than inferred from signatures. There are no missing second-wave lines and no inference approval hidden in the word coverage.

## 7a. Issue Ledger

### Existing finding dispositions

- W1-04 bootstrap convergence acceptance: CLOSED at this source. `_bootstrap_usable_refit:4517-4522` requires `fit.converged` before finite positive components, and the loop calls it at 4596. Attempted `n_boot` and surviving `n_converged` are both returned. The helper's convergence repair is not a bootstrap calibration claim.
- W1-06 large intercept quadratic cancellation: repaired measured cell retained. `_multi_reml_loglik!:2620-2628` uses actual fitted residual and prior quadratics; it does not subtract two large y-based quantities. Broader numerical scales remain conditional.
- W1-07 false convergence from tiny update: scoped repair retained. `fit_sparse_multi_effect_aireml:2888-2901` evaluates score at current variances and requires both prior update and stationary score. This is interior stationarity, not boundary KKT. Iteration-limit results remain `converged=false`.
- Sparse multi-effect control/input/canonical precision findings: scoped CLOSED. Current 2502-2540, 2773-2775, 2829-2835, 2859-2868, 2916-2927, 2940-2942 retain finite converted inputs, precision canonicalization, controls, finite starts/updates and total checks. Workspace finite input does not prove full rank or finite cross-products.
- Selected-inverse support/permutation/failed-factor/finite-range defects: CLOSED for the signed kernel component. Current dependency matches the final finite-range hash. `likelihood:4422-4428,4455-4482` additionally retains checked factorization and the relative pivot floor. This is no adversarial-conditioning or high-fill resource guarantee.
- Optimizer covariance/log-variance boundaries: scoped retained. Direct-maternal 3095-3116 and repeatability 3338-3358 still reject invalid decoded proposals/objectives and final parameters. This does not close raw model-input, initial metadata or every failed final solve.
- First-wave LH01-LH09: CARRIED. No source changed in this slice. Sparse final finite/rank/boundary status, model ingress, supplied precision, dense multi-effect input, selector multiplicity, ratio derivative mismatch, uncertainty controls, inference at unconverged fits, and numerical documentation gaps remain as recorded in the first-wave receipt. Second-wave examples below extend these, rather than retracting them.

### Current remaining contracts

LH10, P2, supplied K-effect finite variance/final output. At 2595-2601 and 2664-2667 positivity accepts `Inf`, and conversion does not check finite/strict-positive Float64 values or reciprocal range. The deterministic p=0 test returns `-Inf` likelihood and finite BLUPs for `sigmas=[Inf]`. `_multi_reml_loglik!` has no finite final likelihood/beta/us validation. Valid finite workspace inputs can also overflow cross-products or residual/prior accumulation. Fitter final loglik/beta/us at 2936-2955 are not separately checked, although the final total guard is retained. Require early variance-domain rejection and a clear nonfinite final-output failure. Do not claim an actual finite-input fit overflow was reproduced.

LH11, P2, profile failure converted to numeric endpoint. `_profile_root:3928-3938` neither validates finite target values nor confirms a negative anchor and valid bracket. `target(bound)>0 || return bound` sends NaN to a number; an interior NaN is classified as the positive side. Both were reproduced. Profile nuisance searches 3881-3922 return `-Optim.minimum` without finite/convergence/search-boundary checks. Gaussian interval wrappers use the supplied fitted ratio/component as the anchor and do not require a converged fit or independently establish the maximum. Nonfinite profile arithmetic can yield a numeric endpoint whose `*_clamped` flags are false, because the flags use `target(bound)<=0`. Existing documentation at 4037 calls a non-PD precision a clamped endpoint and says never a silent number; nonfinite profiles need an explicit unavailable/error contract. The shared root also serves non-Gaussian profile intervals; current line coordinates there changed during parent integration. Repair must coordinate that caller. General separation, non-Gaussian outer catches and calibration remain separate.

LH12, P2, reused PEV ID alignment/domain. `reliability(fit;pev=...):3719-3729` accepts arbitrary IDs/values and divides them by spec-order animal variances. Reversed IDs silently produce the wrong values. Negative PEV yields reliability >1, and infinite PEV yields -Inf. Length, exact ID order, finite nonnegative PEV and finite positive denominator should be checked or an explicit reorder applied. Both reliability overloads at 3719-3743 only require a positive denominator, accepting Inf caused by multiplication. The existing accuracy helper correctly rejects nonfinite/out-of-range reliability at 3762-3773; that neighboring guard does not protect reliability itself. Precomputed relationship diagonals remain caller-certified for consistency with Ainv, as documented in `model_spec:44-49`; that explicit convention is not a newly found bug.

LH13, P2, finite variance summaries overflow. `heritability:3647-3655` returns 0 for finite `(1.2e308,.8e308)` instead of .6 because the sum overflows. The same unchecked sum is used in bootstrap accepted ratio at 4597-4598; its current usable-refit predicate accepts those components. Direct-maternal correlation at 3120 and interval denominator at 3241 use `sqrt(sad*sam)`; valid finite diagonal/off-diagonal values can return 0 or overflow before taking the root. The expression counterexample establishes .0 versus .5. Ratio/delta squared totals at 3866-3873, 3249-3255 and 3419-3420 also need an explicit representability policy or scale-safe formulas. Ordinary mathematical estimands are unchanged; this review does not claim a fitted extreme-scale model remains otherwise valid.

LH14, P2, interval input and usable-fit status, extending LH07/LH08. Direct-maternal 3182-3219 and repeatability 3392-3426 do not require finite positive fd_step, converged source fit, or finite usable covariance/delta outputs. Direct-maternal distinguishes nonfinite Hessian from non-PD information, but can label invalid fd_step as a boundary failure; repeatability does not check Hessian finite separately and raw perturbation failures escape inconsistently. Repeatability 3426 returns no convergence/status field, while direct-maternal 3259 retains `fit.converged`. AnimalModelFit covariance 3837-3846 only checks method, then directly inverts the analytic AI matrix without finite/SPD/conditioning checks; SE helpers can therefore expose raw failures or mask negative delta variance via max. These are static guard/status gaps; no unconverged statistical fit or ill-conditioned inference campaign was run. Require clearly stated conditional calculation semantics or reject an unusable fit, and retain honest asymptotic/uncalibrated limits.

LH15, P2, direct-maternal/repeatability ingress and allocation, extending LH02-LH04. Direct-maternal 3064-3094 lacks finite y/X/Z, symmetry/SPD precision, fixed-design rank/p<n, iteration-budget and ID uniqueness checks. It checks only n squared before forming q squared inverse and `(2q)^2` Kronecker covariance; ids length is checked after optimization at 3118-3119. Initial G0 is tested through a Symmetric triangle view, without a material-symmetry/finite check. Unsupported initial metadata may fall through to defaults. Repeatability 3319-3337 checks structural shape, IDs length and the aggregate cap, but lacks finite y/X/Z/canonical SPD precision, fixed rank and post-Float64 start guard before logs. Signed decode/post-objective checks remain effective. Domain errors should occur before optimization/allocation; no statistical capabilities need changing.

LH16, low practical likelihood, integer cap overflow. `_check_dense_validation_size:4350-4363` multiplies machine integers without checked arithmetic. Direct call with nobs=3037000500,nanimals=0,cap=1 returns negative `dense_cells=-9223372036709301616`, bypassing the cap. Nonnegative count validation is also absent. This synthetic count helper case does not demonstrate a practical allocated model at that size. Checked/saturating integer products can repair the guard without altering valid models.

LH17, contract/provenance and failure-classification debt. Direct-maternal result 3121-3135 omits REML constant/convention metadata although its evaluator 3000-3015 omits the `(n-p)log(2pi)` term, while sparse multi-effect and repeatability expose convention fields. Cross-route raw likelihood comparison must remain fenced until direct-maternal metadata is explicit. Legacy `result_payload:4154-4183` omits target, supplied/estimated source and boundary diagnostics which the richer result/diagnostic routes can distinguish. Current exact payload field tests freeze that legacy shape: this is a compatibility/provenance limitation, not proof that a new field is already promised. Payload re-solves MME twice for breeding/fitted values and separately for PEV; valid reused PEV prevents a second PEV calculation, as documented. Returned ID/reference arrays and stored spec can alias caller state, so payloads are not immutable snapshots.

Plot-data 4078-4092 and bootstrap 4592-4602 use untyped catches, suppressing programmer errors and interrupts together with expected numerical failures. Plot-data may return point-only without reason; bootstrap retains attempted/surviving counts but no failure reason per replicate and accepts one usable replicate. Bootstrap also does not validate the original fit's convergence/finite parameters before simulating. This remains a visible experimental inference/failure-handling limitation. It is not closed by the bootstrap refit convergence repair. No public payload field expansion or bootstrap acceptance threshold is authorized by this receipt.

## 8. Consistency Audit

The Gaussian direct-maternal objective uses GLS residuals with `V=W*kron(G,A)*W'+sigma_e2*I` and the fixed-effect REML determinant. Repeatability reduces to the independent two-effect model. Sparse multi-effect retains the full-constant determinant identity and joint minimized residual/prior quadratic. All use true Gaussian REML on their intended fixed-effect space; adding/removing fixed effects does not make REML likelihood ratios interchangeable. This reuses earlier derivations and checks current branch labels without redoing the proofs.

The analytical single-animal uncertainty is average information. The multi-effect and direct-maternal/repeatability helpers use finite-difference observed information. Earlier 6.1% AI-versus-observed SE differences and finite-difference noise floors remain real estimator/curvature distinctions; these cannot be removed as mere performance optimizations.

Workspace lookup state is local: each fit/covariance call constructs its own mutable workspace. Stored support union includes structural zeros and cancellations before assembly; repeated assembly resets nzval and rhs. No global cross-call lookup ownership leak was found. Internal `_SparseMMECrossProducts` retains its Ainv argument and is not a public immutable cache; mutating that referenced matrix outside the intended call violates consistency. Sparse factor fill, streamed boundary work caps and dense AI working variates still impose resource costs. The phrase always memory-safe in the PEV prose is stronger than the measured high-fill evidence and should be narrowed. No speed, allocation or general production performance result follows here.

## 9. What Did Not Go Smoothly

Graft refresh hit EPERM on `.cache/.sync.lock`; cached likelihood coordinates were checked against the exact source. An unescaped `reliability(` graph grep was rejected as an invalid regex; known overloaded definitions and actual current source resolved the needed contract. No cache or graph was rewritten. One combined skill-read output was truncated; no status claim depends on the omitted prose. Existing Project/Manifest were preserved. Historical dirty source hashes could not be promoted to exact Git byte identity. Parent's announced integration changed runtests and neighboring source pins during the slice, while likelihood was remeasured unchanged.

## 10. Known Residuals

This review does NOT cover calibration, finite-sample coverage, arbitrary conditioning/dynamic range, all variance-boundary accuracy, general separation, non-Gaussian outer failure handling, high-fill peak memory, GPU execution, remote campaigns, release readiness, or widened R formula/family support. No response-scale GLLVM h2 route is activated. The documented supported bounded Poisson T3/K2 R route and Gaussian reductions are unchanged.

First-wave and second-wave defects remain HOLD. Component numerical approvals retain their original assumptions. Source completion supports the next repairs and independent signoff. Capability status remains unchanged.

## 11. Team Learning

A malformed-input guard can be correct for finiteness of each operand while missing finiteness of the derived total. Ordered ID/value pairs need the same order in reused denominators. An endpoint is a numeric result only when its target was evaluated successfully; NaN cannot be treated as evidence of a non-crossing profile.

Memory receipt: operational preflight/shared-checkout guidance was inherited from the first-wave rehydration. Numerical conclusions were established from the current source, exact receipts and direct checks. No private memory claim was used to approve a numerical contract, and no memory file was edited.

Golden Set: the frozen engine source, accepted first-wave receipt, current signed component receipts, registered normal-input tests, and the six direct no-fit controls. No known-truth biological recovery fixture was needed for these malformed-input and arithmetic checks.

## 12. Cross Product Coverage

| Product | Highest supported status from this slice |
| --- | --- |
| Likelihood second half, 2399-4613 | Complete exact-current source coverage; approval HOLD. |
| Likelihood full file, 1-4613 | Complete combined coverage at exact 90cc hash; approval HOLD, with LH01-LH17 carried/confirmed as classified above. |
| R bridge/schema/families | No change or new parity approval. Historical direct-maternal v2 paired-record mismatch is separate bridge debt, not repaired by this file read. |
| Numerical runtime | Direct helper/supplied-variance reproductions, six ordinary controls, exit 0, one-thread caps; no fitting. |
| Integration | Parent may assign narrow repairs and tests, then obtain independent review on resulting hashes. No commit/push/contact from this child. |

### Exact evidence inventory

| File | SHA-256 |
| --- | --- |
| `src/likelihood.jl` | `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30` |
| `src/iterative_solve.jl` | `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132` |
| `src/takahashi_selinv.jl` | `38a07e2e34da2f4a295e52e25b1f1d067a0b7e1b2893bdef8c73f1f78c704782` |
| `src/model_spec.jl` | `d49de74e3990e18e73db37bab9b3019f46dcaa29c4f7102fc3f53fe60fa9f5fb` |
| `test/bootstrap_convergence_contract.jl` | `ba4ae9c3dfa977dd156781102af708db4ca155ebb2adf6b79e4f6c81b2992df6` |
| `test/test_aireml_workspace_reuse.jl` | `350e6498d9147742c2597a5cd9405b30a4c410e183fc873ff6dd385e17420856` |
| `test/test_selinv_trace_contracts.jl` | `ac0cc9a8d371093c6aa8719ef612f794486db6e55c7470c01af800b5a7eb4a05` |
| `test/runtests.jl` | `4da75986ff69040a2c8353e743fd98c336c66848c8ccb8c4cc5ac6472fdbaa23` |
| `docs/dev-log/source-review/2026-09-29-sparse-multieffect-aireml-contracts.md` | `cea701fd028df73e27dcb22094d47c8e6d57c28cff167540456d9b7d5322104f` |
| `docs/dev-log/source-review/2026-09-29-optimizer-covariance-boundaries.md` | `b34767c9457316ac8279cbe2233f7745d2f7a6a842b21cda56dbc83ebfcfabf6` |
| `docs/dev-log/source-review/2026-09-29-selinv-finite-range.md` | `fcd50f1b06322843f1eae1f08bbd69263740ab511b65e90e58bbf7e1e3ad227b` |
| `docs/dev-log/source-review/2026-09-27-wave1.md` | `bead3d7ae94d4c65b8590893af327a64a5bc0b63dec5db97be24e27a367558e3` |

Graft token saving estimate this second-wave turn: 645,223 tokens (47,214 skeleton + 223,828 profile callers + 51,488 reliability callers + 51,787 bootstrap callers + 270,906 profile literal grep). These are tool estimates of avoided whole-file reads, not measured token usage.

Final receipt checks: partition and history-map assertions passed; exact likelihood source pin checked after probe and after report writing. Absolute-path prose check and em-dash check are recorded by the parent-facing completion message. No source approval, package/full-suite pass, calibration result, or broader gate closure is asserted.
