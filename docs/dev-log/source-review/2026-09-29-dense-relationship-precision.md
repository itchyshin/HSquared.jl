# Dense Gaussian relationship precision: exact-current review

## Scope and pins

- Worktree: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`
- `src/likelihood.jl`: SHA-256 `19974d322f39c18e9788cccc8bf9daccd2933a21bb48680c2f2f6ec8772889a3`
- `test/wave1_numerical_contracts.jl`: SHA-256 `d3b8fb036f24e9bf350a070a6441ea8f3196bfd6a048078b3d3c8a9fb458f02c`
- `test/runtests.jl`: SHA-256 `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691`
- Reviewers: Gauss and Noether; both returned exact-hash **PASS** for this scoped guard.

## Findings and repair

The dense Gaussian fitter had lost its explicit ML/REML membership check. Its shared precision helper also wrapped input in `Symmetric` without first checking the raw matrix, which could accept asymmetric precision by reading one triangle. The helper now rejects non-finite and asymmetric Float64 precision before checked Cholesky, and the fitter rejects unsupported methods before optimization. The checked covariance is computed once and reused by the objective.

The existing inverse operation was retained. An earlier solve-based replacement shifted a near-boundary fit enough to fail the #350 quickstart fixture; that alternative was reverted before this repair.

## Evidence

- Red phase: regression tests reproduced the missing fitter method guard and asymmetric-input acceptance.
- Focused `wave1_numerical_contracts.jl`: 126/126 numerical-contract assertions, plus the new precision-route testsets passing 4/4 and 4/4. The same file also reported the existing genomic relationship (16/16), APY finite/scale (8/8), and APY partial-core (5/5) tests passing.
- Full Julia 1.10 `Pkg.test()`: exit 0; output ended `Testing HSquared tests passed`.
- `git diff --check -- src/likelihood.jl test/wave1_numerical_contracts.jl test/runtests.jl`: passed.
- Gauss and Noether confirmed all three exact hashes and the scoped guards. They performed source review only; neither ran tests or fits.

## Limits and open work

The fitter's asymmetric and non-finite cases are not asserted directly, though the fitter calls the reviewed shared helper. The tests check exception types, not message text. Exact `issymmetric` is the contract, with no tolerance-based repair. This is not a whole-file source review or a wave sign-off. FA gate A2, source-review gate E1, and GLLVM gate V3 remain open; no capability or covered-count row changed.
