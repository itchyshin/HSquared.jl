# Check log: model spec and fit help review

Date: 2026-09-30

- Henderson exact-current read-only review of `src/model_spec.jl` and direct tests: conditional pass for structural checks. ID uniqueness/order, retained-array ownership, direct-constructor bypass, and route-specific finite/SPD checks remain open. A remote handover diff touches the helper; no source edit was made.
- Emmy exact-current review found the exported `fit_animal_model` help falsely said the function was unimplemented. The generic now lists both implemented Gaussian input forms and all four supported targets, including AI-REML. The typed target help also names the AI-REML route. Rose confirmed the final help against exact source/test pins.
- Test-first regression failed on the stale help (2 assertions), then the strengthened `test/test_api_docstrings.jl` passed 8/8. It checks both input forms, all four target names, and removal of the stale Phase 0 claim. Rose's read-only audit did not execute dispatch tests. No model fits or simulations were run.
- The doc correction does not change engine behavior or capability status. A2, E1, and V3 remain open. Exact pins and limits are in `docs/dev-log/source-review/2026-09-30-model-specification-contract-review.md` and `docs/dev-log/source-review/2026-09-30-fit-animal-model-help-correction.md`.
