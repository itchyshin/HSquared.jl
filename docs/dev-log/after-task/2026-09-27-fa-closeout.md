## 1. Goal

Correct the Gaussian factor-analytic (FA) payload and documentation so rotation invariance is not confused with identification. Preserve the experimental boundary and record evidence for the bounded closeout slice.

## 2. Implemented

- Marked the structured FA payload's uniqueness identification as `:not_assessed_by_fit`; clarified requested factor count, trait order, relationship-reference heritability, unit dependence, and repeated-eigenvalue limits.
- Corrected the grammar freeze's unsupported `method = :REML` example and the claim that uniqueness is identified.
- Marked the saturated two-trait, one-factor example's fitted uniqueness as diagnostic only.
- Added payload status/order assertions and a trait-permutation covariance construction check.
- Added dated interpretation amendments to capability status and validation debt without changing a capability status or release claim.
- Updated the programme gate and this check log. The broader source-review and fitted-information gates remain open.

## 3a. Decisions and Rejected Alternatives

Kept the two-trait example and labelled its decomposition diagnostic-only rather than replacing it with an unstable four-trait fitted example. Kept fixed rank. The new payload value explicitly says identification is unassessed; neither convergence nor positive Ledermann slack is used as an identification certificate. No R bridge, default formula, or broad FA activation was changed.

## 4. Files Touched

- `src/multivariate.jl`
- `test/runtests.jl`
- `docs/design/54-fa-grammar-freeze.md`
- `docs/src/multivariate-models.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `GATES.md`
- `.unlazy/hsq-fa-closeout/GATES.md`
- `docs/dev-log/after-task/2026-09-27-fa-closeout.md`

## 5. Checks Run

- `git diff --check`: passed.
- Julia 1.10.0 full `Pkg.test()` in `/private/tmp/hsq-fa-closeout-20260927-copy`: passed, ending `Testing HSquared tests passed`, with four Julia threads and one BLAS thread. `src/` and `test/` were compared against the managed candidate with `diff -qr`.
- Managed-checkout `Pkg.test()` attempt: blocked when existing comparator-harness tests tried to write generated files inside the sandboxed checkout. The same source and test tree passed from the writable copy.
- `julia --project=docs docs/make.jl` in the writable copy: passed after attaching the worktree `.git` pointer. Existing warnings remain for 46 undocumented manual entries, deployment auto-detection, and VitePress chunk size.
- Route lookup: `route.py` found no `LOAD-FIRST` manifest for either the managed worktree or canonical HSquared.jl path. Repo-specific and user-provided AGENTS instructions were used; no different project manifest was inferred.
- `closeout.py new` was attempted but its root is hard-wired to the Shinichi brain checkout and it targeted that repository. No file was created there. `check-after-task.R` reports that the required section structure passes; its integrated ledger re-verification fails because the broader `GATES.md:V1` check is unreadable in this sandbox. The report does not claim a ledger-wide pass.
- No upfront duration estimate was stated before running the package fit suite. It completed in under three hours. This is a process miss; estimate before all subsequent fit/simulation work.

## 6. Tests of the Tests

Assertions compare the payload's emitted identification status with the expected FA-only value, compare payload trait and uniqueness order with the fitted result, and compare a permuted FA covariance construction with the correspondingly permuted covariance matrix. These checks fail on missing/wrong status, reordered fields, or broken covariance permutation. No deliberate mutation/negative-control run was performed.

## 7a. Issue Ledger

- **Fixed:** uniqueness was called identified in a freeze table; the API example passed a nonexistent keyword; the saturated T2/K1 example displayed Ψ without a warning; output field interpretations omitted coordinate and relationship-scale limits.
- **Carried:** successful ordinary-start recovery (the exploratory three-start diagnostic found start dependence and floor-proximate fits); feasible boundary/local-information diagnostics; exact-candidate reproducibility of the independent same-model reference; and bridge-side validation of identification wording/trait labels.
- **Carried:** whole-file `multivariate.jl` signoff and all remaining Julia source-review waves; no whole-wave PASS is claimed.

## 8. Consistency Audit

Reviewed the structured payload, Ledermann helper wording, grammar freeze, Julia multivariate example, FA identifiability note, capability-status and validation-debt rows, and the R-to-Julia bridge review notes. Sol's scoped numerical interpretation review found no must-fix. Rose requested a wording correction in the freeze table; it was corrected and Rose's recheck returned scoped pass with limitations. The separate R checkout was not edited because another lane owns it.

## 9. What Did Not Go Smoothly

The managed checkout cannot support comparator tests that write generated files. The docs build also needed a temporary worktree `.git` pointer because Documenter could not detect a remote from a plain copy. The package-level `closeout.py` helper resolves its root to the brain repository, so its generator could not safely be used for this package. The package-suite duration estimate was omitted before launch, a process miss recorded in the check log. The later exploratory three-start fit estimate was stated before execution.

## 10. Known Residuals

The payload status is a Julia structured-payload field; this work does not prove that the R bridge propagates it. A single exploratory three-start probe now exists for the four-trait cell, but it found floor-proximate fits and start dependence; it does not establish ordinary-start recovery. Feasible boundary/local-information evidence and exact-candidate reproducibility of the historical independent fitted reference remain open. The full FA engine review, complete bridge contract review, post-push CI, and broad GLLVM/source-review gates are open. No rank-auto behavior is claimed.

## 11. Team Learning

For structured covariance outputs, test and name three separate properties: rotation invariance, local identification, and fitted-sample information. Treat a returned optimizer component as a candidate estimate unless the latter two have their own evidence. Julia's `genetic_rank` is a requested rank; automatic rank selection needs its own acceptance cell.

Memory receipt: `route.py` was run for the worktree and canonical repository path, but no `LOAD-FIRST` manifest was found. The repository AGENTS instructions, the active HSquared project instructions, and the after-task protocol shaped this work. Golden Set: not run; no routed known-mistake entry was available for this interpretation-only slice.

## 12. Cross-Product Coverage

Covers: Julia structured FA payload interpretation, Julia tests, and Julia documentation for the bounded experimental Gaussian FA cell.

Does NOT cover: R bridge propagation of the identification status; R formula/default route; automatic rank selection; fitted-information/recovery or interval calibration; other `(t,K)` cells; GLLVM; remaining source-review waves; unusual inheritance; GPU execution; CRAN or Julia registry submission; release tags.

## Follow-up diagnostic: ordinary starts (2026-09-27)

Before running this local fit, the estimate was under five minutes for three optimizer starts on a 24-record, four-trait fixture. The completed Julia command took about 12 seconds after startup. This is an exploratory single-fixture diagnostic, not a recovery campaign.

The fixture has 12 pedigree animals, two records per animal, four Gaussian traits, a rank-one genetic FA covariance, trait intercepts, and an estimated unstructured residual covariance. The generating uniqueness values were `[0.35, 0.40, 0.50, 0.45]`. We used three initializations: the fitter default; dispersed loadings with interior uniqueness values and `1.5I` residual covariance; and a restart based on the default fit with each uniqueness clamped to at least `0.0501` so the fitter's interior-start contract was respected. All used the same `fit_multivariate_reml` REML objective and 10,000-iteration limit.

All three returned `converged=true`, but every solution reached the `1e-4` uniqueness floor or came within `7.4e-7` of it. Exact minimum-uniqueness distances above the floor were `0` (default), `7.3768e-7` (dispersed), and `2.4532e-11` (restart). Log likelihoods were `-143.8904176` (default), `-143.3407481` (dispersed), and `-143.3407476` (clamped restart). Relative Frobenius differences between the default and dispersed covariance estimates were `0.4043` for G and `0.1546` for R. The default fit's relative errors against generating G and R were `1.345` and `1.374`.

This shows substantial start dependence in this single fixture despite optimizer-reported convergence. It does not establish general recovery failure, estimator bias, or that the likelihood is flat. Boundary estimates leave open whether the solutions are constrained optima, approximations to zero uniqueness, or numerical failures. The dispersed and restart solutions' near-equal likelihoods do not by themselves prove that their covariance matrices agree. No claim about uncertainty, calibration, or a population of fixtures follows from this probe. Astra and Fisher independently reviewed this interpretation; Astra recommends a bounded diagnostic of objective/feasible first-order conditions and floor sensitivity before any multi-seed recovery exercise.

**Gate outcome:** the ordinary-start/recovery gate remains open. Treat these starts as exploratory only. A Fisher review notes that the frozen S2 preregistration classifies `heywood_flag = min_psi < 1e-4`, while its prose says “uniqueness interior”; a fit numerically equal to the floor is not flagged. That does not change this probe's failed recovery conclusion because its default G/R errors exceed the frozen limits, but future recovery evidence must log `ψ − floor` and use a preregistered boundary tolerance. Do not edit the frozen S2 preregistration after seeing these outcomes. The next diagnostic should verify the default and better candidate solutions against an independent REML objective and feasible directions at the uniqueness boundary, compare the dispersed/restart G, R, and marginal covariance, and test floor sensitivity in a separately declared diagnostic. If that supports stable solutions, plan a separate multi-seed recovery run with interior generating uniqueness and retain boundary/failure fits in its denominator. No capability status or release claim changes.

Reproduction record for the exploratory fixture: `MersenneTwister(20260927)`; animal IDs `1:12`; sire `[0,0,0,0,1,1,2,3,5,5,6,7]`; dam `[0,0,0,0,2,3,3,4,6,7,8,9]`; generating `Λ = [1.0, 0.8, 0.65, 0.5]'`; `Ψ = [0.35, 0.40, 0.50, 0.45]`; residual covariance diagonal `[1.0, 0.9, 0.85, 0.8]` and adjacent covariances `[0.12, 0.08, 0.07]`; trait intercepts `[0.3, -0.4, 0.5, 1.0]`; two records per animal. Full generator and fit call were kept at `/private/tmp/fa-routine-starts-20260927.jl` for this session; the report records the data recipe because `/private/tmp` is ephemeral.
