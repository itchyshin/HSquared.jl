# Wave 4 data diagnostics: one-sided parent aliases

## Scope

Read-only bridge review identified a defect in `_raw_parent_columns` in `src/data.jl`: when exactly one recognized parent alias was present, positional inference could mistake unrelated metadata (for example, `sex`) for the absent parent column. This inflated known-parent and missing-parent diagnostics.

## Repair and evidence

- Positional sire/dam inference now applies only when neither recognized sire nor dam alias is present.
- Recognized one-sided aliases remain intact; the missing side stays empty.
- TDD first reproduced both father-plus-sex and sex-plus-mother failures (four assertions failed against the old code).
- Focused `test/test_data_empty_marker_status.jl`: empty-map checks 2/2 and raw-parent alias checks 13/13 passed.
- Full Julia 1.10 `Pkg.test()` passed, ending `Testing HSquared tests passed`; this includes the genomic symmetry repair and the existing FA/GLLVM contract tests in this candidate.
- Final source SHA-256: `ec49b48db4142a4d6bab80cfb7c63aa8115af9f045baa5cc8df25b36c3991846`.
- Final test SHA-256: `82ffbb1cbb11466adef918ada7da2fb193c202a4289f7dc352b4cd48b43111b1`.
- Independent bridge review verified both metadata cases at those exact hashes.

## Limits

The change repairs input diagnostics. It does not establish R/Julia end-to-end parity, a fitted capability, FA uniqueness inference, GLLVM calibration, whole-source review completion, or a capability-status change. A2, E1, and V3 remain open. No GPU or release action was performed.
