# E1 iterative solver exact-current complete review, 2026-09-30

## 1. Goal

Complete the remaining read-only source review of `src/iterative_solve.jl` in `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, preserving scoped earlier approvals and distinguishing actual defects from accepted partial-claim limits.

Exact source SHA-256: `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132`; 1,408 lines. Candidate HEAD before/after: `6271cfd58651e69cd27a64dcf02cb8960a29e260`. Reviewer: one actual Astra child, independent of the earlier component reviewers; no new subagents. Coverage PASS; whole-file source approval HOLD for I1-I4 below. No source was edited.

## 2. Implemented

Read-only review, exact-byte historical mapping, current guard/caller reattestation, bounded reproductions and this report. Fifteen disjoint inclusive spans account for all 1,408 lines exactly once:

| Current span | Contract and disposition |
| --- | --- |
| 1-55 | PCG recurrence, true residual and downstream convergence guard. Existing core identity retained; finite arithmetic breakdown limits carried. |
| 56-68 | Sparse QR full-column-rank guard; p=0 bypass correct. No new blocker for reuse by the likelihood repair. |
| 69-121 | IC(0) lower-pattern updates and single-effect matvec/diagonal. Exact historical bodies reused; finite-scale/shift limits carried. |
| 122-183 | Converted finite-positive parameter and diagonal guards; single-solve docs. Guard additions current and coherent. |
| 184-267 | Single-effect supplied-variance PCG ingress, assembled/matrix-free routes, preconditioners and output. I1 finite-response omission. |
| 268-302 | Multi-effect matvec/diagonal and precision preamble. Exact historical operator bodies reused. |
| 303-377 | Canonical sparse symmetry/SPD validation and multi-solve docs. Scoped prior approval reattested; factor-fill/resource limits preserved. |
| 378-561 | Public/internal multi PCG, dimensions/IDs, assembly and preconditioners; trace docs. I1 ingress and carried PCG range limits. |
| 562-724 | Public/internal per-block and shared trace estimators, sampling MCSE and fixed-point fit docs. Unbiased trace algebra retained under exact solves; I4 arithmetic overflow. |
| 725-870 | Monte Carlo fixed-point updates, final traces, final solve, ratios/metadata. Final-trace evaluation repair retained; I3 overflowed total. |
| 871-955 | Lanczos full reorthogonalization/breakdown and SLQ likelihood docs. Earlier finite-dimensional/small-scale repairs retained. |
| 956-1093 | Matrix-free likelihood/cache dispatch, determinant and joint residual/prior quadratic, SLQ MCSE; information docs. I1 response omission and I2 unchecked nonfinite final likelihood. |
| 1094-1210 | Average-information construction and ratio intervals. Re-solves consume checked residuals; I2 nonfinite final information; inherited likelihood ratio-gradient finding remains separate. |
| 1211-1363 | Single-effect wrapper/docs, exact optional likelihood and multi-effect router docs. Preserved opt-in scope and coefficient retention; coarse dispatch/fill limits carried. |
| 1364-1408 | Forced/automatic exact versus matrix-free dispatch. Threshold is a coarse heuristic, not a fill certificate. |

Partition asserted programmatically: 1,408 entries, no gaps, no overlaps.

### Historical subtraction and current reattestation

Wave1 baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214:src/iterative_solve.jl` has 1,151 lines, SHA-256 `007b57124f31fda413397aa2d9c69fd1d477b2caa6758fdc065c63105d9e8310`. Its signed Wave1 scope explicitly read all function bodies. Six entire current bodies are byte-identical to those historical bodies (100 lines): `_pcg_solve` 12-44, `_ichol0_factor` 69-96, `_mme_matvec` 104-111, `_mme_diag` 116-120, `_multi_mme_matvec` 268-282, `_multi_mme_diag` 287-297. These are reused proofs/contracts, not a claim that all numerical ranges passed. The other 1,308 lines received current inspection/reattestation, including prose and caller changes.

A search of all 24 Git-history blobs changing this file did not recover the intermediate dirty pins `265cfc8d...`, `56703c9e...`, `53433153...`, or `41f50393...`. Those receipts remain scoped historical evidence; this report does not manufacture complete old-source identity.

The exact signed boundary-tolerance artifact *was* recovered at `/private/tmp/hsq-fa-gllvm-doc-check/src/iterative_solve.jl`: SHA `91968ebd2b437b7abb570a82dd05e94742b108a69e0d7a65c23287c26be56a75`, 1,387 lines. Seventeen current function bodies (277 lines) match this artifact exactly, including QR rank, precision canonicalization/validation, converted variance controls, Lanczos, and `matrix_free_ratio_intervals`. Exact bytes corroborate the stated component scopes; the boundary-tolerance receipt alone does not approve all 277 lines numerically.

The full 91968-to-a4ad diff was read. Numerical changes are: the finite-positive MME diagonal helper applied in five routes; removal of the unnecessary p<n restriction from the supplied multi-effect solve (square full-rank X is valid for solving); and final-variance trace reevaluation plus its metadata in the fitter. Remaining changes are wording/comments/logging that distinguish fixed-point iteration, trace MCSE, and returned-estimate likelihood. The exact-current documentation follow-up attests those changes; the frozen current implementations are reattested here. The single-wrapper function delta from 91968 is its comment saying returned rather than converged estimate. The boundary validator call at 1203 is byte-identical and still precedes information work.

Current scoped function SHA-256 pins:

| Scope | SHA-256 |
| --- | --- |
| rank 56-61 | a2fd38cd6a4c5307434466af55170713ee7dff96f93a1d8e4ac4460905f5692b |
| finite diagonal 122-126 | ae79abb121fb5d04c0144a45bfa936c711190ef6b433864f4902a87110a2715d |
| canonical precision 303-320 | 24b0d5f18bf9e4a676da7b97c877ee0a514018e03fb3d80633c463b1197dc813 |
| SPD validation 324-334 | eb8c787bb567f859e7d690d4d18b967c4eea5b37c6fdb5244bab283a0bf3de87 |
| MC fit 725-864 | 70dbf2c947ee6d2f421e39cf0c9958de976770bb9cd434cc88ad7e5768f016b1 |
| likelihood public/internal 956-1079 | 7074a67fdfdcaf32fcf9641d856ea78b029856155a3bca0ed3e90c16642a9cba |
| ratio wrapper 1191-1209 | 8d784c4fa6b84185dde2fc231d6a1f07aa996a561b3ea10a44681299bd89157a |
| single fit wrapper 1267-1328 | 23dfab5700da1e06bda94c236df3fd8accf4e1a2b53ed5c9b4417f449bcbcfcd |

## 3a. Decisions and Rejected Alternatives

Reused signed MME, Hutchinson, SLQ and average-information algebra rather than repeating their derivations or campaigns. Conditional mathematical contracts: C is SPD for full-column-rank X and SPD priors; E[z z′]=I supplies trace unbiasedness for exact solves; AI=0.5 W′PW is deterministic average information, not observed information; its numerical implementation remains PCG-approximate. Shared probes alter covariance among trace estimates, not the expectation. A residual tolerance controls a backward error, not a universal forward-error bound.

The new probes target zero-design rows and representable scalar summaries. These distinguish missing input/output guards and intermediate overflow from statistical uncertainty. The only fit call is one fixed-point update with a one-dimensional random block and one deterministic-magnitude Rademacher probe, justified by a concrete total-overflow risk. No optimizer search or simulation was needed. The rank/precision helper reuse was communicated promptly to the parent, together with confirmed new defects.

## 4. Files Touched

Only this scratch report and the retained scratch stdout logs `/private/tmp/e1-iterative-current-probe-20260930.log` and `/private/tmp/e1-iterative-trace-range-probe-20260930.log`. Source, runner, registered tests, dependency metadata, Git index, commits, primary driver, R twin, and other workers' files remain untouched. Parent-announced genomic integrations are known unrelated movements; the iterative file stayed pinned.

## 5. Checks Run

Graft skeleton first, exact line reads, signed receipts, relevant registered test sections, all-ref source history, exact symbol comparisons, full 91968-to-a4ad diff and partition arithmetic. Runtime probes used Julia 1.10.0, compiled modules disabled, existing Project/Manifest, and depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. Julia threads and BLAS threads both measured 1. The tiny checks were bounded by the stated under-two-minute estimate; test bodies are subsecond. No dependency update/resolve. No package suite, benchmark, coverage study, GPU or remote work.

First runtime exited 0: ten independent ordinary controls passed in 0.7 s, plus printed reproductions of I1-I3. The controls check zero-incidence solutions, analytic Gaussian likelihood/information, duplicate/p=0/square fixed-rank cases, invalid/asymmetric priors, accepted symmetry canonicalization, and small-scale Lanczos exhaustion. These are independently derived tiny cases, not fitting/calibration evidence.

Second trace-only run exited 0: four ordinary deterministic trace controls passed (0.0 s test body). At additive variance 1.2e308, both shared and per-block routes returned ([Inf],[Inf]) although the exact trace is 1.2e308 and exact sample MCSE is zero. Total fresh ordinary controls: 14/14.

## 6. Tests of the Tests

No new implementation, so no repair red/green claim. Reproductions inspect current wrong behavior against explicit analytic quantities. All controls use X=zeros(2,0), Z=zeros(2,1), Q=[1] unless stated otherwise: beta is empty, u=0, P=I when variance components are one. Then AI=diag(0, sum(y²)/2) and ℓ=-0.5[2log(2π)+sum(y²)]. For a trace at arbitrary additive variance a, C=1/a and tr(Q C⁻¹)=a; both Rademacher signs give the same sample, hence sample MCSE is zero.

The one-update fit uses y=[1.2e154,0], initial [1.2e308,.8e308], iterations=1, nprobe=1, tol=.2. Its trace is analytically a; the additive update stays a, residual update is sum(y²)/2=7.2e307, and the true returned ratio is 1.2/(1.2+.72)=.625. The permissive tolerance is a legal accepted control used to make the arithmetic defect visible; convergence here is only the documented relative-change criterion. It is not an identifiability or biological recovery fixture.

## 7a. Issue Ledger

### I1, P2: nonfinite response can silently produce a converged solve

Single ingress 195-208 and multi ingress 422-474 convert y without checking finiteness. With p=0 and a zero Z row, sparse products do not read that response into rhs. For y=[NaN,0] and [Inf,0], both single-effect modes and the multi-effect public solve return `converged=true`, `relative_residual=0.0`, u=0. The zero-rhs return at 16 is mathematically correct for the constructed rhs, but does not validate the supplied statistical data. Require finite converted responses before products; use one clear ingress contract across consumers. X/Z also lack explicit finite checks, although current rank/finite-diagonal guards reject many malformed design cases; no silent nonfinite-design acceptance was demonstrated. This is the already-carried finite-ingress gap with a concrete acceptance reproduction. It is not a rank or SPD helper defect.

### I2, P2: nonfinite final likelihood and average information escape

At 1054-1078 the residual/prior identity correctly prevents subtractive cancellation, but its accumulation and final loglik lack finite checks. At 1165-1176 the final W′PW multiplication lacks a finite check. For finite y=[1e200,0] and unit components, all PCG solves have exactly zero rhs and converge; the returned information is `[0 0; 0 Inf]` and likelihood is `(-Inf,0.0)` (MCSE zero). The true magnitudes exceed Float64, so the remedy need not promise arbitrary-scale inference: reject with an explicit range error, or return an explicit documented unavailable status. A zero MCSE must not turn this into a usable finite likelihood/information result. Ordinary-scale control values match their analytic references.

### I3, P2: overflowing total gives wrong fitted ratios and boundary flags

At 829, total=sum(sigmas)+sigma_e2 is unchecked; 852 and 857 divide by it. The one-update reproduction returns finite components approximately `[1.2e308,7.2e307]`, `converged=true`, `ratios=[0.0]`, `boundary=[true]`; a BigFloat calculation gives `.6249999999999999`. This is an intermediate-overflow bug in a representable estimand. Scale the component sum/ratio or reject an unrepresentable total before producing these fields. This finding is separate from whether the fixed point is unique, identified or well calibrated.

### I4, P2: trace summary accumulation can overflow when the mean is representable

At 644-645, meanmcse computes sum(samples)/n and a direct sum of squared deviations. With p=0, Z=0, Q=[1], additive variance 1.2e308, residual variance 1 and nprobe=2, both shared and per-block paths return traces=[Inf], mcse=[Inf]. Each exact sample is 1.2e308 regardless of the sign, so the true mean is 1.2e308 with zero sample MCSE; summation overflows before division. Scale-safe accumulation or an explicit nonfinite-output failure is needed; statistical MCSE limitations do not explain an infinite estimate for a finite exact deterministic trace.

### Retained component dispositions

- W1-01: all consuming trace/fit/likelihood/information PCG paths still call the finite true-residual guard. Standalone solvers intentionally expose unconverged diagnostics. No discarded-inner-residual regression found.
- W1-10: Lanczos dimension cap, two-pass reorthogonalization, and scale-relative breakdown remain present; small-scale analytic control passes.
- W1-11: compute_loglik=false retains beta in GaussianLikelihoodResult; exact optional likelihood still evaluates the returned estimate independently of convergence flag.
- W1-12 and 09-29 controls: sparse precision canonicalization, positive-definiteness, converted finite variance/tolerance and finite reciprocal guards retained. Sparse factorization has fill cost; no dense conversion in those helpers.
- 09-30 rank: full-column-rank guard on intended public routes retained, and p=0 accepted; square full-rank X correctly accepted by a supplied-variance solve, while REML estimators require p<n.
- 09-30 diagonal/final-trace repair: finite-positive diagonal guards and final-variance trace metadata retained.
- Boundary-tolerance repair: current ratio wrapper/body and test pin match the recovered signed artifact. This does not close likelihood `_ratio_delta_ci` denominator/gradient issue LH06; that inherited helper is assigned to another repair lane.

## 8. Consistency Audit

C remains unassembled in the matrix-free operator paths, but supplied relationship precisions are sparsely factorized for validation/logdet. No new large-q memory guarantee follows. IC(0) keeps the existing lower pattern and its shift changes the preconditioner, not the target system. Input copies and validated-effect reuse are local to calls. Cached precision log determinants are internal and rely on the corresponding canonical matrices.

The stochastic fit description is now appropriately limited to a reproducible fixed-point map and relative changes, and trace MCSE explicitly excludes solver error and parameter uncertainty. The one-component wrapper still hides trace_mcse; documented use of the low-level fitter is the current route for that diagnostic. The general K=1 exact-dispatch assertion remains a coarse resource heuristic; high-fill custom priors and arbitrary memory budgets are not certified by K alone. These accepted partial-claim limitations are distinct from I1-I4.

## 9. What Did Not Go Smoothly

Graft refresh failed on the read-only cache lock; current source lines and hashes were used. One batched output truncated a source interval; the missing 457-516 span was reread explicitly. Historical dirty source hashes were absent from Git; a specifically named retained docs-build artifact recovered the signed 91968 pin and allowed direct byte comparison. No broader scratch-directory crawl or new campaign was needed.

## 10. Known Residuals

Severe conditioning, sparse QR near-collinear rank classification, finite extreme-scale PCG curvature/update breakdown, preconditioner reciprocal/shift range, factor fill, allocations, peak memory, type stability, forward error, SLQ truncation bias, shared-probe covariance, MC parameter uncertainty and calibration remain carried limits. The first probe and new findings do not reclassify all such debt as a source bug. PCG can still throw an imprecise nonpositive-curvature diagnostic for overflow/underflow, or return unconverged nonfinite iterates; downstream consumers check finite residuals but need the separate final-output checks above. No arbitrary-dynamic-range or broad production claim is made.

## 11. Team Learning

Memory receipt: this is the next bounded slice of the inherited parent programme, using its current reconciliation, scoped review receipts, routed lane policy and existing skill guidance. The prior registry/brain lookup was routing only; numerical conclusions use current source and direct controls. Golden Set: signed Wave1/component contracts, current wave1 numerical test sections, analytic no-incidence controls and exact historical function bodies. No historical package-suite result was relabeled a fresh whole-file approval.

A converged linear system can still be based on invalid data hidden by structural zeros. Finite component inputs do not imply finite totals, quadratic forms or Monte Carlo summaries. Those are arithmetic/input contracts, not calibration claims.

## 12. Cross-Product Coverage

Covers all current source lines in the iterative file, historical/dirty-pin reconciliation, the shared rank and sparse precision guards, supplied single/multi solves, trace/loglik/information construction, scalar ratio exposure and dispatcher semantics. This **does NOT cover** whole-package source approval, R bridge parity, full-suite freshness, arbitrary conditioning/range, performance or memory guarantees, biological recovery, calibrated uncertainty, GPU execution or release readiness. Whole-file source approval remains HOLD pending disposition of I1-I4; earlier scoped approvals retain their stated assumptions.

Dependency/test/receipt pins used:

| Artifact | SHA-256 |
| --- | --- |
| likelihood dependency | 90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30 |
| wave1 numerical tests | a15c456451fc9a3a2c5f3c9aca80a58efc53550ae364c390060fbe2ac32594b2 |
| matrix-free integration tests | decca8dccfdb244e8260f5bfacf1da5c05a10602a70b718ba4761ea514608282 |
| post-fit uncertainty tests | e7b816f8636d0dd611fd684f5c2719a74aebd0d3bd3d0d57f366729738f91539 |
| current documentation receipt | 0b59e77083746d5103c0a9f15df473c7dd41671ba1ae45c68ea414ec4ab44d5f |
| E1 rank/budget repair receipt | ce982fc243ab65c7bfa47b062285bebf80421910dd07f45b13205af96dd89495 |
| precision/control receipt | 25e38e08e24b17292aab0974b59a83fac42a01c2253887127d0450b8730c9d4e |
| Wave1 receipt | bead3d7ae94d4c65b8590893af327a64a5bc0b63dec5db97be24e27a367558e3 |

Graft estimated avoided reads this review: 15,925 tokens (tool estimate, not actual model-token usage).

Retained runtime-log pins: first `736d48d961825dc99e0fbe5ea93ad51bb92c3dd31b0b57fa139bc43d9a66fe24`; trace-only `9a348c4fb4c6660f806ab83f2eec270699c5633ab13fd20abfcf4d4f70e06f8d`.
