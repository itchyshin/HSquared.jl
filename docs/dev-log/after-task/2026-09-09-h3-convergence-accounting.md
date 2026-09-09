# After-task — H3 convergence accounting

## 1. Goal

Ensure a non-converged H1/H3 fit cannot contribute a finite interval to the
retained coverage denominator before any H3 smoke or confirmation is run.

## 2. Implemented

- Tightened `_record_ci` so `interval_success` requires `fit_ok`,
  `fit_converged`, and finite ordered endpoints.
- Retains non-converged attempts with `fit_not_converged` and no interval
  endpoints, preserving rather than filtering the failure.
- Added a regression test that demonstrates this for the H3 `r_g` Fisher-z
  path.
- Made the existing validator subprocess inherit the test process’s active
  Julia environment instead of assuming an uninstantiated source checkout.

## 3a. Decisions and Rejected Alternatives

- Rejected counting any finite endpoint pair from an unconverged fit: that
  would inflate `interval_success` and coverage.
- Rejected deleting the row: failures must remain retained for the scheduled
  denominator and later Fisher/Rose review.
- Did not run a smoke or instantiate the candidate only to test this change.

## 4. Files Touched

- `sim/phase1_interval_coverage_ext.jl`
- `test/test_phase1_interval_coverage_ext.jl`
- `docs/dev-log/check-log.d/2026-09-09-h3-convergence-accounting.md`
- `docs/dev-log/after-task/2026-09-09-h3-convergence-accounting.md`

## 5. Checks Run

- Test-first red run: expected assertions showed the old helper counted an
  unconverged finite H3 interval as successful and covered.
- Focused C1-ext H1/H3 scaffold: **102/102 pass** using the sealed sibling
  environment with the current driver included.
- Standalone validator self-test emitted `A2_EVIDENCE_INFRA_TESTS_OK` and
  `A2_MUTATION_CONTROLS_OK`.
- `git diff --check`: pass.

## 6. Tests of the Tests

The new test passes a finite, truth-containing interval with
`fit_converged = false`.  Before the fix it failed four assertions; after the
fix it proves the record is retained, non-successful, uncovered, labelled, and
cannot carry endpoints into the interval-success path.

## 7a. Issue Ledger

- **Environment / open:** candidate `4d4a55c` lacks `Manifest.toml`, so its
  focused suite cannot be instantiated locally without expanding this slice.
- **Infrastructure / open:** the Unlazy Node checker remains unavailable on
  this shell because no Node runtime is installed.
- **Scientific / held:** H3 compute and all public-state actions remain
  unapproved and unrun.

## 8. Consistency Audit

The shared helper is used by H1-two, H1-multi, H1-t, H3-rg, and H3-ram.  The
new condition consistently retains non-convergence as a failure.  No
scientific fixture, candidate hash, result schema, bridge, capability-status,
or claim surface changed.

## 9. What Did Not Go Smoothly

The original focused test launched a subprocess with the source checkout as
its Julia project.  That was not runnable when the candidate had no lockfile.
The test now uses its active environment, which is the environment actually
running the parent test.

## 10. Known Residuals

The candidate still needs a reproducible locked Julia environment before an
exact-head package test or later H3 smoke can be claimed.  The correction has
not run a numerical H3 fixture and provides no interval-calibration result.

## 11. Team Learning

Separate `fit_success`, `fit_converged`, and `interval_success` are useful only
if the denominator explicitly requires convergence.  Recording the three
fields without that link leaves an attractive but invalid coverage result.

## 12. Cross-Product Coverage

This change covers retained H1/H3 interval accounting in the Julia C1-ext
harness only.  It does NOT cover R behavior, cross-twin parity, a scientific
H3 smoke, a retained campaign, calibration, promotion, versioning, tags,
registry actions, or release.
