# Exact-current selected-inverse factor guard

- Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Scope: failed/partial CHOLMOD factor handling at the shared `_selinv_zvals` entry point.
- Exact files: `src/takahashi_selinv.jl` SHA-256 `818cc7bbd99d46e5cda2fe0f95dab456d2d013c2d381cbd52c6c7cc5836280cd`; `test/test_selinv_trace_contracts.jl` SHA-256 `1d951d1809763fa66fc980fce33aebb3939408c2861b8250e03a6cf27f7580b5`; `test/runtests.jl` SHA-256 `e60e5ba2c968076604369d5b5313e736f82f7d73802cdb18c757a41faf77852a`.
- Initial finding reviewed by Gauss: `CHOLMOD.Factor{Float64}` does not guarantee successful factorization. On Julia 1.10, a singular sparse matrix factored with `check=false` returned the factor type with a zero diagonal pivot, and selected inversion returned `[Inf, Inf]`. Normal in-repo callers use checked factorization; the kernel did not enforce its own input requirement.
- Independent post-fix review: requested from Gauss on the exact hashes above; pending at the time this packet was written.

## Repair

`_selinv_zvals` now rejects nonfinite factor entries, missing diagonal entries, and diagonal entries that are not finite and positive, with `ArgumentError`. The check is shared by diagonal extraction, selected-inverse materialization, and trace helpers.

## Verification

- TDD red: the direct `check=false` singular-factor test failed as expected because no exception was thrown.
- Focused green: `test/test_selinv_trace_contracts.jl` passed 30/30 assertions, including the new malformed-factor test.
- Full green: Julia 1.10 `Pkg.test()` passed on these final source/test bytes and ended `Testing HSquared tests passed`.
- `git diff --check` passed. The test run retained the existing Project/Manifest compatibility warning; no resolve or update was run.

## Limits

This checks finite stored values and positive diagonal pivots; it does not establish numerical stability under severe conditioning or validate every caller's precision matrix. Support errors are still detected after `_selinv_zvals` recursion. The guard is a component repair, not E1 signoff. No capability, validation-debt, covered-count, release, or GPU status changed.
