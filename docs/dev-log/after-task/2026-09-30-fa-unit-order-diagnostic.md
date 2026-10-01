## 1. Goal

Complete the five predeclared ordinary-start Gaussian FA unit and trait-order checks, with exact covariance/prediction oracles and independent artifact verification. This is one acceptance component of the bounded T4/K1 route. A2, E1 and V3 remain open.

## 2. Implemented

All five fits returned finite converged results. All ten named default/balanced starts were valid and converged. Each case met the declared interior-agreement targets. The full raw artifact set, frozen script, README, failed-launch log, successful-run log and independent verification code/log are retained under `docs/dev-log/recovery-checkpoints/fa-unit-order-20260930/`. No live engine or primary driver was changed.

## 3a. Decisions and Rejected Alternatives

Kept the original fixture seed 20260929 and all five maps: baseline, positive units (2, 0.5, 1.5, 0.8), inverse units, order (3, 1, 4, 2), and reverse order. Each start retained a 10,000-iteration cap. No fitted initial covariance was supplied, no replacement seed was chosen and no biological fit was repeated for the independent review. The 200-seed primary campaign retains its separate 5,000-per-start cap and denominator.

## 4. Files Touched

Added the complete artifact folder, `docs/dev-log/source-review/2026-09-30-fa-unit-order-independent-review.md`, this report and the diagnostic launch receipt. Existing dirty engine, source/tests/docs and R work were preserved.

## 5. Checks Run

Runtime estimate before launch: at most one hour on Totoro CPU, Julia four threads and BLAS one. Actual diagnostic runtime: 270.264579069 seconds. Source-tree pin before and after: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. Script pin: `026c3d5ad3a192e26626d3bb38d146266b24b397e981d244d88c960be15f267e`. Summary records `diagnostic_complete`, exit code zero, denominator five, zero correctness failures and `A2_complete=false`.

Curie's independent verification used one Julia and one BLAS thread, estimated under one minute, and exited zero. It validated all 19 original artifact-hash entries, all source pins and serialized input fingerprints. Independent dense trait-major covariance, GLS, REML and breeding-value calculations checked all five saved fits and 30 fixed-covariance transformations. Maximum raw-fit likelihood discrepancy: 1.36424e-12; maximum likelihood-shift discrepancy: 2.04636e-12.

Maximum reverse-mapped fixed-metric relative differences: G 7.88201e-6 and R 7.99561e-6. Corrected fitted likelihood difference is at most 3.73961e-9. Prediction comparisons pass relative 0.002 plus absolute 0.00001 tolerances. EBV norm differences reach 3.46660e-5; they are not claimed below the absolute tolerance alone.

The after-task structure checker passes. Its combined exit is one because the inherited `.unlazy/hsq-gllvm-foundation/GATES.md`, `.unlazy/hsq-w105/GATES.md`, `.unlazy/hsq-wave2-bridge-GATES.md` and programme `GATES.md` retain unmet gates. These gates remain open; the bounded diagnostic report does not certify programme completion.

Raw `fits.tsv` and `oracles.tsv` preserve their final empty exception field as a trailing tab. Git flags those valid delimiters as trailing whitespace; the prose/code whitespace check excludes just these two raw files so their verified hashes and column counts stay unchanged.

## 6. Tests of the Tests

The independent check rebuilds covariance, fixed-effect design and EBV cross-covariance with standard dense linear algebra, rather than calling the engine likelihood or prediction helper. It recomputes the scale likelihood shift, labels, maps, fixed trait metric, named-start selection and declared comparison checks from serialized arrays. The first verification script used Julia's default prediction tolerance; the reviewer corrected it to the predeclared tolerances before the successful final run. No seed or fit was replaced.

## 7a. Issue Ledger

The first launcher failed before fixture generation or fitting because the source-only Totoro snapshot had no Git HEAD. Git identity became optional provenance; mandatory source and fixture fingerprints were retained. The failed log/output remained, and the same cases ran in a fresh retry directory. This was a metadata launch retry with zero previous fit attempts. No numerical correctness or optimizer-sensitivity failure occurred among the five completed cases. General unit/order reliability, floor behavior and population recovery remain separate debt.

## 8. Consistency Audit

All cases use one generated dataset: 40 unrelated founders, five records each, four traits and one genetic factor. They are transformations of one dataset, not five independent replicates. The primary campaign uses a different pedigree DGP, 60 animals and three records each. Neither denominator is substituted for the other. The interior screen passed on the original, transformed and reverse-mapped uniqueness values and mapped baseline. This supports the tested transformations while leaving differences in global feasible sets and global-optimum uncertainty explicit.

## 9. What Did Not Go Smoothly

The first launch's metadata failure was identified and repaired before any numerical work. The retry completed within its one-hour limit. All failed and successful launcher evidence was retained.

## 10. Known Residuals

A2 awaits the primary campaign closeout and panel disposition, with its other accepted components. Population recovery, general optimizer reliability, observed-curvature inference, loading/uniqueness intervals, broader ranks or incomplete data are unproved by this diagnostic. Source/bridge E1 and final integration V3 remain open. The source freeze remains active while PID 676046 completes the approved campaign. No GPU, submission or tag.

## 11. Team Learning

Separate exact transformation identities from optimizer agreement. The independent covariance oracle distinguishes a mapping/likelihood defect from an optimization sensitivity. Keep one comparison metric and preserve the named attempts. Golden Set: independent dense checks served this bounded diagnostic; no broad campaign was added. No memory was updated.

## 12. Cross-Product Coverage

This report covers one Gaussian T4/K1 complete-record founder fixture and the five declared ordinary-start transformations, at the frozen source and cap. It does NOT cover primary-population acceptance, inference calibration, other inheritance structures, automatic rank selection, broad R support, whole Julia source review, final package/CI checks, release readiness or GPU execution.
