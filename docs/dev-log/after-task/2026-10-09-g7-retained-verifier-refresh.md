## 1. Goal

Repair the slow retained G7 verifier without changing the reviewed package runner or product source, then reverify the retained G1, G6, and G7 receipts with auditable output.

## 2. Implemented

The retained verifier now stops before unpacking a compressed mutable registry after the package validator completes its non-registry checks. It validates the retained receipt's registry inventory pins and restores the original extractor in a `finally` block. A regression test covers the historical registry drift path. The package runner, Julia and R product source, campaign data, seeds, and denominators were not changed in this slice.

## 3a. Decisions and Rejected Alternatives

Kept the package runner and its reviewed source freeze unchanged. Reconstructing the current registry archive does not prove what the retained run used; the run receipt's registry inventory pins are the historical evidence. The verifier therefore checks those pins after all other package-preflight semantics pass. Independent review found this scoped path safe for retained verification only. It must not replace current registry validation during a new package run.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/verify_retained_checks.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/tests/test_verify_retained_checks.py`
- `.unlazy/arc1-gaussian-reliability/GATES.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `docs/dev-log/check-log.d/2026-10-09-g7-retained-verifier-refresh.md`
- `docs/dev-log/after-task/2026-10-09-g7-retained-verifier-refresh.md`
- `.unlazy/arc1-gaussian-reliability/evidence/retained-checks/20261009T043546Z-revised-verifier-v3/`

## 5. Checks Run

- Focused regression: first failed against the old path because it attempted registry reconstruction; passed after the repair.
- Full retained-verifier Python test suite: 12/12 passed.
- Python compile check and `git diff --check`: passed.
- Independent Astra review: PASS on verifier SHA-256 `673336bda3cde257f776e0f7566de3b4a69b5948a3b9d783fa43e8363daffb3c` and test SHA-256 `064d590cbce3585b385eb5ad81e8f1504b306b2f0b89def7f49cb0b6522cb709`.
- Fresh retained G1, G6, and G7 checks: each exited zero and emitted its expected marker. Commands, exit codes, and output hashes are recorded in the retained run manifest and logs listed in the check-log sidecar.
- G7's earlier full package run remains the test evidence: Julia, required-live R, `R CMD check`, and docs passed under reviewed freeze-v8. This task only reverified that receipt.

## 6. Tests of the Tests

The new test substitutes a forbidden registry extractor sentinel and fails if retained verification reconstructs the archive. It failed against the previous verifier path and passed with the repair. The full 12-test verifier suite also passed.

## 7a. Issue Ledger

- Resolved: retained G7 verification previously timed out while extracting the registry archive.
- Still open: G2 ordinary-start and rank-selection validation, G3 selection confirmation, G4 FA interval calibration, G5 repeatability interval calibration, and G8 independent scientific closeout.
- Still pending: the user's exact choice of G2 N=80/null pre-run and G5 N=320 continuation. Neither study was started.

## 8. Consistency Audit

Updated the main gate ledger's verifier hash and recorded fresh receipt checks. The package runner hash and reviewed v8 source freeze remain unchanged. The current checkpoint now records the rechecks and their exact evidence. The older timeout sidecar remains as historical evidence; the new sidecar records its resolution. Capability status remains experimental and the covered count remains seven.

## 9. What Did Not Go Smoothly

The original retained verifier spent several minutes unpacking a large mutable registry archive and did not finish in the initial bounded attempt. The changed verifier still takes several minutes to complete G7 receipt inspection, so the successful recheck was rerun with its output directed to retained logs.

## 10. Known Residuals

No scientific acceptance gate was added by this repair. G2-G5 and G8 are open, no pilot or confirmation study has run, and the current campaign approval choice remains pending. The after-task structural check can pass, but the repository closeout gate must remain unmet while the Arc 1 ledger has open gates.

## 11. Team Learning

A retained verifier should test historical evidence against the inventory recorded by that run, not recreate mutable external inputs. The verifier-only exception is narrow: new package executions still use full current registry validation. The lane preflight script named in the repository instructions was not present at `tools/lane_preflight.sh` in this checkout; no ownership or protected files were changed.

## 12. Cross-Product Coverage

Covers: retained G1 objective and identity receipt integrity; G6 live-R and transport receipt integrity; G7 Julia, R, package-check, and documentation receipt integrity under the named freezes.

does NOT cover: new Julia or R package test executions, G2 optimizer reliability, G3 automatic-rank performance, G4 FA interval calibration, G5 repeatability intervals, G8 final review, new source freezes, campaigns, GPU, releases, or overall HSquared completion.

### Draft assessment

**Style:** 3/10, medium confidence. The structured format fits a technical closeout, and the gate labels make scope easy to scan. **Genre and coverage:** complete report, read in full. **Evidence and repair:** the opening goal sentence states both repair and receipt rechecks clearly. The repeated open-gate status in sections 7a and 10 keeps the residuals consistent. No edits were needed. **Gates:** science = pass for the narrow statement that this verifier repair changes no estimator or campaign; facts = pass against the retained test output, independent review note, exact receipt manifest, and current gate ledger; references = not applicable, no external citations. **Provenance:** self-review of this draft, revision 1, 2026-10-08 Edmonton; the assessment is informed by project controls seen earlier.
