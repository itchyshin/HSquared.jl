# Non-Gaussian heritability descriptor contract design

## 1. Goal

Define a narrow repair contract for NG-07, NG-08, and NG-09 from the exact-current full-file review. This symbolic design receipt defines the proposed model. The frozen source and every existing isolated patch remain unchanged. No implementation, optimizer, statistical fit, simulation, or quadrature campaign was run; two direct analytic helper calls confirmed the scalar fixture.

Candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`.

| Pin | Exact value |
|---|---|
| Current HEAD, verified | `3d6d7ffc961b65fa5a44ce277a7d1168ba69b6fe` |
| Frozen complete source tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| src/nongaussian.jl, 1803 lines | `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00` |
| docs/design/19-h2-scale-contract.md | `85c8c4b80bb6f3298a8e1ebf6ff086f704d89f19d54b835cf24a7a3c671c710a` |
| test/runtests.jl | `b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24` |
| test/a3_three_field.jl | `e7a8b8a91e454055de94818d737f6f6849dfa27d6ed49bcb61052f372d8c0b1d` |
| Prior full-file review receipt | `ff8623095f351877e5586f64c52534d62bbb33d11fab6c71a2cf026c53c04413` |

The HEAD advance is the parent-authorized documentation checkpoint. The current source pin matches the freeze.

## 2. Implemented

Only this report was written. The following model, branch mapping, proposed guards, and test plan define the next isolated implementation slice.

### 2.1 Reference variance and predictor distribution

For one reference animal and a declared target population, write

`eta = mu + a + f`, `Var(a) = V_A`, `Var(f) = V_F`, `Cov(a,f) = 0`,

and use the current descriptor's Gaussian predictor approximation

`eta ~ Normal(mu, V_eta)`, where `V_eta = V_A + V_F`.

The keyword `predictor_variance` means **V_F, additional fixed-effect predictor spread**, per doc-19 lines 212-222. It is not a supplied total V_eta. Therefore requiring `predictor_variance >= V_A` would be incorrect. Nonnegative V_F implies V_A <= V_eta. Valid V_F=0 with positive V_A must remain accepted.

V_A is the caller's reference additive genetic variance, currently sigma_a2. The helper does not calculate a population-weighted variance from pedigree diagonal entries, design weights, or animal-specific relationship scaling. A mean and fixed-effect spread are population choices; they are not extra fitted random-effect parameters. The normal approximation to fixed-effect spread is part of the current transform convention.

The zero covariance assumption is needed for the existing numerator, and should become explicit in the helper documentation. Pedigree correlation between animals does not establish independence of an animal's genetic value and its fixed-effect contribution. If Cov(a,f)=c instead, then V_eta=V_A+V_F+2c and Cov(a,eta)=V_A+c. For jointly Gaussian (a,eta), the additive projection variance would be `((V_A+c)^2/V_A)*Psi^2` for positive V_A. The current interface supplies no c; that different model is outside this repair.

### 2.2 Observation-scale additive projection

Let `m(eta)=E[Y|eta]`, `q(eta)=Var(Y|eta)`, and `Psi=E[m'(eta)]`. Conditional observation noise is uncorrelated with a. For positive V_A, Stein's identity gives

`Cov(a,Y)=V_A*Psi`,

`Var(linear projection of Y on a)=Cov(a,Y)^2/V_A=V_A*Psi^2`,

`V_P,obs=Var(m(eta))+E[q(eta)]`,

`h2_obs=(V_A*Psi^2)/V_P,obs`.

At V_A=0, the numerator has its continuous value zero. The numerator defines a first-order additive projection estimand. It need not equal all variance in the nonlinear conditional mean attributable to the genotype. Under the stated model and exact finite moments, Cauchy-Schwarz bounds this numerator by Var(m(eta)), so a positive finite observation variance gives 0 <= h2_obs <= 1. The zero genetic-variance case corrects the existing prose's strict `(0,1)` claim. A 20-node numerical approximation is not a proof of that bound at all parameter values; do not silently clamp a failed calculation.

Link residual V_link enters the latent denominator. It is not added to V_eta for observation integration. The existing Gaussian conditional exception is specified below.

### 2.3 Family formulas and exact source map

| Current source span | Family and preserved estimand |
|---|---|
| 1591-1601 | Gaussian identity, conditional on fixed effects: h2_lat=h2_obs=V_A/(V_A+sigma_e2). Total reported conditional variance V_A+sigma_e2. |
| 1602-1612 | Poisson count: lambda_bar=exp(mu+V_eta/2), Psi=lambda_bar, V_A,obs=lambda_bar^2*V_A, V_P,obs=lambda_bar^2*expm1(V_eta)+lambda_bar. Preserve h2_lat=NaN and var_link=0 by the existing Poisson convention. Reported latent_total_variance here denotes V_eta. |
| 1613-1630 | Bernoulli/binomial proportion: p=logistic(eta), p_bar=E[p], Psi=E[p(1-p)], var_p=E[p^2]-p_bar^2. With one common positive integer n, h2_obs=V_A*Psi^2/(var_p+Psi/n). h2_lat=V_A/(V_eta+pi^2/3). Bernoulli uses n=1. |
| 1631-1649 | Binary probit: p=Phi(eta), Psi=E[phi(eta)], h2_obs=V_A*Psi^2/[p_bar*(1-p_bar)]. Liability h2_lat=V_A/(V_eta+1). |
| 1650-1677 | Ordered probit: p_k=E[Phi(theta_k-eta)-Phi(theta_(k-1)-eta)], Psi_k=E[phi(theta_(k-1)-eta)-phi(theta_k-eta)]. Per-category h2_obs,k=V_A*Psi_k^2/[p_k*(1-p_k)]. Scalar h2_obs remains NaN; liability h2_lat=V_A/(V_eta+1). Interior categories retain their descriptive projection limitation. |
| 1678-1700 | Gamma log, shape nu: m=exp(eta), q=exp(2eta)/nu, lambda_bar=exp(mu+V_eta/2). V_P,obs=exp(2mu+V_eta)*[expm1(V_eta)+exp(V_eta)/nu], V_A,obs=exp(2mu+V_eta)*V_A. Therefore h2_obs=V_A/[exp(V_eta)*(1+1/nu)-1]. Preserve h2_lat=V_A/[V_eta+trigamma(nu)]. |
| 1701-1713 | Unsupported-family rejection and family-object parameter extraction. Negative-binomial and beta-binomial transforms remain unsupported. |
| 1715-1761 | Public helper documentation, including contradictory Gaussian fixed-spread wording and stale ordinal/comparator wording. |
| 1762-1794 | Fit extraction, converged-fit refusal, default mean, every-vector binomial early return, and scalar trial conversion. |
| 1796-1803 | Direct variance/mean/family-object entry, currently unchecked before Float64 conversion. |

Gamma shape is nu, with Var(Y|eta)=m(eta)^2/nu. The observation ratio's cancellation of mu follows the current lognormal moments. Preserve that parameterization and trigamma residual. Do not replace trigamma(nu) with a lognormal coefficient-of-variation approximation, and do not add it to V_eta.

The output field `var_distribution` is already family specific: Gaussian residual variance; Poisson mean count; logit mean conditional sampling variance on the proportion scale; binary probit marginal indicator variance; Gamma E[q(eta)]; ordinal NaN. This design does not expand or relabel the payload fields.

## 3a. Decisions and Rejected Alternatives

### Gaussian: resolve the contradiction with an explicit conditional fence

Doc-19 general formula at 74, Gaussian residual statement at 79-80, and fixed-effect rule at 212-222 imply a population-total denominator including V_F. Its Gaussian row at 156, source reduction wording at 1738, branch at 1594-1601, and existing default tests at 1221-1236 explicitly use the conditional ratio V_A/(V_A+sigma_e2). Existing tests do not decide the nonzero-V_F case.

Thus the ignored keyword is a real contract defect, but the evidence does not authorize choosing a new Gaussian population denominator. The narrow repair is:

1. Validate V_A, mu, and V_F first.
2. For Gaussian require V_F==0; reject a nonzero value with an ArgumentError explaining that this descriptor uses variance conditional on fixed effects.
3. Preserve the existing Gaussian result and reported total for all valid current default calls.
4. Make the Gaussian exception explicit in doc-19 sections 2 and 4, its table, and the helper docstring/caveat. State that mu is immaterial to this ratio, while supplied nonfinite mu is invalid.

The reproduced V_A=1, sigma_e2=1, V_F=8 returns .5 and total=2 today. Under this proposed contract it rejects. Default V_F=0 remains .5. A population-total Gaussian denominator would give .1 for those inputs; that is a different, presently unchosen summary. It must not be introduced implicitly during the guard fix.

### Binomial: normalize constant denominators before the varying-trial fence

For Y=B/n with B|eta ~ Binomial(n,p), constant vectors [5,5] and scalar 5 denote the same sampling model. Every-vector early return at 1775-1781 is a representation bug. The previously reproduced scalar result is .5040211874317815 for V_A=1, mu=0, n=5 in the prior fixture; the equivalent vector currently returns NaN.

Proposed normalization for the fit's n_trials or explicit keyword:

- Require scalar trials to be positive integer values representable as Int, preserving acceptance of integer-valued Real values where conversion already succeeds.
- Require a trial vector to be nonempty, each member finite, positive, integer valued, and representable as Int.
- If all values equal, reduce to the common scalar and use the unchanged scalar core. [1,1] retains binomial family identity and n=1 information flag; its numbers equal scalar n=1.
- If valid values genuinely vary, preserve the latent result and h2_obs=NaN with an explicit unsupported observation-scale caveat. No mean denominator or implicit weighting rule is introduced.
- Validate variances and mean before this early return.

Do not check this vector against the length of breeding values: per-record trial counts and per-animal breeding values have different index domains. The synthetic fit lacks response-count metadata. This proposal repairs the fit extraction representation; it does not add direct BinomialVectorResponse family-object support to _h2_family_params.

A varying-trial population ratio could be defined only after declaring the record weights and joint trial-count/predictor distribution. The current variance/mean interface does not declare those quantities. Preserving the unsupported result is sufficient for the current usable descriptor.

### Input domain and conversion

For both public overloads, validate the original Real domain and the resulting Float64 domain:

- V_A and V_F must be finite and nonnegative. Zero genetic variance is valid; reject negative, NaN, or infinite values clearly.
- mu must be finite, including the default single stored coefficient.
- The converted sum V_eta must be finite. Two individually finite variances can overflow when added; reject a nonrepresentable total before quadrature or moments.
- Gaussian sigma_e2 and Gamma shape must be finite and strictly positive, including stored synthetic-fit metadata. Check conversion for overflow and positive underflow to zero.
- Ordered cutpoints must be nonempty, finite, and strictly increasing after conversion. Synthetic NonGaussianFit metadata bypasses family constructors, so constructor fixes alone do not enforce this requirement.
- Apply the trial normalization above before scalar core dispatch or the varying-trial return.

An internal core guard should enforce its Float64 invariants for direct internal callers. Original-domain checks belong before public conversions. Preserve explicit rejection of nonconverged fits and the existing ambiguous-mean guard. A single beta coefficient is assumed to be an intercept by the current default; users with a sole non-intercept column must supply mu explicitly because the fit does not retain that design meaning.

Rejecting nonfinite descriptor inputs is independent of the prepared family/count finite-ingress patch. Both are needed because the helper accepts direct sigma_a2/mu keywords and synthetic fit variance components. No new field is needed.

## 4. Files Touched

Created only `/private/tmp/e1-nongaussian-h2-contract-design-20260930.md`. No source, test, schema, driver, branch, index, or prior isolated patch changed. Any later implementation should own a new isolated directory and retain the finite-ingress patch independently.

## 5. Checks Run

- Applied the symbolic-alignment skill: model equations and variance domains precede implementation proposals.
- Queried Graft precisely for nongaussian_heritability, predictor variance, Gaussian denominator, and constant trial vectors. Returned crux 1762-1794 was expanded only to the relevant 1591-1803 helper surface. Graft reported 117,159 tokens saved. Its cache write failed with EPERM; the returned source pin and exact current read were checked directly.
- Verified current HEAD and all tabled file SHA256 pins. Current runtests SHA was remeasured because the prior recorded test pin was historical.
- Read doc-19 65-104, 149-164, 210-222 and H7 tests 1207-1299. Reused source-only Gamma/probit tests 1338-1388 and private three-field controls from the prior review.
- Reused the deterministic prior no-fit counterexamples recorded in `/private/tmp/e1-nongaussian-complete-current-review-20260930.md`, NG-07 through NG-09. A final two-call analytic check was estimated under one minute and completed with exit 0, Julia=1 and BLAS=1, compiled modules disabled. It confirmed scalar n=5, mu=0 values .5040211874317815 at V_A=1 and .45778710056742744 at V_A=.8. No optimizer or mode solve ran.
- Existing H7 default Gaussian, scalar-binomial, independent 64-node logit oracle, and varying-trial tests cover ordinary behavior. They do not cover nonzero Gaussian fixed spread, constant vectors, or malformed descriptor inputs.

## 6. Tests of the Tests

Proposed deterministic red/green suite, using direct helper calls and manually constructed converged fits only:

1. Gaussian V_A=1, sigma_e2=1 default returns both h2=.5 and total=2. V_F=8 raises the conditional-contract error. Negative/nonfinite V_F raises the domain error before the Gaussian fence.
2. Scalar n=5 and [5,5] produce equal complete numeric summaries for V_A=1, mu=0, with h2_obs=.5040211874317815. An ordinary V_A=.8, mu=0 control has scalar h2_obs=.45778710056742744. All-one vector and scalar-one parity preserve family/method/information flags. Test stored vector and keyword override paths.
3. Genuinely varying [5,6] retains finite latent h2, NaN observation h2, and the varying-trial caveat. Empty, zero, negative, fractional, NaN, infinite, and nonrepresentable trial values reject. Do not use an average-trials oracle.
4. Both overloads reject negative/NaN/Inf genetic variance, fixed spread, and mean. Include high-precision finite values that overflow conversion, and positive family fields that underflow conversion. Test stored invalid Gaussian/Gamma/cutpoint metadata separately from family-constructor rejection.
5. V_A=0 gives h2_obs=0 on ordinary Gaussian, Poisson, logit, binary-probit, and Gamma fixtures; preserve Poisson latent NaN and ordinal scalar NaN. V_F=0 with V_A>0 must pass, preventing an erroneous V_F>=V_A restriction.
6. Positive V_F moderate Poisson controls compare against its closed moments. Gamma shape 1 and 2 controls compare against V_A/[exp(V_eta)*(1+1/nu)-1] and V_A/[V_eta+trigamma(nu)]; means 0 and 4.2 give the same observation ratio. Confirm link residual is absent from V_eta.
7. Preserve nonconverged-fit refusal, ambiguous-mean refusal, and unsupported NB/beta-binomial family behavior. Reuse the existing independent moderate logit quadrature oracle without a broad grid or new recovery claim.

These fixtures distinguish the incorrect representation and input paths from the intended formula. They require no fitting to make red failures meaningful.

### Symbolic alignment table

| Concept | Keyword/source | Hypothetical generating model | Recovery target/oracle |
|---|---|---|---|
| Reference additive variance | sigma_a2, V_A | a with variance V_A | Supplied truth, not variance across EBVs |
| Fixed predictor spread | predictor_variance, V_F | Independent population f, normal approximation | Var(f), not total Var(eta) |
| Total predictor variance | V_A+V_F | eta=mu+a+f | V_eta; exclude link residual |
| Gaussian conditional ratio | Gaussian branch; V_F=0 fence | Y=mu+a+epsilon conditional on fixed design | V_A/(V_A+sigma_e2) |
| Common binomial denominator | scalar n or constant vector | Y=B/n, B conditional binomial | Same proportion ratio under either representation |
| Gamma moments | shape nu | Y conditional Gamma, mean exp(eta), variance exp(2eta)/nu | Lognormal moment ratio and trigamma latent residual |
| Observation additive projection | V_A*Psi^2 | Independent genetic/predictor contributions | Variance of linear projection on a |

This table defines truth for deterministic checks. It is not a new data-generating campaign or a calibration declaration.

## 7a. Issue Ledger

| Finding | Disposition |
|---|---|
| NG-07 Gaussian ignored fixed-spread keyword | Contract contradiction confirmed. Model now specified by the proposed conditional fence; source defect remains OPEN until isolated repair and docs/tests are reviewed. |
| NG-08 constant trial vector produces NaN | True representation bug; proposed constant normalization preserves the homogeneous scalar model. Source remains OPEN. |
| NG-09 malformed descriptor inputs | True ingress bug; common pre-conversion plus core domain guards specified. Source remains OPEN. |
| Finite family/count ingress | Prepared independent patch with 141/141 checks; not live and not changed here. It does not validate helper variances or fit metadata. |
| Correlated genetic/fixed contributions | Adjacent model limit; interface lacks covariance c. No new support proposed. |
| Varying-trial observation summary | Adjacent unsupported estimand; explicit fence retained. |
| Extreme finite moment and quadrature numerics | Carried numerical range limit. Finite parameter guards alone do not establish finite exp moments in Float64, cancellation-free logit variance, or GH accuracy over arbitrary inputs. |

## 8. Consistency Audit

Proposed Gaussian documentation must state the exception at the general variance equation, table row, fixed-effect section, and helper caveat so the unsupported keyword cannot appear accepted in one surface. The ordinal docstring currently says category output is follow-up while the branch implements it; it also has stale comparator wording. Update those specific sentences to the existing implemented descriptor and its current limitations without changing validation status.

Preserve existing count/Gamma formulas and output field shapes. The independent mathematical model does not require V_F>=V_A. It does require independent reference contributions and representable, valid variance inputs. A fitted parameter point estimate inherits the fit's objective, convergence, and identifiability limitations; algebraic descriptor consistency does not resolve them.

## 9. What Did Not Go Smoothly

The generic fixed-effect convention and the explicit Gaussian reduction conflict, so current documentation cannot decide a population-total Gaussian implementation. This design resolves that conflict through the smallest explicit supported convention. Graft cache permissions prevented its cache update; exact source/hash verification supplied the needed current evidence.

## 10. Known Residuals

This work does NOT cover statistical fits, calibration, intervals, general separation, outer optimizer failure handling, VA covariance stationarity, objective-kind payload expansion, result-schema expansion, varying-trial weighting, arbitrary correlated predictor distributions, or response-scale heritability for the new genetic GLLVM R route. No public R grammar or fitted-capability status changes are proposed.

Poisson and Gamma moment products can overflow for finite inputs; Gamma's ratio can be evaluated through its mu-independent equivalent, and Poisson has an equivalent scaled ratio. Such numerical implementation changes require their own bounded fixtures and receipt. No extreme-domain numerical approval is claimed here. GH approximation error and nearly degenerate indicator probabilities also remain separate from malformed-input rejection.

The helper refuses nonconverged fits, but boundary/restart information and generic objective provenance retain their full-file review dispositions. This report does not close those findings or reinterpret a boundary estimate as calibrated inference.

## 11. Team Learning

The exact meaning of predictor_variance settles the inequality question before code: it is additional fixed spread, so total variance is derived. Constant trials require representation normalization, while varying trials require an estimand declaration. Preserving an explicit conditional Gaussian convention avoids silently changing the meaning of existing calls.

Memory receipt: repo source, docs, existing test source, and the exact prior scratch review supplied the evidence. No memory files were modified. Golden Set: conditional Gaussian control; nonzero fixed-spread rejection; scalar/constant-vector parity; varying-trial fence; invalid and converted-invalid variance inputs; zero genetic variance; positive fixed spread; Poisson and Gamma analytic moments; unsupported families; convergence/mean guards.

## 12. Cross Product Coverage

This bounded design covers both helper overloads, core dispatch, stored versus keyword trial vectors, valid constant versus varying denominators, original versus converted parameter domains, and the documented family transforms. Existing full-file coverage remains PASS with approval HOLD. The requested three helper findings have a concrete proposed contract; they remain unfixed in the frozen source.

Next parent action: review the conditional Gaussian fence and constant-trial normalization, then authorize an isolated implementation and deterministic red/green tests using this model. Merge the independent finite-ingress patch separately; this design introduces no merge dependency beyond the shared nongaussian.jl file and later line-offset reconciliation.
