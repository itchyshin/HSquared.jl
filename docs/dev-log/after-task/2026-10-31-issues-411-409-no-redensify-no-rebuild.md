# After-task: issues 411 and 409, reuse A in refitting intervals and one MME workspace per profile

## 1. Goal

Two speed defects, one PR, with results unchanged. #411: the refitting forms of the dense interval
functions inverted `Ainv` in the fit and then again in the interval. #409: the profile intervals
assembled the sparse MME from scratch (cross products, block concatenation, fill-reducing order) at
every one of about 70 (h2) to 1,600 (sigma_a2) evaluations.

## 2. Implemented

- `fit_repeatability_reml`, `fit_two_effect_reml`, `fit_direct_maternal_reml` and
  `fit_multi_effect_reml` became thin wrappers over private `_fit_*_dense` cores that return the fit
  and the dense inputs they built (`y`, `X`, `Z`, `A`). The refitting forms of
  `repeatability_interval`, `two_effect_ratio_interval`, `direct_maternal_interval` and
  `multi_effect_ratio_interval` pass those inputs to the interval code. The fit-taking forms still
  build them once, as before.
- `_profile_reml_context` carries a `_ProfileMMEWorkspace`: `[X'X X'Z; Z'X Z'Z]` and
  `blockdiag(0, Ainv)` stored once on one shared sparsity pattern. Each evaluation fills the
  coefficient matrix in place and calls `cholesky!` on the cached symbolic factor, falling back to a
  fresh factorisation on a `PosDefException`, as `_factorize!` does.
- `_sparse_reml_loglik_parts` was split so the part after the factorisation
  (`_sparse_reml_loglik_from_factor`) is shared by both paths.
- Test-only counters `_SPARSE_MME_ASSEMBLIES` and `_DENSE_RELATIONSHIP_INVERSES`, following the
  existing `_SPARSE_REML_EVALS` and `_VALIDATED_SPEC_CALLS`.

No subagents ran. Gauss, Karpinski and Rose were used as review perspectives only.

## 3a. Decisions and Rejected Alternatives

- Reused the fit's own dense inputs rather than adding an `A` keyword to the public fitters (that
  would have been a public API change).
- Built the workspace from the same products as `_sparse_mme_system` (`Zt * X`, not the
  `transpose(XtZ)` used by `_SparseMMECrossProducts`), so the coefficient entries and the
  factor match the old path to the last bit. Measured: bitwise identical outputs.
- Kept the inner Brent search for the sigma_a2 profile. Holding sigma_a2 fixed is not a scale
  family, so the closed form from #486 does not apply. Fewer evaluations would need a different
  root-finder, which would change the endpoints. Out of scope for a no-result-change PR.
- Followed the repo's existing process-global counter pattern. The #408 after-task argued for
  test-injected closures instead; a reviewer may prefer that.

## 4. Files Touched

- `src/likelihood.jl`
- `test/test_issue_411_409_no_redensify_no_rebuild.jl` (new), `test/runtests.jl` (one include)
- `docs/src/changelog.md`
- `docs/dev-log/check-log.d/2026-10-31-issues-411-409-no-redensify-no-rebuild.md`
- this report

## 5. Checks Run

- New test file: red on main plus counters (dense inverses 2, 4, 4, 2 against 1, 2, 2, 1; MME
  assemblies 1611 and 68 against at most 1), green on the branch (19 of 19 alongside the #411 and
  #409 test files, 47 in total).
- Reference comparison against a worktree at `8f58b13a`: 64 + 58 numeric outputs, all bitwise
  identical.
- Full `Pkg.test()` and the Documenter build: results in the PR body.

## 6. Tests of the Tests

The counter assertions failed on main for the right reason (each count was exactly double, or about
1,600 against 1) before any fix. The equality assertions between the refitting and fit-taking forms
use `==`, so a change in the dense inputs would fail them.

## 7a. Issue Ledger

- #409: all items in the issue's suggested fix are now done (#473 hoist, #486 closed form, this
  workspace).
- #411: the Julia-side items in the suggested fix are done (#477, #487, this PR). Still open outside
  this repo: the hsquared bridge calls the refitting forms. The comments also ask for a sparse
  direct-maternal route, which is new work. Whether #411 closes is the owner's call (see PR body).

## 8. Consistency Audit

Public signatures, docstrings and return shapes are unchanged. No default changed. No
capability-status, validation-debt or count change. The changelog's earlier "Part of #411" entry
says "each interval still forms one dense inv(Ainv)". That remains true for the fit-taking forms;
the new entry above it covers the refitting forms.

## 9. What Did Not Go Smoothly

My first comparison script used `x isa Bool == false`. Julia parses that as a chained comparison,
so every leaf was skipped and the script reported zero difference without comparing anything. I
caught it, fixed it, and added a count of compared leaves.

## 10. Known Residuals

- The #411 saving is one O(q^3) dense inverse per call. At q = 400 that is lost in the noise of a
  9 s refit. It only matters when q is large relative to the fit cost.
- The sigma_a2 profile still runs about 1,600 factorisations; this PR makes each one cheaper.
- Not run: Julia 1.10, hosted CI, BTdata or gryphon data.

## 11. Team Learning

When a comparison reports "identical", also report how many things it compared.

## 12. Cross-Product Coverage

This PR covers the Julia engine only: the four dense refitting interval functions and the two
Gaussian sparse profile intervals. It does NOT cover the R package or the bridge,
`laplace_reml_interval` (non-Gaussian, with its own inner mode search), the multivariate interval
paths, Julia 1.10, or hosted CI.
