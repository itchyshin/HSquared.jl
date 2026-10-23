# Check log: exact-current Gaussian FA review

- Worktree: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`
- HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`
- Source hash: `src/multivariate.jl` `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670`
- Focused test hashes and counts: uniqueness `56022f...` 29/29; multistart `ad018c...` 51/51; ordinary-start driver `1a4127...` was inspected but not run in this focused command.
- Exact focused commands: the uniqueness-map file passed 29/29; `julia --project=. -e 'using HSquared, Test; include("test/test_multivariate_fa_multistart.jl")'` passed 62/62 on its updated hash.
- Focused outcome: 91 assertions passed across the two exact-source focused runs. The updated multistart run includes 11 fitted trait-permutation assertions.
- Independent reference: `Rscript /private/tmp/fa_same_model_reference.R`; R 4.6.0 BFGS converged in 1.033 s.
- Candidate fit: `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH=/private/tmp/hsq-fa-depot:/Users/z3437171/.julia julia --project=. /private/tmp/fa_same_model_reference.jl`; Julia 1.10.0 converged in 5,500 iterations and 2.565 s after package load.
- Crosscheck: `Rscript /private/tmp/fa_same_model_crosscheck.R`; max absolute G/R differences `7.2491e-6` / `1.5804e-5`; independent EBV recomputation difference `3.22e-15`.
- Hashes for all three scripts are recorded in `docs/dev-log/source-review/2026-09-29-fa-exact-current-review.md`.
- Interpretation limit: one truth-informed fixture, two uniqueness estimates within `5.1e-6` of the `1e-4` floor; no routine-start recovery or fitted-likelihood information claim.
- Panel: Kirkpatrick and Noether conditional on the covariance map and passed review of the fitted trait-order test; Rose clean with limitations. A2 remains open.
