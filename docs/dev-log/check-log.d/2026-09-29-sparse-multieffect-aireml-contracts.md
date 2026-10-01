# Check log shard: sparse multi-effect AI-REML contracts

- Date: 2026-09-29
- Worktree: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`
- Branch: `codex/hsquared-fa-gllvm-20260927`
- HEAD before this slice: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`
- Focused command: `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --compiled-modules=no --project=. -e 'using Test, Random, HSquared, SparseArrays, LinearAlgebra; include("test/test_aireml_workspace_reuse.jl")'`
- Focused result: pass, 51/51.
- Full command: `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --compiled-modules=no --project=. -e 'using Pkg; Pkg.test()'`
- Full result: exit 0; `Testing HSquared tests passed`.
- `git diff --check -- src/likelihood.jl src/iterative_solve.jl test/test_aireml_workspace_reuse.jl`: pass.
- Review: Gauss PASS and Noether PASS on source `1c47fc86fa61a36a8817866e2cd8af1464354079adefd2a30c979b6ef35f9d69` and test `350e6498d9147742c2597a5cd9405b30a4c410e183fc873ff6dd385e17420856`.
- Environment note: Julia warned that project compat/dependencies differ from the existing manifest; no dependency resolution was performed.
- Boundary: no public capability/status change, R bridge change, GPU work, release submission, registry submission, merge, or tag.
