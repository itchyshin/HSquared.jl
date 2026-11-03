## 1. Goal

Re-establish current-source G7 after the inspector projection-deduplication change. This slice was limited to source review, the canonical Julia/R/docs package run, and exact retained-receipt verification. It does not complete Arc 1.

## 2. Implemented

No Julia or R code changed during this resumed slice. The existing inspector optimization and regression test were bound into package-freeze v10, independently reviewed, and passed through the all-components G7 runner. G7 now has current evidence for the exact freeze-v10 source bytes.

## 3a. Decisions and Rejected Alternatives

Kept the existing implementation and frozen runner limits. Used the isolated R reconstruction pinned by the reviewed freeze. The first invocation used the runner's legacy default R root because the shell omitted `HSQUARED_ARC1_R_ROOT`; it stopped before any component ran. Preserved that failure and started one clean invocation with the reviewed R root explicitly set. Did not change the protected acceptance-ledger permissions or the isolated R source.

## 4. Files Touched

- `sim/arc1/inspect_artifacts.jl` and `test/arc1_simulation_executor.jl`: existing slice inputs at resume; no code edits in this resumed turn.
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g7-source-freeze-20261009-v10/`: candidate freeze, Astra review receipt, and reviewed freeze.
- `docs/dev-log/check-log.d/2026-10-09-g7-v10-addendum.md`: append-only reconciliation for the read-only historical acceptance ledger.
- `.unlazy/arc1-gaussian-reliability/evidence/package-checks/20261009T071012Z-14becc8cef/`: retained preflight failure; no package component ran.
- `.unlazy/arc1-gaussian-reliability/evidence/package-checks/20261009T071113Z-0936478ef9/`: retained successful Julia, live R, R CMD check, and docs evidence.
- `.unlazy/arc1-gaussian-reliability/GATES.md`: G7 command and evidence now point to the v10 receipt and freeze.
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md` and `checkpoint-archive-20261009-before-g7-v10-closeout.md`: current status updated; prior checkpoint preserved verbatim.
- `docs/dev-log/check-log.md`, `docs/dev-log/check-log.d/2026-10-09-g7-current-source-v10.md`, and `docs/dev-log/coordination-board.md`: current G7 evidence and status.
- `docs/dev-log/after-task/2026-10-09-g7-v10-current-package-pass.md`: this report.
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checks/arc1-acceptance-ledger.md` was not changed because its mode is read-only. Its G7 row still names historical evidence; the active `.unlazy/arc1-gaussian-reliability/GATES.md`, current checkpoint, and check log carry the v10 evidence.

## 5. Checks Run

- Focused inspector tests were already green at resume: 163/163 in `.unlazy/arc1-gaussian-reliability/evidence/inspector-projection-dedup/focused-tests.log`.
- `HSQUARED_ARC1_R_ROOT=/private/tmp/hsquared-arc1-r-reconstruction-20261008 python3 tools/arc1_package_checks.py --freeze .../package-freeze-reviewed-v10.json --gate all`: passed in 6,569.580 seconds. Julia passed 11,526/11,526 assertions; required-live R passed 682/682 expectations across seven files with zero failures, errors, skips, or warnings; `R CMD check` returned `Status: OK`; local Julia docs passed. The R log contains non-fatal repository-index and Quarto-version probe warnings after the package-level `Status: OK`.
- Exact retained verifier: `verify_retained_checks.py --gate G7 --receipt .../20261009T071113Z-0936478ef9/run.json --receipt-sha256 862a045dd982743ef9a1131662c5f3f7a7bd5e9cf3ea3f578c1079166a26d223 --freeze .../package-freeze-reviewed-v10.json --freeze-sha256 76fa6c6535041c3eb17ec3691550ee0316b897212fded2c0f87b5b0b1c2a3251`: emitted `ARC1_G7_RETAINED_RECEIPT_VERIFIED`.
- The package runner emitted `ARC1_PACKAGE_CHECKS_G7_PASS`. Run receipt SHA-256 is `862a045dd982743ef9a1131662c5f3f7a7bd5e9cf3ea3f578c1079166a26d223`; reviewed freeze SHA-256 is `76fa6c6535041c3eb17ec3691550ee0316b897212fded2c0f87b5b0b1c2a3251`; independent review receipt SHA-256 is `11d0cb761de0642787e30d56962a75f76c61369463f2bbfbdec795febf5dd439`.
- `git diff --check`: passed for the current worktree diff.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <absolute report path>`: after-task structure passed. `closeout.py check` did not pass because its root is the brain vault, so it resolved the relative report under that vault; direct `evidence_gate.py --root <repo>` also could not run because this repository has no `memory/evidence-registry.tsv`. The structural R check and exact G7 retained verifier passed independently.

## 6. Tests of the Tests

The focused regression instruments the actual projection function in the copied executor and requires one call for a successful artifact and zero when the raw result is absent. The retained red run failed on the old duplicate call (162 passed, one failed); the focused green run passed 163/163. The full G7 run also passed the Julia source and receipt adversary suites under the exact reviewed inventory.

## 7a. Issue Ledger

- Fixed before this resumed slice: duplicate raw-result projection in the inspector; regression retained with the implementation.
- Fixed in invocation setup: missing `HSQUARED_ARC1_R_ROOT`; the first attempt failed before tests and remains retained as a setup failure.
- Deferred: G2 development allocation awaits the user's answer. G2-G5 and G8 remain open.
- Protected ledger residual: `checks/arc1-acceptance-ledger.md` is read-only and still points to historical G7 evidence. No permission change was made.

## 8. Consistency Audit

Compared v10 to reviewed v9. Astra confirmed the complete 772 Julia / 275 R inventories, exactly the inspector and test source-hash changes, unchanged runtime, bootstrap, sandbox, frontend, roots, runner hashes, and limits. Rechecked G7 run receipt and freeze hashes, component markers, all required logs, and the retained verifier. The capability remains experimental; the public covered count remains seven; the original Dropbox `hsquared` checkout remains unchanged.

## 9. What Did Not Go Smoothly

The first package-run invocation selected the wrong default R root because the shell lacked its explicit environment variable. No package component ran in that invocation. The follow-up used the reviewed R root and passed. The long R profile-v4 live test and R CMD check took 2,613.036 and 5,406.111 seconds respectively, both within their frozen limits.

## 10. Known Residuals

This proves G7 only for the exact reviewed freeze-v10. G2-G5 and G8 remain open. No pilot or confirmation study ran, and no seeds, attempt counts, or denominators changed. This is not a scientific reliability result, release approval, or public capability promotion. The protected acceptance-ledger row remains a stale reference and is called out above.

## 11. Team Learning

Memory receipt: `route.py HSquared.jl` supplied the repository LOAD-FIRST manifest. The three-hour estimate rule and R/Julia boundary shaped the run; the repo checkpoint and exact source freeze were treated as technical truth. No sibling project was scouted and no durable brain note was needed for this narrow package-check replay.

Golden Set: not run. This slice did not alter a known-mistake class covered by the Golden Set; source-inventory and receipt integrity were checked by the frozen runner and retained verifier.

## 12. Cross-Product Coverage

Covers ✓: Julia full package tests, required-live R/Julia bridge tests, R package check, and the local Julia documentation build for the exact reviewed freeze-v10.

Does NOT cover ✗: G2 ordinary-start reliability; G3 automatic-rank calibration; G4 FA heritability interval calibration; G5 five-target repeatability interval calibration; G8 final scientific reconciliation; GPU, releases, CRAN submission, or any covered-status change.
