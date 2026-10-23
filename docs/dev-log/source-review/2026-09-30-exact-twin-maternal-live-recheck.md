# Exact twin live maternal bridge receipt, 2026-09-30

The current intended R candidate passed the existing live direct-maternal regression against the frozen Julia source. Result: **90 passed, zero failures, zero warnings, zero skips**. Testthat reported 18.3 seconds; the full R process took 20.18 seconds and exited 0. Julia exited normally. The pre-run estimate was two minutes, with a process-group timeout at 120 seconds; the timeout was not reached.

R candidate: `/private/tmp/hsquared-fa-gllvm-20260927`, HEAD `fa98c262eb21694d672e671c9672491ce3369cec` plus existing dirty work. Julia candidate: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` plus existing dirty work. Julia source-tree SHA-256 matched `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` before and after the run.

The test file contains quick parser/payload/extractor fixtures and one live six-animal, eight-record fixture, including a direct Julia reference call. Only this test file ran. The existing live setup was taken from `docs/dev-log/check-log.d/2026-09-30-live-fa-gllvm-bridge-recheck.md` in the R candidate.

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 OMP_NUM_THREADS=1 \
JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia \
JULIA_PKG_PRECOMPILE_AUTO=0 HSQUARED_REQUIRE_BRIDGE=true \
HSQUARED_JULIA_PROJECT=/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl \
Rscript -e 'devtools::test(filter = "^direct-maternal$")'
```

The command ran from the R candidate. `devtools::test` enabled the maintainer test path. The recorded output confirms the exact Julia project activation and zero skips. The paired-result assertions at `tests/testthat/test-direct-maternal.R:525-540` ran: one random-effect record, maternal label, and exactly `name`, `ids`, `direct`, `partner` fields. The remaining live assertions checked variance components, genetic correlation identity, direct heritability, scalar variance/covariance extractors, breeding-value and maternal-effect tables, and direct/maternal variance agreement with `HSquared.fit_direct_maternal_reml` at tolerance `1e-6`.

This closes the transport evidence gap left by the synthetic result check in `/private/tmp/e1-exact-twin-maternal-recheck-20260930.md` for this small fixture. The committed R base still has the old reader; its existing dirty correction must be preserved during integration. This receipt does not establish coverage calibration, broad pedigree/model behavior, the separate coefcov parser contract, whole E1, or campaign acceptance.

All seven reviewed source/test file hashes were unchanged after execution:

| File | SHA-256 |
| --- | --- |
| Julia `src/bridge_payload_v2.jl` | `3f1c5eed39414860953898ec23e6a8cec622d90d7009f107519892b22b63a7e0` |
| R `R/julia-bridge.R` | `4cb8074949c8b843727cd4d6acf8ef720113967e5820f135c5170bc3496e24c2` |
| R `R/fit-object.R` | `a450dcc39b42189e91a264139b83c8af5fac564fccd46bc6e55dcd4ccddb1b0e` |
| R `R/extractors.R` | `d2a4c73453eb3e7c384ad656c0c046452a20a958a7cb61691b013393257ab163` |
| R `R/bridge-payload.R` | `a18645b6445069fef8f9c8202a9e08d59c26a3f84f8923c3b6105a6c19539ef9` |
| R `R/model-spec.R` | `894ad7d2eccee2c1a3eef4416a737916ffb03f39e0e189c6d5e4115fb5a07149` |
| R `tests/testthat/test-direct-maternal.R` | `7d2ba0e91e8c3a33a01045ad6afed5474947a782a294f297e40179714b4f17bf` |

Raw output: `/private/tmp/e1-exact-twin-maternal-live-recheck-20260930.log`. No repo source edit, simulation campaign, GPU run, commit, or push occurred. The test process completed within its estimate and was not left running.
