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
- **Carried:** ordinary/dispersed-start fitted recovery, floor-distance and local-information diagnostics, exact-candidate reproducibility of the independent same-model reference, and bridge-side validation of identification wording/trait labels.
- **Carried:** whole-file `multivariate.jl` signoff and all remaining Julia source-review waves; no whole-wave PASS is claimed.

## 8. Consistency Audit

Reviewed the structured payload, Ledermann helper wording, grammar freeze, Julia multivariate example, FA identifiability note, capability-status and validation-debt rows, and the R-to-Julia bridge review notes. Sol's scoped numerical interpretation review found no must-fix. Rose requested a wording correction in the freeze table; it was corrected and Rose's recheck returned scoped pass with limitations. The separate R checkout was not edited because another lane owns it.

## 9. What Did Not Go Smoothly

The managed checkout cannot support comparator tests that write generated files. The docs build also needed a temporary worktree `.git` pointer because Documenter could not detect a remote from a plain copy. The package-level `closeout.py` helper resolves its root to the brain repository, so its generator could not safely be used for this package. The simulation-time estimate was omitted before testing.

## 10. Known Residuals

The payload status is a Julia structured-payload field; this work does not prove that the R bridge propagates it. The four-trait cell still lacks ordinary-start/interior-fit and observed-information evidence, and the historical independent fitted reference is not yet reproduced against this exact candidate. The full FA engine review, complete bridge contract review, CI after the eventual push, and broad GLLVM/source-review gates are open. No rank-auto behavior is claimed.

## 11. Team Learning

For structured covariance outputs, test and name three separate properties: rotation invariance, local identification, and fitted-sample information. Treat a returned optimizer component as a candidate estimate unless the latter two have their own evidence. Julia's `genetic_rank` is a requested rank; automatic rank selection needs its own acceptance cell.

Memory receipt: `route.py` was run for the worktree and canonical repository path, but no `LOAD-FIRST` manifest was found. The repository AGENTS instructions, the active HSquared project instructions, and the after-task protocol shaped this work. Golden Set: not run; no routed known-mistake entry was available for this interpretation-only slice.

## 12. Cross-Product Coverage

Covers: Julia structured FA payload interpretation, Julia tests, and Julia documentation for the bounded experimental Gaussian FA cell.

Does NOT cover: R bridge propagation of the identification status; R formula/default route; automatic rank selection; fitted-information/recovery or interval calibration; other `(t,K)` cells; GLLVM; remaining source-review waves; unusual inheritance; GPU execution; CRAN or Julia registry submission; release tags.
