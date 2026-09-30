# Genetic GLLVM foundation follow-up review

## Scope and pinned candidates

This is a read-only numerical and R-to-Julia bridge review for the bounded
genetic GLLVM route. It records findings only; it does not close GLLVM gates or
authorize implementation changes on the reviewed files.

| Candidate | Snapshot | Reviewed files |
|---|---|---|
| Julia | `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`; working-tree file SHA `src/genetic_gllvm.jl` = `d7d2a2c3dd276cc86813081963e9d61350c5123c0b186b8e222b1630ba5944fd` | `src/genetic_gllvm.jl`, `test/genetic_gllvm_trait_effects.jl`, `docs/design/genetic-gllvm-objective-contract.md` |
| R | `/private/tmp/hsquared-fa-gllvm-20260927`, branch `codex/hsquared-fa-gllvm-20260927`, HEAD `fa98c262eb21694d672e671c9672491ce3369cec` | working-tree `R/julia-bridge.R` SHA `c37f4ba887da4a262d4e6957dbebb98235b8a08b1513b93cdcb888ff3605436d`; `R/hs_control.R` SHA `17f273883f2b58086abe2c0358868c5874ddfacd3adf9f8c04aeb3037787ef41`; `R/extractors.R` SHA `d2a4c73453eb3e7c384ad656c0c046452a20a958a7cb61691b013393257ab163` |

The Dropbox `hsquared` checkout was an older July branch and was not used as
the R candidate. The GLLVM implementation is reviewed from the matched R
candidate above.

## Supported objective and reduction evidence

Gauss found the written and implemented objective consistent for the reviewed
model: fixed effects are integrated under a flat measure, genetic effects have
the pedigree Gaussian prior, and the joint Laplace correction includes the
specified precision and Hessian normalizers. This is a Laplace-approximate
marginal objective for non-Gaussian families, not ordinary non-Gaussian REML.
The Gaussian special case has exact-REML reduction tests for scalar, full-rank,
singular low-rank, and over-ranked latent representations in tested
intercept-only designs.

The R route is narrowly fenced to Poisson-log, three traits, rank two, complete
nonnegative integer counts, an intercept-only design, and one record per
pedigree animal, including ancestors. The bridge reorders responses to the
normalized pedigree IDs, rebuilds `Ainv`, and checks the result ID order. Julia
reconstructs trait-level conditional modes as `F * Lambda' + D`, and existing
tests cover rotations, uniqueness scaling, trait permutation, and animal
reordering. R returns link-scale conditional modes and covariance/correlation,
while withholding `logLik()`, AIC, and heritability. These checks support the
bounded cell only.

## Findings requiring disposition

### Julia inner-mode failure can throw

At `src/genetic_gllvm.jl:339-355`, the fitter recomputes observed curvature and
calls Cholesky even when its final mode check says nonconverged. A singular or
indefinite observed Hessian can throw before returning `converged = false`, the
stop reason, and gradient norm. This can also interrupt an outer objective
evaluation that should treat an inner failure as an invalid evaluation.

Required follow-up: exercise an inner nonconvergence with singular or
indefinite observed curvature and return structured failure diagnostics, or
document and test an intentional typed error contract. Preserve the separate
outer optimizer and inner mode status.

#### 2026-09-29 disposition

The candidate now returns a structured `converged = false`, `loglik = NaN`
result with the final mode and diagnostics when the final score is finite but
above tolerance. It skips observed-Hessian factorization on that path. At a
stationary mode, a failed positive-definite factorization is converted to the
internal `GLLVMInvalidLaplaceCurvatureError`. Nonfinite parameter-point
quantities use a separate typed evaluation failure. The outer parameter
objective maps only these classified numerical trial failures to `Inf` and
rethrows other errors; the final fitted mode must also be converged with finite
likelihood. Deterministic synthetic families exercise the curvature, nonfinite
trial, singular working-Hessian, final-fit rejection, and malformed-input
paths. The focused Julia file passes 61/61 assertions, including the new 8/8
regression. Gauss approved the final narrow diff and found no remaining defect
in this failure path. No GLLVM or whole-wave gate is closed by this
implementation slice.

### Dense validation-scale boundary

The current genetic GLLVM path densifies `Ainv`, record designs, prior
precision, and joint Hessian. The code documents this route as dense and
validation-scale; sparse pedigree input does not imply sparse execution here.
Keep this scope visible and require a measured size/allocation boundary before
any wider scale claim.

### Mode tolerance and restart breadth

The inner mode check uses an absolute Euclidean score tolerance of `1e-10`,
whose meaning may change with response magnitude, design scale, and family.
Ordinary starts currently support only the fixed complete-data `T=3, K=2`
cell. This does not establish general recovery, covariance agreement across
starts, or calibrated performance.

### R control and diagnostics contract

- `R/hs_control.R:45-46` documents `initial` for `genetic_gllvm`, but the
  `R/julia-bridge.R:5345` allowlist omits it and the forwarding validator
  rejects a supplied value at `:6303`. The route does not pass `initial` to
  Julia. This is an exposed-help/runtime mismatch, not a silently ignored
  value. Decide whether `initial` is a supported expert input or remove it
  from the target-specific help and add a rejection test.
- Julia stores separate optimizer and mode convergence fields, the inner
  gradient norm, stop reason, and backtracks. The R raw result currently
  serializes only the combined convergence flag and outer iteration count at
  `R/julia-bridge.R:6366-6374`. The R diagnostic object therefore cannot
  identify which stage failed or show the final mode diagnostics.
- `GeneticGLLVMFit` and `fit_gllvm_laplace_reml` are internal and unexported;
  the R route calls the internal fitter and builds its own result payload. This
  coupling is acceptable only while the feature remains experimental and the
  bridge contract stays covered by parity tests.

## Reviewer dispositions and verification limits

- **Gauss:** objective normalization and tested Gaussian reductions are
  consistent. Medium findings remain for the failed-Hessian path and dense
  implementation boundary; score tolerance and restart evidence are narrow.
- **Hopper:** the result mapping and ordering align for the stated route. The
  control/help mismatch and dropped inner-mode diagnostics require disposition;
  internal API coupling remains an experimental risk.
- Both reviews were read-only. Neither reviewer ran tests or fits in this
  review. Existing gate artifacts report their own test receipts; this note
  does not re-verify them.
- After the reviews, the exact matched R candidate was freshly tested against
  the Julia worktree named above with `HSQUARED_JULIA_TESTS=true`,
  `HSQUARED_JULIA_PROJECT` set to that worktree, one Julia thread, and one
  OpenBLAS thread. `devtools::test(filter = "gllvm-optin")` passed 53
  assertions with 0 failures, 0 warnings, and 0 skips in 15.9 seconds. This
  includes live same-input R-to-Julia parity for the bounded fixture. The
  initial run without the live-test opt-in passed 38 and skipped that parity
  case; the explicit opt-in rerun is the authoritative receipt.
- Julia GLLVM gates G4 and G6 remain open, as do cross-language parity and the
  programme source-review gates. No code change, simulation, GPU run, capability
  promotion, merge, release submission, registry submission, or public tag is
  authorized by this review note.

### 2026-09-29 bounded G6 panel closeout

The subsequent narrow R bridge fixes and their receipts supersede the earlier
open R findings above: `initial` is no longer presented as a supported control,
and the fitted payload now exposes separate outer/inner diagnostics. The live
focused R bridge and diagnostic checks passed 69/69; the control-honesty check
passed 54 assertions. The same-input 12-animal R–Julia parity receipt is in
`docs/dev-log/after-task/2026-09-28-julia-comparator-harness-and-twin-parity.md`.

The five current G6 review dispositions are recorded in
`.unlazy/hsq-gllvm-foundation/GATES.md`: Gauss numerical signoff; Noether
mathematical wording signoff; Astra independent bounded estimand/code signoff;
Karpinski dense validation-scale performance signoff; and Rose bounded public
claim signoff with limitations. The 50/50 Totoro replay reuses the earlier
frozen seeds. It demonstrates same-seed reproducibility and one-cell
ordinary-start usability, not independent 100-fit evidence, calibration,
EBV accuracy, or broad recovery.

Noether and Astra reviewed fit behavior at the pinned logic snapshot
`fd0fb9832b1855f26dc36bb3cffd3b15e131629c4863a1c3db854e1aa8039df4`.
The later Julia source change is docstring-only (current SHA-256
`0322096ffa0f1bac757f247b207dc832e71786f7f28f1392613aad1cc33dada6`); the
objective contract was clarified to separate the pure-low-rank formula from
the FA augmented `K+T` mode construction and to state the flat fixed-effect
basis measure. No fit or test was run for these prose corrections.

G6 is met for the bounded foundation claim. G4 is now met after the Julia
capability/debt rows, Julia status source and generated page, and R planned
validation row were reconciled to this evidence. The bounded R cell remains
experimental under G5 because no matched external comparator or calibration
evidence exists. Cross-language parity beyond the single recorded fixture,
broader source-review waves, FA recovery, any capability promotion, and all
release actions remain outside this signoff.
