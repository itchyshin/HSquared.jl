## 1. Goal

Review two remaining Julia source areas: fitted animal-model marker-scan extraction and backend control metadata.

## 2. Implemented

Added two scoped read-only review receipts, a combined check-log shard, and a GATES entry. The post-fit scan has three P2 findings. Backend control is metadata-only and has one low-severity custom-subtype edge. No code changed.

## 3a. Decisions and Rejected Alternatives

Kept this as source-review work rather than expanding the FA/GLLVM API scope. Did not infer execution from backend labels, infer scan validity from a converged-only fixture, or claim direct marker-row alignment when IDs are absent.

## 4. Files Touched

Evidence only: two files under `docs/dev-log/source-review/`, `docs/dev-log/check-log.d/2026-09-30-postfit-backend-reviews.md`, `GATES.md`, and this report. The check-log generator validated the shards; it did not rewrite the frozen `docs/dev-log/check-log.md`.

## 5. Checks Run

Both reviews were read-only and ran no tests, fits, benchmarks, or simulations. Lane preflight was run before review. After recording, check-log generation and `--check`, preamble cap, `git diff --check`, prose lint, and after-task structure/acceptance checks were run; exact outcomes are reported in the final response. The acceptance ledger remains open at programme level.

## 6. Tests of the Tests

Reviewed current direct test spans for tiny GLS calculations, wrapper reductions, invalid-input checks, row-order fixture assertions, backend parsing, and status flags. Tests were not executed in this review. They do not establish external parity, failed-fit behavior, zero-genetic-variance reduction, threaded execution, or large-scale performance.

## 7a. Issue Ledger

- Open P2: allow and test a zero additive-genetic variance scan boundary when residual variance is positive, if the model contract intends this boundary.
- Open P2: flag or reject scans from nonconverged/unresolved fits.
- Open P2: make marker-row ordering explicit or offer ID-based alignment.
- Open low: decide whether custom backend subtypes are supported; otherwise reject them before `backend_info` dispatch.
- Open: capture an exact pre-review `src/control.jl` hash on a future replay.
- Open: finish all remaining Julia source spans and whole-wave E1 signoff.

## 8. Consistency Audit

No capability, validation-debt, covered-count, release, or GPU status was changed. The backend contract is described as metadata only. The marker-scan limits remain experimental and validation-scale.

## 9. What Did Not Go Smoothly

The supplied test pin for `test/runtests.jl` was stale; the reviewer rejected it and recorded the actual current hash. The backend review did not capture the control file hash until follow-up, so its exact-current claim is deliberately qualified.

## 10. Known Residuals

This does NOT establish complete source coverage, full E1/A2/V3 signoff, animal-model genome-wide inference, threaded/accelerator execution, GPU support, release readiness, or capability promotion.

## 11. Team Learning

Pin every dependency before the first read, not after. When a fitted convenience wrapper emits downstream statistics, carry convergence and input-order provenance into the visible contract.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new fixture was added.

## 12. Cross-Product Coverage

Julia engine source review only. It does NOT cover the R language or extractor, R-Julia parity, release state, or capability promotion. E1 remains open.
