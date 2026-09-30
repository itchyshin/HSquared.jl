# Check log: payload v2 bridge result shape and parser contract

Date: 2026-09-30

- Read-only exact-candidate review of Julia payload-v2 output, current R extraction, schema, and directly relevant Julia tests. Verdict: hold on direct-maternal R-Julia result shape and `coefcov` parser validation; whole E1 remains open.
- Exact SHA-256 pins, concrete mismatch, supported mappings, and limitations are in `docs/dev-log/source-review/2026-09-30-payload-v2-direct-maternal-and-coefcov-review.md`.
- No tests or edits were made by the reviewer. Lane preflight found other refs with source/R bridge work and an active R opt-in-test lease; no reconciliation or contract-changing edit was attempted.
- The multivariate-repeatability result remains Julia-only per schema. No capability status, release claim, or covered count changed.
