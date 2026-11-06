# G5 outer-2 receipt-verifier hardening

## 1. Goal

Harden the local verifier for the retained N=320 near-zero-additive outer-2 development observation and test its fail-closed behavior. Do not change study data, source admission, denominators, gates, or scientific criteria.

## 2. Implemented

The helper now checks the result's canonical admission digest, delegates full runtime identity validation to `arc1_manifest.verify_execution_identity`, rejects nonfinite or negative elapsed times, checks exact command values while rejecting duplicate and abbreviated long options, and requires one exact zero exit-status line. It also reads the executor test log from its actual `checks/` subdirectory. A synthetic adversarial suite covers these conditions.

## 3a. Decisions and Rejected Alternatives

The test uses the real runtime-identity validator but stubs lower-level interval-row, point-diagnostic, and v4-profile-evidence validation. This isolates the receipt wrapper guards. The test explicitly does not claim to verify scientific interval calculations. The helper was not rerun against the remote multi-gigabyte output; the original outer-2 result retains its separate Astra audit.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/verify_outer2_attempt.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/test_verify_outer2_attempt.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-n320-dev-prerun-v2/checks/g5-outer2-verifier-adversaries.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md` and `checkpoint-archive-20261007-before-verifier-audit.md`
- `docs/dev-log/source-review/2026-10-07-g5-outer2-verifier-review.md`
- This after-task report and `docs/dev-log/check-log.d/2026-10-07-g5-outer2-verifier-adversaries.md`

The shared main check log and coordination board were not edited; earlier path-level preflight found changes in other refs that this checkout lacks.

## 5. Checks Run

- `python3 -B .../test_verify_outer2_attempt.py`: 26 tests passed. Retained log SHA-256: `3c05a47b38cbf2345ce8c8858d107add5330f908c1986f4b06e163feb6595ca0`.
- `python3 -m py_compile` on the verifier and test: exit 0.
- `git diff --check`: exit 0.
- After-task section structure passed. The completion check then returned nonzero because the Arc 1, automatic-FA-rank, and full non-GPU project ledgers still contain open gates; these are intentionally left open while work continues.
- Arc 1 gate-lock verification: `GATES OK`.
- Astra reviewed the exact files as PASS: verifier SHA-256 `ac8b72b1953a5b7b3e4f5fc7d119d4e01ecee6b4a13e21763e3dde5514c3589f`; test SHA-256 `5792a702baa3c063f5d3463b2fa2b36d6a32ac8f0b2a0658006770603705123e`.

## 6. Tests of the Tests

The suite includes a synthetic valid record and 25 adversaries for wrong admission, outer index, seed, status, profile version, target set, truth, artifact hash, command arguments, process status, time bounds, engine identity, and malformed or duplicate dependency records. It calls the real runtime validator. The scientific interval validators are deliberately stubbed, so these cases test outer receipt guards only.

## 7a. Issue Ledger

- No G0-G8 status changed. G0, G1, G6, and G7 remain marked met; G2, G3, G4, G5, and G8 remain open.
- The original outer-2 dataset remains one development outcome. No G5 formation-rate or coverage claim follows from this verifier work.
- The N=320 cell's remaining 28 attempts are still estimated above the frozen three-hour boundary. Separate user approval is required before that campaign.

## 8. Consistency Audit

The source admission and scientific thresholds were not changed. The `GATES.md` lock remains valid. The complete non-GPU HSquared goal remains active. The repo route manifest puts coverage calibration first; this validation hardening does not replace that work. An active separate lease covers an N=160 profile replay and `src/arc1_fa.jl`; those paths were left untouched. The isolated R checkout and protected settings were not touched.

## 9. What Did Not Go Smoothly

The first synthetic fixture exposed an incorrect check-log path. The independent review then found missing admission binding and incomplete runtime checks, followed by time-value and exact-option parsing bypasses. Each issue received a focused adversary. A test run hung on an equals-form option because its parser loop did not advance; the loop was corrected, and the retained 26-test run completed.

## 10. Known Residuals

The updated local helper was validated on synthetic output, not rerun on the remote 1.37 GB JSON result. Astra's earlier review of that actual attempt remains the evidence for its record integrity and target outcomes. Synthetic tests stub the scientific interval and v4 evidence checks. All scientific campaign gates remain open as listed above.

## 11. Team Learning

Retained-result verifiers need adversaries for canonical identities, parser aliases and duplicate options, plus tests with the real lower-level identity checker. Clearly state which scientific checks are stubbed so wrapper tests cannot be mistaken for method validation.

## 12. Cross-Product Coverage

This slice covers only one Julia-side G5 receipt-verifier and its synthetic guards. It does not cover R parity, interval calibration, other G5 cells, G2-G4 campaigns, G8 final reconciliation, GPU, release, or completion of HSquared.

## Post-draft naturalness assessment

Style score: 3/10, medium confidence; the required audit structure is repetitive, but the report ties each statement to concrete checks. Genre/coverage: after-task diagnostic, read in full. Evidence/repair: “26 tests passed” and “validators are deliberately stubbed” make the scope legible; no change needed. Gates: science = pass for limiting claims to receipt checks; facts = pass against the retained test log, exact file hashes, gate lock, and Astra review; references = not applicable, no external citations. Provenance: self-review, report version 2026-10-07, source evidence and review already seen.
