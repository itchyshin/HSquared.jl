# Bridge payload and interval fixture reconciliation

## 1. Goal

Reconcile the Julia experimental multivariate-repeatability result payload with its documented boundary, reflect caller-supplied block names, and repair boundary-fit interval tests without weakening the refusal guard.

## 2. Implemented

- Kept the scalar v2 result contract for univariate routes and documented the Julia-only multivariate-repeatability extension: covariance matrices are trait-by-trait, random-effect values are animal-by-trait, and columns follow the top-level `traits` field. The R normalizer remains fenced from this route.
- Made `component_names` follow parsed pedigree and IID names, followed by `residual`.
- Added assertions for trait labels, matrix dimensions, and custom block names.
- Reconciled H6 boundary Poisson/Bernoulli tests and replaced two Poisson endpoint fixtures with a repeated-record fixture whose fitted genetic variance is interior.
- Preserved an explicit Bernoulli interval refusal assertion for the boundary fixture. No model guard was relaxed.

## 3a. Decisions and Rejected Alternatives

- Kept the existing boundary refusal behavior. Boundary fits do not produce finite-looking intervals from these fixtures.
- Used a repeated-record Poisson fixture for endpoint checks. A short local fit estimated `sigma_a2 = 3.4444`; its 95% interval was `[1.3455, 12.5398]` and converged.
- Documented the multivariate result as a Julia-only experimental extension instead of broadening the R-facing v2 guarantee. R normalization and parity evidence are still required before that route crosses the twin boundary.

## 4. Files Touched

- `src/bridge_payload_v2.jl`
- `test/test_payload_v2_parity.jl`
- `test/test_multivariate_repeatability.jl`
- `test/runtests.jl`
- `docs/design/21-payload-v2-multiblock-schema.md`
- `docs/dev-log/after-task/2026-09-28-bridge-contract-fixes.md`

## 5. Checks Run

- `julia --compiled-modules=no --project=. -e 'include("test/test_multivariate_repeatability.jl")'`: PASS, repeatability payload tests 63/63 and known-truth recovery 8/8.
- Interior Poisson fixture probe using the public fit and interval functions: PASS; both interval endpoints were finite and converged.
- `julia --project=. -e 'using Pkg; Pkg.test()'`: PASS, full package suite completed. H6, public Poisson API, Poisson and binomial/Bernoulli profile intervals, bridge payload tests, multivariate repeatability tests, FA tests, and GLLVM tests all passed.
- `julia --project=docs docs/make.jl`: PASS. Documenter reported 46 docstrings absent from canonical `@docs`/`@autodocs` blocks and local Vitepress/deployment warnings; deployment was skipped as expected for a local build.
- `python3 /Users/z3437171/shinichi-brain/tools/memory_regression.py --selftest`: PASS, all Golden-Set detectors discriminate their fixtures.
- After-task structure validator: PASS. Slop check: 0 findings. `git diff --check`: PASS.
- `graft build`: PASS after the sandbox initially refused `.graph` creation; the local ignored graph indexed 2,455 nodes and 2,931 edges. MCP freshness remains tied to the source checkout and reports no manifest in this worktree.
- `tools/lane_preflight.sh --file` was run for the edited test and schema paths. Shared-lane census showed the Julia candidate branch and separate active leases; only the bridge-owned files and the non-overlapping interval test path were changed.
- `route.py` returned no LOAD-FIRST manifest for either checkout path. This receipt is recorded as a routing limitation, not as evidence that project memory was loaded.

## 6. Tests of the Tests

- Assertions exercise the two previously contradictory boundary cases and require `ArgumentError`; removing the boundary guard would make those checks fail.
- Assertions require custom names to appear consistently in `component_names` and `random_effects`, and bind trait order to the matrix-valued output. No deliberate mutation run was performed.
- An independent bridge-contract review confirmed the shared-Z/ordered-ID checks and REML-only guard, and identified the schema and custom-name issues corrected here.

## 7a. Issue Ledger

- Fixed: H6 expected successful intervals for boundary Poisson and Bernoulli point fits.
- Fixed: the public Poisson interval test used the same boundary count dataset.
- Fixed: the multivariate-repeatability payload's `component_names` ignored caller-supplied names.
- Documented: matrix-valued multivariate repeatability is an experimental Julia-only extension outside the current R-normalizer contract.
- Deferred: R normalization and R-Julia parity for multivariate repeatability; that route remains fenced in the R twin.

## 8. Consistency Audit

- Checked every `laplace_reml_interval` call in `test/runtests.jl` for Poisson, Bernoulli, and Bernoulli-probit expectations. The two Poisson endpoint tests now use the repeated-record interior fixture; the Bernoulli boundary fixture now asserts refusal; binomial and probit endpoint checks remain.
- Checked schema §5 and the Julia result docstring against the returned matrix shapes and labels.
- Confirmed the output includes trait labels and the test pins their order to the estimator result. R-side normalizer code was not changed and remains outside this Julia worktree's ownership.

## 9. What Did Not Go Smoothly

- The first full suite stopped at H6. Fixing that exposed a second Poisson expectation, then a Bernoulli expectation; the subsequent complete run passed.
- The brain `closeout.py new` helper resolved its output root to the brain repository and could not create this repository's report. The report was written directly and passed the repository's validators.
- The brain router had no manifest for the managed worktree path, and the central lease registry reported an OS permission error even while printing a grant. File-specific preflight and the existing bridge lease were used to keep ownership narrow.
- The graft build needed an escalated retry after sandbox denial; the resulting cache is ignored and local to this worktree.

## 10. Known Residuals

- `Pkg.test()` passed; the after-task structure validator, slop check, and `git diff --check` passed against the managed worktree paths.
- The shared `docs/dev-log/check-log.md` remains unchanged because its active source-review-closeout lease owns that file.
- R-Julia parity for the experimental multivariate-repeatability matrix extension has not been implemented or tested.
- Independent source reviews reported pre-existing improper-integral cases for endpoint Bernoulli-probit and negative-binomial fits, plus a large-count Poisson initialization failure. Those issues are outside this bridge-and-fixture slice and need separate triage.
- A reviewer identified a potentially stale full-Gaussian-constant statement in `src/likelihood.jl`; the file has multi-branch drift, so it was left for its source-review owner rather than edited here.
- This slice does not complete the FA or genetic GLLVM arcs, the Julia source-review programme, or the full HSquared twin objective.

## 11. Team Learning

When a point-fit guard changes interval eligibility, search all fit families and API examples for both expected success and endpoint-clamp assertions. Preserve an interior fixture for inference checks and test boundary refusal separately. For multivariate payloads, state matrix orientation and trait order at the boundary, and test caller-provided labels end to end.

Memory receipt: the repository instructions and after-task protocol were read. The project router did not supply a LOAD-FIRST manifest; no brain note was used as technical evidence. Golden Set: `memory_regression.py --selftest` passed all detector fixtures.

## 12. Cross-Product Coverage

- Julia multivariate-repeatability fit and Julia payload shape: covered for focused tests, matrix orientation, ordered IDs, custom block names, and REML-only dispatch.
- H6 boundary Poisson/Bernoulli interval expectations: covered by assertions that boundary fixtures are refused; Poisson endpoint behavior is covered on the repeated-record interior fixture.
- R result normalization and R-Julia parity: does NOT cover these surfaces; the route remains fenced in the R twin.
- FA rank selection, Poisson genetic GLLVM usability, GPU execution, package release, and public release tag: does NOT cover these surfaces.
