# Selected-inverse finite-range guard: exact-current review

## Scope and pins

- Worktree: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`
- Source `src/takahashi_selinv.jl`: SHA-256 `38a07e2e34da2f4a295e52e25b1f1d067a0b7e1b2893bdef8c73f1f78c704782`
- Regression `test/test_selinv_trace_contracts.jl`: SHA-256 `ac0cc9a8d371093c6aa8719ef612f794486db6e55c7470c01af800b5a7eb4a05`
- Independent reviewer: Gauss; verdict: **PASS for the finite-range guard**.

## Finding and repair

A valid `check=true` Cholesky factor for the 1×1 SPD matrix `[1e-320]` has a finite, positive factor diagonal near `1e-160`, while its inverse is outside Float64 range. The pre-existing factor-pivot guard therefore accepted it and both selected-inverse routes returned non-finite values.

`_selinv_zvals` now verifies that all computed selected-inverse values are finite before returning from the `per_pair` reference branch and after the optimized recursion. The new regression checks the factor diagonal, then expects `ArgumentError` from both `takahashi_diag` and `_selinv_zvals(...; per_pair=true)`.

## Evidence

- Red phase: both expected exceptions were absent on the exact tiny-SPD case.
- Focused regression after repair: selected-inverse tests pass 33/33.
- Full Julia 1.10 `Pkg.test()`: exit 0; output ended `Testing HSquared tests passed`.
- `git diff --check`: passed for the source and regression.
- Gauss confirmed both return paths are checked on the exact hashes above.

## Limits and open work

The guard prevents non-finite selected entries from escaping. It does not establish accuracy for ill-conditioned factors or prevent finite entries from overflowing later during trace multiplication or accumulation. Support-error timing and sparse performance evidence remain open component concerns. This is not whole-file or E1 signoff; E1, A2, and V3 remain open.
