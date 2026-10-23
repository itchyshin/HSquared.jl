## 1. Goal

Review the animal-model input specification contract and correct the exported `fit_animal_model` help so it matches the implemented Julia methods.

## 2. Implemented

Recorded Henderson's exact-current model-spec review. Replaced the stale fallback help and added the omitted AI-REML target to the method-specific help. Added a regression for the exported help contract.

## 3a. Decisions and Rejected Alternatives

Kept model-spec findings read-only because an older remote handover changes the helper's structure and signature. Fixed the misleading help without changing dispatch, estimation, or failure behavior.

## 4. Files Touched

`src/placeholders.jl`, `src/likelihood.jl`, `test/test_api_docstrings.jl`, `GATES.md`, `docs/dev-log/check-log.d/2026-09-30-model-spec-and-fit-help.md`, both source-review receipts, and this report.

## 5. Checks Run

The focused docstring test first failed on the stale generic help, then passed 8/8 with a task-local Julia depot after the regression was expanded to both input forms and all four targets. `git diff --check`, preamble cap, prose lint, check-log shard validation, and after-task structure validation were run. Rose confirmed the final exact source/test pins and claim alignment. Acceptance remains red for open programme gates. No full `Pkg.test()`, fit, simulation, GPU run, or release action occurred.

## 6. Tests of the Tests

The new assertions read the public `fit_animal_model` help, require both input forms and all four supported target names, and reject the stale “not implemented in Phase 0” statement. They reproduced two failures before the edit and pass afterward. They do not validate numerical fitting or runtime dispatch.

## 7a. Issue Ledger

- Open: document caller responsibility for unique, nonmissing, correctly ordered animal IDs.
- Open: document that `y/X/Z/Ainv` are retained by reference, or adopt copy/immutability semantics in a separately designed change.
- Open: decide whether exported direct `AnimalModelSpec` constructors should bypass helper validation.
- Open: review route-specific numeric/precision validation, especially Henderson MME.
- Open: complete remaining engine and bridge reviews; A2, E1, and V3 remain open.

## 8. Consistency Audit

Rose confirmed that the help describes current Gaussian routes and preserves fail-closed behavior for unsupported shapes. The model-spec constructor findings remain explicit. Capability status, validation debt, covered count, version, and release status were not changed.

## 9. What Did Not Go Smoothly

The initial doc test confirmed the bug: Julia combined the stale fallback help with method-specific text that omitted AI-REML. The regression was added first, failed as expected, and passed after both help blocks were corrected.

## 10. Known Residuals

This does NOT establish animal-model numerical validity, fitted-output parity, R-Julia parity, full source coverage, A2/E1/V3 closure, GPU support, or release readiness.

## 11. Team Learning

Julia generic help can combine fallback and method-specific docstrings. When adding an estimator route, check both the exported generic help and the concrete method help.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new numerical fixture was added.

## 12. Cross-Product Coverage

This is Julia documentation and a docstring test only. It does NOT cover R syntax, bridge extraction, or twin parity. The broader objective remains active.
