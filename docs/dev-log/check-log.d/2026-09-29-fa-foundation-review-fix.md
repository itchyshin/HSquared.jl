# 2026-09-29 FA foundation review fixes

## Scope

Close three bounded findings from the current-candidate FA panel: Ledermann
dimension wording, a production-map local-rank check, and fitted-descriptor
identification wording. Reconcile the historical grammar freeze with the
current bounded R expert-control route. A2 remains HOLD.

## Checks

- Focused command: `julia --project=. -e 'using HSquared, Test; include("test/test_fa_uniqueness_interior.jl")'`
- Result: 29/29 assertions passed, including finite-difference rank 8 at a
  generic T4K1 point and rank 7 at the sparse-loading counterexample.
- `Rscript` after-task structure check: passed.
- `slop_check.py` on the after-task report: 0 findings.
- `git diff --check`: passed.
- `gate-check.mjs --status GATES.md`: A2, E1, and V3 remain unmet; 8 other
  gates are met. This review slice does not close those programme gates.
- Full `Pkg.test()`, R package checks, and docs build were not rerun for this
  wording and focused-test slice.

## Limits

This verifies the local derivative of the production covariance
parameterization, not information in a fitted likelihood. It does not close
routine-start recovery, uniqueness inference, LRT calibration, broad FA cells,
or the Julia source-review wave. No simulation campaign or GPU work was run.
The held 200-seed FA run remains unstarted; Totoro availability does not grant
approval for its estimated runtime above three hours.
