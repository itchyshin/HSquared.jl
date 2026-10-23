# Evolvability numerical stability closeout

Date: 2026-09-29. Julia 1.10.0. Candidate branch `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`; reviewed files are dirty, so hashes below identify the tested bytes.

## Scope and estimate

Bounded numerical hardening of G-matrix evolvability summaries. The focused test was estimated under one minute and the complete package suite at about 8–10 minutes from the prior same-checkout run. No simulation, fit campaign, benchmark, or external comparator was run.

## TDD and implementation

The new regression file first reproduced failures for an ill-conditioned positive-definite `G` (autonomy exceeded its mathematical upper bound), extreme finite covariance scales (overflow/underflow in mean evolvability and explained-variance fractions), an unrepresentable eigenvalue, and very large/small finite `beta` norms. Fixes use scale-normalized Cholesky and a maximum condition-number bound of `1/sqrt(eps(Float64))` for inverse metrics, scale-safe covariance summaries, finite eigenvalue checks, and max-absolute-value normalization for `beta`. Tests compare regular, huge, and subnormal vectors in the same non-isotropic direction, including autonomy.

## Exact hashes

- `src/evolvability.jl`: `fd49987ee69c1f9b6e3335bdb6e4f8c73b6f0cdab3da4b7263cf4e87b6577ff3`
- `test/test_evolvability_stability.jl`: `c7281841ce51279ce4f7e68b0f94625baab04cdbe06c4519191efe06b26c4777`
- `test/runtests.jl`: `f55e4682015a2b4aa37b6b1c84a6c8e4df5beaf4376355687e0860af47b13ac0`
- `docs/src/multivariate-models.md`: `685525aeba2896be6e4697d2b04141fc7a65fcd10ae0953abb752c7de4e4bbcf`

## Commands and results

Focused test:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-review-depot:/Users/z3437171/.julia JULIA_PKG_OFFLINE=true julia --project=. --startup-file=no -e 'using HSquared, LinearAlgebra, Test; include("test/test_evolvability_stability.jl")'
```

Result: 18/18 passed.

Full package suite:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-review-depot:/Users/z3437171/.julia JULIA_PKG_OFFLINE=true julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: exit 0, ending `Testing HSquared tests passed`. Pkg reports the existing Project/Manifest mismatch; no resolve or update was run. `git diff --check` passed. The docs build had passed earlier with the same manual source bytes; existing missing-docstring, deployment-autodetection, VitePress config/favicon, and bundle-size advisories remain. The full docs build was not repeated after the documentation-only ledger/report edits.

## Independent review and limits

Gauss and Noether reviewed the final numerical implementation and normalization; Kirkpatrick reviewed the matrix definitions; Rose's bounded public-claim audit found no reason to promote status. The `V4-EVOLVE` row remains `partial`. The condition threshold rejects ill-conditioned inputs but does not establish broad conditioning performance or invariance to trait rescaling. External comparator, fitted-FA inference, calibration, and the rest of Wave 4 remain open. No status promotion, GPU run, release action, registry submission, merge, or tag.
