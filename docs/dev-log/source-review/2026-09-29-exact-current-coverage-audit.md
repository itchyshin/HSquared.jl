# Exact-current source-review coverage audit

## Scope and pin

Read-only review of source-review coverage for E1 on candidate HEAD
`a7ca8ed557b23ec23c8486365e97a7bac4b71c16` with dirty working files. Two
independent audit agents compared Waves 1–4 packets to the current tree. The
following SHA-256 inventory was measured from every tracked `src/*.jl` file.
A current hash is a source pin; it does not imply full-file review when the
review receipt covers only selected spans.

| Source file | Current SHA-256 | Review disposition |
|---|---|---|
| `src/HSquared.jl` | `5c6c4c84e372e9adb75dd43d326e7603243286313c788cd3c98a599d1468eaf0` | Wave 3 baseline bytes unchanged; whole file reviewed. |
| `src/backends.jl` | `b22f118ea8aeba5dceb80918ee40a3f7d698211c69e91ee6c7e6c5b718b10cf9` | Wave 4 baseline bytes unchanged; scoped metadata review only. |
| `src/bridge_payload_v2.jl` | `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0` | Exact-current Boole component review covers parser signatures, dispatch boundaries, and single-block `coefcov` error/doc wording. Whole bridge/R contract and repeatability result shape remain open. |
| `src/control.jl` | `c466b4cf9e33fcafe8b4821791af54cc559a2dab78755fa759f387f6601e6b3f` | Wave 3 baseline bytes unchanged; whole file reviewed. |
| `src/data.jl` | `91ab80b4140459eb406547974876b1d15169d4fb5a2c3676ddaaf9ce3f16541a` | Current pin exists; empty-marker, parent-alias, and dictionary explicit-ID row-count follow-ups are covered. Other original spans remain open. Component receipt: `2026-09-29-dictionary-row-count-contract.md`. |
| `src/errors.jl` | `6ebb3635c308097213b1581fae26e94089969f34a07cbf5b735a5ee945d44fba` | Exact-current complete-file scoped PASS in `2026-09-29-errors-planned-terms.md`; low-severity `showerror` operation-string assertion gap remains. |
| `src/evolvability.jl` | `fd49987ee69c1f9b6e3335bdb6e4f8c73b6f0cdab3da4b7263cf4e87b6577ff3` | Current pin exists for stability follow-up; remaining numeric and coordinate limits are carried. |
| `src/genetic_gllvm.jl` | `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca` | Exact-current scoped objective/trait-effect review exists; full Wave 2 file and earlier findings remain partial. |
| `src/genomic.jl` | `72423bd1523dbcf25ef55081d89328c12004797637d8506e17e5ff574a87c021` | Current symmetry review pin exists; broader input and genomic-boundary spans are not covered at this exact pin. |
| `src/gpu_ext.jl` | `b5bfbe73e12363cb7c9d518841006554c220d93038294a1826faefc1a1b2767f` | Changed; static interface review only, no runtime or GPU execution. |
| `src/iterative_solve.jl` | `a7c0666e796664fa6a3c6f98136ab901be82897c7eff55c9a33fab9498d36402` | Differs from the last recorded review/test pin; whole-file current disposition missing. |
| `src/likelihood.jl` | `cd36e0c21802c9f4c71e9a0980ece50e926b7bb3337a3efc9442ef88365b8f11` | Exact-current optimizer/covariance-boundary review exists; original full-file review left spans open and genomic-boundary disposition is stale. |
| `src/model_spec.jl` | `d49de74e3990e18e73db37bab9b3019f46dcaa29c4f7102fc3f53fe60fa9f5fb` | Wave 3 baseline bytes unchanged; whole file reviewed. |
| `src/multivariate.jl` | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` | Exact-current FA and optimizer subsets reviewed; whole Wave 2 file and E4-02 current pin remain open. |
| `src/nongaussian.jl` | `d1f935c99e75e8c83cdb70469693dbe3574808123841d13bf7681bc243f1f616` | Differs from original and follow-up review pins; no exact-current full-source disposition. |
| `src/pedigree.jl` | `6bea72fffbd47d10b701d200145fa9b664a6dfc045199f6d604d78f0749a173f` | Current pin exists for input-contract fixes; original ranges 101–287 and 346–804 remain unreviewed. |
| `src/placeholders.jl` | `1f429afeb1a6f65865843a414cf397236e961b6ac4083b0c6a77f642cf77de2f` | Wave 4 baseline bytes unchanged; inert-entry-point scope reviewed. |
| `src/planned_terms.jl` | `a47d953d72565f347db805b5d0c7bdc86d5440dedaa6454c674f6e48c9607d5c` | Exact-current complete-file scoped PASS in `2026-09-29-errors-planned-terms.md`; adjacent grammar-table wording and all-row contract test remain open. |
| `src/plotting_ext.jl` | `e38c4d436d59bce93315eebc0296e6227fdd71990b25f2b4f608f302c458a569` | Wave 4 baseline bytes unchanged; stub/documentation scope reviewed. |
| `src/postfit.jl` | `d065d525ccdca8c8d881432f3c312141929571d52629f38bf72cfc513bdbf71f` | Wave 4 baseline bytes unchanged; delegation contract scope reviewed. |
| `src/random_regression.jl` | `761151eb0297bece4c859db8a504a244a26510d320f123f85a9a9295621e7a5c` | Exact-current optimizer/covariance-boundary subset; full Wave 2 review remains open. |
| `src/sparse_bridge.jl` | `f8a681b7491a002577747775fef26f486d53ab2b4b8def6f6071e7a5eb4c2427` | Matches reviewed baseline; CSC marshalling scope only. |
| `src/takahashi_selinv.jl` | `38a07e2e34da2f4a295e52e25b1f1d067a0b7e1b2893bdef8c73f1f78c704782` | Exact-current Gauss review plus failed-factor and non-finite-result guards; severe-conditioning and support-error timing remain open. Component receipts: `2026-09-29-selected-inverse-and-pcg-review.md`, `2026-09-29-selinv-factor-guard.md`, `2026-09-29-selinv-finite-range.md`. |
| `src/validation_status.jl` | `8778dd2513603115c43f51b4e57fb6d87495a8c8061b66195f58c00a90a4df28` | Rose exact-current status/claim wording review PASS WITH LIMITATIONS; source and capability-table hashes match. The engine-control test changed after Rose's pinned test hash, so exact-current test integration remains open. |

## Findings and disposition

Both independent audits find E1 **HOLD**. Wave 1/2 packets list their scoped
files, but exact-current pins cover selected subsets, not every declared span.
Largest gaps include `iterative_solve.jl`, `takahashi_selinv.jl`, and
`nongaussian.jl`. Wave 3 still has unreviewed pedigree/data ranges; the bridge
has a current parser/error component review but not whole-contract or bilateral
R signoff. The `errors.jl` and `planned_terms.jl` files have current complete-file
reviews, with the `showerror` assertion and adjacent grammar-table consistency
gaps retained. Wave 4 has a current status/claim component review, but the
engine-control test hash changed after the review and needs a current integration
check. GPU review remains static-only, and the genomic-boundary portion of
`likelihood.jl` still needs an exact-current disposition. Fixed findings have
local tests where recorded, but the coverage receipts do not prove complete
source review.

The bounded reviews and the full test run are useful evidence; neither closes
E1. No GPU execution is part of this programme. Next, split the uncovered
source spans into pinned, disjoint review waves, carry findings explicitly,
and obtain independent signoff after fixes.

## 2026-09-29 exact-current component receipts update

The table pins above incorporate exact-current reviews completed after the
original coverage audit. Boole reviewed the current payload-v2 parser and its
runtime/doc error contract; Rose reviewed current capability-status wording;
the existing errors/planned-terms packet covers both complete source files.
These are component dispositions only. The current engine-control test hash
changed after Rose's pinned test hash, so its integration must be checked
separately. Whole E1 source-wave coverage, the bilateral R contract, A2, and V3
remain open.
