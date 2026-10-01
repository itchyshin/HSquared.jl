# Genomic matrix construction review, 2026-09-30

## Scope and pins

Read-only Karpinski review of genomic relationship construction, inversion, activation, APY, and LOCO paths. The exact candidate pins matched:

| File | SHA-256 |
| --- | --- |
| `src/genomic.jl` | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` |
| `test/test_genomic_greml_s0_identity.jl` | `76d01f3d17e6f05ce9701ea54860abc76176a4e70293988033b5f639247784c5` |
| `test/test_relationship_diag_1pF.jl` | `7f356265f00e676c365ddb6b657bb078e95776865fe635d380176906ee061332` |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` |
| `test/wave1_numerical_contracts.jl` | `2a983d2e5526e945ec6eb090895e7db8c5830cf0b06a7fb9758ecb890d695ed6` |

Reviewed `src/genomic.jl:15-457`, including marker centering and relationship construction (`:78-117`), inverse (`:136-151`), activation/provenance (`:157-329`), APY (`:355-392`), and LOCO (`:413-457`). The identity-GREML test is direct genomic evidence; `test/test_relationship_diag_1pF.jl` tests pedigree relationship diagonals and is not counted as genomic validation. Six refs with divergent work were reported for `src/genomic.jl`; no source edit or test was made.

## Findings

- The reviewed construction and inverse routes use dense relationship matrices. Construction has quadratic storage; dense inversion has cubic cost. The inspected source does not establish sparse genomic precision construction.
- Activation copies and centers marker data before calling a relationship constructor that centers again, retains dense relationship and precision objects, and fingerprints full objects. This adds passes and raises peak-memory demand.
- APY reduces the arithmetic structure but still returns dense precision, so output storage remains quadratic.
- LOCO masks/slices marker data and rebuilds and densely inverts a relationship matrix for each group. Group-wise scaling and peak memory are unmeasured.
- The public signatures accept broad matrix and backend types, but return-type stability and allocation behavior across them have not been demonstrated. Ridge handling is not normalized identically in `genomic_relationship_inverse`, activation, and APY routes.
- A finite guard exists after an in-place symmetry pass. The pass itself is quadratic.
- Small tests cover hand-computed values, centering/method identity, weighted construction, symmetry/overflow, ridge inversion, APY core choices, provenance fingerprints, and small LOCO examples. They establish bounded correctness examples, not scaling, allocation, inference, or peak-memory performance.
- No GPU execution or GPU completion claim was reviewed.

## Verdict and limits

Component verdict: **conditional pass** for the inspected small-example construction and guard contracts, with material dense-scaling and validation limits carried. No test, benchmark, fit, or simulation was run by the reviewer. This is not a performance signoff, genomic inference validation, full-file review, E1 closure, or GPU review. It does not change capability status, covered count, or release status.
