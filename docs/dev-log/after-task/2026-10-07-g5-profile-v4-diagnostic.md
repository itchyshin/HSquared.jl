## 1. Goal

Resume Arc 1 from its retained checkpoint by examining one retained N=160 near-zero-additive repeatability input under profile v4. Preserve the result as engineering evidence and keep frozen G5 acceptance status unchanged.

## 2. Implemented

Created a separately reviewed, hash-pinned retry harness and driver after the first invocation exposed a Julia top-level `@elapsed` soft-scope defect. The corrected retry completed in 162.327 seconds. All five target intervals formed with status `ok`, finite ordered endpoints, and one connected segment on this one input. The point fit status was `ok`; `point_fit_not_optimal=false`. This is one diagnostic input, not pilot or confirmation evidence.

The retry used Julia 1.10.0, four Julia threads, one BLAS thread, one OMP thread, the restricted Julia load path, and the admitted engine. All 56 loaded dependency identities and engine/environment hashes matched. The supervisor verified all source pins after execution and confirmed the child process group was gone.

## 3a. Decisions and Rejected Alternatives

Preserved the first failed run under `run-v2` with its exact candidate, review, receipt, and log. Did not overwrite it. The corrected retry used distinct `run-v3` output and a fresh candidate/review. The retry estimate is 240 seconds based on the first full child invocation of 145.676 seconds; the supervisor allows no estimate above 300 seconds. Did not change profile-v4 mathematics, the G5 design, seeds, denominators, or acceptance thresholds.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/candidate.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/source-snapshot-index.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/source-snapshot.tar.gz`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/supervise_profile_v4.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run_profile_v4.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/test_supervise_profile_v4.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/engine-load-only-preflight.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/source-review.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/prior-attempt-v2-receipt.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/prior-attempt-v2-julia.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run_profile_v4_retry.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/supervise_profile_v4_retry.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/test_supervise_profile_v4_retry.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/candidate-retry.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/source-snapshot-index-retry.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/source-snapshot-retry.tar.gz`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/source-review-retry.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v2/receipt.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v2/julia.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v2/candidate-runtime.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v3/receipt.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v3/julia.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v3/candidate-runtime.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v3/profile-output/summary.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v3/profile-output/profile-v4.jls`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v3/profile-output/profile-v4-evidence.jls`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n160-v4-refusal-replay-v2/run-v3/profile-output/postrun-audit.toml`
- `docs/dev-log/after-task/2026-10-07-g5-profile-v4-diagnostic.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`

No production Julia source, R source, public grammar, capability status, or G5 acceptance gate was changed.

## 5. Checks Run

- Retry supervisor unit tests: 14/14 passed.
- Julia driver `Meta.parseall`: passed.
- Exact no-fit timed-scope regression: returned 42 and passed.
- Julia admitted-engine load-only preflight: passed with source/environment identity verified and 56 loaded dependencies recorded; no profile fit in this preflight.
- Retry candidate/index/archive/current-file verification: 44/44 entries matched; all archive members were unique regular files.
- Astra independent exact-source review: PASS for this one retry; candidate SHA-256 `9eb273404aac6072742ff3f6a26eed857fd2dd512b80277d6fbc733623680185`.
- Retry supervisor: PASS; 162.327 seconds elapsed against 240-second estimate and 300-second maximum; post-run pins matched; process group absent.
- Post-run interval audit: five formed target intervals were finite and ordered. G5 remains unmet because this is one inspected input without calibration denominators.
- Current Unlazy Arc 1 status: G0, G1, G6, G7 met; G2, G3, G4, G5, G8 open.
- After-task structural validation passed. The broader evidence-promotion check correctly stayed red because the Arc 1, automatic-rank, and non-GPU completion ledgers still contain unmet gates; no completion promotion was made.

## 6. Tests of the Tests

The retry test suite exercises candidate/reviewer mismatch, launch-time signals, descendant cleanup, cleanup timeout, receipt fallback, source changes, finalization signals, and cleanup errors. Its added failure regression creates otherwise complete profile artifacts, injects a log-close error, and requires a retained failure receipt and nonzero result. The Julia scope regression calls the exact timed-result helper used by the fit and verifies the return value is preserved, catching the first run's dropped assignment without performing a fit.

## 7a. Issue Ledger

- Fixed: top-level Julia `@elapsed` soft scope left `profile` as `nothing` after a 145.676-second child invocation. Preserved the failed receipt/log and added a function-scoped result helper with a no-fit regression.
- Fixed: earlier supervisor review defects in candidate/review binding, lifecycle cleanup, identity recheck, and fail-closed terminal receipts; Astra reviewed each exact bundle before execution.
- Open: G5 formation-rate and all-attempt coverage requirements have not been tested across the frozen cells.
- Open: G2, G3, G4, and G8 remain unmet.

## 8. Consistency Audit

The candidate includes Julia source, project/manifest, and the admitted loader identity. Before and after the retry, source hashes, environment hashes, loaded dependencies, project path, module path, and candidate files matched. The retry retained the same N=160 near-zero-additive input and all five frozen estimands. The R lane and public R-Julia contract were not edited. The G5 acceptance ledger remains open and unchanged.

## 9. What Did Not Go Smoothly

The first exact-reviewed invocation spent 145.676 seconds before exposing the top-level soft-scope error. It exited nonzero and produced no profile summary or serialized profile. Rather than reuse its output directory or candidate, the run and review were retained and a separate corrected retry was frozen and reviewed.

## 10. Known Residuals

This diagnostic establishes behavior only for one retained N=160 input with truth `(Va=0.01, Vpe=0.3, Ve=0.69)`. It does not estimate formation rates, all-attempt coverage, coverage among formed intervals, interval widths across datasets, or exact-zero boundary behavior. It adds zero allocated study attempts and cannot qualify G5. The G5 pilot and confirmation campaigns remain unrun. Do not start any campaign projected above three hours without its measured pre-run evidence and approval of the full estimate. G2, G3, G4, and G8 also remain open.

## 11. Team Learning

Memory receipt: repository instructions and retained Arc 1 records were consulted; private memory was not used as technical evidence. Durable implementation lesson: put measured work and its return value inside a function when Julia soft-scope rules would otherwise make assignment ambiguous, and test the exact timing wrapper in a no-fit regression. Golden Set: not in scope; no held-out or confirmation seed was consumed.

## 12. Cross-Product Coverage

Covers ✓: the experimental Julia profile-v4 repeatability diagnostic on the one retained input; its admitted source/runtime identity and terminal receipt path.

Does NOT cover ✗: the R public API, Julia/R parity for these intervals, the 9-cell G5 calibration design, exact-zero boundary calibration, formation-rate or coverage requirements, G2-G4 or G8, GPU execution, or production capability status.

Style: 2/10, medium confidence; concise evidence-focused engineering report. Genre/coverage: after-task validation report, all sections assessed. Evidence/repair: §5 gives exact test and review outcomes; §9 names the measured soft-scope failure; §10 limits the result to one input and leaves G5 open. These concrete details make the report checkable; no prose repair needed. Gates: science = pass for the narrow diagnostic interpretation only; facts = pass against the run receipt, summary, source review, and interval audit; references = not applicable. Provenance: self-review, report version 2026-10-07-v1, 2026-10-07; controls/examples were not used.
