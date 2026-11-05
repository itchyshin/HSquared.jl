# 2026-11-04 PR 495 Logging test target

Scratch source copies at PR head `71deb2e053537c0200a6d71ee85a65f89a39b22b`
used the package project and test target, with scratch `test/runtests.jl`
including only `test_issue_416_sibling_fitters_warning.jl`.

- Before the test-only dependency, Julia 1.12.6 `Pkg.test()` failed with
  `Package Logging not found in current path`.
- After declaring Logging in `[extras]` and the test target, the same focused
  `Pkg.test()` passed 44 assertions on Julia 1.12.6 and 44 on 1.10.12.
- `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=2` and one precompile task were used.

This was not the full package suite; hosted CI remains pending.
