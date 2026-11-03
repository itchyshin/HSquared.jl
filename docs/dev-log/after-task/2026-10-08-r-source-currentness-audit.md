## 1. Goal

Resume Arc 1 from its retained evidence and identify the next admissible R and Julia parity step without assigning credit to stale or unpaired source.

## 2. Implemented

No Julia package source or tests were changed. I audited the stale shared R candidate, retained R scratch copy, and protected main R checkout; corrected and obtained independent PASS on the reconstruction proposal; then created a separate disposable Git clone, rebuilt the R Arc 1 source overlay, ported the reviewed parser repair onto the retained source, and authored a replacement required-live bootstrap-v2 test. The original shared R candidate and protected main R checkout remain unchanged.

## 3a. Decisions and Rejected Alternatives

Do not edit `/private/tmp/hsquared-arc1-r-active-20261008`; lane preflight found recent cross-lane history, a shared checkout branch switch, and unrelated newer ref work. The new reconstruction lives at `/private/tmp/hsquared-arc1-r-reconstruction-20261008`, branch `codex/h2-arc1-r-reconstruction-20261008`, based on `a563ea88f3076819a4a5d8966e2644489efd1688`. It preserves the reviewed parser regression test and applies the exact retained Arc 1 overlay in isolation. The protected Dropbox R checkout and old orphaned scratch remain untouched. The original bootstrap-v2 test bytes are unavailable; the new test is explicitly new and does not claim historical recovery.

## 4. Files Touched

- Julia repo: `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`; `docs/dev-log/after-task/2026-10-08-r-source-currentness-audit.md`; `docs/dev-log/check-log.d/2026-10-08-r-source-currentness-audit.md`; `docs/dev-log/decisions/2026-10-08-r-current-source-reconstruction-candidate.md`; and `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/r-source-reconstruction-20261008/` inventory and logs.
- Disposable R clone: `NAMESPACE`; `R/arc1-uncertainty.R`; `R/extractors.R`; `R/fa-rank-selection.R`; `R/julia-bridge.R`; the four shared Arc 1 tests; both recovered profile-v4 tests; the new bootstrap-v2 live test; and parser regression test `tests/testthat/test-auto-fa-rank-optin.R`.

## 5. Checks Run

- Graft query of the Arc 1 source inventory and retained runner: completed.
- Julia worktree lane preflight: one lane reported; no foreign lane had work on the files recorded here.
- Arc 1 Unlazy status: G0 met; G1 through G8 unmet in the live ledger.
- The isolated parser candidate's retained receipt records offline and mandatory-live focused tests passing, with exact source/test/patch hashes and independent parser-only review. Those are prior-turn component results, not tests run during this audit.
- Shared parser-candidate HEAD remains `a563ea88f3076819a4a5d8966e2644489efd1688`; it was not edited. New reconstruction clone is based on that commit and has a separate branch.
- The reconstructed tree has all 100 frozen R paths. Ninety-seven match the historical freeze exactly. Three differences are explained and pinned separately: parser-patched `R/fa-rank-selection.R` `fe6393dba470490302df17be4b7f2acd1466768c6a85db68967b82e1c7c5f27c`; later transport-locked `R/julia-bridge.R` `409147b4f9b54f04b09121ccbdd775a4b8d54030ee6b465cc3a165caf52848a0`; and the newly authored `test-arc1-bootstrap-v2-live.R` `6eab8104250bbbfca53f024bd8e7897b30a81abfa3ba32066b0f043a51e18cac`. The full 100-path map is retained in the source inventory JSON.
- Recovered profile-v4 tests retain hashes `be6bb51da63a59eec405d0ec3c8bf0f189f4b95a38dd23f65f9694c762a08874` and `f9f65cf70c416ded06613f4e04d43c3de9316add3df8087c75088c664edb3716`. The new seven-file runner inventory includes all required test paths; the bootstrap test is a replacement source, not recovery of the historical bytes.
- Astra independently reviewed the exact source inventory read-only. The historical G6 receipt and testthat RDS prove the dedicated `test-arc1-bootstrap-v2-live.R` ran alongside the embedded block in `test-arc1-uncertainty-live.R`; it passed 20/20 expectations. Historical test SHA-256 is `d787d406d9227e3aea63f84fc6095551da56c64abdd42783485616e4581d19fb`; retained RDS SHA-256 is `66e4d743655c14c38d03e5a3e1681c64120aba007c48a6ab55dd9f63ccb8bfba`. Neither inspected Git object database nor retained archive contains its bytes. Keep the seven-file contract; do not infer that embedded assertions superseded the dedicated test.
- Astra passed the corrected reconstruction proposal at SHA-256 `155cc6a46adc251425ddbf98bac7da5088c24bf47fadf6bdfd35a7ab735ad94f`; it covers per-file lock authority, the 19-start successful v2 result contract, and exact generated-response capture/replay via the injected selector.
- The independent Luna parser port starts from the retained B source and preserves its v2 identity, selected-fit, and vector-loading behavior. Final parser SHA-256 is `fe6393dba470490302df17be4b7f2acd1466768c6a85db68967b82e1c7c5f27c`; parser test SHA-256 is `c4f1e6e61b9a248647e6a15553de6715d081dee1a507a7fe315febfc4f55a839`.
- R source hashes differ between the candidate and retained scratch: candidate `R/arc1-uncertainty.R` `8b64df40f7864dc2ace2cc0dd9b00de9434a0d15148384ddf61e896c4bcb6049`; retained scratch `bf82a23218f1f345f01815977d63815ac722df2fdae47e671c7d40741f20cb91`. Candidate `R/julia-bridge.R` is `341c2c4fe23b63a77ae0bcf9f9d9b36a49e485fadcb849b58f16dbaf5ceb038e`; retained scratch is `409147b4f9b54f04b09121ccbdd775a4b8d54030ee6b465cc3a165caf52848a0`.
- The protected main checkout has no Arc 1 rank or uncertainty source files and was not changed.
- `tools/arc1_oracles.py --help` confirms that G1/G6 require an externally reviewed exact source freeze and the runner has no freeze-generation mode.
- No Julia fit, R parity suite, simulation, or package check was run during this audit.

## 6. Tests of the Tests

Offline R parser tests passed; one mandatory-live parser test skipped because its opt-in environment variable was false. The new bootstrap-v2 live test parsed and skipped in offline mode as designed. `git diff --check` passed in the isolated clone. `python3 tools/arc1_oracles.py --self-test` passed its synthetic R and Julia pass/fail/skip/error/empty cases. Logs are retained in `evidence/r-source-reconstruction-20261008/`. No fit, selector, live Julia bridge run, full package check, or simulation ran.

## 7a. Issue Ledger

- Resolved: the focused parser fix is independently reviewed and has retained offline and live component evidence.
- Open: Astra exact-source review of the reconstructed R inventory, parser port, and new bootstrap-v2 live test.
- Open: after review PASS, build the new paired source freeze and run canonical G1/G6; a live test passing alone does not close them.
- Open: refresh paired G1/G6 and complete G7 evidence.
- Open: G2 through G5 and G8; no Arc 1 gate is closed by this audit.

## 8. Consistency Audit

The source inventory records all 100 frozen paths and three documented deviations. The test runner still selects seven R files. Astra passed the proposal review; exact source/test review of the reconstruction remains pending. No canonical G1/G6/G7 status changed. The shared R candidate, main R checkout, protected settings, and old scratch source remain unchanged.

## 9. What Did Not Go Smoothly

The current disposable parser candidate was built from an older R commit. Its passing focused test therefore cannot be used as evidence for the more recent Arc 1 uncertainty implementation in the retained scratch copy. The frozen oracle also expects a bootstrap-v2 test file that is not present in either isolated copy.

## 10. Known Residuals

This is a source-currentness audit only. No gate changed. G1 through G8 remain unmet in the live Arc 1 ledger, and the full non-GPU H2 goal remains active. No pilot, confirmation study, capability promotion, release, or publication action occurred.

## 11. Team Learning

Before repairing tests or creating a source freeze, bind the R candidate to the source version used by the retained Julia/R acceptance work. A passing bridge component on an older base is useful diagnostic evidence, not a current paired result. Astra performed an independent read-only source-inventory review; it did not review or authorize any code change.

Memory receipt: consulted the Codex memory registry for HSquared lane-preservation context and ran the repository route manifest and lane preflight. The repository instructions and validation-harness routing shaped the source-freeze boundary. Golden Set: not run; this audit made no implementation change and introduced no new failure-class guard.

## 12. Cross-Product Coverage

Covers: currentness and provenance of the isolated R parser candidate, retained R source copy, canonical G1/G6 file selection, and live gate status.

Does NOT cover: implementation, canonical G1/G6/G7 execution, numerical fitting, simulation, interval calibration, package-wide checks, or any Arc 1 acceptance requirement.
