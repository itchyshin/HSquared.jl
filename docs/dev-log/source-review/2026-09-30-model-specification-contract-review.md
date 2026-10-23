# Model specification contract review, 2026-09-30

## Scope and pins

Read-only Henderson review of the low-level Gaussian animal-model specification helper and direct tests. Exact-current pins matched before and after:

| File | SHA-256 |
| --- | --- |
| `src/model_spec.jl` | `d49de74e3990e18e73db37bab9b3019f46dcaa29c4f7102fc3f53fe60fa9f5fb` |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` |

Reviewed `animal_model_spec` at `src/model_spec.jl:38-92`, fitted MME validation at `src/likelihood.jl:1174-1208,4245-4264`, and direct tests at `test/runtests.jl:2344-2367`. No tests or fits were run. Preflight found an older remote handover diff touching the helper's structure and signature; no source edit was attempted.

## Findings

- The helper checks method, Gaussian family, observation-row dimensions, square `Ainv`, the number of animal columns in `Z`, ID length, and basic `relationship_diag` length/finiteness/positivity. Its text correctly limits these checks to structure and does not claim that the diagonal matches `Ainv`.
- Animal IDs are not checked for uniqueness or missing values, and the helper cannot confirm that their order matches `Ainv` rows or `Z` columns. The MME result uses IDs as labels, so duplicates or wrong order can make animal effects ambiguous or mislabeled.
- `y`, `X`, `Z`, and `Ainv` are retained by reference. Mutating them after constructing the spec changes later fit inputs. IDs and `relationship_diag` are copied. Existing tests assert reference identity but the help does not explain this ownership contract.
- Exported direct `AnimalModelSpec` constructors can bypass helper checks. Any restriction needs to preserve internal constructor use in `src/iterative_solve.jl`.
- The helper does not check numeric types, finite `y/X/Z`, fixed-effect rank, or symmetric positive-definite `Ainv`. Some likelihood routes check parts of this contract, while the Henderson MME route does not provide equivalent validation. The helper packages structure; fitted-input validity still depends on route-specific checks.

## Verdict and limits

Conditional pass for the narrow structural helper contract. Public documentation should state that ID uniqueness/order and array ownership are caller responsibilities. Constructor bypass and route-specific numeric validation need separate design decisions. Direct tests cover dimensions, family, method normalization, ID length, and reference identity; they do not cover the findings above. This static review does not establish fitted animal-model validity, R-Julia alignment, or E1 closure.
