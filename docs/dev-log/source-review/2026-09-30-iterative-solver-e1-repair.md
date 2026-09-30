# Iterative-solver E1 repair review

## Scope and verdict

Bounded component PASS for the fixed-effect rank guard, likelihood iteration-budget guard, and matrix-free likelihood error wording. This is not a full-file or whole-wave E1 signoff.

The prior exact-current review found that rank-deficient fixed effects could be accepted by zero-right-hand-side PCG, that the matrix-free likelihood did not reject a nonpositive PCG iteration budget, and that its reported probe MCSE could be mistaken for total likelihood error. The fixes are in `src/iterative_solve.jl` and `test/wave1_numerical_contracts.jl`.

## Exact pins

- `src/iterative_solve.jl`: `41f50393dd75dfca942f8b53b06ad1a7b50419cdecf3d7d74e3e34605ee06ef2`
- `test/wave1_numerical_contracts.jl`: `2a983d2e5526e945ec6eb090895e7db8c5830cf0b06a7fb9758ecb890d695ed6`

Gauss/Astra reviewed the implementation at the prior source hash `53433153fdb52c4a86d22f5830e29af3f3728cb3277d8e6559847bfd29c91f0f`; only the two documentation lines described in the review changed afterward. Noether confirmed the current source hash and both wording fixes. Rose reviewed the current exact source hash and returned clean-with-limitations. The rank check uses sparse QR in solve, trace, fit, likelihood, and information paths; the valid zero-column fixed-effect case bypasses the rank computation. `pcg_maxiter >= 1` is checked before the likelihood solve. The docstring separates exact `log|R|` and `log|G|`, SLQ approximation of `log|C|`, PCG error in `y'Py`, and the narrower meaning of `loglik_mcse`.

## Evidence

- New RED tests failed on the old source for duplicate and zero fixed-effect columns across the affected iterative routes, and for likelihood budgets zero and negative on a zero response.
- Final focused Wave 1 numerical contract test: 152/152 passed, including an independent Gaussian likelihood reduction and a `p=0` information-matrix reference.
- Julia 1.10 `Pkg.test()`: exit 0; final output `Testing HSquared tests passed`.
- `julia --project=docs docs/make.jl`: exit 0; local documentation rendered.
- The focused test was rerun after the two docstring-only edits and passed 152/152 on the current source. The full suite and docs build ran on the immediately preceding source hash; neither was rerun because the final changes only altered docstrings.
- `git diff --check`: passed; `bash tools/preamble_cap.sh`: passed at 11,024 bytes under the 14,000-byte cap; `bash tools/build_check_log.sh --check`: all 249 entries well-formed.

## Limits carried

Noether found no blocking mathematical defect. Karpinski found sparse SuiteSparse QR dispatch with no source-level densification, but flagged repeated QR cost during iterative fits. A local warm-call check at n=5000 measured median 0.000166 s and 0.74 MB allocated for p=20 (409 stored entries), and 0.00840 s and 15.3 MB for p=200 (4,191 stored entries), five calls per case. This measures the guard alone; full-fit impact, peak memory, and near-collinear rank classification remain unmeasured.

The exact component review does not cover every span of `iterative_solve.jl`, the rest of Wave 1, other Julia source files, or the R bridge. Separate current E1 reviews have also found open pedigree wrapper and ID-alignment findings. E1, A2, and V3 remain open. No capability row, covered count, release state, or GPU state changed.
