# After-task: Julia comparator harness and twin parity check

## 1. Goal

Fix comparator validation when the package checkout is read-only, verify the current Julia candidate, and record current R/Julia bridge evidence without widening capability claims.

## 2. Implemented

- Changed the BLUPF90 parity adapter to build generated packet files in a temporary directory.
- Registered the empty-marker status regression in `test/runtests.jl` (it was previously absent from the full-suite include chain).
- Corrected GLLVM validation prose that treated five-seed Bernoulli and Binomial results as proof of a directional bias or a trial-count cause.
- Updated `GATES.md` with the current full-suite hash and current-candidate R bridge results. A2, E1, and V3 remain open.

## 3a. Decisions and Rejected Alternatives

The adapter only checks that the comparator packet can be built; it does not need to write into the source tree. The bounded fix uses `mktempdir()` and leaves the external BLUPF90 run opt-in. No estimator, fit result, capability status, release state, or public count was promoted.

## 4. Files Touched

- `comparator/run_targets.jl`
- `test/runtests.jl`
- `GATES.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `sim/phase6_gllvm_recovery.jl`
- `docs/dev-log/after-task/2026-09-28-julia-comparator-harness-and-twin-parity.md`

## 5. Checks Run

- Before the fix, focused comparator reproduction failed with `Operation not permitted` while the BLUPF90 packet writer targeted the read-only source checkout.
- After the fix, the same focused harness passed 22/22 checks.
- `JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia JULIA_PKG_OFFLINE=true julia --project=. -e 'using Pkg; Pkg.test()'`: exit 0; package output ended `Testing HSquared tests passed`. Aggregate SHA-256 over sorted `src/` and `test/` file hashes: `3b8be5776554e7198d518c5eb1df0dffcf8d3487a7cce5e656b7ff93fb4a6a60`.
- `node /Users/z3437171/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root "$PWD" --cwd "$PWD" --timeout 3600 --approve GATES.md`: V1 passed with the exact success matcher and V2 passed from the content-matched temporary copy. Overall ledger exit was 1 because A2, B1, E1, and V3 remain open.
- R candidate against this exact Julia worktree: GLLVM focused tests passed 53/53, including live same-input parity.
- R candidate FA tests: 64 passed and 40 failed across the full file. The live FA fit passed covariance, effect, ordering, and uniqueness-identification checks, but 17 assertions failed because `fa_start_*` diagnostics were not forwarded through the R normalizer.
- `git diff --check` passed after the edits.

## 6. Tests of the Tests

The read-only-checkout failure was reproduced before the adapter change and the same focused harness passed after the change. The full package run exercised that harness together with the registered empty-marker regression. No deliberate fault injection was run.

## 7a. Issue Ledger

- Fixed: comparator packet generation wrote into the source checkout during validation.
- Fixed: the empty-marker regression existed but was not part of `Pkg.test()`.
- Fixed: GLLVM table prose asserted a known Bernoulli bias direction and a causal trial-count explanation from five seeds; the replacement language reports the observed unsigned error and descriptive contrast only.
- Open: B1, because the R FA normalizer drops Julia `fa_start_*` diagnostics. The current live FA check exposes this gap. Do not edit the shared R bridge until the coordinator establishes single-lane ownership.
- Open: current-candidate FA independent comparator, broader recovery, full Julia source-wave signoff, and post-change CI.

## 8. Consistency Audit

Checked the adapter's single harness call path, the related test include chain, the fitted capability and validation-debt text, and the current R live bridge paths. The test run did not execute BLUPF90 or promote its comparator status. Current GLLVM bridge parity is supported for the bounded cell; current FA fit parity is supported for covariance and effects, while diagnostic forwarding is not.

## 9. What Did Not Go Smoothly

The first full-suite rerun tried to write Julia's usage lock under the protected shared depot. A writable temporary depot resolved that environment issue. The harness then surfaced the source-tree write assumption, which was reproduced directly and fixed. The after-task helper resolved to the parent brain repository rather than this worktree, so its `new` command could not create the report; this report was created in the current worktree using the reviewed path.

## 10. Known Residuals

The R FA diagnostic failure remains open because another Codex lane is active and the shared bridge has divergent branch history. R package checks and hosted CI were not run for this candidate. `docs/dev-log/check-log.md` and `docs/dev-log/coordination-board.md` remain owned by another lane and were not changed. The after-task structure check passed. The ledger recheck passed V1 and V2; the overall ledger remains open on A2, B1, E1, and V3. No CRAN submission, Julia registry submission, tag, or deployment was made.

## 11. Team Learning

Validation adapters should write generated packets and manifests to temporary locations unless their explicit purpose is to create a repository artifact. A passing core fit does not imply that new diagnostic fields survive a cross-language normalizer; test the returned R object as well as numerical parity.

Memory receipt: the prior ask-brain search and repository routing check were available in the task context; routing returned no LOAD-FIRST manifest. No Golden Set run was needed for this filesystem-only harness issue. Astra's earlier non-Gaussian review and the read-only R-lane coordinator review informed the open issue list. No shared memory files were changed.

## 12. Cross-Product Coverage

- Julia comparator validation harness: covered for a read-only source checkout; does NOT cover running the external BLUPF90 comparator.
- Bounded R GLLVM route: current same-input Julia parity covered for the tested Poisson cell; does NOT cover other families, missing records, broad calibration, or external GLLVM.jl/gllvmTMB comparison.
- Bounded R FA route: covariance/effect parity and uniqueness-identification status covered; does NOT cover R exposure of multistart diagnostics, a current independent FA comparator, broad recovery, or calibrated inference.
- Public capability and release state: no coverage promotion; `public_covered_count` remains 7 and release/submission gates remain closed.
