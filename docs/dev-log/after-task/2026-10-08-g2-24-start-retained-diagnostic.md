## 1. Goal

Run and independently audit a bounded current-source 6+18 ordinary-selector replay on consumed G2 outer7 and outer10 inputs. Preserve the original attempts and assign zero G2 credit.

## 2. Implemented

Created a versioned v2 candidate and retained its exact-source HOLD. Created v3 with the two review repairs: valid K1 start-name construction and an explicit source-lock binding for the terminal BFGS audit. Added a no-fit Julia smoke receipt. The reviewed v3 replay completed the current production selector for both consumed inputs. Independent source and output reviews passed. No production engine source, R source, public contract, G2 denominator, seed, gate, or capability status changed.

The replay completed 24/24 attempts per case, six K0 and eighteen K1. Both selected K0. Outer10's K0 criterion improved from 924.9752509803 under the original default start to 924.6361834972 under the split_0.3 start. Every K1 start remained near the uniqueness floor. This is diagnostic evidence on consumed inputs, not fresh reliability evidence.

## 3a. Decisions and Rejected Alternatives

Preserved v2 after Astra found two defects; repaired a new v3 instead of mutating reviewed bytes. Pinned the terminal-state audit rather than dropping a useful runtime identity check. Used only the existing consumed outer7/outer10 inputs. Did not start pilot or confirmation, change failure denominators, or change the public/covered capability status.

## 4. Files Touched

- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v2/README.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v2/admission-candidate.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v2/candidate-contract.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v2/retained_full_selector.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v2/run_diagnostic.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v2/source-lock.tsv`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v2/test_runner.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v2/astra-review-HOLD.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/README.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/admission-candidate.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/candidate-contract.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/retained_full_selector.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/run_diagnostic.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/source-lock.tsv`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/test_runner.py`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/no-fit-smoke-receipt.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/astra-review.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/diagnostic.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/diagnostic.sha256`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/outer0007.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/outer0007.sha256`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/outer0010.toml`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/outer0010.sha256`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/stdout.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/stderr.log`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/supervisor-receipt.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-next-method-v3/output/run-20261008T061051Z-8cad1ba6/astra-output-review.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `docs/dev-log/check-log.d/2026-10-08-g2-24-start-diagnostic.md`
- `docs/dev-log/after-task/2026-10-08-g2-24-start-retained-diagnostic.md`

The checkout already contained other dirty and untracked work; it was preserved and not staged. No commit was created.

## 5. Checks Run

- v2 initial red regressions exposed the obsolete 19-row validator. Its first full suite was repaired before review; the candidate then passed 35/35 but Astra held the source for two defects.
- v3 offline suite: 37/37 passed in 4.974 seconds.
- No-fit Julia smoke: exit 0; reported `k0=6; k1=18; cases=2; selector_calls=0; simulation_calls=0`.
- Exact-digest v3 preflight: `PREFLIGHT_PASS_NOT_ADMITTED`; no Julia process started by preflight.
- Astra exact-source review: PASS for candidate `b05c58ef68ab5caad2eef828ba4bdc53585c01b12826a7c425a511ea32fbef39` and 47-pin lock `44b743b688628ec6b87401ed5e4705d0c278e71bae342f107ca0ce0814699ca6`.
- Two-case diagnostic: exit 0, completed within the 180-second cap; retained under `.../output/run-20261008T061051Z-8cad1ba6/`.
- Astra output audit: PASS. Combined diagnostic SHA-256 `b94f5b3badcd7f7e5db9e50cb20820fa2819c45090fc3b648e1efe5986f0cf0e`; outer7 SHA-256 `463d30fa1220fc0ef434a43b6ec3c5c36fe798f7b4778f86d34bc2ab9f9da39c`; outer10 SHA-256 `996ca01de57547fdd9540effb0e3bd08f618fc6df9cac54ca706f044fe0cb30c`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The v3 adversarial suite accepts a correct 6+18 ledger and separate 19-row original ledger, rejects the old 19-row current schedule, rejects an incomplete schedule, detects source drift, verifies that counted G2 cases stay at zero, and verifies the audit-file pin and drift response. The no-fit Julia smoke executes top-level runner setup, which caught the class of defect missed by source-only tests. Astra's v2 HOLD found the invalid vector addition and unpinned read before a fit was launched.

## 7a. Issue Ledger

- Fixed in v3: Julia vector addition used for start-name concatenation. v2 preserved with HOLD evidence.
- Fixed in v3: terminal BFGS audit was read without source-lock binding. The audit is now included among 47 pins and tested for drift.
- Open: all 18 K1 starts remain near the uniqueness floor in both consumed cases. This is a numerical diagnostic observation, not evidence that the method meets its reliability target.
- Open: R lane ownership and current-source paired Julia/R freeze remain unresolved. The isolated dirty R branch was not edited.

## 8. Consistency Audit

The independent output review matched all 47 pins, runtime and input identities, sidecars, per-case files, combined output, iteration totals, covariance checks, criteria and nesting. The original 19-row attempts and failures remain intact. Both new schedules are 24/24 complete with six K0 and eighteen K1 starts. The check also confirmed no simulation calls, no changed seeds or denominators, and zero G2-counted cases. Current gate status remains G0 scoped as met; G1 and G6-G7 are open for the current source freeze; G2-G5 and G8 remain open. No public claim or capability row changed.

The shared `docs/dev-log/check-log.md` and `docs/dev-log/coordination-board.md` were not edited because lane preflight reported missing work from other refs on those shared files. This slice uses a unique `check-log.d` record and the lane checkpoint instead of risking another lane's content.

## 9. What Did Not Go Smoothly

The first v2 full suite passed but missed two real Julia-runner issues. Astra caught both by reading the exact source. The closeout scaffold command resolves the brain checkout through a symlink to a path outside this task's writable root, so it could not create the report there. This report was written in the authorized worktree and will be checked using the repo-root validator directly.

## 10. Known Residuals

This diagnostic does not qualify G2, prove a global optimum, establish fresh-data ordinary-start reliability, or qualify a pilot. All 18 K1 starts remain near-floor. The output auditor could not regenerate the Julia-specific `repr` ledger digest; the independent artifact checks still passed. The supervisor receipt omits PID, exit-code and elapsed-time fields, so those historical facts rely on the verified supervisor code path and runner exit captured in this session. G1, G6, G7, G2-G5 and G8 remain open as stated above. The full HSquared non-GPU goal remains active.

## 11. Team Learning

Memory receipt: the HSquared LOAD-FIRST manifest routed coverage calibration, validation harness, compute routing and the R-public/Julia-engine boundary. These kept this work to a bounded consumed-data diagnostic. Golden Set: not run; no new statistical engine implementation or scientific acceptance was in scope. A no-fit Julia smoke should accompany tests of top-level Julia runner expressions when those expressions can fail before `main()`.

## 12. Cross-Product Coverage

Covers: Julia-only diagnostic harness for the experimental `arc1_v1` six-K0/eighteen-K1 selector; retained-input ledgers, output and runtime/source receipts.

Does NOT cover: R controls or Julia/R parity; new or allocated G2 development attempts; pilot or confirmation; FA or repeatability interval calibration; global optimality or broad reliability; capability promotion; GPU, release or publication.
