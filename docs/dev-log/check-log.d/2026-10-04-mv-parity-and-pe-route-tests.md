# 2026-10-04 MV bridge and MV+PE focused checks

Status: exploratory current-tree evidence. This is not a frozen-source acceptance batch.

## Check

From `/private/tmp/hsquared-arc1-r-20261003`, run the four focused `devtools::test()` filters with `stop_on_failure = TRUE`, pointing JuliaCall to `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl` and capping Julia, OpenBLAS, OMP, and vecLib threads at one. The retained command output is `2026-10-04-mv-parity-and-pe-route-tests.log` (SHA-256 `a477e282aa55583106f7d34b1b03b89c80f29d09994f96a4e3b8d16677757ae0`). Process exit: 0.

## Result

| R test filter | Result | Meaning |
|---|---:|---|
| `multivariate-engine-parity` | 44 pass, 0 fail, 0 skip; 4 warnings | Live paired bridge parity and row-order checks for the animal-only multivariate fixture. The warnings correctly state that with repeated records and no permanent term, additive variance absorbs permanent-environment variance; its h² is not narrow-sense heritability. |
| `multivariate-permanent-237` | 26 pass, 0 fail, 0 skip | R parsing and target contract only. The test explicitly uses `engine = "validate"`; no fit is made. |
| `multivariate-permanent-recovery-237` | 11 pass, 0 fail, 0 skip | One pinned-seed live Julia MV+PE fit; basic finite/recovery sanity bounds only. |
| `multivariate-permanent-comparator-237` | 4 pass, 0 fail, 0 skip | One generated-data comparison against `sommer` with animal and identity permanent effects; point-estimate checks for selected G0/P0 elements only. |

The Julia and R checkouts were dirty on their Arc 1 branches. HEADs were Julia `0e4e5d742000f66bdb2127e43ca3756b432a5f10` and R `a563ea88f3076819a4a5d8966e2644489efd1688`. Directly implicated file hashes at execution were:

- Julia `src/bridge_payload_v2.jl`: `9d389444008a25ddfb3ba140836bab5a3d2c8ebfb94052424d8d1ac6c0c5a3e9`
- Julia `src/multivariate.jl`: `2947cb72d8850593a62ca41e84c8125a52194a12730d0ad2b72b4b3d57c474a9`
- R `R/julia-bridge.R`: `b295e74abf50ec6ad249a6a53de99aa047b916dbb353edbea3d26b132b7e2814`
- R test files: engine parity `d2fc41182815b25450343cc1a55b2bbb99dbb38e147ccbb94647f81ce158ed71`; MV+PE contract `3576f68021888efa69f2c192529688d1c2b1062708968488f5c85c1c9367238e`; recovery `b545c5daeb395e254db8fe89e8c6deda9f00e312387ba7ca34e28838797abb7e`; comparator `666397491d6961122cadb513169ecbb975941afada8d4ac5c2ff3a425999099c`.

These hashes do not freeze every transitive source, dependency, test, or protocol input. The results are route diagnostics on the current worktrees, not confirmation evidence and not a capability-status change. They do not establish MV+PE recovery over a seed set, interval coverage, all-target R/Julia parity, or broad MV acceptance. `sommer` and `nadiv` were installed; the comparator test reported no skips.

## Evidence and prose assessment

Style: 2/10, medium confidence; the test names and limits keep this short technical record concrete. Genre/coverage: internal check log, all sections reviewed. Evidence/repair: “exploratory current-tree evidence” states the scope at the start; no change needed. Gates: science passes for the narrow test claims only; facts pass against the retained log, source fingerprints, and test assertions; references pass for the internal paths cited. Provenance: self-review of this 2026-10-04 draft after inspecting these same tests and ledger entries; no independent style reviewer.

## Next executable leaf

Freeze the paired Julia/R MV+PE source, test, and seed identities; independently check the declared recovery and comparator criteria; then run only the predeclared development screen. Keep repeatability and broader MV+PE acceptance open until their seed-based criteria pass. Do not treat this one-seed fit or comparator as confirmation.
