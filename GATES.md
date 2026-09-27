# HSquared twin FA/GLLVM programme gates

OWNS: src/**, test/**, docs/**, GATES.md; sibling hsquared R/**, tests/**, docs/**

Scope: Deliver bounded opt-in FA and genetic GLLVM fits through hsquared, then review every tracked HSquared.jl src file and the public bridge. Programme branch starts at Julia faed40182 and R 86f40f41. No GPU work, CRAN or registry submission, or public release tag.

- [x] A1: FA symbolic contract, local-identifiability limits, uniqueness boundary, ordering, scale, and status claims agree in both twins.
  EVIDENCE: `docs/design/fa-t4k1-identifiability-and-units.md`; `test/fa_independent_dense_reml.jl` 7/7; Julia and R capability/debt rows; `docs/dev-log/scout/2026-09-27-fa-same-model-reference.md` records one near-boundary independently fitted check and its limits.

- [ ] A2: FA engine review records source spans, findings, numerical checks, and agent-panel verdict.
  EVIDENCE: `docs/dev-log/source-review/2026-09-27-wave2.md` records full `multivariate.jl` spans and findings; scoped numerical repairs and 24/24 G-guard tests pass. The wave and independent panel signoff remain HOLD.

- [x] B1: Four-trait Gaussian K=1 pedigree FA is usable through a documented opt-in R route with invariant G, uniqueness limits, correlation, and diagnostics; unsupported routes fail clearly.
  EVIDENCE: R `tests/testthat/test-fa-optin.R` and `vignettes/articles/multivariate.Rmd`; 50 live same-input parity checks plus final focused opt-in rerun; R package check Status: OK. This is a partial expert route; default-iteration convergence, broad recovery, and inference are open.

- [x] C1: Genetic GLLVM symbolic objective and Gaussian reduction are named correctly; trait breeding values include factor and uniqueness terms, with invariant extraction.
  EVIDENCE: `docs/design/genetic-gllvm-objective-contract.md`; `test/genetic_gllvm_trait_effects.jl` 4/4 and 5/5 trait-effect tests; independent Gaussian reduction and observed-curvature regression; final `Pkg.test()` pass.

- [x] C2: Ordinary-start and restart checks, tiny oracles, and negative tests establish the selected Poisson cell independently of truth-start recovery.
  EVIDENCE: `test/genetic_gllvm_trait_effects.jl` 7/7 Poisson guards and 9/9 ordinary-start assertions; final `Pkg.test()` pass. Broader recovery remains open.

- [x] D1: Three-trait Poisson-log K=2 pure-low-rank pedigree GLLVM is usable through a documented opt-in R route with link-scale conditional modes and limits.
  EVIDENCE: R `tests/testthat/test-gllvm-optin.R` and `vignettes/articles/genetic-gllvm.Rmd`; 49 same-input direct-Julia parity checks, 38 ordering/ID checks, final opt-in rerun, R package check Status: OK. This remains partial without an external same-objective comparator.

- [ ] E1: Every tracked core src file and public bridge contract has a pinned-span review disposition; findings are fixed or explicitly carried.
  EVIDENCE: four packets under `docs/dev-log/source-review/2026-09-27-wave*.md` inventory all 24 tracked `src/` files, with the CUDA stub reviewed statically only. Wave 1 and 3 have unreviewed spans, waves 1–4 remain HOLD, and independent panel signoff is open. Carried findings are explicit in the packets.

- [x] V1: Julia package suite passes on the final candidate.
  CHECK: julia --project=. -e 'using Pkg; Pkg.test(); println("HSQ_JULIA_TESTS_OK")'
  EXPECT: HSQ_JULIA_TESTS_OK
  EVIDENCE: `/private/tmp/hsq-fa-gllvm-pkg-test-20260927-final4.log` ends `Testing HSquared tests passed`, exit 0. The writable source copy's `src/` and `test/` contents checksum-match the candidate; only timestamps differ. No checkout source was altered for the test.

- [x] V2: Julia documentation builds on the final candidate.
  CHECK: julia --project=docs docs/make.jl && echo HSQ_JULIA_DOCS_OK
  EXPECT: HSQ_JULIA_DOCS_OK
  EVIDENCE: `/private/tmp/hsq-fa-gllvm-docs-20260927-final2.log` exited 0 from a writable identical source copy with a temporary local Git repository for Documenter metadata. The managed checkout itself could not regenerate the status page under the sandbox.

- [ ] V3: R package check, bridge parity, current CI, capability/debt rows, check logs, after-task reports, and Rose audit pass for the final candidate.
  EVIDENCE: R package check Status: OK (`/private/tmp/hsquared-fa-gllvm-rcmdcheck-20260927-postrose.log`); pkgdown check clean; 50 FA and 49 GLLVM live parity checks plus final opt-in rerun; both twins' capability/debt rows and reports updated; Rose audit clean with limitations (`docs/dev-log/source-review/2026-09-27-rose-claims.md`). CI and final cross-repo panel signoff are pending.

- [x] V4: The candidate stops before CRAN submission, Julia registry submission, and public release tag.
  EVIDENCE: Candidate branches retain version 0.9.0 and contain no new public release tag or submission. The user's existing 0.9.0 CRAN submission remains in its separate review lane.

At each arc boundary, record exact commits, met/unmet/abandoned counts, compute estimates, test results, and next arc. A gate stays open if evidence is incomplete. A run estimated above three hours requires a pre-run result and Shinichi's approval.
