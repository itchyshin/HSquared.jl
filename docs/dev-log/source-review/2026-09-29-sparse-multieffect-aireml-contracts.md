# Source review: sparse multi-effect AI-REML input contract

## Reviewed scope

- `src/likelihood.jl`: `_multi_reml_workspace` and `fit_sparse_multi_effect_aireml`.
- `src/iterative_solve.jl`: reused `_validate_matrix_free_precision` and sparse canonicalization contract.
- `test/test_aireml_workspace_reuse.jl`: registered workspace, control, and input-contract tests.

## Findings and repairs

Gauss identified missing iteration/tolerance/EM-warmup checks, starts not checked after `Float64` conversion, missing finite checks on converted model inputs, and unguarded invalid variance updates/final total. These were added with focused tests.

Noether then identified that the multi-effect workspace accepted asymmetric `Ainv`, while Cholesky's `Symmetric` wrapper and the full-matrix quadratic could use different effective matrices. The workspace now calls `_validate_matrix_free_precision` for each converted precision and stores its canonical sparse SPD result. Tests reject material asymmetry and verify roundoff averaging before downstream use.

## Final reviewed byte identities

| File | SHA-256 |
| --- | --- |
| `src/likelihood.jl` | `1c47fc86fa61a36a8817866e2cd8af1464354079adefd2a30c979b6ef35f9d69` |
| `src/iterative_solve.jl` | `265cfc8d6ba9ca33475b85c56c4701cdd0359b90db9b0cdcae47c6740f4d8a34` |
| `test/test_aireml_workspace_reuse.jl` | `350e6498d9147742c2597a5cd9405b30a4c410e183fc873ff6dd385e17420856` |

## Verification and panel verdict

- Focused workspace test: 51/51 pass.
- Full `Pkg.test()`: exit 0, ending `Testing HSquared tests passed` on the final source/test hashes.
- `git diff --check`: pass for changed code/test files.
- Gauss: PASS for numeric controls and sparse precision canonicalization.
- Noether: PASS; the prior precision inconsistency finding is closed.

This is a scoped input-contract review. It does not sign off FA or GLLVM inference, public bridge routes, or all remaining Julia engine source.
