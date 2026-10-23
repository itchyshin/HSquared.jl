# Check log shard: GLLVM trait-effect contract

- Date: 2026-09-29.
- Candidate HEAD: `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- `src/genetic_gllvm.jl` SHA `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca`.
- `test/genetic_gllvm_trait_effects.jl` SHA `a5c68350b2778e069e9c0b2d4cb1542a40b33e406e621bed5495863f4418698b`.
- Falconer exact-current review: PASS for `FΛ' + D` reconstruction and link-scale interpretation; review did not run code or simulations.
- Existing registered tests cover the equation, rotation, trait order, and pedigree order. The current complete Julia `Pkg.test()` from this candidate passed after the pinned source/test bytes were present.
- Residual: Julia result has trait labels but not animal IDs; bounded R route must preserve or map IDs. No broad recovery claim follows.
