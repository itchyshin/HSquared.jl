## 1. Goal

Close bounded Julia numerical and payload findings, then check their R bridge effects while keeping the four source-review waves on HOLD.

## 2. Implemented

The AI-REML stopping rule now requires a small previous update and a dimensionless score at the returned point. Sparse multi-effect assembly uses the structural union of stored matrix positions. Cancellation-prone single- and multi-effect scores use a bounded streamed calculation; cases above its combined 512-column budget return `boundary_score_unresolved` without convergence. Structured payload-v2 results carry parameter count, observation count, and objective diagnostics; the legacy animal shape stays as before. An animal-only covariance likelihood comparison rejects repeatability input. The R twin validates structured block identity, compares all models in multi-fit AIC, validates integer controls before conversion, and names the bounded FA/GLLVM controls in help and grammar. The FA status row and generated page now describe the live bounded R outputs.

## 3a. Decisions and Rejected Alternatives

We kept the frozen genomic fixture and corrected the stopping rule after an independent Newton check. We kept the arithmetic of successful multi-effect Cholesky solves and normalized only the ridge fallback after an exact live payload shifted under the broader change. A streamed score is used only when subtraction loses precision; the 512-column budget prevents hidden unbounded solve work. We did not infer exact-zero boundary convergence or broad calibration from the repaired score. We retained the existing 0.9.0 version and partial capability status.

## 4. Files Touched

Julia: `src/likelihood.jl`, `src/multivariate.jl`, `src/bridge_payload_v2.jl`, `src/validation_status.jl`, `test/runtests.jl`, `test/test_payload_v2_parity.jl`, `test/wave1_stationarity_contracts.jl`, `test/wave1_workspace_pattern_contracts.jl`, `test/wave1_boundary_score_contracts.jl`, `test/wave3_payload_result_shape.jl`, `test/wave4_covariance_contracts.jl`, `GATES.md`, `docs/design/06-public-claims-register.md`, `docs/src/validation-status.md`, `docs/dev-log/source-review/2026-09-27-wave1.md`, `docs/dev-log/source-review/2026-09-27-wave2.md`, `docs/dev-log/source-review/2026-09-27-wave3.md`, `docs/dev-log/source-review/2026-09-27-wave4.md`, `docs/dev-log/handover/2026-09-27-source-review-followup.md`, this report, and `docs/dev-log/check-log.md`. The paired R paths are listed in its separate after-task report.

## 5. Checks Run

The content-matched Julia copy passed the full `Pkg.test()` with `HSQ_JULIA_TESTS_OK` after W1-09 (`/private/tmp/hsq-fa-gllvm-pkg-test-20260927-w109-final-green.log`). Documentation built after the FA status-row correction (`/private/tmp/hsq-fa-gllvm-docs-20260927-w109-final.log`, exit 0). The exact frozen K3 score changed from `+876.4064063576101` to `-9.377161031090765`, versus independent dense `-9.377161031090708`; 157 boundary assertions passed, including simultaneous triggers and refusal. The first W1-09 full suite found a stale capitalization-sensitive test, which was corrected before the passing run. Focused W1-08 tests passed 82/82 plus 75 stationarity and 406 neighboring assertions. R synthetic bridge tests and post-W1-09 live three-block/direct-maternal tests passed (`/private/tmp/hsquared-fa-gllvm-w109-live-bridge-final.log`). The final R package check returned zero errors, warnings, and notes (`/private/tmp/hsquared-fa-gllvm-rcmdcheck-20260927-final-rose.log`). Both Git diffs passed `git diff --check`. The report is well formed, but the open programme ledger correctly prevents a completion verdict; the hub closeout wrapper also reports unrelated open brain ledgers. CI has a separate gate.

## 6. Tests of the Tests

The first W1-07 stopping change failed four frozen genomic assertions; its corrected conjunction passed without changing the fixture. W1-08's two positive-definite models crashed before structural support was fixed. The W1-09 multi-effect ladder failed all 18 score comparisons before streamed correction, and budget refusal tests failed before the explicit status was added. R negative tests failed on mixed-convention multi-fit AIC, truncated/permuted block lists, and fractional/string integer controls before their repairs.

## 7a. Issue Ledger

Fixed in this candidate: W1-07 false stationarity, W1-08 sparse support loss, the bounded W1-09 cancellation case, W2-04 covariance LRT scope, W3-05 structured result metadata, and the paired R AIC/block/control errors. Open: W1-05, exact-zero/KKT and residual-near-zero boundary behavior, unreviewed source spans in all four waves, bilateral payload freeze, and whole-wave panel signoff.

## 8. Consistency Audit

The check covered genomic frozen values, sparse and dense multi-effect branches, payload-v2 result shape, legacy animal shape, R metadata extraction and AIC, controlled input errors, help, formula grammar, status claims, and sibling package tests. Rose's public-claim review keeps FA/GLLVM partial and the covered count at seven.

## 9. What Did Not Go Smoothly

The first stationarity repair stopped a genomic fit too early. Normalizing every successful solve shifted a nonconverged three-block trajectory; the narrowed fallback-only change restored its prior path. JuliaCall could not create a package-cache pidfile inside the sandbox; the same bounded live tests passed with local cache access. An older random R fixture never converged, so the reduction check now uses a deterministic converged fixture.

## 10. Known Residuals

The corrected sparse score matches the independent dense score at the original `3.2e-16` K3 point. Exact-zero constrained convergence, residual variance approaching zero, and fallback cost on arbitrary large models remain unverified. Cases needing more than 512 streamed columns refuse score certification. FA default-start breadth, GLLVM calibration, multivariate repeatability v2 shape, full source review, independent same-objective GLLVM comparison, and CI remain open.

## 11. Team Learning

Memory receipt: the HSquared route manifest, repo capability/status files, cross-repo lane and claim guards, and prior twin handover shaped the candidate. Golden Set: the unchanged genomic activation fixture was exercised; hub memory-regression tooling was outside this code slice. Build structural matrix support from stored positions. A numeric sum at one parameter point can erase needed entries. Record objective constants and comparability with every exposed log likelihood.

## 12. Cross-Product Coverage

Covers: bounded Gaussian AI-REML stopping tests, sparse multi-effect assembly, finite W1-09 near-boundary scores within the solve budget, structured payload-v2 metadata for two-effect/multi-effect/direct-maternal, and the paired R extractor controls. This does NOT cover exact-zero/KKT fit certification, arbitrary large-model fallback time, every Julia `src/` span, multivariate repeatability payload shape, broad FA or GLLVM inference, release submission, GPU execution, or all future objective comparisons.
