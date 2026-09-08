# After-task — 2026-09-08 A3 three-field contract (Julia)

## 1. Goal

Implement the maintainer-authorized R1–R5 private Julia half of the paired 0.9
three-field non-Gaussian contract: source, tests, bridge-normalized result
shape, and bounded documentation only. No S10/S11, remote compute,
promotion, versioning, tagging, registry action, or release.

## 2. Implemented

`nongaussian_three_field_payload` now emits the versioned private envelope for
the admitted intercept-only Poisson(log) and Binomial(logit) cases. Poisson has
latent/count-observation fields; Binomial has latent/liability plus literal
`NaN` observation with `not_yet_ratified`. Scalar and varying positive trials
are preserved; unsupported family/scale/predictor/trial/convergence cells fail
loudly. The legacy payload remains separate.

## 3a. Decisions and Rejected Alternatives

The ratified contract keeps Binomial observation scale as literal `NaN`, not an
averaged scalar. Rejected: adding a public extractor, calling the likelihood
route REML/AI-REML, expanding families or scales, compute, promotion, and
release actions.

## 4. Files Touched

`src/nongaussian.jl`, `src/validation_status.jl`, status/design/debt/claims
documents, the comparator fixture, `test/a3_three_field.jl`, and the ordinary
test include in `test/runtests.jl`.

## 5. Checks Run

- `Pkg.test()` — PASS, including `A3 three-field private Julia envelope` 43/43.
- `julia --project=docs docs/make.jl` — PASS; pre-existing unlisted-docstring
  warnings remain non-fatal.
- `git diff --check` — PASS.
- Unlazy A3 ledger — 8/8 gates met and reverified.

## 6. Tests of the Tests

The registered test rejects unsupported family/scale/predictor/trial/
convergence cases, including the all-one-trial mutation, and preserves the
explicit `NaN` observation field rather than averaging it. The full suite then
exercised that file through the normal harness.

## 7a. Issue Ledger

Resolved: stale legacy fixture/status phrases contradicted the narrow A3
boundary. They now retain legacy scope while identifying the separate A3 path.
Deferred: calibration, retained campaign evidence, and external comparator
work remain outside this source amendment.

## 8. Consistency Audit

Rose's independent audit passed. Status/claim/debt text says experimental and
partial; it does not call the likelihood route REML/AI-REML and does not claim
calibration, external-comparator evidence, promotion, a default route, or a
release.

Rose's independent audit passed. Status/claim/debt text says experimental and
partial; it does not call the likelihood route REML/AI-REML and does not claim
calibration, external-comparator evidence, promotion, a default route, or a
release. The telemetry lane had closed and committed its own harness change
before the A3 include was added; the narrow lease was released after the green
suite. No Dropbox original was touched.

## 9. What Did Not Go Smoothly

Status and fixture language had legacy test-string expectations. The corrected
phrases preserve the old fixture's scope while explicitly separating A3; the
normal suite caught each mismatch before final verification.

## 10. Known Residuals

This is a private engine envelope plus the paired R transport, not a calibrated
scientific conclusion. It does not supply H0/H1/H3 campaign evidence, an
external same-estimand comparator, coverage, or any release authority.

## 11. Team Learning

An ordinary suite's string assertions can expose status drift just as a numeric
test exposes implementation drift. The correct repair was to preserve historical
fixture scope explicitly, rather than weaken the test or the contract.

## 12. Cross-Product Coverage

Covers Julia envelope construction, strict admission, family/scale/trial
boundaries, public-harness registration, R transport selection, and
claim/debt/documentation alignment. It does not cover calibration, campaign
denominators, external comparators, promotion, versioning, or release.
