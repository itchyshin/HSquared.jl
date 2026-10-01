# Current test portability follow-up: independent local Rose acceptance

## 1. Request and verdict

PASS for local acceptance of the reviewed test follow-up to `ec9414c35d7621c6bd4321a9d16067ac9a2ea2eb`. Highest proven status: locally accepted reviewed Julia candidate, R already landed, exact-current Julia hosted acceptance and landing pending. V3 remains open.

## 2. Ownership

Actual independent Sol reviewer, Gauss and Rose lenses. This reviewer wrote only `/private/tmp/e1-final-test-portability-rose-review-20261001*`. Live repository was read only. No fit, campaign, full package rerun or public write was performed by this reviewer. Noncompute verification was bounded to the stated five-minute scope.

## 3. Exact numerical and environment pins

Reproduced the canonical aggregate over all 24 current `src/*.jl` files: `59d4a803e4d290a840927b4bce26ea4722f4404c009c171d173ba0c300c7d76e`. The algorithm hashes each sorted bare source-relative filename, NUL, raw bytes, NUL. No numerical source delta exists relative to the baseline HEAD.

Current active Project: `8797dab5ac93c3c03e29c6fa3924056c173873d40356e8be86a7367344cdd9dc`. Manifest: `c5940f2be0347f7ff987468aed67f17070f556a0aa99e0e5ec5317898cfa0fad`. Removing only REPL compatibility, test extra and test target reproduces the complete original Project TOML structure. Runtime dependencies, version and Manifest are unchanged.

## 4. Exact test composition

Only Project.toml and three test files differ in the tracked source/test/environment scope.

- Runner: `27b7adbfe0b1c8d397e9041710fe713410d6692d9ef8ebf50af4354a0429adf3`.
- API documentation test: `3a3afbfbfb1cf3f81566b8cdb7871dd874b73c4481736a8f097fda8dd3215299`.
- FA diagnostic test: `e340a84b71b6ae3b62ffa96591d5b576ba9c0d43c6fdb9e24382fa198ef942ea`.

Both canonical Docs.doc readers and REPL test declaration retain their separate v1/v2 reviews. The runtime unsupported coefcov contract and exact documentation assertion are unchanged. The two namespaced hosted numerical regression registrations remain present in the runner.

## 5. FA diagnostic correction

Static comparison independently confirms exactly four original assertions replaced: two positive disagreement thresholds, a fixed absence of better nonconverged starts, and a demand that one random-fixture start fail to converge. Their replacements recompute defined diagnostic/status quantities from separately fitted starts and retain controlled selector cases. The first 103 original lines and final 77 original lines remain byte identical; the complete unit/order block remains intact.

Astra's signed replay is 83 passing assertion executions: 68 author/original plus 15 independent controls. Author focused runs pass 68 on each tested runtime. These counts do not represent independent scientific samples. Neither expected-information rank nor passing diagnostic tests establishes interval coverage, observed curvature or global optimizer convergence.

## 6. Complete archives

The FA author archive SHA is `8ce60b9917f1d690e5cea1ecbf149fe29f7b7849ab345472628605536712f2c2`; independent archive SHA is `2909dcb268771a21080fadbe11867c0201b95a4f31c19de43deaa2b6f9972618`. All 26 and 43 regular members respectively match their exact inventories, with no missing, extra or duplicate member. Counts are archive files, not tests. No extraction or live mutation was needed.

## 7. Retained failures

The undeclared-REPL full sandbox failed after 84.4891 seconds, exit 1; the empirical FA assumptions failed after 311.6658 seconds, exit 1. Both logs, results and original freezes remain under `check-log.d/2026-09-30-docstr-portability/`. The v1 claim that no Project amendment was needed is superseded by the signed actual-sandbox v2 correction. The FA author's terminated 120-second whole-file probe remains in its archive and supplies no completed-test verdict. Timeouts are retained as incomplete runs.

## 8. Fresh runtime evidence

Read the pinned completed results: full Julia 1.13.1 Pkg.test exit zero in 466.9529 seconds under its 1200-second cap; required live R bridge exit zero in 22.7257 seconds; current Julia docs exit zero in 44.2642 seconds. Parent owns these runs. The complete 186-entry source/test/environment freeze precedes the package start. Current numerical source, all discovered tests, Project, Manifest and runner match that freeze.

## 9. Independent installed oracle replay

After parent evidence refresh, independently ran all three installed read-only modes. Each returned exit zero, empty stderr and its exact standalone success token: `HSQ_FINAL_JULIA_PASS`, `HSQ_FINAL_DOCS_PASS`, `HSQ_FINAL_R_BRIDGE_DOCS_PASS`. Checker SHA remains `2a404a0a2bb478b5f45bced92993a3c8193196f92f322f5f820fa892b26e0c4d`.

Final freeze SHA: `170e4dda33d2b357b2c24a4b10b94fe3d15597b355436d9d471dced2afc736c0`. Acceptance manifest SHA: `b52d1df83c0941f25d81255eed70b3e56a16fdf93cac5f394b60a8a3558cb342`. The oracle rechecks 66 retained artifacts, 31 Julia documentation inputs, 272 R inputs and five current rendered caveat pages. These inventory counts are not independent replications.

## 10. Current claims and ledger

The consolidated report's dated current header and latest check-log section describe fresh local acceptance and pending exact-current hosted checks/landing. Historical states keep their original scope. The retained gate reverification records nine read-only checks, 32 met and only V3 unmet. This is gate execution evidence; repeated oracle aliases supply no additional scientific validation. Covered count seven, experimental scope, immutable 200-attempt FA denominator, calibration/scaling limitations and GPU/release exclusions are unchanged.

## 11. Memory and Golden Set

Memory receipt: current source, archives, signed component receipts, completed runtime metadata and installed oracle outputs provide the evidence. Golden Set: exact unsupported documentation contract, declared actual test sandbox dependency, four defined FA diagnostic oracles, preserved selection/unit/order controls, full current inventories and required rendered caveats. Graft saved approximately 119,915 tokens in this bounded follow-up. This does NOT cover new calibration, campaign repetition, public deployment, release, or exact-current hosted acceptance.

## 12. Next action

Parent may checkpoint and proceed through its authorized hosted acceptance and ordinary Julia landing gates. Source/test/environment acceptance is local and exact-byte scoped. All residual scientific and capability limits remain visible; V3 closes only after its remaining evidence is established.

Signed: independent Sol reviewer, Gauss and Rose lenses, 2026-10-01 UTC.
