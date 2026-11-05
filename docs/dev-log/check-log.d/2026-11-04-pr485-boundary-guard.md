# 2026-11-04 PR 485 uncertainty boundary guard

On Julia 1.12.6, `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=2`:

- `julia --startup-file=no --project=. -e 'include("test/test_issue_408_variance_component_uncertainty.jl"); include("test/test_issue_437_nonconverged_uncertainty.jl")'`: 43 passed.
- Before the source change, the new guard regression produced 4 passes and 2 failures, including `PosDefException` instead of the boundary error.
- `bash tools/preamble_cap.sh` and `git diff --check`: passed.
- Hosted CI and post-merge checks remain pending.

The tests cover the Julia uncertainty bundle only, with no calibration claim.
