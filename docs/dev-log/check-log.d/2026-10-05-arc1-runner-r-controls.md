# Arc 1 runner and paired R control diagnostics, 2026-10-05

Julia branch: `codex/arc1-gaussian-reliability-20261002`, HEAD `34b0e81c5e9ae862a7099aab73404d18a3e25fba`.
R branch: `codex/arc1-gaussian-reliability-20261003`, HEAD `a563ea88f3076819a4a5d8966e2644489efd1688`.

## Change

Added `test/arc1_fa_v2_contracts.jl` to `JULIA_TESTS` in `tools/arc1_oracles.py`. The G1 runner now inventories the current retained-factor v2 contract suite alongside its existing eight suites. The runner self-test now guards v2-suite inventory membership. Clarified R `rank_selection`, engine/target, and unsupported-shape messages for automatic and fixed-rank policy modes.

## Checks

- Julia focused suite: `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --startup-file=no --project=. -e 'include("test/arc1_fa_v2_contracts.jl")'` exited 0; 23 profile-v4 interface checks and 157 retained-factor v2 checks passed. Log: `2026-10-05-arc1-fa-v2-contracts.log`, SHA-256 `7278de0abd2c2b8419d958590be9af378096e9975851bbe4fc02405d2b6df71e`.
- Oracle test harness: `python3 -B tools/arc1_oracles.py --self-test` exited 0 with `ARC1_ORACLE_SELF_TEST_PASS`; synthetic positive, failure, skip, and empty cases were exercised. Log SHA-256 `a0ef9c653b2ca609da558c103dbc0d81b8c2100b3509066a5779fa91d033edb5`.
- R control suite: `Rscript -e 'devtools::test(filter = "arc1-controls")'` exited 0; 113 assertions passed, zero failures, warnings, or skips. Paired log SHA-256 `48b602d2788b348d6df1555264273fd639a9c5b51da65a703d21a6387445d327`.
- `git diff --check` on changed code/tests and `bash tools/preamble_cap.sh`: PASS.

- Canonical G1: PASS, nine suites and 2,386 assertions; no failures, errors, broken tests, or timeouts. Run receipt: `.unlazy/arc1-gaussian-reliability/oracles/runs/20261005T110236Z-e9c556964f8c/run.json`, SHA-256 `1ad5b15461b2486b3b5036cdb5d37e6053efc2a899f6c7253b9d63cfb227ffac`. Reviewed freeze SHA-256 `3e00d6878a725544d752249d6c9aaff6be05eb2bc4acf9cbc3d09262155042be`; runner SHA-256 `ef559987341249d9c560538ee05b04a33ac3588ed56d3aad2c42bfbc665ac9ae`.
- The first run reached the 300-second gate-wide timeout after ten suites passed; isolated current-source executor passed 120 checks in 70.1 seconds. The reviewed 480-second gate cap now provides measured headroom. Red/green self-test and independent review are retained.
- R focused controls passed, including automatic and fixed-rank wrong-shape assertions; log SHA-256 `2cb2bc0bd425ad2ff43ae4789873fc6dc3f0bea7cde9f7f8699ae8a88bccf28a`.

## Scope

This proves the G1 component runner execution against the reviewed freeze. The locked acceptance ledger still leaves G0-G8 open until formal reconciliation and the remaining independent gates pass. No study ran. The public capability remains experimental and covered count remains seven.

The broad `docs/dev-log/check-log.md` and coordination board were not edited because path preflight found divergent work on other refs. The changes and exact focused results are documented in this new path and in `docs/dev-log/after-task/2026-10-05-arc1-runner-r-diagnostics.md`.

## Canonical G6 replay, 2026-10-05

- Runner self-test: PASS after correcting the G6 gate-wide cap. Current runner SHA-256 `d9e18d06765d220925251e3208ced2cbdca53a17236496d0d7d6803434e8435c`; retained synthetic log SHA-256 `a0ef9c653b2ca609da558c103dbc0d81b8c2100b3509066a5779fa91d033edb5`. The self-test asserts both the 3,600-second per-command cap and a G6 gate cap of at least 3,900 seconds; configured gate cap is 4,200 seconds.
- Independent read-only review: ACCEPT for this runner revision. Reviewer verified the runner hash, reran the synthetic self-test and confirmed sufficient headroom from the exact profile/uncertainty runtimes.
- Canonical command: `HSQUARED_ARC1_R_ROOT=/private/tmp/hsquared-arc1-r-20261003 JULIA_DEPOT_PATH=/private/tmp/hsquared-arc1-bootstrap-depot:/Users/z3437171/.julia OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_PKG_OFFLINE=true python3 -B tools/arc1_oracles.py --gate g6 --freeze /private/tmp/h2-arc1-g6-freeze-candidate-20261005.json`
- Result: PASS, `ARC1_G6_LIVE_PASS`, 2,539.085 seconds. Seven required suites produced 625 assertions, 625 successes, zero failures, errors, skips, or warnings. Suite counts: controls 115; live parity 50; bootstrap v2 20; profile v4 85; profile transport isolation 3; uncertainty controls 179; uncertainty live 173.
- Retained run: `.unlazy/arc1-gaussian-reliability/oracles/runs/20261005T120744Z-07a5fc667fd8/`; `run.json` SHA-256 `0583e47ab09a52a3af70812ed01a917f9d568b96e910dcb47e19b76f7654f7d7`; R log SHA-256 `a53058d99b6384eaf5d3c1ec218b7d38a9d2ad8bf83a73fd064a07dee966d301`; results CSV SHA-256 `e91a388c7f0495cadfb577187b2c591f4d812ecba4fc57e062a3a1b4803153e8`; results RDS SHA-256 `6e0602e3d543927194f0dfa1173f0fa2f4487643d12850591a72d49cd1d635f1`.
- Reviewed source freeze SHA-256 `fe1ba02b35ffee75f14cc37ce867143b0f39a451262b98089826cc726becd018`. Julia and R source inventories matched the run's initial and final snapshots. Julia 1.10.0 and R 4.6.0 matched the freeze. JuliaCall Project and Manifest initial bytes matched pinned hashes `92abfe5a405601a7c3dc4bc06f84d6659643dcc772117ebb59b08023aec9c613` and `b4a8ea7b1ad5d2e806d512d09175e16dd483ce921c2da123bc26eab9e2d3c25f`.

G6 paired execution is verified at this source freeze. It does not establish selection or interval calibration and does not close the locked G0-G8 acceptance ledger.
