## 1. Goal

Complete the preregistered single-cell ordinary-start recovery study for the experimental Poisson genetic GLLVM and report its limits.

## 2. Implemented

Added an opt-in-only ordinary-start recovery driver and froze its model cell, seed stream, estimator, success criteria, and runtime gate before the primary run. The driver calls the existing internal fitter through `HSquared.fit_gllvm_laplace_reml` and the non-exported family constructor through `HSquared.PoissonResponse`.

The measured development seed recovered. The frozen primary stream recovered in all 50 attempts. Added the raw seed-level TSV and recorded the result, metric summaries, hashes, and scope limitations in the pre-registration.

## 3a. Decisions and Rejected Alternatives

Kept the current fixed rank (three traits, two factors), complete balanced pedigree cell, Poisson-log family, pure low-rank covariance, and ordinary deterministic default initialization. No retries or post hoc iteration changes were made. Development and primary streams were disjoint as preregistered.

Kept this as internal usability evidence. Did not claim general calibration, promote capability status, compare with a non-matching estimator, or infer accuracy from loading estimates. No GPU run, release submission, or tag was involved.

## 4. Files Touched

- `sim/phase6_gllvm_ordinary_start_recovery_20260928.jl`
- `docs/dev-log/recovery-checkpoints/2026-09-28-gllvm-ordinary-start-prereg.md`
- `docs/dev-log/recovery-checkpoints/2026-09-28-gllvm-ordinary-start-primary.tsv`
- `docs/dev-log/after-task/2026-09-28-gllvm-ordinary-start-recovery.md`
- `.unlazy/hsq-gllvm-foundation/GATES.md`
- `test/genetic_gllvm_trait_effects.jl`

## 5. Checks Run

- Curie reviewed the frozen design before primary execution and found no blocking design issue. Curie's later read-only validation review identified the missing fitted-output permutation evidence addressed below.
- Opt-in-off Julia smoke check passed. It did not start a fit.
- First development attempts exposed runner namespace errors before a model fit: `PoissonResponse` and `fit_gllvm_laplace_reml` are internal, non-exported names. The runner was corrected to qualify both; no primary seed was consumed by these attempts.
- Corrected development seed `20261699` recovered. Fit time was 3.77 s. This implied approximately 6–7 minutes for the 50-seed stream with a 2× margin, below the three-hour approval threshold.
- An initial primary launch used a colon range unsupported by the runner's comma-list parser and stopped before any seed ran. Retrying with the frozen 50 seed IDs in the accepted format completed on Totoro in 140.13 s, with four Julia threads and one BLAS thread.
- Primary result: 50/50 full successes; Wilson 95% interval [0.929, 1.000], MCSE 0. Relative covariance error median 0.1997 (range 0.0422–0.4179); mean absolute correlation error median 0.0590 (range 0.0068–0.2345). The raw TSV hash is `d592bbcde8e61b53e95e3b12e0714fb15d408ca1e2ea7c36480d1da52446ac1d`.
- Fisher's independent read-only audit recomputed the Wilson interval, checked all 50 rows, thresholds, estimator target, PSD values, and runtime, and found no denominator or estimand flaw. Fisher confirmed that MCSE 0 at the observed boundary does not mean zero uncertainty. The TSV stores scalar summaries, so fitted covariance matrices cannot be independently reconstructed from it.
- Focused GLLVM Julia tests passed 53/53 assertions in six testsets. New paired fits test trait-permuted covariance, intercepts, and trait modes, plus raw pedigree-row reordering with rebuilt `Ainv` and ID-aligned trait modes.
- `git diff --check` passed for the four touched files. The no-AI-slop checker passed the pre-registration with 0 findings under its threshold. The final opt-in-off smoke check passed after the runner changes.
- The after-task structure check passed. The scoped GLLVM ledger now records G5 as met through the explicit experimental-hold alternative, with the exact comparator gap cited from the R candidate branch. G4 and G6 remain open. Its status check reports four gates met and two open; two previously met runnable checks have no gate-check approval records and were not rerun in this slice. The root ledger still has FA engine review, FA opt-in acceptance, full Julia source review, and final twin checks open. This report records one completed evidence slice, not completion of those broader goals.
- A fresh `Pkg.test()` on candidate HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` plus the current working tree exited 0 and printed `Testing HSquared tests passed`. It ran with four Julia threads, one BLAS thread, and a writable temporary Julia depot. The deterministic source/test snapshot hash was `87fc63632060441005e24886bd71e520be2c98117d34257b356b50fa314b84d9` across 146 tracked and untracked files under `src/` and `test/`. This verifies the local integrated package suite, not exact-head hosted CI or deployment.

## 6. Tests of the Tests

The primary output includes a row for every seed and separate optimizer, inner-mode, covariance, error, and runtime fields. It records `fit_status=ok`, optimizer convergence, mode convergence, full success, and `class=recovered` for all 50 rows. The preregistered rule would retain exceptions and nonconvergence as failures in the denominator. No intentional defect injection was performed in this simulation slice.

## 7a. Issue Ledger

- Fixed: runner called the internal response-family type as an exported name.
- Fixed: runner called the internal fitter as an exported name.
- Fixed at invocation: primary seed stream was first supplied in an unsupported colon-range syntax; no seed ran before retry.
- Fixed: fitted-output trait and pedigree-order checks now pass on the deterministic eight-animal fixture; this does not establish broader bridge parity or calibration.
- Open: independent same-objective external comparator, R–Julia parity, and independent tiny-model/reduction validation.
- Open: wider calibration and other families, missingness, ranks, and genetic covariance structures.

## 8. Consistency Audit

The frozen DGP, rank-two target, success criteria, and implementation call were checked against `docs/design/genetic-gllvm-objective-contract.md` and the R route's narrow opt-in model cell. The low-rank fitted covariance is rank two, so eigenvalues at numerical zero are expected; the most negative observed value (`-4.34e-16`) is far inside the preregistered scaled PSD tolerance. The fit did not estimate or score raw loadings. The new fitted-output tests rebuild pedigree relationships from reordered raw inputs and align outputs by animal ID. No R formula or public capability-status row changed. The GLLVM foundation ledger records ordinary-start and fitted-order evidence under G3, the experimental hold and comparator gap under G5, and leaves G4 and G6 open.

## 9. What Did Not Go Smoothly

The first two development attempts stopped before fitting because internal Julia names were used without module qualification. A subsequent primary invocation stopped before fitting because the runner parses comma-separated seeds rather than colon ranges. Each issue was corrected without changing the frozen DGP, criteria, or seed stream. During final bridge review, direct inclusion of `test_payload_v2_parity.jl` lacked the test-only JSON3 dependency, and an initial `Pkg.test()` hit a default-depot permission error; the proper package test environment and writable temporary depot resolved both environment issues. Totoro's `julia` binary was not on the non-interactive `PATH`; the documented Julia 1.10 binary path was used.

## 10. Known Residuals

This result covers one complete, balanced, known-pedigree Poisson-log cell only. The confidence interval is broad, and a 50/50 result is not a high-precision calibration statement. The TSV does not retain fitted covariance matrices, so the reported per-seed matrix errors cannot be recomputed from the artifact. No matched external comparator or R–Julia parity result is supplied by this slice. Capability status remains experimental; exact-head CI was not run here.

## 11. Team Learning

Curie reviewed the preregistration before primary execution. Fisher independently audited the primary evidence. The agent panel has not signed off the broader GLLVM capability or the full Julia engine review.

Memory receipt: `route.py` was run for the repository path but no `LOAD-FIRST` manifest is registered for this checkout. The local brain search confirmed the standing Totoro compute rules and the >3-hour approval gate. These governed the capped, estimated run. No sibling-project scouting occurred in this slice.

Golden Set: not run; this task did not touch a known Golden Set code class.

## 12. Cross-Product Coverage

- Julia experimental genetic GLLVM ordinary-start recovery for one Poisson-log, three-trait, two-factor, complete known-pedigree cell: covered ✓.
- R–Julia payload parity, other response families, incomplete data, automatic rank selection, FA uniqueness, broad calibration, public capability promotion, GPU execution, release submission, and public tagging: this slice does NOT cover these surfaces.
