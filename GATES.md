# HSquared twin FA/GLLVM programme gates

OWNS: src/**, test/**, docs/**, GATES.md; sibling hsquared R/**, tests/**, docs/**

Scope: Deliver bounded opt-in FA and genetic GLLVM fits through hsquared, then review every tracked HSquared.jl src file and the public bridge. Programme branch starts at Julia faed40182 and R 86f40f41. No GPU work, CRAN or registry submission, or public release tag.

- [x] A1: FA symbolic contract, local-identifiability limits, uniqueness boundary, ordering, scale, and status claims agree in both twins.
  EVIDENCE: `docs/design/fa-t4k1-identifiability-and-units.md`; `test/fa_independent_dense_reml.jl` 7/7; Julia and R capability/debt rows; `docs/dev-log/scout/2026-09-27-fa-same-model-reference.md` records one near-boundary independently fitted check and its limits.

- [ ] A2: FA engine review records source spans, findings, numerical checks, and agent-panel verdict.
  EVIDENCE: `docs/dev-log/source-review/2026-09-27-wave2.md` records full `multivariate.jl` spans and findings; scoped numerical repairs and 24/24 G-guard tests pass. FA closeout review corrected the payload's uniqueness-identification status, rank/trait/unit definitions, repeated-eigenvalue caveat, stale REML keyword, and saturated T2 example. Scoped Sol and Rose reviews found no remaining must-fix in touched files after correcting Rose's table wording comment. Full Pkg.test and docs build pass in a writable copy; this does not close the whole source wave, fitted-information/routine-start evidence, or R bridge status propagation. Wave and whole-wave panel signoff remain HOLD.

- [x] B1: Four-trait Gaussian K=1 pedigree FA is usable through a documented opt-in R route with invariant G, uniqueness limits, correlation, and diagnostics; unsupported routes fail clearly.
  EVIDENCE: R `tests/testthat/test-fa-optin.R` and `vignettes/articles/multivariate.Rmd`; 50 live same-input parity checks plus final focused opt-in rerun; R package check Status: OK. This is a partial expert route; default-iteration convergence, broad recovery, and inference are open.

- [x] C1: Genetic GLLVM symbolic objective and Gaussian reduction are named correctly; trait breeding values include factor and uniqueness terms, with invariant extraction.
  EVIDENCE: `docs/design/genetic-gllvm-objective-contract.md`; `test/genetic_gllvm_trait_effects.jl` 4/4 and 5/5 trait-effect tests; independent Gaussian reduction and observed-curvature regression; final `Pkg.test()` pass.

- [x] C2: Ordinary-start and restart checks, tiny oracles, and negative tests establish the selected Poisson cell independently of truth-start recovery.
  EVIDENCE: `test/genetic_gllvm_trait_effects.jl` 7/7 Poisson guards and 9/9 ordinary-start assertions; final `Pkg.test()` pass. Broader recovery remains open.

- [x] D1: Three-trait Poisson-log K=2 pure-low-rank pedigree GLLVM is usable through a documented opt-in R route with link-scale conditional modes and limits.
  EVIDENCE: R `tests/testthat/test-gllvm-optin.R` and `vignettes/articles/genetic-gllvm.Rmd`; 49 same-input direct-Julia parity checks, 38 ordering/ID checks, final opt-in rerun, R package check Status: OK. This remains partial without an external same-objective comparator.

- [ ] E1: Every tracked core src file and public bridge contract has a pinned-span review disposition; findings are fixed or explicitly carried.
  EVIDENCE: four packets under `docs/dev-log/source-review/2026-09-27-wave*.md` inventory all 24 tracked `src/` files, with the CUDA stub reviewed statically only. W1-05 now has scoped strict-order/SIMD score, step, fit, and common-point PEV parity evidence; this does not close wave 1. W1-06/07/08/09, W2-03/04, and W3-03/04/05 received scoped repairs and regressions; W2-03 has independent Astra signoff. W1-09's original K3 score now agrees with independent dense calculation to `5.68e-14`, with explicit refusal above its 512-column fallback budget; Noether gave scoped mathematical signoff. Exact-zero/KKT fitting and residual variance near zero remain open. Wave 1 and 3 still have unreviewed spans, waves 1–4 remain HOLD, and whole-wave panel signoff is open. Carried findings are explicit in the packets.

- [x] V1: Julia package suite passes on the current source-review candidate.
  CHECK: julia --project=. -e 'using Pkg; Pkg.test(); println("HSQ_JULIA_TESTS_OK")'
  EXPECT: HSQ_JULIA_TESTS_OK
  EVIDENCE: content-matched writable copy `/private/tmp/hsq-fa-gllvm-test-copy-20260927` passed the exact suite after W1-09 and the FA status-row correction (`/private/tmp/hsq-fa-gllvm-pkg-test-20260927-w109-final-green.log`, exit 0, `HSQ_JULIA_TESTS_OK`). The frozen genomic fixture remains unchanged. An earlier run caught one capitalization-sensitive status assertion; its corrected wording test passed in this final run.

- [x] V2: Julia documentation builds on the current source-review candidate.
  CHECK: julia --project=docs docs/make.jl && echo HSQ_JULIA_DOCS_OK
  EXPECT: HSQ_JULIA_DOCS_OK
  EVIDENCE: the content-matched writable copy built after W1-09 and FA status-row edits (`/private/tmp/hsq-fa-gllvm-docs-20260927-w109-final.log`, exit 0). The 56-row status page was regenerated from the live source and the exact package suite checked its content. The managed checkout's source-page generator also ran successfully with cache access.

- [ ] V3: R package check, bridge parity, current CI, capability/debt rows, check logs, after-task reports, and Rose audit pass for the final candidate.
  EVIDENCE: R package check returned Status: OK, zero errors/warnings/notes after Rose's final prose corrections (`/private/tmp/hsquared-fa-gllvm-rcmdcheck-20260927-final-rose.log`); pkgdown check found no problems. Live three-block/direct-maternal bridge tests passed again against the W1-09 Julia source (`/private/tmp/hsquared-fa-gllvm-w109-live-bridge-final.log`), as did structured-result AIC, block-shape, and control-validation synthetic tests. The earlier 50 FA and 49 GLLVM same-input parity checks and no-fit unsorted pedigree probe remain valid. Rose audit is clean with limitations (`docs/dev-log/source-review/2026-09-27-rose-claims.md`). Read-only CI checks: R #259 Julia 1, Julia 1.10, docs, and deploy pass; Julia #401 at pre-change head `54907ea8` fails one internal AI stop-label assertion on Julia 1 Ubuntu in the unidentifiable `Z = Q = I` endpoint-tie fixture (71/72 assertions), while its boundary classification assertions pass; Julia 1 Windows, both Julia 1.10 jobs, docs, and deploy pass. The stop-label assertion has now been removed and the fixture capped at one iteration; local semantic and full-suite tests pass, but this patch is unpushed and post-change CI remains unobserved. V3 and full source-review panel signoff remain open.

- [x] V4: The candidate stops before CRAN submission, Julia registry submission, and public release tag.
  EVIDENCE: Candidate branches retain version 0.9.0 and contain no new public release tag or submission. The user's existing 0.9.0 CRAN submission remains in its separate review lane.

At each arc boundary, record exact commits, met/unmet/abandoned counts, compute estimates, test results, and next arc. A gate stays open if evidence is incomplete. A run estimated above three hours requires a pre-run result and Shinichi's approval.

## 2026-09-27 FA closeout update

The review addendum records current FA spans, file hashes, tests, and scoped Sol/Rose verdicts. The payload and interpretation-language corrections do not resolve the outstanding exact-candidate comparator, routine-start/local-information evidence, R bridge status propagation, or other unreviewed source spans. E1 stays open; this update is not whole-wave signoff. Full local package tests and the docs build passed in a writable content-matched copy. Post-push Julia CI could not be observed because the GitHub API was unreachable from this session; the earlier pre-change checks are not evidence for this commit.

2026-09-27 ordinary-start diagnostic: a local three-start probe on one 12-animal, two-record-per-animal synthetic T=4, K=1 fixture converged from all starts, but all fitted uniqueness values were at or within 7.4e-7 of the 1e-4 floor. The default start had loglik -143.8904; dispersed and clamped-restart starts reached -143.3407, with relative Frobenius differences of 0.404 in G and 0.155 in R between the default and dispersed solution. Default-fit relative errors against the generating G and R were 1.35 and 1.37. This is a material start-dependence warning for this fixture, not a recovery, bias, or general FA-method conclusion. F3 remains open; see `docs/dev-log/after-task/2026-09-27-fa-closeout.md` for the complete diagnostic and limits. The three-start probe is not a multi-seed validation campaign and does not close the gate.

Correction to the earlier V3 evidence paragraph: its statement that the closeout patch was unpushed is superseded. Commit `08a5a38e` was pushed; post-push CI remains unobserved because the GitHub API was unreachable from this session. Its pre-change CI results do not establish CI for `08a5a38e`.
