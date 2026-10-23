# E1 GLLVM residual contract review, 2026-09-30

## 1. Goal

Review the remaining current source spans of `src/genetic_gllvm.jl` without changing the frozen candidate. Reviewer: Gauss numerical engine lens. No additional agents were spawned.

Verdict: **full-file source review coverage, 1–682, is now accounted for; full-file approval remains HOLD**. Existing numerical component approvals remain conditional within their documented scope. Findings below require a repair or an explicit accepted scope disposition before E1 approval.

## 2. Implemented

Created this scratch review receipt. Source, tests, repository reports, capability rows, and gate files were unchanged by this review.

Candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, branch `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`, dirty working tree. The source-file pin was measured before inspection and checked again at closeout:

| File | SHA-256 |
|---|---|
| `src/genetic_gllvm.jl` | `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca` |
| `src/nongaussian.jl` | `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00` |
| `src/multivariate.jl` | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| `test/genetic_gllvm_trait_effects.jl` | `a5c68350b2778e069e9c0b2d4cb1542a40b33e406e621bed5495863f4418698b` |
| `test/runtests.jl` | `b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24` |

Frozen primary-run source-tree pin: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`, recorded in `docs/dev-log/recovery-checkpoints/2026-09-30-fa-ordinary-start-primary-launch.md:13` and the Totoro prerun TSV. Closeout independently recomputed and matched the tree using the driver's relative-path/NUL/file-bytes/NUL method. This receipt does not approve the primary run.

## 3a. Decisions and Rejected Alternatives

Reuse the exact-current objective and trait-effect receipts; retain the older full-read HOLD as history. This task completes residual contract inspection and does not repeat the objective derivation or execute recovery tests.

Receipt `docs/dev-log/source-review/2026-09-29-gllvm-current-exact-candidate.md` explicitly approves inclusive spans `157–180,253–299,325–428,510–517,537–552,560–670` at the matching source SHA. Their union covers 310 lines. The matching trait-effect receipt supports `_gllvm_trait_effects` and fitted reconstruction, already inside those ranges; it supplies no extra numbered curvature/family range to subtract. The older foundation-followup file pins `d7d2a2…`, so its failure-path disposition is historical context, supplemented by the current matching objective receipt.

Fresh inclusive residual spans inspected in this task:

| Span | Contract | Disposition |
|---|---|---|
| 1–156 | supplied/result descriptors, Gaussian MME wrapper, typed error declarations | Conditional for valid engine-produced metadata; malformed descriptor metadata finding carried below |
| 181–252 | family/shape/count input boundaries and documented failure contract | HOLD for general family/invalid-input promises |
| 300–324 | Poisson initialization, loop state, finite scoring classification | Conditional on valid controls and finite inputs |
| 429–509 | wrapper declarations, trait-name validator, covariance extractor | Conditional; names are checked, matrix extractor aliases stored data |
| 518–536 | latent descriptor and objective extractors | Conditional; mutable arrays alias stored data |
| 553–559 | helper closure and fitter signature docs | No additional defect |
| 671–682 | final object construction and diagnostics | Correct mapping of separate optimizer and mode diagnostics |

These ranges cover 372 lines and exactly complement the approved 310 lines, producing 682/682 source lines with no gap or overlap. Approved spans were consulted only for boundary dependencies and dispositions; their objective approval is reused.

The diff against HEAD confirms unchanged executable bodies of both descriptor methods and the Gaussian wrapper, with revised interpretation prose; these historical components are reattested at the current source pin. Family lookup and Poisson initialization remain unchanged executable bodies. Error declarations, wrapper fields, trait names, and final diagnostics were inspected as current additions. Historical unchanged code can still contain the findings below.

## 4. Files Touched

Only `/private/tmp/e1-gllvm-residual-contract-review-20260930.md` was created. Other lanes own the dirty source and tests. No commit, push, merge, external contact, lease acquisition, or source mutation occurred.

## 5. Checks Run

Static source and test inspection only. Closeout hash checks matched the file and whole source tree; a set-union check confirmed 310 reused lines plus 372 residual lines, with zero gaps and zero overlap. The prose checker passed with zero hits. The after-task structure check passed after correcting the required Golden Set and negative-space labels. The closeout compiler remains blocked by unrelated unmet hub ledgers `.unlazy/h2-fixer/GATES.md` and `.unlazy/h2-test-campaign/GATES.md`; those ledgers were left unchanged. Lane preflight completed; active leases include the FA primary validator and pedigree tests. No overlapping edits were made. Graft map, source queries, grep and skeleton preceded source inspection. Graft cache refresh failed with EPERM, and graph coordinates were stale; numbered current source supplied exact coordinates.

Reviewed relevant tests in `test/runtests.jl:10193–10332,10467–10562` and `test/genetic_gllvm_trait_effects.jl:5–179,279–318`. They contain descriptor guards, Gaussian wrapper identity/rotation/univariate reduction, scalar/vector-family equality, mixed families, extractor shape, typed-curvature failures, Gaussian one-step/basis reduction, and name guards. These assertions were reviewed as source; they were not executed in this task. Existing exact-current receipt reports 73/73 focused assertions and full `Pkg.test()`; that execution is attributed to its own author.

Source review does not infer runtime evidence from the current `test/runtests.jl` hash: it differs from the older non-Gaussian receipt's test hash. Source hashes of the dependency files match that receipt.

## 6. Tests of the Tests

No mutation tests or runtime tests were executed. Regression requirements:

1. Reject nonfinite/nonpositive mode tolerance before any optimizer work. Verify `tol=Inf` with a nonzero-score Gaussian fixture is rejected; use a finite-tolerance Gaussian reduction as the control. Preserve `maxiter=0` as the intentional diagnostic test route if that is the contract; reject negative budgets explicitly.
2. For per-record binomial denominators, either reject `BinomialVectorResponse` clearly at ingress or use `_fam_record` with the within-trait animal index. Test scalar and per-trait vectors with varying denominators and a column permutation.
3. Test invalid family-vector members, nonfinite Gaussian responses/designs/family variances, nonfinite initial loadings and uniqueness, and empty trait matrices. Require input errors to remain input errors rather than becoming invalid trial points or raw dispatch/SVD exceptions.
4. Test omitted negative-binomial/beta-binomial endpoints and separated covariates, with no-fixed-effect controls. A finite stationary point must not certify a proper flat-measure integral.
5. Test synthetic descriptor metadata with uniqueness longer/shorter than trait count, negative or excessive uniqueness, and invalid rank. Valid fitted metadata remains the control.

## 7a. Issue Ledger

GLLVM-C1, P1: nonfinite tolerance can certify a nonstationary mode. `gllvm_laplace_marginal_loglik` accepts any `tol::Real` at 223 without checking finite positivity. At 329 and 387 any finite score norm is less than `Inf`, so `tol=Inf` skips scoring and proceeds to observed-Hessian integration at the initial mode. For a Gaussian response with a nonzero initial score and PD Hessian, the reported objective is finite but evaluated away from the exact mode; the Gaussian reduction claim fails under that accepted control. The fitter forwards this control at 637–638 and 658. Reject invalid tolerance at both relevant entry points. Zero/negative/NaN tolerances instead force failure; negative `maxiter` is also unvalidated. Static defect, not executed here.

GLLVM-C2, P1 carried: proper-integral guard is incomplete. GLLVM calls `_check_flat_effect_integral` at 261. The shared helper at `src/nongaussian.jl:609–637` omits negative-binomial all-zero and beta-binomial all-zero/all-success traits, and deliberately excludes separation along other design columns. Full rank of X does not ensure the integral exists. Endpoint likelihoods approach a positive constant along an intercept direction, leaving an infinite flat-measure integral; latent Gaussian priors do not regularize that fixed-effect direction. The existing 09-30 non-Gaussian review P1 is carried here with its GLLVM call site. The bounded Poisson bridge's all-zero intercept check remains effective; generic Julia family/design approval is withheld.

GLLVM-C3, P2: accepted per-record binomial family lacks dispatch. `family::Union{ResponseFamily,AbstractVector}` at 221 accepts `BinomialVectorResponse`; `_check_counts` validates its denominators (`src/nongaussian.jl:575–580`). GLLVM closures at 287–290 call `_fam_score`, `_fam_weight`, `_fam_observed_weight` and `_fam_loglik` directly on the family, whereas scalar-record implementations exist for `BinomialResponse` and require `_fam_record` (`src/nongaussian.jl:184`). Consequently a valid per-record-denominator family reaches a MethodError. The same defect applies to per-trait family vectors containing it. Require an explicit support boundary or correct within-trait denominator dispatch. Existing family tests cover Poisson/Gaussian only.

GLLVM-C4, P2: malformed input classification is incomplete. Family vectors are length-checked at 237–240 but members are not checked as `ResponseFamily`, so invalid members leak MethodError at 249 or conversion at 276. Gaussian Y and X lack explicit finite checks at 224/227; nonfinite X can fail SVD/rank, while nonfinite Gaussian Y becomes a typed parameter-evaluation failure and the outer optimizer maps it to `Inf`. `GaussianResponse` itself permits infinity at `src/nongaussian.jl:32–34`; `initial_uniqueness` permits infinity at 648, and initial loading finiteness is classified later as a trial failure at 626. Add ingress checks before invoking Optim. This weakens the documented 186–188 distinction between input errors and optimizer trial failures.

GLLVM-C5, P2: synthetic result descriptors trust inconsistent metadata. `genetic_gllvm_descriptors(result)` at 81–98 checks structure presence, then computes communality from unvalidated uniqueness. A valid PSD G paired with `ψ > diag(G)` returns negative communality; singleton uniqueness can broadcast to multiple traits. Its covariance checks through `genetic_correlation` do not validate the G/ψ decomposition. Validate length, finite nonnegative uniqueness, valid factor count, and nonnegative common variance, or explicitly constrain this overload to valid engine-produced results. Source assertions include one valid synthetic result, so synthetic ingress is relevant.

## 8. Consistency Audit

Gaussian wrapper correctly constructs supplied `G_lat`, checks trait dimensions, delegates input/precision validation to `multivariate_mme`, and preserves IDs in that solver's breeding-value object. Pure singular low-rank covariance is rejected by the delegated PD covariance check; the latent integral supports singular trait G through a proper latent precision. No Ainv construction is performed here: callers supply an aligned PD precision, checked for finite entries, relative symmetry, averaging, and PD at `src/multivariate.jl:296–309`.

Historical failed-curvature finding is FIXED for the matching current objective component: finite nonconvergence returns NaN plus diagnostics without observed factorization; typed curvature/numerical trial failures become Inf in the outer objective, and a failed final inner mode is rejected. Separate optimizer and mode fields at 671–680 agree with the struct order. Existing R control/help and dropped-diagnostics findings are FIXED for the later bounded bridge receipt, not re-reviewed here. Direct Julia fits still omit animal IDs; preserve row alignment explicitly.

## 9. What Did Not Go Smoothly

Graft refresh could not write its lock in the frozen worktree, so current line maps were measured directly. Preflight took longer than its usual estimate while scanning refs. Divergent historical refs are context only and did not prompt a permission request.

## 10. Known Residuals

Dense scaling remains FENCED: Ainv is materialized at 225 and by the shared validator; record/prior/Hessian matrices are dense. No dense-cell budget is enforced. The Gaussian MME convenience also materializes precision/design inputs before sparse assembly. Require measured allocation and a size guard before expanding scale claims.

Absolute score tolerance depends on family/design/count scale. Rotation invariance does not establish uniqueness identifiability or optimizer reliability. FA uses `exp(θ)` without the Gaussian FA floor, permitting underflow to zero followed by descriptor rejection. Existing ordinary-start and recovery evidence remains cell-specific and conditional. Extractors at 507,517,526 return stored mutable arrays, so a caller can invalidate fit/descriptor consistency; either document this or adopt copy-returning behavior. The internal default struct constructor accepts inconsistent stored fields; serialization must validate them independently.

## 11. Team Learning

A complete source coverage ledger must distinguish inspected lines from approved behavior. Reusing pinned objective components completed coverage efficiently, while the remaining ingress checks exposed failures outside their valid-input numerical scope. Carry C1–C5 to the parent's E1 ledger with the existing precision/dense/identifiability fences.

Memory receipt: quick MEMORY registry lookup supplied the lane-preflight fallback (`MEMORY.md:114–115`); live repo state supplied all technical conclusions. Brain search returned no exact-candidate note. LOAD-FIRST routing retained cell-specific evidence and twin-boundary limits. Golden Set: runtime was not run for this source-only review. No memory was updated.

## 12. Cross-Product Coverage

This receipt completes `genetic_gllvm.jl` source-review coverage at its exact hash. It does NOT cover downstream R generic-v2 payloads, other engine providers, missing/unbalanced latent-response records, family-wide recovery or inference, or GPU execution. Full-file approval, whole-wave E1, A2, recovery, calibration, public capability promotion, general R bridge support, release readiness, GPU behavior, and primary-run acceptance remain unproven by this task. The R bounded route retains its earlier parity receipt; no R source was inspected or modified here.
