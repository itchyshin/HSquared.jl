# Iterative finite contracts: independent review, 2026-09-30

## 1. Goal

Independently review the isolated I1–I4 iterative numerical repair prepared by Astra. Reviewer is the actual Gauss child at Sol high, separate from the proposal author. Bounded repair verdict: PASS. No new blocker was found in the changed finite-input, finite-output, ratio or probe-summary contracts. Full programme and inference approval remain outside this verdict.

The original source is `a4adfe04fe736fd55039b329d9d1d1fa4083b02478dc33c60181c7c453c42132`, 1,408 lines. The reviewed proposed source is `91317fe23ab913767b3f4ed44f74b69b9d5e0f5a5ce46fa09ed442047f361769`, 1,467 lines. The exact patch is `04e0e3e903a073632e0f286376e48cc34ae013a24ef42e2e6721f7040a859943`. Proposal root: `/private/tmp/hsq-iterative-finite-contracts-fix-20260930/`.

## 2. Implemented

This review changed no proposed or live engine source. Read the complete unified patch, frozen symbolic contracts, author red/green evidence, current whole-file read-only receipt, affected current source bodies and tests. Verified all 38 author inventory pins, independently copied the execution snapshot and ran its focused tests. Added deterministic numerical challenges in the separately owned review scratch root.

The exact a4ad full-file receipt `/private/tmp/e1-iterative-complete-current-review-20260930.md`, SHA256 `ae8514b075f36fbee3a9044184757bd73238c8743ac230cf557c9a2fccbf4448`, establishes the inherited coverage. Its conditional MME, trace, SLQ and AI algebra was reused. The new patch's arithmetic checks were reviewed directly; determinant or REML proofs were not repeated.

Disjoint proposed-source ledger, accounting for 1–1467 once:

| Inclusive span | Review disposition |
| --- | --- |
| 1–12 | Existing solver preamble; unchanged |
| 13–60 | PCG range guards and true final residual; direct review |
| 61–94 | Original/converted finite-data helper, finite-result helper and scaled probe summary; direct review |
| 95–114 | Downstream convergence and sparse QR rank contracts; unchanged bodies |
| 115–229 | IC(0), scalar operators, variance/diagonal controls and docs; reused exact baseline bodies |
| 230–316 | Single supplied PCG finite ingress, both execution paths and returned diagnostics; direct review |
| 317–426 | Multi operators and canonical precision/SPD checks; unchanged bodies |
| 427–612 | Multi supplied PCG finite ingress, assembly, preconditioners and output; direct review |
| 613–773 | Both probe routes and scaled mean/MCSE dispatch; direct review |
| 774–924 | Fixed-point fit, scaled ratios/boundary flags, retained-state/final-trace logic; direct review |
| 925–1010 | Unchanged Lanczos body and revised SLQ failure docs; reattestation |
| 1011–1144 | Likelihood finite ingress, joint quadratic, SLQ failure and finite final result; direct review |
| 1145–1249 | Average-information ingress and finite final matrix; direct review |
| 1250–1467 | Existing ratio/single-fit/router wrappers; unchanged bodies and guarded delegate edges reattested |

This ledger combines the exact baseline full read with complete patch/delta inspection and the stated current-body checks. It records source coverage. The PASS verdict concerns the bounded I1–I4 repair; it does not recertify neighbouring likelihood ratio helpers or the wider statistical inference contract.

## 3a. Decisions and Rejected Alternatives

I1: finite original arrays and finite Float64 conversion must precede products, because sparse structural zeros can hide invalid response values from the right-hand side. Both assembled and matrix-free single solves now share this entry check. Multi solves, traces, fit, likelihood and information use the same helper; ratio/single-fit wrappers inherit it through their delegates.

I2: positive PCG inner products, steps and arithmetic must be representable in the supported Float64 computation. Public consumers still require the true returned residual to meet tolerance. A successful zero-rhs solve remains supported. Finite unconverged standalone iterates remain inspectable. Likelihood/AI results that overflow must fail explicitly, even when all individual solves reached tolerance. SLQ failure now throws a documented ArgumentError; a numerical unavailable likelihood is no longer returned for that failure.

I3: with s=max(components), r_i=(theta_i/s)/sum(theta/s). The random-effect ratios include residual variance in that denominator. All components are finite and positive before this transformation, and at least one scaled term equals one. The computed finite ratios now determine boundary flags. The reproduced oversized-total case gives .625.

I4: scaling finite trace samples preserves their mean and sample standard error, with denominator n−1 and the final division by n. The one-probe standard error stays undefined. Signed and subnormal independent controls verify the consumed arithmetic; no arbitrary-relative-accuracy guarantee follows when cancellations or underflow dominate.

Explicit range refusal is appropriate within the documented partial engine contract. Full PCG/logdet/quadratic rescaling would be a broader algorithm change and is outside this packet.

## 4. Files Touched

Owned report: `/private/tmp/e1-iterative-finite-independent-review-20260930.md`. Owned copy, tests and evidence: `/private/tmp/e1-iterative-finite-independent-probes-20260930/`. The author proposal, candidate source, registered tests/runner, Git state, primary driver and sibling repo were unchanged by this reviewer.

Review evidence pins:

| Artifact in owned probe root | SHA256 |
| --- | --- |
| First independent log | `0aa188c9b26265d9c60428f3628fabc7b36c7c6f165dc78443f0ce8c556d72ae` |
| Final challenge log | `8180a651b1038ef474a9cb2145aae457e053abf4b5f113ac9af8107099b3132b` |
| Final challenge source | `b5a8bfbfce223fd32a50a28eeba8dbad92beecb71c5bb87dc4886aeefec498bf` |
| Packaging/body verification | `7a4eeb0ada06980ab14a2ee3a43250f2e875d1407fbaa147c1e6969e3aafff16` |

`SHA256SUMS` retains all copied execution source, dependency, test, log and verification pins, excluding itself and the redundant patch-application copy. Both run JSON receipts retain the exact command, timeout, exit status and elapsed time.

## 5. Checks Run

Estimated the first tiny focused rerun and challenges under two minutes; estimated the corrected challenge rerun under one minute. First run finished in 39.61 seconds, final challenge run in 21.71 seconds. Julia 1.10.0, compiled modules and startup disabled, Julia threads=1 and BLAS threads=1, existing Project/Manifest and depot. No dependency resolution/update, package-wide suite, campaign, GPU or remote compute.

Independent first run on exact proposed source:

| Check | Result |
| --- | --- |
| Frozen primary iterative finite contracts | 105/105 |
| Author independent summary controls | 18/18 |
| Wave1 numerical contracts | 167/167 |
| Copied neighbouring testsets | 37/37 |
| Existing matrix-free integration pins | 22/22 |
| Newly written Gauss challenges, first fixture | 33 pass / 1 fail |

All 349 author green assertions reproduced. The sole challenge failure was the reviewer's SLQ fixture reaching the existing precision-norm guard earlier than intended. Its exact failed fixture/log are retained. Corrected challenges passed 34/34. Final distinct passing checks: 383, comprising the 349 supplied assertions and 34 independent challenges.

The Julia command uses `--compiled-modules=no --startup-file=no --project=package`, includes the copied test files and then the challenge file. Launch environment is `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. Python child timeouts were 110 and 60 seconds with kill/wait on expiry. Tiny fits are the already requested deterministic regression checks and one invalid-update challenge; no recovery or optimizer campaign was added.

Patch application to an isolated exact baseline reproduced the execution source byte for byte. Whole-function comparisons verified eight unchanged bodies: sparse rank, canonical precision, SPD validation, Lanczos, scalar/multi MME matvecs and scalar/multi diagonals. Their exact body hashes are retained in `verification.json`.

## 6. Tests of the Tests

The author's frozen original-source test has SHA256 `63c1a90b9a30ab5336f2033881dc92ff7e0ab46251eee6b7571dcfa6885550c0`; retained baseline red reports 58 pass/47 fail. This review reran the proposed-source check rather than repeating the already retained baseline reproduction. Original failures distinguish response hiding, unsupported final likelihood/information, overflowed trace accumulation and fitted ratios. Converted-design cases that already rejected indirectly are correctly identified as consistency checks in the author receipt.

Fresh challenges independently check PCG norm overflow, inner-product underflow, nonfinite preconditioner/operator products, exact zero-rhs return and the true residual at a finite one-iteration point. BigFloat summary oracles use zero absolute tolerance for subnormal values and a relative tolerance for large signed values, strengthening the supplied summary controls whose generic absolute tolerance is loose at subnormal scale.

For an invalid zero-residual fixed-point update, y=[1,1], X=ones(2,1), Z=0, Q=[1], initial components=[2,3]. The result retains those components with converged=false, beta=[1], the current solved effects/IDs, trace metadata at the returned components, ratios=.4 and zero trace MCSE. Disabled likelihood fields retain NaN. A separate one-probe likelihood remains finite with undefined MCSE.

The corrected failed-SLQ fixture has finite SPD Q=[.8e308 .6e308; .6e308 .8e308], additive variance .5, finite diagonal and zero rhs. Q's norm is representable. A deterministic same-sign probe makes its current scaled operator arithmetic overflow; the public evaluator rejects with the SLQ ArgumentError. This checks failure dispatch within the accepted range-refusal contract.

Golden Set: zero-incidence analytic likelihood/AI, hand-assembled Henderson reference, finite starved PCG residual, exact invalid-update returned state, huge/subnormal summary oracle and all 349 supplied focused assertions.

## 7a. Issue Ledger

| Finding | Independent disposition |
| --- | --- |
| I1 finite input hiding | PASS for the proposed ingress repair; explicit original and converted array checks precede products |
| I2 nonfinite solver/likelihood/AI result | PASS for range refusal and finite reported results; documented SLQ failure now throws |
| I3 overflowing total and wrong ratios | PASS for scaled ratio and matching boundary flags |
| I4 overflowed trace mean/MCSE | PASS for both trace modes and shared SLQ summary helper |
| Invalid update state | Retained coherent previous components with false convergence and freshly evaluated effects/trace metadata |
| Rich failure provenance | CARRIED: fit result has no distinct failure-reason field |
| Arbitrary range, conditioning, forward error and calibration | CARRIED within the partial capability contract |

No new source defect in the changed packet requires revision before parent composition. The original a4ad report remains a truthful HOLD assessment of its old bytes; parent may close I1–I4 only after integrating the independently reviewed patch and exercising the composed focused checks.

## 8. Consistency Audit

The shared sparse QR and precision helpers are byte-identical to the bodies reused by the separate likelihood-input packet. No new dense conversion, solver target or stochastic estimator is introduced. Finite guards add linear scans to existing vectors/data; this is no benchmark or arbitrary sparse-fill guarantee.

All affected original/converted data sites use the helper. Expected intentional NaNs are limited to disabled likelihood and one-probe MCSE. Finite unsupported likelihood/information arithmetic cannot be promoted by a converged inner solve or zero MCSE. Final ratios and boundary flags consume the same normalized values. Final effects and traces are evaluated at the returned variance components after both accepted and rejected updates.

The ratio-gradient helper in likelihood, uncertainty/calibration interpretation and single-wrapper diagnostic omissions remain under their existing dispositions. Iterative supplied ID validation retains its baseline length contract; this patch adds no new uniqueness guarantee. Parent owns composition with the separate input and inference helpers and any runner registration.

Memory receipt: inherited operating guidance for preflight and shared-checkout preservation was used; exact source/tests establish the numerical evidence. Graft skeleton/callers ran first. Its read-only cache-lock failure was retained as a tool limitation and exact source coordinates were used. Graft token-saving estimates for this review total 48,982.

## 9. What Did Not Go Smoothly

The first independent SLQ fixture used a finite SPD matrix with an unrepresentable infinity norm. Existing precision validation correctly rejected it before SLQ. The fixture was corrected to a representable prior norm and an unsupported scaled operator product; the intended public SLQ rejection then passed. The error was in the challenge design.

An isolated packaging check initially supplied an absolute Git `--directory`, which Git rejected before applying anything. The relative-directory check/application passed. The attempt is recorded in `verification-attempts.log`. Both runs and both challenge versions are retained; no failed evidence was deleted.

## 10. Known Residuals

This bounded PASS does NOT cover arbitrary dynamic-range support, ill-conditioned forward error, sparse fill/memory/performance, global or unique fixed-point convergence, biological recovery, stochastic coverage/calibration, public R bridge/schema, accelerator behavior, package-wide freshness or release readiness.

Finite inputs may still trigger a clear range error for mathematically representable quantities whose current intermediates overflow or underflow. PCG inner-product breakdown, finite underflow and near-collinear sparse rank classification remain contextual numerical limits. One-probe MCSE measures no uncertainty, and multi-probe MCSE excludes solver and Lanczos bias. No stationarity or closed-boundary inference proof follows from a finite optimizer/fixed-point stopping result.

The MC fitter retains the existing Boolean convergence flag and iteration count; an invalid update has no distinct reason field. Iterative effect IDs retain the prior length-only validation. Richer provenance and consistent metadata across adjacent routes can be reviewed separately without expanding this finite-arithmetic repair.

## 11. Team Learning

Use independent summary checks with zero absolute tolerance at subnormal scale. Test a failure branch with inputs that pass all earlier guards, then retain the failed fixture when that premise proves false. Pair finite guards with ordinary reference calculations and returned-state checks so refusal improvements preserve supported small-model behaviour.

## 12. Cross Product Coverage

Reviewed and independently exercised finite ingress at single/multi supplied solve, trace, MC fit, likelihood, AI and delegate wrappers; finite range refusal in PCG, likelihood and information; per-block/shared trace summaries; scaled fitted ratios/boundary flags; intentional NaN metadata and invalid-update state consistency. Full exact proposal coverage is reconciled with the inherited complete baseline review and this complete delta review.

Parent next action: compose only the reviewed repository-relative patch, register the two author regression files once, combine with the independently reviewed likelihood proposals and run the relevant composed checks. Preserve partial capability and inference limits. The author proposal remains isolated at the completion of this review.
