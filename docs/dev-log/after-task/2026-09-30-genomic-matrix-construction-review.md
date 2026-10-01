## 1. Goal

Review the current genomic relationship construction, inversion, activation, APY, and LOCO source paths as one bounded Julia source-review slice.

## 2. Implemented

Added an exact-current read-only review receipt and matching check-log shard. The review conditionally passed inspected small-example construction and guard contracts, while recording dense scaling and validation limitations.

## 3a. Decisions and Rejected Alternatives

Kept the review read-only because preflight found six divergent refs on `src/genomic.jl`. Did not treat APY structure as sparse output, small correctness examples as scaling evidence, or a pedigree diagonal test as genomic validation.

## 4. Files Touched

Evidence only: `docs/dev-log/source-review/2026-09-30-genomic-matrix-construction-review.md`, `docs/dev-log/check-log.d/2026-09-30-genomic-matrix-construction-review.md`, `GATES.md`, `docs/dev-log/check-log.md`, and this report.

## 5. Checks Run

Karpinski reviewed the exact source and test hashes listed in the receipt and ran no tests, fits, benchmarks, or simulations. The coordinator ran check-log generation and `--check`, `preamble_cap.sh`, `git diff --check`, and `slop_check.py` on the report. The structural after-task check is recorded after this report is complete; its acceptance phase may remain red while programme gates are open.

## 6. Tests of the Tests

Small tests cover hand calculations, centering, weighted construction, symmetry/overflow, ridge inversion, APY core choices, provenance, and small LOCO examples. They do not measure scaling, allocation, peak memory, or inferential calibration. `test/test_relationship_diag_1pF.jl` is pedigree evidence, not direct genomic evidence.

## 7a. Issue Ledger

- Open: establish memory and runtime scaling for relationship construction and inversion.
- Open: quantify activation peak memory and remove redundant centering/copies if ownership permits.
- Open: establish whether APY and LOCO dense outputs meet supported size expectations.
- Open: check ridge consistency and type stability across public entry points.
- Open: finish remaining `src/genomic.jl` spans and whole-wave E1 signoff.

## 8. Consistency Audit

The receipt makes no sparse-output or performance claim from APY structure. Capability status, validation debt, covered count, release state, and GPU state are unchanged.

## 9. What Did Not Go Smoothly

The source file has divergent work on six refs. The review could proceed without modifying that shared file.

## 10. Known Residuals

This review does NOT establish large-data suitability, sparse genomic precision, allocation bounds, inferential validity, all genomic source contracts, whole E1, or GPU support.

## 11. Team Learning

Describe APY by its actual dense return shape and separate arithmetic reduction from storage reduction. Keep pedigree fixtures out of genomic evidence counts unless they exercise the genomic path.

Memory receipt: no second-brain decision or memory file was changed. Golden Set: no new fixture was added.

## 12. Cross-Product Coverage

This is Julia engine review only. It does NOT cover R formula or extractor behavior, R-Julia parity, release state, whole-file review, or capability promotion. E1 remains open.
