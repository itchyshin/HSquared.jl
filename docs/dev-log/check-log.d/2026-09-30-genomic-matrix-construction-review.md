# Check log: genomic matrix construction review

Date: 2026-09-30

- Read-only Karpinski review of `src/genomic.jl:15-457` on exact source/test pins. Conditional component pass for inspected small-example construction and guards; dense quadratic storage, cubic inversion, activation copies/re-centering, dense APY output, repeated LOCO rebuilds, and absent scaling/allocation evidence remain limitations.
- Direct genomic tests cover small examples only. The pedigree diagonal test is not counted as genomic evidence.
- Reviewer ran no tests, benchmarks, fits, or simulations. Preflight found six refs with divergent work on `src/genomic.jl`; no source edit or reconciliation was attempted.
- Exact hashes, findings, and limits: `docs/dev-log/source-review/2026-09-30-genomic-matrix-construction-review.md`.
- This component review does not close full-file review, E1, genomic performance validation, or GPU work.
