## 1. Goal

Repair the Arc 1 oracle runner inventory and timeout controls, make R rank-control errors describe the accepted fixed-rank and automatic routes accurately, and complete the reviewed-source G6 live R parity/failure-handling run.

## 2. Implemented

- Added `test/arc1_fa_v2_contracts.jl` to the G1 runner's required Julia suite list.
- Clarified the R `rank_selection` message: `auto` is the only explicit value; omission with an optimizer policy selects fixed-rank mode.
- Made engine, target, and unsupported-model-shape diagnostics distinguish automatic selection from fixed-rank optimizer policy mode.
- Added R regressions for engine, target, and wrong-shape errors in both routes. Existing `arc1_v1` and `arc1_v2` policy wording remains explicit.
- Increased the G1 gate-wide runner cap from 300 to 480 seconds after the exact run exhausted 300 seconds; retained the 300-second per-suite cap. Added a lower-bound self-test, verified red against the old cap and green with the new cap.
- Increased the G6 gate-wide cap to 4,200 seconds and the per-command R cap to 3,600 seconds after exact-environment profile and uncertainty tests measured 515.48 and 2,022.27 seconds. Added a self-test assertion on the gate-wide cap; independent read-only review accepted runner SHA-256 `d9e18d06765d220925251e3208ced2cbdca53a17236496d0d7d6803434e8435c`.
- Completed canonical G6 live R/Julia checks against the independently reviewed source freeze. All seven required R suites passed with 625 assertions and zero failures, errors, skips, or warnings; JuliaCall bootstrap hashes and all frozen Julia/R source hashes remained unchanged.

## 3a. Decisions and Rejected Alternatives

Kept the change opt-in and diagnostic-only. Did not alter model selection, numerical behavior, policy defaults, package capability status, or the frozen study protocol. Added the missing suite as a runner input rather than treating `Pkg.test()` inclusion as proof that the focused G1 runner executes it.

## 4. Files Touched

- Julia: `tools/arc1_oracles.py`; `docs/dev-log/check-log.d/2026-10-05-arc1-runner-r-controls.md`; `docs/dev-log/check-log.d/2026-10-05-arc1-fa-v2-contracts.log`; `docs/dev-log/check-log.d/2026-10-05-arc1-oracle-self-test.log`; `.unlazy/arc1-gaussian-reliability/oracles/runs/20261005T120744Z-07a5fc667fd8/`.
- R: `/private/tmp/hsquared-arc1-r-20261003/R/fa-rank-selection.R`; `/private/tmp/hsquared-arc1-r-20261003/tests/testthat/test-arc1-controls.R`; `docs/dev-log/check-log.d/2026-10-05-arc1-controls-focused.md`; `docs/dev-log/check-log.d/2026-10-05-arc1-controls-test.log`; `/private/tmp/h2-arc1-g1-freeze-review-20261005b.txt`; `.unlazy/arc1-gaussian-reliability/oracles/runs/20261005T105434Z-8490926df8fb/`; `.unlazy/arc1-gaussian-reliability/oracles/runs/20261005T110236Z-e9c556964f8c/`.
- Reports: this report and the paired R report at `/private/tmp/hsquared-arc1-r-20261003/docs/dev-log/after-task/2026-10-05-arc1-control-diagnostics.md`.

## 5. Checks Run

- R focused controls: PASS, zero failures, warnings, or skips. Retained log SHA-256 `2cb2bc0bd425ad2ff43ae4789873fc6dc3f0bea7cde9f7f8699ae8a88bccf28a`. Source hashes: `R/fa-rank-selection.R` `520d12f3d7c1fe008ec856398c72f7466faad97007f1e575b779e1ee2914e8d9`; test `tests/testthat/test-arc1-controls.R` `35fd495e1a41a44bb19404cb7d602eadea9a42dc6f31a91e1ca296cf48771ef8`.
- Direct retained-factor v2 Julia suite: PASS, 180 assertions (23 profile-v4 interface and 157 v2 contract checks); log SHA-256 `7278de0abd2c2b8419d958590be9af378096e9975851bbe4fc02405d2b6df71e`.
- Oracle synthetic self-test: PASS, `ARC1_ORACLE_SELF_TEST_PASS`; log SHA-256 `a0ef9c653b2ca609da558c103dbc0d81b8c2100b3509066a5779fa91d033edb5`.
- Independent freeze review accepted 47 Julia and 100 R paths, roots, hashes, runtime strings and v2 suite registration. Reviewed freeze SHA-256 `3e00d6878a725544d752249d6c9aaff6be05eb2bc4acf9cbc3d09262155042be`; reviewer receipt SHA-256 `110d8c9c3ebcada54c4ccbc97ca1fbafc52f099deb54e54db94e121b1f326686`.
- First canonical G1 attempt ran ten suites successfully but timed out on the executor suite at the 300-second gate cap. An isolated rerun of that exact suite passed 120 assertions in 70.1 seconds. Raised the gate cap to 480 seconds; the red self-test rejected the old cap and the updated self-test passed. Independent runner review accepted runner SHA-256 `ef559987341249d9c560538ee05b04a33ac3588ed56d3aad2c42bfbc665ac9ae`.
- Canonical G1 rerun: PASS, all nine Julia suites and 2,386 assertions; zero failed, errored, broken, or timed-out suites. Retained run directory `.unlazy/arc1-gaussian-reliability/oracles/runs/20261005T110236Z-e9c556964f8c`; run receipt SHA-256 `1ad5b15461b2486b3b5036cdb5d37e6053efc2a899f6c7253b9d63cfb227ffac`. It pins freeze SHA `3e00d6878a725544d752249d6c9aaff6be05eb2bc4acf9cbc3d09262155042be` and runner SHA `ef559987341249d9c560538ee05b04a33ac3588ed56d3aad2c42bfbc665ac9ae`.
- Independent G6 timeout review: ACCEPT; reviewer verified runner SHA `d9e18d06765d220925251e3208ced2cbdca53a17236496d0d7d6803434e8435c`, reran the synthetic self-test, and confirmed the 4,200-second gate cap provides 15 minutes beyond the measured 55-minute upper estimate.
- Canonical G6 rerun: PASS, seven required R suites and 625 assertions; zero failures, errors, skips, or warnings. Elapsed 2,539.085 seconds. Retained run directory `.unlazy/arc1-gaussian-reliability/oracles/runs/20261005T120744Z-07a5fc667fd8`; run receipt SHA-256 `0583e47ab09a52a3af70812ed01a917f9d568b96e910dcb47e19b76f7654f7d7`; R log SHA-256 `a53058d99b6384eaf5d3c1ec218b7d38a9d2ad8bf83a73fd064a07dee966d301`; results CSV SHA-256 `e91a388c7f0495cadfb577187b2c591f4d812ecba4fc57e062a3a1b4803153e8`; results RDS SHA-256 `6e0602e3d543927194f0dfa1173f0fa2f4487643d12850591a72d49cd1d635f1`. Reviewed freeze SHA-256 `fe1ba02b35ffee75f14cc37ce867143b0f39a451262b98089826cc726becd018`; runner SHA-256 `d9e18d06765d220925251e3208ced2cbdca53a17236496d0d7d6803434e8435c`. JuliaCall Project and Manifest initial hashes matched the reviewed pins; source snapshots matched at run start and end.
- `Rscript ~/shinichi-brain/tools/check-after-task.R` accepted the report structure. Its overall acceptance check correctly returned nonzero because the Arc 1, automatic-FA and H2 non-GPU ledgers still contain unmet gates. Slop scan: zero findings. `bash tools/preamble_cap.sh` and scoped `git diff --check`: PASS.
- `bash tools/preamble_cap.sh`: PASS. `git diff --check` on owned source/test paths: PASS.

G1 component execution is now verified. The locked G0-G8 acceptance ledger and wider gate status have not been changed; this component receipt alone does not close Arc 1 or the overall goal.
## 6. Tests of the Tests

The R test first failed against the old selector wording; the follow-up wrong-shape fixed-rank expectation also failed against the old shared automatic-only diagnostic. Both were corrected and the full focused control suite passed. The first canonical G1 run exposed a gate-budget defect rather than a suite failure: all earlier suites passed, and the isolated executor suite then passed. A deliberate red self-test proved the old 300-second limit violated the measured-budget guard; with the revised 480-second cap, the complete canonical G1 rerun passed. Independent review caught that the initial G6 per-command timeout increase did not change the gate-wide cap; the explicit gate-cap assertion and 4,200-second cap passed a fresh independent self-test, then the full G6 run completed successfully.

## 7a. Issue Ledger

- Fixed: R control errors described omitted-policy fixed-rank mode as automatic-only and listed an incomplete accepted `rank_selection` contract.
- Fixed: the G1 runner omitted the retained-factor v2 contract test from its focused execution list.
- Fixed: the gate-wide G1 timeout could terminate a valid full suite after per-suite tests passed.
- Fixed: the G6 gate-wide timeout could terminate the canonical live R suite before its measured profile/uncertainty tests completed.
- Verified: current reviewed-source G1 component and G6 live R/Julia runs pass. The acceptance ledger still records all G0-G8 as open pending formal reconciliation and the other gates.

## 8. Consistency Audit

Checked the paired R control validator and its focused tests, the Julia test entry in `test/runtests.jl`, the G1/G6 runner inventories and timeout self-tests, exact freezes, every command log, and both canonical receipts. The G6 receipt binds the exact reviewed Julia/R freeze and runner, verifies all seven selected R files have positive assertion counts with zero failures/errors/skips/warnings, and verifies the before/after source snapshots and JuliaCall bootstrap hashes. No public grammar, default, capability status, or covered-count change was made. These checks do not establish calibration or full Arc 1 acceptance.

## 9. What Did Not Go Smoothly

The initial Julia test invocation could not write a Julia compile-cache lock in the user depot. Rerunning with the approved elevated test command succeeded. The revised R test first used an engine value that `hs_control()` correctly rejects before reaching the intended validator branch; the fixture now mutates a valid control object. The canonical G1 run first exhausted its gate cap only at the last suite; after measured isolation and independent review of the cap increase, the full nine-suite run passed. The first G6 timeout repair changed only the per-command limit; independent review caught the unchanged gate-wide cap before the full run. The second repair raised and tested both limits, and canonical G6 passed.

## 10. Known Residuals

No allocated development, pilot, or confirmation study ran. Canonical G1 passed all nine suites with 2,386 assertions, and canonical G6 passed all seven required R suites with 625 assertions against reviewed freezes. These are component and paired-execution checks only; rank-selection and interval calibration remain untested, and the locked G0-G8 acceptance ledger remains unchanged. The project remains experimental and the covered count remains seven. The broad Julia `check-log.md` and coordination board were left untouched because preflight found substantial work on other refs. The isolated R canonical check log and coordination board were also left untouched for the same reason. Exact dated evidence and this report are retained as new files.

## 11. Team Learning

For focused numerical gates, verify the runner's explicit file inventory, not only the package-wide test entry point. For expert controls, distinguish an omitted argument that selects a documented mode from an explicit unsupported value, and name the active route in downstream errors.

Memory receipt: `route.py` found no LOAD-FIRST manifest for this managed worktree; Graft source spans were used for the runner, R control validator, and test suite. These directed the runner inventory check and the narrow R test additions. No sibling-project scout was run. Golden Set: not in scope for this bounded runner and diagnostic repair.

## 12. Cross-Product Coverage

Covers: focused Julia G1 execution of the retained-factor v2 contract test; R error wording for automatic selection and fixed-rank optimizer-policy control validation; canonical G6 live R/Julia parity, bootstrap/profile transport and interruption/failure handling against reviewed source bytes.

Does NOT cover: G0 admission, G2 ordinary-start reliability, G3 rank-selection calibration, G4 FA interval calibration, G5 repeatability interval calibration, G7 full package and docs replay, G8 final scientific reconciliation, any pilot or confirmation study, public status promotion, GPU behavior, or project completion.
