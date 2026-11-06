# Automatic FA rank: recovered R snapshot re-verification

Status: focused implementation evidence only. This does not close the whole HSquared goal or Arc 1 G0-G8.

The original isolated R worktree had been removed. Its accepted source commit was recovered from the local object database into an independent scratch clone at `/private/tmp/hsquared-auto-fa-r-20261001`, detached at `2108c0d0d2a9b528d257dea0b2f5f4a87c19a080`. The clone has no tracked or untracked changes. All 11 R files in `final-check-source-freeze-v7.json` match their retained SHA-256 values; representative pins are `R/fa-rank-selection.R` `82b70bb7f274ab2774330a96a8849120fb85411450b8f1503560697ccf08e326`, `R/julia-bridge.R` `f0e5d7498f40004f31ce14df39aa749ee5858605113376674948bd6b05dc6f51`, and `tests/testthat/test-auto-fa-rank-optin.R` `da973074dbd87fc8df26968c8b192556ba6592e05c384b134797d8d2d591d9a6`.

On 2026-10-04, with R 4.6.0, Julia 1.10.0, one Julia thread, and BLAS/OMP one thread, the following checks ran from that recovered R source. Live parity used the current dirty Julia worktree at HEAD `0e4e5d742000f66bdb2127e43ca3756b432a5f10`; current source pins during the run were `src/HSquared.jl` `70a896e236b63f63d097e5826fea058b5ce1ad2c7adee86fe811c627852c1a48`, `src/fa_rank_selection.jl` `61eb542bf34796c0222e1a8df7550de5dfdb03f3bb855c63a43c243f6bbbeda0`, and `src/arc1_fa.jl` `01a47052c2a0fb658a9ab054ade22f26af6454a000632c95e845e31783931906`.

| Gate | Result |
|---|---|
| R focused `devtools::test(filter="auto-fa-rank")` | Exit 0; 32 pass, 0 fail, 0 warnings; one expected optional live test skipped; `AUTO_FA_R_ACCEPTANCE_PASS` |
| Mandatory-live Julia/R `devtools::test(filter="auto-fa-rank")` | Exit 0; 128 pass, 0 fail, 0 warnings, 0 skips; `AUTO_FA_LIVE_TWIN_PASS` |
| R `devtools::check(document=FALSE, cran=FALSE)` | Exit 0; `Status: OK`; errors/warnings/notes all zero; `AUTO_FA_R_FULL_PASS` |

The R check emitted a separate warning that `quarto -V` could not run, but the package check itself returned `Status: OK` and no check warnings. Full output is `.unlazy/h2-nongpu-completion/evidence/2026-10-04-auto-fa-r-snapshot-reverify.log`, SHA-256 `b9a254b4652a3c701b5a1cccfdeb835fa3042621e5e8e9b7087da37f32f17ff0`.

This verifies the bounded automatic-FA implementation against the exact retained R source and current Julia source for these tests. The recovered clone uses Git's shared object store from the local hsquared repository; its exact commit remains reachable there. It does not establish ordinary optimizer-driven K1 reliability, selection-adjusted interval calibration, or the wider H1-H9 project. The existing historical full acceptance receipt is `full-report-validation-v7-result.json` in `.unlazy/auto-fa-rank-implementation-20261001/`. The generic current gate status still reports Arc 1 and H1-H9 open; the default status command also cannot see that historical receipt's custom approval directory, so it calls six previously checked implementation gates unexecuted. That approval-path discrepancy remains a ledger-tooling issue, not Arc 1 completion evidence.
