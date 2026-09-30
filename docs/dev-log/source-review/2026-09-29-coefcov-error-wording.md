# Exact-current bridge error wording review

## Scope and pin

Candidate: `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.

| File | SHA-256 |
| --- | --- |
| `src/bridge_payload_v2.jl` | `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0` |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` |

## Review and repair

Boole found the single `coefcov` block dispatched to an error naming a “multi-block random-regression estimator,” which incorrectly described the rejected route. The runtime error and the public `fit_payload_v2` docstring now say that no `coefcov` payload fitting route is wired. A regression checks that parsing accepts the frozen block syntax, fitting raises `Phase0NotImplementedError`, and runtime and docstring wording agree.

Boole's exact-hash follow-up passed. The review confirmed neighboring block types, dispatch constraints, payload-version checks, and response-field boundaries remain consistent. The focused probe passed after the repair. The integrated Julia 1.10 `Pkg.test()` on this candidate exited 0 and ended `Testing HSquared tests passed`; the parser integration group reported 66/66.

## Limits

This closes only the error-wording contract. The `coefcov` fit route remains unwired, the payload schema remains unratified, and this does not close whole-file E1 or the R-Julia bridge contract. A2 and V3 remain open. No capability row or public covered count changed; no GPU, release, registry, merge, or tag action occurred.
