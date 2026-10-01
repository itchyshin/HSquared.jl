## 1. Goal

Prevent unrelated metadata columns from being treated as a missing sire or dam when raw pedigree input provides one recognized parent alias.

## 2. Implemented

Changed `_raw_parent_columns` so positional sire/dam inference is used only when neither recognized sire nor dam alias is present. Added regressions for father-plus-sex and sex-plus-mother input.

## 3a. Decisions and Rejected Alternatives

- Preserve recognized parent aliases and represent the absent parent as empty.
- Do not infer the absent parent positionally when a recognized alias already anchors the pedigree columns; metadata must not be converted into pedigree links.

## 4. Files Touched

- `src/data.jl`
- `test/test_data_empty_marker_status.jl`
- `docs/dev-log/source-review/2026-09-29-data-parent-alias.md`
- `docs/dev-log/check-log.d/2026-09-29-data-parent-alias.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-29-data-parent-alias.md`

## 5. Checks Run

- TDD negative control: four assertions failed before the source fix.
- Focused tests: empty-map checks 2/2 and raw-parent alias checks 13/13 passed.
- Full Julia 1.10 `Pkg.test()`: passed, ending `Testing HSquared tests passed`; existing Project/Manifest mismatch warning retained, with no resolve/update.
- Independent bridge review passed the exact final source and test hashes recorded in the source-review packet.
- The Julia source-review packet and check-log receipt were prepared against those hashes. The after-task structure check passed; integrated acceptance remains open across five ledgers: `.unlazy/hsq-fa-closeout`, `.unlazy/hsq-gllvm-foundation`, `.unlazy/hsq-w105`, `.unlazy/hsq-wave2-bridge`, and root `GATES.md`.

## 6. Tests of the Tests

Both one-sided alias fixtures failed against the old positional behavior: each falsely counted a metadata column as the absent parent, changing both the known-parent and missing-parent diagnostics. Both pass after the repair.

## 7a. Issue Ledger

- Fixed: one recognized parent alias plus unrelated metadata could create a false parent link and distort missing-parent counts.
- Open: broader Julia source-review waves and bridge review; A2, E1, and V3 acceptance gates remain open.

## 8. Consistency Audit

Checked both supported one-sided alias orientations, empty parent maps, nearby pedigree status assertions, and the full Julia package test suite. The recognized alias is preserved and absent-parent diagnostics remain empty. No capability-status row, validation-debt row, or covered count was changed.

## 9. What Did Not Go Smoothly

The first `route.py` call used an absolute worktree path and returned no manifest. Re-running with the registered repository name `HSquared.jl` loaded the LOAD-FIRST guidance. Lane preflight surfaced an older handover naming Claude; the exact live Codex lease for these source, test, and evidence paths was checked before continuing.

## 10. Known Residuals

This repair establishes Julia input-diagnostic behavior only. Exact current R parity, full source-review signoff, and FA/GLLVM opt-in R usability remain incomplete. A2, E1, and V3 remain open. No simulation, GPU execution, release submission, registry submission, merge, or tag occurred.

## 11. Team Learning

Positional fallback must not fill a missing semantic field after a recognized alias has already identified the available field. A lone parent alias plus metadata is a distinct supported input shape and needs direct assertions for both known-link and missing-parent summaries.

Memory receipt: `route.py HSquared.jl` loaded the LOAD-FIRST manifest after the absolute-path lookup failed. The current coordination board and lane preflight were consulted. The exact live path-scoped Codex lease was verified. No sibling-project scout or simulation was run.

Golden Set: listed the current cases and ran `memory_regression.py --selftest`; all detectors passed. No targeted parent-alias case exists in the set.

## 12. Cross-Product Coverage

This covers Julia raw-pedigree parent-column detection and its missing-parent diagnostics. It does NOT cover R bridge parity, other pedigree importers, model fitting, FA/GLLVM acceptance, unusual inheritance, GPU execution, or release readiness.
