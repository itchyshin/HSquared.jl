# Isolated GLLVM control and input repair, 2026-09-30

## 1. Goal

Repair C1 and the basic C4 input guards in an isolated copy. The frozen candidate remains unchanged. Reviewer and implementer: Gauss. No additional agents were spawned.

## 2. Implemented

The isolated `src/genetic_gllvm.jl` validates finite positive `tol`, nonnegative integer `maxiter`, finite Y/X, family-vector length and ResponseFamily members, and finite positive GaussianResponse residual variance before mode work or outer optimization. It also rejects nonfinite initial loadings and, for factor-analytic structure, nonfinite initial uniqueness.

The existing integer method signatures remain in place; `maxiter=0` preserves its diagnostic behavior. Valid supported families, scoring, objective normalization, optimizer choice, and fit result construction retain their existing code.

Only `genetic_gllvm.jl` differs among copied source files. C1 is repaired in the isolated candidate. C4 is repaired for the enumerated controls, numeric values, Gaussian variance, family-vector membership, and initial values; it remains partial for arbitrary conversion errors, empty trait matrices, or other malformed data classes.

## 3a. Decisions and Rejected Alternatives

Used the test-driven-development skill: first record the failed assertions, then add guards and rerun. Shared `_check_finite_matrix` handles numeric conversion and finiteness. GaussianResponse exposes `sigma_e2`; the GLLVM entry guard checks that existing field directly, leaving the shared family constructor untouched.

Kept C2 proper-integral checks, C3 per-record binomial dispatch, and C5 descriptor validation carried. Family-vector membership validation accepts BinomialVectorResponse as a ResponseFamily, so the C3 dispatch defect remains visible. No family capability or estimator was added.

## 4. Files Touched

All deliverables are under `/private/tmp/hsq-gllvm-input-fix-20260930/`:

- `src/`: a copy of the frozen source, with only `genetic_gllvm.jl` changed.
- `Project.toml` and `Manifest.toml`: unchanged copies, without resolving or installing dependencies.
- `test/gllvm_input_guard_regression.jl`: focused regressions and the existing Gaussian reduction test blocks.
- `gllvm-input-guards.patch`: unified source and new-test patch for later review.
- `red.log`, `red-all.log`, `green.log`, `green-final.log`: execution receipts.
- `sha256-inventory.json`: exact source, tree, test, patch, log, and project pins.
- `receipt.md`: this report.

No live candidate file, driver, shared non-Gaussian source, repository artifact, Git state, or remote state was changed. No Git directory was copied.

## 5. Checks Run

Graft callers were consulted before the change. Cache refresh failed with EPERM; frozen numbered source supplied current coordinates. The earlier lane preflight identified active validator and pedigree-test leases; this task used scratch files exclusively.

Estimate given before runtime: under one minute for the tiny Gaussian checks. Every Julia process used `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`, and `JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`.

Command, with output redirected to the named logs:

```sh
julia --project=/private/tmp/hsq-gllvm-input-fix-20260930 --startup-file=no /private/tmp/hsq-gllvm-input-fix-20260930/test/gllvm_input_guard_regression.jl
```

Initial control-only red run: 4 passed, 12 failed, exit 1. Complete red run: 25 passed, 25 failed, zero errors, exit 1; test execution time 1.2 seconds. The missing guards caused failures, including `tol=Inf` returning without the required exception at the nonstationary Gaussian initialization.

Green run: 50/50 passed, exit 0, test execution time 0.7 seconds. After moving fixtures inside the testset to avoid global-name collisions, the final green run again passed 50/50 in 0.7 seconds. The valid-input portion includes 5 scalar/vector Gaussian equality assertions plus 11 existing Gaussian one-step and multi-column fixed-effect basis reduction assertions copied from `test/genetic_gllvm_trait_effects.jl:67–124`.

Hash comparison independently confirmed the frozen source tree and the only changed copied source file. No full suite, non-Gaussian fit, simulation, campaign, GPU work, package update, or remote compute ran.

## 6. Tests of the Tests

The red logs demonstrate that the regression catches the old behavior. The complete red run recorded 25 missing-guard failures and zero test errors. Existing controls passed before the patch and after it, supporting preserved valid Gaussian objective values, mode behavior, and `maxiter=0` diagnostics.

## 7a. Issue Ledger

| Finding | Isolated disposition |
|---|---|
| C1 invalid tolerance certifies nonstationary mode | Fixed for both entry points; negative maxiter also rejects |
| Basic C4 malformed numeric/family/initial inputs | Fixed for the enumerated cases before rank/optimization |
| C2 incomplete proper-integral guard | Carried, unchanged |
| C3 per-record binomial dispatch | Carried, unchanged |
| C5 descriptor metadata validity | Carried, unchanged |
| Dense scaling, identifiability, extractor aliases | Existing limitations carried |

## 8. Consistency Audit

Frozen base GLLVM SHA-256: `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca`.

Isolated patched GLLVM SHA-256: `44e871db58417273e04d4e76b00db6d81edb28e6fddef21505e9248af0fd0a15`.

Frozen source-tree SHA-256: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.

Isolated patched source-tree SHA-256: `570123ce873c76a7e015ff6a3fa26359d4bee9f460f1c0b53a8d86beaff6689a`.

New test SHA-256: `59d254178a426bd58a6bf7ea58d416bc517acc8e9505622bea297007858a7edf`.

Patch SHA-256: `b3dd47ab24c491ec4e727cb3a36b2d5aa89a5dfc1bc3bb35092853029fff9ef1`.

The inventory lists exact log and copied Project/Manifest pins. The source-tree algorithm matches the frozen driver's relative-path/NUL/file-bytes/NUL construction. A scratch unified patch can change future source pins; this repair supplies no new evidence for the frozen primary run.

## 9. What Did Not Go Smoothly

Graft cache writing was unavailable in the frozen worktree. Current line coordinates were read directly. The first red run stopped at its failed control testset; nesting the cases under one outer testset allowed all guard failures to be recorded before implementation.

## 10. Known Residuals

The patch is isolated and awaits the parent's review and landing after the freeze. It adds a one-time numeric Y/X materialization before the fitter's existing repeated dense kernel calls; dense execution remains the documented validation-scale route. Shared family constructors remain unchanged. General proper-integral validity and general family execution remain open. The new test is standalone; the parent must add its include to the live test runner when landing.

## 11. Team Learning

Entry validation preserves the distinction between malformed caller inputs and numerical failures at optimizer trial points. A finite positive tolerance is necessary for the stationarity-based convergence contract.

Memory receipt: the earlier scoped review supplied all technical routing; current source, Graft callers, and the red/green logs supplied repair evidence. Golden Set: no broader campaign was run for this narrow isolated repair. No memory was updated.

## 12. Cross-Product Coverage

This task covers both Julia GLLVM entry points for the specified control/input classes and the tested Gaussian reductions. It does NOT cover C2/C3/C5 closure, generic R-v2 payloads, arbitrary conversion errors, empty-trait ingress, other family parameter guards, missing/unbalanced responses, recovery, calibration, inference, GPU execution, E1 signoff, capability promotion, or release readiness.

Next parent action: inspect the unified patch and red/green receipts, preserve the frozen primary candidate until its acceptance work is complete, then apply the reviewed source/test patch in the parent's owned lane and include the standalone regression in the package test runner. Record fresh landed source pins and update only C1 and the enumerated C4 dispositions.
