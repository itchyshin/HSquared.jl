## Arc 1 current-source optimizer contract rerun, 2026-10-19

Command: `julia --compiled-modules=no --project=. -e 'using Test; include("test/arc1_optimizer_contracts.jl")'`.

Result: exit 0; 289/289 assertions passed in 12.2 seconds with Julia 1.10.0. The retained log is `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/recovery-20261019/g2-optimizer-contract-current-source-20261019/optimizer-contracts.log` (SHA-256 `c394173a6f935bd752aead62c2e39d6d028f05c40b2a59203ea3b60ad2d3d151`). Receipt: `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/recovery-20261019/g2-optimizer-contract-current-source-20261019/receipt.json`.

Source pins: `src/arc1_fa.jl` `35eb9e1a9f8f44b1149b5c352a05c6fbf21849dfab6c9a76488a2910681b732f`; `test/arc1_optimizer_contracts.jl` `df39249b82d143c7cebec133cccfeb6e5be73b3cc85560c438f1a2624699787b`. No model fit, seed, pilot, confirmation, or R check ran. G2 remains open and this result grants no gate credit. G6 and G7 are currently reopened pending fresh checks on the profile-v4 source identity.
