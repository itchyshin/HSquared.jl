# After-task — 2026-09-09 S10 Totoro smoke no-go

## 1. Goal

Run one predeclared, bounded S10 path-only smoke and retain enough evidence to
decide whether the H1/H3 campaign could proceed.

## 2. Implemented

Added a mutation-tested S10 receipt validator and a safe-by-default Totoro
launcher. The launcher pins a candidate/runtime digest, has a 1,470-second
stop, stages output atomically, validates it, and retains failures. The final
receipt is retained remotely and summarized in the S10 check log.

## 3a. Decisions and Rejected Alternatives

S11 is rejected: the predeclared H1-two interior sentinel had zero successful
intervals. Rejected a DRAC screen/confirm array, a changed denominator, a
coverage interpretation, capability promotion, or release. Those would turn a
smoke failure into post-hoc evidence selection.

## 4. Files Touched

- `tools/validate_hsq09_s10_smoke.jl`
- `tools/run_hsq09_s10_totoro.sh`
- `test/test_hsq09_s10_smoke.jl`
- `docs/dev-log/evidence/2026-09-09-hsq09-s10-smoke-manifest.toml`
- `docs/dev-log/check-log.d/2026-09-09-s10-totoro-smoke-no-go.md`
- this report.

## 5. Checks Run

Focused validator test: **15/15 pass**. A2 retained-evidence self-test passed.
The S10 launcher passed `bash -n`. Unlazy G0–G3 passed; G4 is visibly unmet
because the H1-two sentinel no-go is the measured outcome. Final Totoro driver:
10.75 seconds, 99% CPU, maximum RSS 453,444 KiB; its post-run validator failed
only at the required H1-two sentinel.

## 6. Tests of the Tests

The validator test began red (absent validator), then tested positive output
and mutations for claim eligibility, absent H1-two success, malformed boolean,
and missing inventory row. The first two live launcher faults (unretained
failure stage; wrong `--output` flag) were exposed by bounded attempts and
repaired before the final retained structural receipt.

## 7a. Issue Ledger

- Fixed: failed stages are atomically retained instead of deleted.
- Fixed: launcher now supplies the driver's `--out` summary path.
- Open, scientific: tiny H1-two fit did not converge, leaving both ratio
  intervals unsuccessful. This blocks S11.

## 8. Consistency Audit

Final receipt has all seven detail and summary rows, explicit failures, exact
candidate/runtime inputs, measured resources, false `claim_eligible` values,
and a nonempty `h3_ram` failure reason. It does not meet the independent
H1-two sentinel condition.

## 9. What Did Not Go Smoothly

The first launcher deleted a failure stage; the second wrote the summary to the
driver default instead of the stage. Neither is used as scientific evidence;
both remain documented infrastructure findings. The corrected final result
remains a no-go for scientific reasons.

## 10. Known Residuals

No S11 screen/confirm campaign, R parity, external comparator, public claim,
capability change, version/tag, registration, CI promotion, or release has
occurred. A separately preregistered H1-two convergence-diagnosis slice is
needed before another S10 can be proposed.

## 11. Team Learning

An honest smoke gate must retain its failures and explicitly distinguish a
driver completion from a claim-bearing sentinel success. A tiny diagnostic
cell may be useful precisely because it proves the campaign is not ready.

## 12. Cross-Product Coverage

This covers ✓ S10 transport, output integrity, resource measurement, failure
retention, and the H1-two no-go. It does NOT cover ✗ H1 calibration, H3
calibration, S11, R-public promotion, release evidence, or any 0.9.0 release.
