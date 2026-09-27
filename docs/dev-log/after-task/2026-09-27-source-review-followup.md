## 1. Goal

Close bounded Julia numerical and payload findings, then check their R bridge effects while keeping the four source-review waves on HOLD.

## 2. Implemented

The AI-REML stopping rule now requires a small previous update and a dimensionless score at the returned point. Sparse multi-effect assembly uses the structural union of stored matrix positions. Structured payload-v2 results carry parameter count, observation count, and objective diagnostics; the legacy animal shape stays as before. An animal-only covariance likelihood comparison rejects repeatability input. The R twin validates structured block identity, compares all models in multi-fit AIC, validates integer controls before conversion, and names the bounded FA/GLLVM controls in help and grammar.

## 3a. Decisions and Rejected Alternatives

We kept the frozen genomic fixture and corrected the stopping rule after an independent Newton check. We kept the arithmetic of successful multi-effect Cholesky solves and normalized only the ridge fallback after an exact live payload shifted under the broader change. We did not infer a broad boundary-accuracy result from the package pass. We retained the existing 0.9.0 version and partial capability status.

## 4. Files Touched

Julia: `src/likelihood.jl`, `src/multivariate.jl`, `src/bridge_payload_v2.jl`, `test/runtests.jl`, `test/test_payload_v2_parity.jl`, `test/wave1_stationarity_contracts.jl`, `test/wave1_workspace_pattern_contracts.jl`, `test/wave3_payload_result_shape.jl`, `test/wave4_covariance_contracts.jl`, `GATES.md`, `docs/design/06-public-claims-register.md`, `docs/dev-log/source-review/2026-09-27-wave1.md`, `docs/dev-log/source-review/2026-09-27-wave2.md`, `docs/dev-log/source-review/2026-09-27-wave3.md`, this report, and `docs/dev-log/check-log.md`. The paired R paths are listed in its separate after-task report.

## 5. Checks Run

The content-matched Julia copy passed the full `Pkg.test()` with `HSQ_JULIA_TESTS_OK` (`/private/tmp/hsq-fa-gllvm-pkg-test-20260927-final-exact.log`). Documentation built with `HSQ_JULIA_DOCS_OK` (`/private/tmp/hsq-fa-gllvm-docs-20260927-final-exact.log`). Focused W1-08 tests passed 82/82 plus 75 stationarity and 406 neighboring assertions. R synthetic bridge tests and final live three-block/direct-maternal tests passed (`/private/tmp/hsquared-fa-gllvm-final-live-bridge-escalated.log`). The final R package check returned zero errors, warnings, and notes (`/private/tmp/hsquared-fa-gllvm-rcmdcheck-20260927-final-rose.log`). Both Git diffs passed `git diff --check`. The report is well formed, but the open programme ledger correctly prevents a completion verdict; the hub closeout wrapper also reports unrelated open brain ledgers. CI has a separate gate.

## 6. Tests of the Tests

The first W1-07 stopping change failed four frozen genomic assertions; its corrected conjunction passed without changing the fixture. W1-08's two positive-definite models crashed before structural support was fixed. R negative tests failed on mixed-convention multi-fit AIC, truncated/permuted block lists, and fractional/string integer controls before their repairs.

## 7a. Issue Ledger

Fixed in this candidate: W1-07 false stationarity, W1-08 sparse support loss, W2-04 covariance LRT scope, W3-05 structured result metadata, and the paired R AIC/block/control errors. Open: W1-05 and W1-09 near-boundary score cancellation, unreviewed source spans in all four waves, bilateral payload freeze, and whole-wave panel signoff.

## 8. Consistency Audit

The check covered genomic frozen values, sparse and dense multi-effect branches, payload-v2 result shape, legacy animal shape, R metadata extraction and AIC, controlled input errors, help, formula grammar, status claims, and sibling package tests. Rose's public-claim review keeps FA/GLLVM partial and the covered count at seven.

## 9. What Did Not Go Smoothly

The first stationarity repair stopped a genomic fit too early. Normalizing every successful solve shifted a nonconverged three-block trajectory; the narrowed fallback-only change restored its prior path. JuliaCall could not create a package-cache pidfile inside the sandbox; the same bounded live tests passed with local cache access. An older random R fixture never converged, so the reduction check now uses a deterministic converged fixture.

## 10. Known Residuals

At additive variance about `3.2e-16`, a sparse MME score had the opposite sign from an independent dense score. W1-09 needs stable boundary treatment or a clear refusal. FA default-start breadth, GLLVM calibration, multivariate repeatability v2 shape, full source review, independent same-objective GLLVM comparison, and CI remain open.

## 11. Team Learning

Memory receipt: the HSquared route manifest, repo capability/status files, cross-repo lane and claim guards, and prior twin handover shaped the candidate. Golden Set: the unchanged genomic activation fixture was exercised; hub memory-regression tooling was outside this code slice. Build structural matrix support from stored positions. A numeric sum at one parameter point can erase needed entries. Record objective constants and comparability with every exposed log likelihood.

## 12. Cross-Product Coverage

Covers: bounded Gaussian AI-REML stopping tests, sparse multi-effect assembly, structured payload-v2 metadata for two-effect/multi-effect/direct-maternal, and the paired R extractor controls. This does NOT cover near-boundary score accuracy, every Julia `src/` span, multivariate repeatability payload shape, broad FA or GLLVM inference, release submission, GPU execution, or all future objective comparisons.
