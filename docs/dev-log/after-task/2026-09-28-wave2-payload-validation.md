## 1. Goal

Repair Julia payload-v2 parser defects found by the pinned wave-2 review and keep valid twin payloads on the frozen contract.

## 2. Implemented

- Accept only the legacy payload versions (absent or integer 1) and integer version 2. Reject unknown, boolean, and non-integer values; reject version 1 when `random_effects` is also present.
- Enforce live relationship pairings: IID requires identity precision, pedigree cannot use identity precision, and correlated blocks accept Julia-built or supplied precision, as allowed by the frozen schema.
- Reject non-matrix or non-square precision, duplicate IDs, and block ID counts that do not match incidence columns.
- Apply the same precision and ID validation to v2 and legacy-lifted blocks, including the second legacy effect.
- Reject legacy identity precision under the animal/pedigree label; default an omitted correlated partner label to `maternal`; reject empty or colliding partner labels.
- Added malformed-boundary tests for v2 and legacy payloads, supplied correlated precision, partner collisions, and the partner default. Updated the multivariate repeatability fixture to represent its IID identity precision with the documented `identity` status.
- Emit the frozen correlated result shape as one `name`/`ids`/`direct`/`partner` record, enforce shared direct/partner ID order, and update the R bridge extractor to consume that record while preserving hsquared's existing `animal` and `maternal` outputs.
- Reject a partial raw single-animal tuple instead of returning an incomplete legacy payload; add a regression assertion for the error. The supported `AnimalModelFit` route continues to return the complete legacy result via `result_payload`.
- Updated the wave-2 source-review report and created a per-slice acceptance ledger.

## 3a. Decisions and Rejected Alternatives

Kept the R payload grammar and public fitted-object shape unchanged. The parser fails closed on unsupported or inconsistent requests instead of inferring a different model from a relationship matrix. Reconciled the internal correlated result shape with the frozen schema in both twins. Partial raw animal tuples now fail closed because they cannot satisfy the existing legacy result contract.

## 4. Files Touched

- `src/bridge_payload_v2.jl`
- `test/test_payload_v2_parity.jl`
- `test/test_multivariate_repeatability.jl`
- paired R bridge extraction and live parity test in `R/julia-bridge.R` and `tests/testthat/test-direct-maternal.R`
- `docs/dev-log/source-review/2026-09-28-wave2-pedigree-bridge.md`
- `docs/dev-log/after-task/2026-09-28-wave2-payload-validation.md`
- `.unlazy/hsq-wave2-bridge-GATES.md`

## 5. Checks Run

- A direct `Pkg.test()` attempt on the managed candidate reached the comparator validate-only suite but could not write its read-only fixture. The complete writable mirror `/private/tmp/hsq-wave2-payload-final-20260928` passed `Pkg.test()` with `JULIA_NUM_THREADS=1` and `OPENBLAS_NUM_THREADS=1` (`Testing HSquared tests passed`). The comparator harness printed two Git lookup diagnostics because the mirror has no `.git`; its validate-only tests passed 37/37.
- Candidate-to-mirror SHA-256 matched for all changed Julia source/test inputs: parser `5181665f96f52ea2fd5a625731bc53da08f98b35ea10db6aed8cda5f1a15a57f`; payload tests `f361d0fa9a512f931975a796f32f3782bf6ccac294df31d6afb52ed5e35582df`; repeatability fixture `760802d7afca31f795949fb6fdd0128a5c02e676923817cc0a102a15a4161a1c`.
- R live direct-maternal bridge test passed 90 assertions against the paired candidate branch; Julia activated the matching HSquared.jl project.
- `git diff --check`: passed after implementation and report edits.
- `python3 /Users/z3437171/shinichi-brain/tools/memory_regression.py --selftest`: passed; every detector discriminates.
- `bash tools/preamble_cap.sh`: passed (`CAP OK`).
- `graft grep`: unavailable because this checkout has no writable `graft/.cache`; used the pinned source spans and direct file inspection.

## 6. Tests of the Tests

The regression cases submit invalid versions, IID/pedigree status mismatches, non-square precision, ID count and uniqueness errors, and a legacy identity-as-animal payload. Each expects `ArgumentError`; removing the corresponding parser guard makes that assertion fail. Positive controls remain in the package suite: v2 schema/parity fixtures, legacy pedigree aliases, the correlated parser default, and multivariate repeatability.

## 7a. Issue Ledger

- Fixed in this slice: unsupported payload versions and relationship statuses, live relationship type/status mismatch, supplied correlated precision support, precision shape and ID alignment on v2 and legacy paths, legacy identity-as-animal labelling, partner default and collision, and correlated direct/partner output structure in both twins.
- Still open: broader JuliaCall/R S3 parity beyond the direct-maternal route remains unverified; grouped founders and arbitrary pedigree depth remain outside the proven contract.

## 8. Consistency Audit

Checked the frozen schema's version and relationship rules, every local `iid`/`pedigree` test fixture that constructs payload blocks, the multivariate repeatability fixture, and the parser's common dimension path. The one IID fixture that used `supplied` for an identity matrix now uses `identity`. R request construction and public status tables were left untouched.

## 9. What Did Not Go Smoothly

The first direct Julia test include could not load the test-only `JSON3` dependency. The first package run hit a write-permission error when the comparator harness tried to create fixture packets in the managed checkout. The exact worktree was mirrored to a writable temporary directory and `Pkg.test()` passed; the comparator harness printed two Git lookup diagnostics because the mirror has no `.git` directory. The closeout structure check passed. Its integrated ledger step does not pass: the bundled validator reports that it cannot read this checkout's top-level `GATES.md`, and the current gate status shows A2, E1, and V3 still open. These are programme-wide review and acceptance gates, so this bridge slice cannot close the overall package gate.

## 10. Known Residuals

This slice hardens the Julia parser, verifies the correlated-result R extraction route, and rejects incomplete raw animal results. The local source review and test gates pass; integrated after-task closeout remains open on the programme-wide gate ledger. It does not establish general R–Julia S3 parity. No capability status row changed.

## 11. Team Learning

Memory receipt: searched the `shinichi-brain` vault for HSquared bridge and lane history and read `H² twin mission control`; also read the repository instructions and payload schema. `route.py` returned no LOAD-FIRST manifest for the absolute worktree path, so repository docs and source remain the technical authority. The active code change followed Hopper's pinned findings and schema contract.

Golden Set: `memory_regression.py --selftest` passed.

## 12. Cross-Product Coverage

Covers: Julia-side validation for supported payload-v2 requests, legacy animal labelling, the frozen correlated result shape, and the R direct-maternal extraction route.

Does NOT cover: Gaussian FA opt-in R fitting, Poisson genetic GLLVM opt-in R fitting, general R–Julia round-trip parity, raw animal-result fallback parity, the full Julia source review, unusual inheritance, automatic-rank selection, GPU execution, release submission, or public tagging.
