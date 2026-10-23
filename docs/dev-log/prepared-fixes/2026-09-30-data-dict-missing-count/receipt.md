# Dictionary genotype missing-cell counter: isolated receipt

## 1. Goal

Correct the P2 data diagnostics finding D1 from the complete exact-current data source review. Count each physical marker column when a dictionary contains both Symbol and string keys with the same normalized marker name.

## 2. Implemented

The isolated `_genotype_missing_value_count` helper reads dictionary values through each original key. Other table protocols retain `_column` lookup; matrix dispatch is unchanged. Duplicate-name diagnostics remain available and the input dictionary is preserved. ID columns continue to be excluded by the configured name convention.

## 3a. Decisions and Rejected Alternatives

Preserve accepted malformed-name diagnostics. Rejecting every duplicate-name table would remove that surface. Changing global `_column` precedence could alter ID lookup in unrelated input routes. The correction is limited to the physical-cell counter.

## 4. Files Touched

Scratch-only `src/data.jl`, `test/data_dict_missing_count_regression.jl`, patch, logs, inventory and this receipt under `/private/tmp/hsq-data-dict-missing-fix-20260930/`. The package source copy, Project and Manifest match the active frozen candidate apart from the stated helper. No live source or runner was edited.

## 5. Checks Run

Estimate before launch: under one minute for deterministic metadata checks, one Julia and one BLAS thread. No fitting or simulation ran. The frozen version reports 22 passed and seven failed assertions, exit 1, testset time 1.5 seconds. The isolated corrected version reports 29/29 passed, exit 0, testset time 1.0 seconds. Each whole process completed within its estimate. Command: `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --project=. --startup-file=no --compiled-modules=no test/data_dict_missing_count_regression.jl`. Exact source, test, patch and log fingerprints are recorded in `sha256-inventory.json`.

## 6. Tests of the Tests

The independent physical-column oracle iterates original dictionary key/value pairs directly. Cases reverse the Symbol/string missingness, combine missing and nothing, and retain a no-missing control. The old implementation fails seven expected helper/visible-row assertions. Neighbor controls preserve custom ID names, string-only and Symbol-only dictionaries, named tuples, matrices, ID-only dictionaries, duplicate-name counts and input immutability.

## 7a. Issue Ledger

D1 is fixed in isolation, with independent review and integration pending. Delayed rectangular-table validation for inferred IDs, ID-first positional pedigree convention and mutable metadata remain explicitly fenced in the exact-current data review. This slice changes their implementation or approval neither.

## 8. Consistency Audit

Graft caller navigation identifies `_data_genotype_status` as the sole caller. The visible missing-cell metric agrees with physical dictionary columns after correction. Marker-label duplicate diagnostics retain their original meaning. The source tree and FA campaign driver remain frozen during this preparation; current programme gates and public capability count remain unchanged.

## 9. What Did Not Go Smoothly

Two guessed navigation names were absent from the graph. Using the exact current helper name resolved the lookup. Graft reports overload ambiguity, so literal search confirmed the caller before the isolated change. The red test demonstrates the original defect and remains part of the evidence.

## 10. Known Residuals

No fitter, R bridge, genotype matrix construction, arbitrary dictionary key protocol, calibration, broad package suite, GPU or release evidence follows from this metadata correction. After the campaign freeze ends, integrate the patch, register its focused test, and reattest the changed helper at new source pins.

## 11. Team Learning

One Sol 6.1 High contract reviewer completed the 1251-line data audit and isolated D1. The parent implemented this two-line repair and deterministic negative controls. A normalized label can identify duplicate columns while their physical values still require original-key access. Independent review is the next acceptance step.

## 12. Cross-Product Coverage

Covers the Julia diagnostic count for duplicated Symbol/string marker labels and selected unchanged metadata neighbors. R user language, capabilities, row statuses and campaign settings stay at their existing scope. No public covered-row change is requested.
