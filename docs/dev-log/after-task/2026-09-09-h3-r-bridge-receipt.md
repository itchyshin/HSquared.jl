# After-task — locked H3 candidate R bridge receipt

## 1. Goal

Verify that the isolated R 0.9 three-field candidate can exercise its admitted
non-Gaussian bridge against the locked Julia candidate.

## 2. Implemented

Ran the existing R test through an explicitly required Julia bridge and
recorded its exact outcome.

## 3a. Decisions and Rejected Alternatives

The ordinary R run that skipped bridge cases was not reported as bridge
evidence.  A process-local Julia PATH and `HSQUARED_REQUIRE_BRIDGE=true` made
missing provisioning fail loudly instead.

## 4. Files Touched

- `docs/dev-log/check-log.d/2026-09-09-h3-r-bridge-receipt.md`
- `docs/dev-log/after-task/2026-09-09-h3-r-bridge-receipt.md`

## 5. Checks Run

`devtools::test(filter = "nongaussian-three-field-v09")` against the locked
candidate: **104 pass, 0 fail, 0 skip**.

## 6. Tests of the Tests

The test is source-loaded by `devtools`; the bridge-required helper would stop
rather than skip if JuliaCall, Julia, or the project were unavailable.

## 7a. Issue Ledger

This test validates the A3/A4 transport only.  H3 science and compute remain
held behind their separate authorization.

## 8. Consistency Audit

The R source identifies itself as experimental 0.8.0 and the test changed no
R or Julia source, public count, or release state.

## 9. What Did Not Go Smoothly

`test_file()` first loaded the installed, older R package.  The corrected
`devtools::test()` invocation loaded the candidate sources; Julia also required
its existing launcher on this test process PATH.

## 10. Known Residuals

No R CMD check, pkgdown verification, H3 smoke, campaign, promotion, or release
is established by this receipt.

## 11. Team Learning

For bridge evidence, a passing source-only normalizer test and a skipped live
case are not enough: require the bridge and ensure the source candidate is
loaded.

## 12. Cross-Product Coverage

This receipt covers the R-to-Julia three-field bridge only.  It does NOT cover
H3 `r_g`/`r_am` interval calibration, R public promotion, release artifacts,
DRAC, tags, registry actions, or release.
