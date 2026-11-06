# JuliaCall startup and live FA-rank parity diagnostic

## 1. Goal

Find a safe path to the required live R-to-Julia FA-rank parity check without launching a study campaign or changing shared packages.

## 2. Implemented

No package source or shared runtime was changed. JuliaCall 0.17.6 segfaulted on Totoro with Julia 1.10.10 under the default library loading path. Preloading Julia's bundled `libunwind.so.8.0.1` allowed JuliaCall to initialize. The required-live FA-rank R test then passed on its eight-row fixture and compared R output with a direct Julia selection.

## 3a. Decisions and Rejected Alternatives

- Tested `install=FALSE` and `rebuild=FALSE`; those options alone did not prevent the crash.
- Used an isolated depot ahead of the shared depot so generated compile caches stayed in temporary storage.
- Preloaded Julia's own `libunwind` for the live test. The environment workaround is not a package-source change and its wider platform scope is unverified.
- JuliaCall's dependency script was inspected. It only adds `RCall` or `Suppressor` if absent; both were already direct dependencies of the selected Julia environment.
- Assumptions made without asking: none.

## 4. Files Touched

- Created this diagnostic report.
- Totoro scratch depot retained at `/tmp/arc1-juliacall-warm-20261024-27327`.
- Temporary R test package copied to `/home/snakagaw/hsq_work/arc1-r-live-parity-unwind-preload-20261024/package`; its selector, bridge, and live-test hashes match the isolated R package.
- No source, test, lock, or shared package files changed. One required-live fixture test ran the R selector and direct Julia selector; no study campaign or bootstrap ran.

## 5. Checks Run

- Local `Rscript`: R 4.6.0; JuliaCall is installed; Julia is not on the local `PATH`.
- Existing Totoro ControlMaster read-only inventory: R 4.6.1 and JuliaCall 0.17.6 are present. Julia executables were found at 1.10.0, 1.10.10, and 1.12.7 locations.
- On Totoro, standalone Julia 1.10.10 loaded `Suppressor` and `RCall` successfully from the isolated depot: `STANDALONE_RCALL_WARM=PASS`.
- The same isolated depot was then used for `JuliaCall::julia_setup(JULIA_HOME="/home/snakagaw/hsq_work/julia-1.10.10/bin", install=FALSE, rebuild=FALSE, useRCall=TRUE)`. JuliaCall printed `Loading setup script for JuliaCall...`, then the R process segfaulted with exit 139 before returning to R.
- With Julia's bundled `libunwind.so.8.0.1` in `LD_PRELOAD`, the same JuliaCall smoke setup completed and `julia_eval("1 + 1")` returned `2`, exit 0.
- Before the live test, the transferred R files matched the local isolated package: `R/fa-rank-selection.R` SHA-256 `46403d5e1bf16a75d4be634a0cd1a711d581f20d43111c7195a635c08008aee2`; `R/julia-bridge.R` SHA-256 `4495e55ccf03ef6cb69469464eed03a4fd8bae066cca3cfaa94c2961c6df5c35`; live test SHA-256 `fd44e00a89b9c9d3b04041026a9eb8c06c8657dc8cfa3441a33dc2559772d89e`.
- Julia `Project.toml` and `Manifest.toml` hashes were `93422d9228f3e2d6c5170e2b6055bf8bccf6bef59f4189edfa9f68adbe32af5d` and `421dbda588a1ad70aa82c433fa97f172286d6f0da7076b5b9c5ac7638615e2ad`.
- Required-live environment pins: `HSQUARED_JULIA_PROJECT=/home/snakagaw/hsq_work/arc1-diagnostic-rebuild-20261024-34mpd77/source`, `JULIA_HOME=/home/snakagaw/hsq_work/julia-1.10.10/bin`, `JULIA_PROJECT=/home/snakagaw/.julia/environments/v1.10`, `JULIA_DEPOT_PATH=/tmp/arc1-juliacall-warm-20261024-27327:/home/snakagaw/.julia`, `JULIA_NUM_THREADS=1,1`, `JULIA_PKG_PRECOMPILE_AUTO=0`, and `LD_PRELOAD=/home/snakagaw/hsq_work/julia-1.10.10/lib/julia/libunwind.so.8.0.1`.
- `HSQUARED_AUTO_FA_REQUIRE_LIVE=true testthat::test_local(".", filter="auto-fa-rank-optin", reporter="summary")`: **exit 0**, `DONE`, Julia exited normally, no test failure or skip was reported. The mandatory live case ran and compared the R-selected result with direct Julia output. Total run time was about one minute.
- No pilot, confirmation, or bootstrap fit ran. No shared Julia package was rebuilt or modified.

## 6. Tests of the Tests

The required-live test itself exercises bridge initialization, R-to-Julia payload transfer, rank selection, result extraction, and direct-result comparison for the fixture. The test code was not modified and no negative-control run was made in this diagnostic.

## 7a. Issue Ledger

- The required-live FA-rank parity fixture passes under the pinned Totoro environment with Julia's bundled `libunwind` preloaded.
- No external issue was opened. Root cause and portability of the environment workaround remain unverified.

## 8. Consistency Audit

Read the isolated R bridge setup and mandatory live FA-rank test, then verified the test package's exact selector, bridge, and test hashes after transfer. The test reached the R fit, direct Julia selection, and parity assertions. This is one live parity cell and partial G6 evidence; it does not satisfy G6's failure and interruption checks.

## 9. What Did Not Go Smoothly

Disabling JuliaCall's install and rebuild stages and warming the dependencies did not avoid the crash. The first live-test invocation stopped at a shell export syntax error before Rscript started. After correcting the command, preloading Julia's bundled libunwind allowed the test to pass. The underlying loader or unwinder cause is not established.

## 10. Known Residuals

- The required-live FA-rank fixture passed only with the environment workaround. Portability to other Julia, R, and operating-system combinations remains unverified.
- G6 remains open until its required failure and interruption handling checks are proved. G2-G8 remain open. This diagnostic changes no acceptance status, `public_covered_count`, or v7 HOLD state.
- The failed closeout helper resolved the Git root to the protected Dropbox checkout and its write was denied. No Dropbox file changed; this report was created directly in the Codex worktree.

## 11. Team Learning

For this Totoro setup, `install=FALSE`, prewarmed dependencies, and an isolated depot did not prevent the embedded startup segfault. Preloading the matching Julia-bundled libunwind enabled the required-live test. Keep this workaround scoped to the test environment until portability and production setup are reviewed.

Routing receipt: `route.py` found no LOAD-FIRST manifest for this Codex worktree. The brain search returned no matching current Arc 1 note. The supplied AGENTS instructions guided the work. The Golden Set check was not run because this diagnostic changed no implementation or test.

## 12. Cross-Product Coverage

- Covers: one required-live R-to-Julia FA-rank fixture on Totoro with Julia 1.10.10, R 4.6.1, JuliaCall 0.17.6, exact R source hashes, and an isolated compile depot.
- does NOT cover: other R-Julia routes, G6 failure and interruption acceptance, pilot or confirmation reliability, interval calibration, repeatability profiles, GPU routes, or capability promotion.
