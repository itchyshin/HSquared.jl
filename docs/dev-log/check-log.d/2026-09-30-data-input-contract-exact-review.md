# Check log: data input-contract exact-current review

Date: 2026-09-30

- Read-only exact-current review of `src/data.jl` and registered ID/marker-status tests. Conditional pass for the covered Dict and marker-status cases; unequal `NamedTuple` column lengths can evade row-count validation.
- Exact pins, spans, current test coverage, and additional gaps are recorded in `docs/dev-log/source-review/2026-09-30-data-input-contract-exact-review.md`.
- Reviewer ran no tests or edits. Lane preflight found one divergent `src/data.jl` ref; its hard-coded `id` change would break custom genotype-ID marker counting and was not adopted.
- This is one data-input component disposition only. E1 remains open.
