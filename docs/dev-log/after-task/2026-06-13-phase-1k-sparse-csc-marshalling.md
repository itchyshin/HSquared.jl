# Phase 1K Sparse CSC Bridge Marshalling

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose.

Spawned subagents: none.

## Scope

Add a Julia sparse CSC marshalling helper for R `Matrix::dgCMatrix` slots and
record the R twin's opt-in experimental Julia engine path.

This is bridge infrastructure. It is not production fitting, Mrode validation,
or a performance claim.

## Implementation

Added:

- `sparse_csc_matrix(nrow, ncol, colptr, rowval, nzval; index_base = :zero)`

The helper:

- accepts zero-based R CSC slots by default;
- accepts one-based Julia CSC slots with `index_base = :one`;
- validates dimensions, column-pointer length, value lengths, column-pointer
  monotonicity, row bounds, and row ordering within each CSC column;
- returns `SparseMatrixCSC{Float64,Int}`.

## Tests

Added tests for:

- R-style zero-based slots;
- Julia-style one-based slots;
- string aliases `"r"` and `"julia"`;
- malformed dimensions;
- malformed column pointers;
- out-of-bounds row indices;
- unsorted row indices within a column;
- mismatched value lengths;
- invalid `index_base`;
- direct payload fitting parity after reconstructing `Z` from CSC slots.

Local checks:

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 163 checks.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only blocked-wording/audit rows, not public claims that R
  already uses sparse `Z` marshalling, production sparse fitting works, Mrode
  validation is complete, or bridge performance has been demonstrated.

## R Handoff

The R twin reports `hsquared` commit `9eabf0d` with:

```r
hsquared(..., control = hs_control(engine = "julia"))
```

Default behavior remains:

```r
hs_control(engine = "validate")
```

R-specific Julia controls stay inside `engine_control`:

- `julia_project`
- `initial`
- `max_dense_cells`

Reported R evidence:

- R-CMD-check `27456875004`: success.
- pkgdown `27456874995`: success.
- Pages `27456904688`: success.
- R issue #6 evidence comment:
  `https://github.com/itchyshin/hsquared/issues/6#issuecomment-4697531111`.

## Rose Audit

Verdict: clean with limitations.

Allowed wording:

- Julia has a sparse CSC marshalling helper for bridge payloads.
- R has an opt-in experimental tiny/local Julia path.

Blocked wording:

- R uses sparse `Z` marshalling already;
- production sparse fitting works;
- Mrode validation is complete;
- bridge performance has been demonstrated.

## Next Work

1. Update the R bridge to pass `Z` and relationship objects through sparse CSC
   slots.
2. Add Mrode/tiny validation fixtures across the live bridge.
3. Keep `fit_animal_model(y, X, Z, Ainv; ids, method, initial)` and
   `result_payload()` stable unless both twins coordinate a contract change.
