# 2026-09-29 Wave 2 random-regression input contracts

Estimated under ten minutes for the focused test and under five minutes for
the full package suite. Julia 1.10.0, `JULIA_NUM_THREADS=4`,
`OPENBLAS_NUM_THREADS=1`, offline package mode. The focused
`test/wave2_precision_contracts.jl` run passed 105/105 assertions. Its new
regressions reproduced missing ID-length checks, nonfinite dense/sparse `Z`
reaching numerical work, and nonfinite residual inputs passing positivity-only
guards before the fixes. The full `Pkg.test()` run printed
`Testing HSquared tests passed`; it emitted the existing Project/Manifest
mismatch warning. No package resolve or update was run.

Gauss and Astra independently reviewed the final `src/random_regression.jl`
source hash `e282760b01cfb6b05c1affc6e24089aa66cb575a3bfdaba374b4f27589f73868`
and test hash `ca13fb83ac9d35abcd08a4115e78b229c57283a512da19e0b1f3d88dbf0c0719`.
Rose audited the source and roadmap wording against capability and public-claim
status; stale broad-status phrases were corrected without changing capability
status. The 105/105 focused test was rerun after the final docstring correction.
`git diff --check` passed. This closes only the random-regression
parts of W2-03/W2-07 and adjacent finite-input contracts. Full Wave 2, E1,
other random-regression validation, A2, and V3 remain open. No simulation,
GPU execution, release submission, registry submission, or tag.

The evidence promotion gate passed for all eight registered claims. The
after-task structure checker passed, then stopped at the active programme
acceptance ledgers: FA closeout, GLLVM foundation, W1-05, Wave 2 bridge, and
the root GATES still have unmet work. This partial slice does not abandon or
close those gates.

Full record: `docs/dev-log/source-review/2026-09-29-wave2-random-regression-followup.md`.
