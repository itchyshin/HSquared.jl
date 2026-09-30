# Exact-current source review: GLLVM trait effects

Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.

## Pinned scope and verdict

- `src/genetic_gllvm.jl`, SHA-256 `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca`.
- `test/genetic_gllvm_trait_effects.jl`, SHA-256 `a5c68350b2778e069e9c0b2d4cb1542a40b33e406e621bed5495863f4418698b`.
- Formula/objective context: `docs/design/genetic-gllvm-objective-contract.md`, Model and units section.
- Falconer verdict: PASS for reconstructed trait-effect and interpretation contract, with acceptance limits below.

## Findings

`_gllvm_trait_effects` reconstructs `F * Λ'` and, for FA, adds `Dstandard * Diagonal(sqrt(ψ))`, so the fitted trait effects implement `U = FΛ' + D` when augmented latent modes are standard normal. The fitter stores this reconstructed `q × T` trait-scale matrix rather than rotation-dependent factor scores. The docs describe them as approximate conditional modes on the link scale, not posterior means. `G = ΛΛ' + diag(ψ)`, and the result does not claim response-scale heritability.

Trait stacking is column-major, traits outermost and animals within trait; returned `trait_names` preserve input column order. Existing tests cover the direct equation, orthogonal rotation invariance for low-rank and FA helpers, dimensions, fitted trait permutation for covariance/beta/effects/names, and pedigree-row permutation with ID-aligned comparison.

## Limits

- The equation is tested at helper level; a fitted result intentionally does not expose raw factor modes/loadings, so the equation is not recomputed from a returned fit object.
- `GeneticGLLVMFit` returns trait names but no animal IDs. Result rows therefore depend on preserving `Y`/`Ainv` order. The bounded R bridge must map IDs explicitly before exposing those rows.
- The output is a conditional mode, not a conventional posterior-mean EBV. Current docs state this caveat.
- This review does not establish broad recovery, missing/unbalanced-data support, response-scale summaries, or general public GLLVM coverage.

## Twin R bridge cross-check

In the matching R candidate worktree `/private/tmp/hsquared-fa-gllvm-20260927` at HEAD `fa98c262eb21694d672e671c9672491ce3369cec`, `hs_fit_julia_gllvm_payload` reorders `Y` and `X` with the same `row_order`, passes the pedigree-order IDs and trait names to Julia, checks that normalized Julia pedigree IDs exactly match, and returns both IDs and trait names. The R normalizer then requires returned IDs and traits to match the original payload order. Pinned R hashes: `R/julia-bridge.R` `4cb8074949c8b843727cd4d6acf8ef720113967e5820f135c5170bc3496e24c2`; `tests/testthat/test-gllvm-optin.R` `a7f33d6ff78f7f3296bcf1a4eec95c735711e5af0e3de77e8532b7d0c08d4bc7`. Its recorded exact-current live GLLVM filter passed 87 assertions with no failures, warnings, or skips. This closes the ID-order concern for that R bridge candidate, not for direct Julia callers.
