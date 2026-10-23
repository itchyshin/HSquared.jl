# Check log: sparse Gaussian REML exact-current component review

Date: 2026-09-30

- Read-only exact-byte numerical review of `src/likelihood.jl:174-269,341-412` and directly relevant registered tests. Verdict: conditional pass for the REML determinant algebra and represented tiny/interior checks; whole-file and Wave 1 signoff remain open.
- Exact SHA-256 pins, spans, assumptions, ranked findings, and limitations are in `docs/dev-log/source-review/2026-09-30-sparse-reml-exact-component-review.md`.
- All five source/test hashes matched before and after review. The reviewer ran no tests, fits, simulations, or GPU work.
- Lane preflight found nine refs with `src/likelihood.jl` changes absent from this checkout. No source edit or branch reconciliation was attempted.
- This component review does not close E1, A2, or V3 and makes no production-scale or general boundary-recovery claim.
