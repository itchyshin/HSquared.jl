# After-task report: E1 selected-inverse and bridge parser repair

## 1. Goal

Repair independently identified exact-contract gaps in sparse selected-inverse trace helpers and the Julia payload-v2 parser, then retain tests and honest E1 limits.

## 2. Implemented

- Selected-inverse trace helpers validate dimensions and offsets, and reject nonzero precision entries outside the factor’s selected-inverse pattern.
- The block-trace helper rejects dense inputs with `ArgumentError` before selected-inverse recursion.
- Shape and offset checks now precede the costly selected-inverse recursion. The dense oracle compares both trace helpers under a forced nonidentity CHOLMOD permutation.
- Payload parsing rejects ambiguous response fields, empty responses, an `X` row mismatch, and block names that are not nonempty strings.
- The schema now matches the `ParsedPayloadV2` return and result-wrapper contracts, states that correlated blocks must stand alone, distinguishes the unwired single-pedigree multivariate route from wired repeatability, and records the sibling R emitter without implying all callers migrated. Ratification remains pending. No model capability changed.

## 3a. Decisions and Rejected Alternatives

- Pattern validation runs inside the trace accumulation loop, so the hot path does not scan precision entries twice.
- The R emitter already emits one response field and valid block labels for the reviewed route; no R source change was needed.
- The full E1 checkbox stays open for remaining source spans and whole-wave signoff. Gauss passed exact-current selected-inverse review; Boole passed exact-current schema review after one final sentence was narrowed.

## 4. Files Touched

- `src/takahashi_selinv.jl`
- `src/bridge_payload_v2.jl`
- `test/test_selinv_trace_contracts.jl`
- `test/test_payload_v2_parity.jl`
- `test/runtests.jl`
- `docs/design/21-payload-v2-multiblock-schema.md`
- `GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/source-review/2026-09-29-e1-selinv-bridge-repair.md`
- `docs/dev-log/check-log.d/2026-09-29-e1-selinv-bridge-repair.md`
- This report

## 5. Checks Run

- Initial focused selected-inverse tests: **25/25 passed**. Follow-up focused tests: **28/28 passed**, including dense trace checks under a nonidentity permutation and rejection of dense block inputs. The latest focused run used `--compiled-modules=no` after the default Julia depot could not create a pidfile outside writable roots.
- Focused bridge parser checks: **8/8 passed**; integrated response and name testsets passed in `Pkg.test()`.
- Julia 1.10 `Pkg.test()` on the final code and schema state, including the sparse-input guard: **exit 0**, ending `Testing HSquared tests passed`. This run also passed the FA, GLLVM ordinary-restart, and payload-v2 integration tests. It reported the known `Project.toml`/`Manifest.toml` mismatch; no resolve or update was run.
- `git diff --check` and `bash tools/preamble_cap.sh` passed after follow-up edits.
- Gauss's latest selected-inverse review found no material correctness or valid-input hot-path concern. Boole's latest schema review confirmed the final wording. Hashes and findings are in the source-review receipt.

## 6. Tests of the Tests

Before implementation, six selected-inverse expectations failed because the helpers returned values or failed to reject invalid dimensions/offsets. The bridge probe accepted both `y` and `Y`. The latest focused test compares selected entries and both trace routines against dense calculations under a nonidentity factor permutation, and checks that dense block inputs fail early. The full package suite also passed after the final code and documentation edits.

## 7a. Issue Ledger

- The specific silent selected-pattern miss and parser boundary gaps identified in this review are repaired and locally tested.
- Exact-current component reviews passed after repair. E1 remains open for the remaining source spans and whole-wave panel signoff.
- A2 (FA likelihood information and recovery) and V3 (final-candidate validation and CI) remain open.
- This work does NOT close source review of every tracked Julia file, R/Julia parity as a whole, FA inference, GLLVM promotion, calibration, or any release gate.

## 8. Consistency Audit

The parser, schema, and tests agree that exactly one nonempty response is required and `X` must match the response row count. The schema describes the actual parsed type and distinguishes the unwired and wired multivariate routes. The sibling R emitter emits one response field and string labels. `public_covered_count` stays 7; FA and GLLVM status remains unchanged.

## 9. What Did Not Go Smoothly

The first package-test wrapper attempted to assign zsh’s read-only `status` variable after Julia printed its success marker. The final run used direct exit-code capture and completed successfully. The project/manifest mismatch warning remains and was left unresolved.

## 10. Known Residuals

- Exact-current component reviews passed; full E1 source coverage and whole-wave signoff remain open.
- The complete engine and bridge review is not signed off; E1 remains HOLD.
- CI, an R package check on the final tree, and a docs-site build after internal schema edits were not run in this slice.
- The after-task structure check passed, but the integrated acceptance-ledger check remains red because the programme, Wave 1, Wave 2 bridge, and E1 gates in the active ledgers remain open.
- A2 and V3 remain open. No GPU, registry, release, merge, or tag action occurred.

## 11. Team Learning

A documented sparsity precondition is not enforced merely because all current production callers satisfy it. Direct numerical helpers should validate the contract before returning an estimate. For shared request schemas, parser behavior and ratification status need to be explicit in both source comments and the schema page.

## 12. Cross-Product Coverage

This slice covers Julia selected-inverse helpers and payload parsing plus their tests and schema. It does NOT cover an R source change; the reviewed sibling emitter already sends one response field and string labels. It does NOT cover broader R–Julia parity, other payload routes, the remaining engine source, A2, V3, CI, or release checks. Memory receipt: repo source-review and gate files retain these findings; no memory decision update was needed. Golden Set: no new fitted reference result was added.
