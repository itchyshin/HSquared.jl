# Non-Gaussian complete exact-current source review

Date: 2026-09-30. Reviewer: Gauss numerical lens. **Coverage PASS: current 1–1803, with no gaps or overlap. Approval HOLD.** The signed mathematical components retain their conditional approval; full-file, E1/wave, inference, and capability approval are withheld for the blockers below.

## 1. Goal

Complete the exact-current disposition of nongaussian.jl by reattesting the real historical full-file review and reviewing current residual contracts and deltas. Reuse the observed-curvature/integrated-Laplace and VA components, and Astra's flat-fixed-measure interpretation, without repeating their determinant or Gaussian-reduction proofs.

## 2. Implemented

Read-only review; only this scratch report was written. The candidate is `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, HEAD `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`. Current nongaussian.jl has 1803 lines and SHA-256 `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`. The whole-source tree remains `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`, using sorted src-relative path, NUL, bytes, NUL.

Historical bytes recovered with `git show faed40182cdbba2bf69f3e8dff0c5054be2dd214:src/nongaussian.jl` exactly reproduce the Wave 2 baseline: 1613 lines, SHA-256 `0999c6b9dd074b01e1273202bd822873d9ecec0b947916ec6788a9a2ad2554c3`. Line comparison with autojunk disabled finds 1533 identical lines and 270 current inserted/changed lines, replacing 80 historical lines. The net increase is 190. There is no independent appended tail: historical 1567–1613 maps unchanged to current 1757–1803.

### Disjoint inclusive current coverage partition

| Current lines | Count | Disposition method |
| --- | ---: | --- |
| 1–436 | 436 | Residual family/kernel contracts; baseline reattestation plus Poisson delta |
| 437–445 | 9 | Reuse exact signed observed-versus-working curvature component |
| 446–608 | 163 | Residual working/observed family kernels and count checks; unchanged bodies plus delta |
| 609–649 | 41 | Current necessary-integral guard and objective boundary; endpoints remain missing live |
| 650–721 | 72 | Current mode/input/backtracking contracts and inherited failure boundaries |
| 722–735 | 14 | Reuse exact signed integrated Laplace component |
| 736–767 | 32 | Expected Gaussian/Poisson kernels and fixed GH rule; baseline plus numerical delta |
| 768–822 | 55 | GH logit kernels/covariance fixed-point and residual documentation |
| 823–849 | 27 | Reuse exact signed VA objective/contract component |
| 850–890 | 41 | Current VA ingress and initialization |
| 891–918 | 28 | Reuse exact signed VA mean/covariance convergence component |
| 919–923 | 5 | Reattest inherited expected likelihood/KL assembly without rederivation |
| 924–949 | 26 | Reuse exact signed VA Schur/objective-label component |
| 950–973 | 24 | Typed-fit boundary documentation |
| 974–1245 | 272 | Fit/extractor/payload contracts; exact unchanged bodies plus documentation deltas |
| 1246–1472 | 227 | Current fitter/outer failure/restart contracts |
| 1473–1590 | 118 | Current profile prerequisites and scale/estimand documentation |
| 1591–1803 | 213 | Heritability transforms/extractors; unchanged algebra plus wording deltas |

Signed-span union: 437–445, 722–735, 823–849, 891–918, 924–949 = 104 lines. Residual current attestation = 1699 lines. Total = 1803. Signed reuse is component approval only, conditional on valid inputs, proper integrals, and the stated approximation. Coverage is not a count of approved lines.

### Exact unchanged body mappings

| Historical lines | Current lines | Byte-identical scope |
| --- | --- | --- |
| 49–215 | 49–215 | Family constructors/resolver after the edited binomial recovery prose |
| 515–563 | 559–607 | Scalar-family count checks |
| 644–674 | 760–790 | GH rule, expectation helper and logit expected kernels |
| 813–831 | 974–992 | NonGaussianFit and extractors |
| 866–880 | 1027–1041 | Generic result serializer |
| 899–987 | 1060–1148 | Private three-field serializer |
| 989–1010 | 1150–1171 | Three-field trial-count helper |
| 1572–1604 | 1762–1794 | Fit heritability extractor |
| 1606–1613 | 1796–1803 | Supplied-value heritability entry |

Every listed body/range comparison is true at the two pinned byte sets. Other unchanged spans were reattested through the complete line mapping and historical full read; changed blocks were checked against current source and signed receipts. The changed/current insertion ranges are:

47–48, 356–389, 442–444, 464–477, 553, 609–639, 654–656, 667, 669, 689–696, 700–719, 723, 745–757, 794, 797–801, 809–812, 814–815, 820–821, 823–828, 830–835, 837–851, 857–861, 864, 875, 877, 887, 891–893, 905, 913–915, 918, 924–929, 934–938, 942–943, 945–949, 1022–1023, 1179–1182, 1211–1213, 1215–1217, 1288, 1292–1295, 1439, 1473–1483, 1486–1487, 1495–1498, 1501, 1507–1508, 1513–1514, 1517–1519, 1524–1525, 1531, 1533, 1542–1549, 1554, 1628, 1648, 1675, 1750, 1755–1756.

## 3a. Decisions and Rejected Alternatives

Reuse the real historical full review as evidence of inspected unchanged code, while reclassifying its findings against current bytes. Do not inherit a historical HOLD as an assertion that each repaired component is still defective. Reuse the exact signed math as conditional evidence, without treating it as input-contract or serialization approval. Do not infer full-file approval from prepared isolated patches or a neighboring green suite.

No numerical fit was needed. Tiny no-fit checks resolve constructor, serializer, and transform behavior; logistic VA covariance stationarity remains carried from the exact component review.

## 4. Files Touched

Owned output: `/private/tmp/e1-nongaussian-complete-current-review-20260930.md` only. No source, tests, primary driver, Project/Manifest, existing reports, or other lane's files were changed. Parent retains the source freeze; the latest authorized HEAD advance is respected.

Exact receipt and test pins:

| File | SHA-256 |
| --- | --- |
| `docs/dev-log/source-review/2026-09-27-wave2.md` | `f5da5f1a5147d682d426f31e36b98f3fa8c121bda6bc21e9ddc6168874f1ad56` |
| `docs/dev-log/source-review/2026-09-29-nongaussian-and-payload-contracts.md` | `5d4bab1857f5056852dc38dd5fa1b9f1c77873690ac1d226e9011ca3aeff1dd1` |
| `docs/dev-log/source-review/2026-09-30-nongaussian-current-review.md` | `7dafa5ecbcce62161d73d38edf3528719294d8f90cdd5653af59281ae2ed33ac` |
| `docs/dev-log/source-review/2026-09-30-legacy-objective-labels-astra-review.md` | `9596579ebe5838d0d401ba63344ffd8f354e4c92bf35448241da08bd04ffe907` |
| `test/wave2_nongaussian_contracts.jl` | `c7a6cd8eba56cf54f4b0ffed629ba1b5a5dfbd5220f2d5d7d09e3ec1cebaad60` |
| `test/test_nongaussian_inner_convergence.jl` | `f405a75e14da1be035c9de29cc17accef4dbaedeeb740d0d96f7d44f401cb33c` |
| `test/a3_three_field.jl` | `e7a8b8a91e454055de94818d737f6f6849dfa27d6ed49bcb61052f372d8c0b1d` |
| `test/test_327_boundary_flag.jl` | `fdcac4a923488c40ebe9de950caad4a864b2eddfe8303b6cf29559d61198d3a6` |

## 5. Checks Run

Graft skeleton and precise caller queries preceded source reads. The nonexistent queried alias `laplace_result_payload` was replaced with the actual `nongaussian_result_payload`; no source symbol was invented. Caller ambiguity on overloaded heritability is acknowledged; the family and result contracts are established from exact source. Reported Graft context savings total 417,474 tokens.

A deterministic constructor/serializer/supplied-transform probe was estimated below one minute before launch and completed with exit 0. Julia 1.10.0; `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1`, depot `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`, pinned candidate project, startup disabled. No fit, optimizer, statistical mode, campaign, GPU, or package-wide suite ran. Probe results are recorded in section 7a; they are counterexamples to current contracts, not estimates from fitted data.

Current tests were inspected as source. Wave 2 tests cover observed final curvature, enumerated endpoint rejection, VA labels/reduction, effect IDs, and profile prerequisites. Inner-convergence tests distinguish a zero mean score from an unfinished covariance loop. A3 tests check the private three-field transport and deliberately keep the generic legacy payload separate. Boundary tests cover selected Poisson/Gamma/NB rail and restart cases; they do not check generic metadata transport or usability of a failed second-start fit. Existing low-level logit finite differences check mean derivatives; the finite-quadrature variance derivative remains unchecked.

## 6. Tests of the Tests

The no-fit objects deliberately carry `marginal=:variational`, `boundary=true`, and `restart_estimate=2.0`, so missing serialization fields cannot be hidden by default values. The private serializer rejects that boundary object, proving that its stronger guard does not repair the generic serializer. Scalar and constant-vector binomial fixtures differ only in their denominator representation. The Gaussian predictor-variance counterexample uses ordinary finite values. Family constructor checks isolate ingress and do not depend on convergence or numerical tail behavior.

## 7a. Issue Ledger

### Current approval blockers

| ID and severity | Exact current evidence and disposition |
| --- | --- |
| NG-01, P1: objective kind lost in serialization | VA exposes `objective` and `is_lower_bound` at 942–949; `val(r)` at 1290 chooses `r.elbo`, and NonGaussianFit at 974–987 has no fields for those declarations. Generic serializer 1027–1041 names the stored value `loglik`; the private envelope also names it `loglik` at 1136. Neither preserves objective kind/lower-bound status. A synthetic VA fit serializes method `variational`, loglik -12, with no objective_kind field. Older high-priority finding remains OPEN, even though the low-level labels are repaired. Full-covariance Gaussian VA remains the separately proven exact reduction. |
| NG-02, P2: generic boundary diagnostics dropped | NonGaussianFit 985–986 stores boundary/restart_estimate; generic serializer 1027–1041 omits both. The boundary=true, restart=2 probe confirms neither is present. Private three-field rejection at 1074–1080 is effective but does not close the generic contract. Older finding remains OPEN. |
| NG-03, P1: incomplete proper-integral gate | Helper 609–638 rejects the enumerated intercept endpoints, but current 620/628 omit NB all-zero and beta-binomial all-zero/all-success. General separation on other columns remains explicitly undiagnosed. The prepared two-condition isolated patch has 35 core assertions plus one cleanup assertion passing; its nongaussian SHA is c609b2a58de819ad8a96b74525895a92cd5f2b9517c080a5ec678ae348d87e9f. It is not live. W2-02 remains HOLD for current bytes and general designs. |
| NG-04, P2: malformed ingress lacks finite-after-conversion guards | Laplace 657–669 and VA 865–877 convert y/X/Z without uniform finite validation. Ainv is guarded. Gamma counts at 603–607 and outer check 1402–1404 accept positive infinity; the helper probe returns nothing for y=[Inf]. Constructors Gaussian 32–35, NB 85–88, Gamma 172–175 only check positivity before Float64 conversion. Probe accepts Inf for each. Ordered threshold constructor 151–156 admits singleton NaN and Inf because its ordering comparison is empty. Positive finite values can also underflow/overflow on Float64 conversion because resulting family fields are not rechecked. Outer starts 1299–1302,1323–1326,1352,1404–1405,1428 similarly lack a uniform finite ingress guard. Older finite/Gamma finding remains OPEN and includes the same neighboring constructor pattern. |
| NG-05, P2: outer numerical failure contract inconsistent | Gaussian 1306–1309 and NB 1327–1330 forward negative inner values directly to Optim without catches or finite/convergence mapping. Ordinal 1366–1375, Gamma 1406–1414, scalar 1430–1437 catch only SingularException/PosDefException/DomainError and use finite 1e12 penalties. A failed Laplace mode still forms final observed H and its Cholesky at 722–731 before returning NaN at 734; it can throw before returning diagnostics. VA covariance/mean updates remain undamped at 800–808,902–904. Restart 1465–1470 uses only the second variance estimate; second-fit convergence and boundary are not propagated into the usability check. OPEN; no claim about actual optimizer behavior from a new fit. |
| NG-06, P2: finite-quadrature logit VA covariance stationarity unverified | GH rule 763–765 fixes 20 nodes. Mean score/weight derivatives at 781–790 are internally consistent with that mean quadrature; the covariance update 802–808 uses expected curvature. The exact component review requires the finite-quadrature variance derivative/order sensitivity to be checked. Known numerical approval condition; no new runtime defect was reproduced. HOLD remains. |
| NG-07, P2: Gaussian predictor-variance convention unresolved | Public general denominator wording 1728–1749 admits fixed predictor variance, while Gaussian 1594–1601 ignores it. Probe VA=1,residual=1,predictor_variance=8 returns h2=.5,total=2. The result uses the conditional Gaussian ratio; choose and state the conditional convention and reject/exclude this keyword, or honor the population-total convention. W2-07 remains OPEN. |
| NG-08, P2: constant binomial trial vectors treated as varying | Fit extractor 1775–1781 returns observation h2=NaN for every vector. Scalar n=5 gives .5040211874317815; equivalent [5,5] gives NaN. Private envelope 1107–1129 already distinguishes constant vectors, proving the general extractor remains inconsistent. W2-07 remains OPEN. |
| NG-09, P2: supplied h2 inputs not validated | Entries 1766–1793,1796–1803 do not require finite/nonnegative VA or fixed predictor variance, finite mean, or valid stored family fields. Probe VA=-.5 gives Gaussian h2=-1; VA=Inf gives NaN; predictor_variance=-1 is accepted. W2-07 remains OPEN. |

NG-01/02/04 were recorded against the older dd3babb8... snapshot; their cited current bodies and fresh probes confirm that the later math review did not discharge them. The method token `variational` is present, but does not preserve the lower-level declaration of ELBO versus hybrid VA-Laplace versus exact Gaussian objective.

### Repaired components and adjacent limits

| Earlier item | Exact current disposition |
| --- | --- |
| W2-01, beta-binomial final determinant | Conditional PASS reused from exact component; working Fisher scoring remains distinct from observed final curvature. No proof repeated. |
| W2-03, precision consistency | Bounded PASS reattested at Laplace 667, VA 875, outer 1288 using the same validated PD precision. Dense coercion remains. |
| W2-05, lower-bound claim and covariance-loop status | Low-level objective labels and covariance convergence requirements are repaired in signed spans. NG-01 and NG-06 remain separate transport/numerical conditions. |
| W2-07, breeding-value IDs | Bounded repair reattested at 1291–1295 before Optim: length equals size(Z,2), IDs unique. This does not close the three inherited h2 findings. |
| W2-08, Laplace-profile prerequisites | Bounded repair reattested at 1531–1549 and 1473–1482: positive iterations, Laplace only, converged finite interior point fit, each finite converged profile evaluation. No interval calibration approval. |
| W2-10, large-count Poisson cancellation | Current numerical delta 356–387,745–757 matches the documented bounded deviance/Stirling correction and expected-likelihood repair. Existing 1e15-reference evidence is reused; arbitrary-scale accuracy/calibration is not inferred. |
| Legacy objective labels | Astra's exact review establishes the flat-fixed-effect integrated interpretation, conditional on existence and valid inputs. Historical REML names are retained API tokens; ordinary profiled ML and a universal lower bound require separate justification. |
| Direct VA unsupported families | Outer fitter explicitly fences Laplace-only NB/beta-binomial/probit/ordinal/Gamma routes. Direct VA expected kernels cover Gaussian/Poisson/logit Bernoulli/binomial. No new family support inferred from the abstract family signature. |
| Dense scaling and inference | Dense conversions and full inverse/covariance work are stated implementation limits. Sparse acceptance is not sparse performance. Boundary search, flat measure/design scale, conditional approximations, tail underflow, and cell-specific empirical coverage remain visible limits. |
| Documentation drift, lower priority | Container 958–960 omits beta-binomial trials despite actual storage at 1444. Generic payload enumeration 1005 omits ordered_probit/Gamma. Gamma family prose 168 calls joint shape estimation future work although outer 1392–1423 already jointly estimates shape; distinguish supplied family fields from estimated outer parameters. Ordinal h2 prose 1744–1745 still calls per-category transforms future work although 1650–1676 implements them. These wording errors are carried separately from algebra/calibration. |

## 8. Consistency Audit

The full historical source was really reviewed and its exact bytes are recovered here. Whole-function equivalence lets that read support current unchanged bodies; explicit delta review supports the changed contracts. Source tests at their pins and prepared scratch checks are kept distinct from a current full-suite run.

No current signed math receipt implies universal proper-integral approval, finite-input classification, generic transport safety, or consistent outer failure handling. No general source HOLD changes the separate bounded Poisson T=3,K=2 intercept route or valid Gaussian reduction; their prior receipts remain at their own exact scope. Supplied Ainv must be proper PD and aligned with Z/IDs; this file constructs no pedigree inverse. Current standalone varying-trial binomial dispatch uses _fam_record consistently and is distinct from the isolated GLLVM rejection fence.

## 9. What Did Not Go Smoothly

The initial caller query used an obsolete/nonexistent payload alias; querying the actual serializer resolved it. Some broad status/read output was truncated, so exact needed source ranges and hashes were used. No blocking condition or file ownership conflict prevented the read-only review. Historical divergent refs alone are not a permission gate.

## 10. Known Residuals

This report does NOT cover integration of prepared patches, consistent outer error handling, general separation detection, logistic finite-quadrature covariance stationarity, same-objective comparator parity, interval calibration, sparse scalability, broad R activation, family-wide recovery, primary-run acceptance, or GPU execution. Coverage PASS is solely source-review coverage at the exact pin. Approval remains HOLD with NG-01 through NG-09 carried as specified.

## 11. Team Learning

Recover the exact reviewed historical blob before reusing a full-file read. Record both unchanged function bodies and changed current ranges; line-count growth alone does not identify a new tail. Preserve the distinction between a mathematical component approval and complete ingress/result/failure contracts.

Memory receipt: a registry search returned no relevant historical review note; all technical evidence here comes from repository receipts, recovered source bytes, current source, and the no-fit probe. No memory was changed.

## 12. Cross-Product Coverage

Golden Set: historical/current byte equivalence; disjoint 1803-line coverage; signed components; nonfinite family constructors; Gamma infinite response guard; VA generic serializer metadata; private boundary refusal; Gaussian predictor variance; negative/nonfinite h2 inputs; scalar/constant-vector binomial parity.

Parent next action: add this full-coverage HOLD receipt to E1, keep the signed components conditional, and route narrow isolated repairs for objective/boundary transport, finite ingress, h2 contracts and outer failures. The prepared endpoint patch can close its enumerated subcases only after integration/review; general separation and logistic VA stationarity retain explicit scope limits.
