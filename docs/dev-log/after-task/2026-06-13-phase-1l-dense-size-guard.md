# Phase 1L Dense Validation Size Guard And R PEV Sync

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Karpinski, Gauss, Grace, Rose.

Spawned subagents: none.

## Scope

Add a Julia-side guard for the temporary dense validation path and record the R
twin's PEV/reliability extractor-contract handoff without widening the current
Julia bridge payload.

## Implementation

Changed:

- `src/likelihood.jl`
- `test/runtests.jl`
- `AGENTS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-v0.1-contract.md`
- `docs/design/03-engine-contract.md`
- `docs/design/06-public-claims-register.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/src/changelog.md`
- `docs/src/index.md`
- `docs/src/quickstart.md`
- `docs/src/roadmap.md`

Added `max_dense_cells` to:

- `gaussian_loglik()`;
- `fit_variance_components()`;
- `fit_animal_model(spec)`;
- `fit_animal_model(y, X, Z, Ainv; ...)`.

The guard checks the dense covariance and relationship cell count before the
current validation implementation forms dense matrices. It is deliberately a
temporary dense-path guard, not a sparse solver.

## R Handoff

The R twin reports `hsquared` commit `78ba5ff` with:

- exported `prediction_error_variance()` and `reliability()` generics;
- `hsquared_fit` methods for both;
- future-compatible bridge normalization if Julia later returns
  `prediction_error_variance` or `reliability`;
- current live-bridge tests that still expect these fields to be absent from
  Julia `result_payload()`.

Julia kept `result_payload()` unchanged in this slice. Future bridge widening
needs lockstep R and Julia tests with `(ids = ..., values = ...)` shapes.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 169 checks.
- `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm advisories
  in temporary build artifacts.
- Generated docs artifacts were removed after the build.
- `git diff --check` passed.
- Claim scan found only blocked/planned wording in old after-task reports and
  the claims register, not public claims that PEV/reliability are returned
  through the bridge, sparse production fitting works, Mrode validation is
  complete, or GPU/QTL support exists.

## Tests Of The Tests

The test suite now checks:

- the boundary value where the tiny three-observation, three-animal spec is
  allowed at `max_dense_cells = 18`;
- failure at `max_dense_cells = 17`;
- failure for non-positive `max_dense_cells`;
- propagation through the dense optimizer;
- propagation through spec dispatch;
- propagation through direct bridge-shaped payload dispatch.

## Public Claim Audit

Allowed wording:

- the dense validation path is size-guarded;
- the guard aligns with R `engine_control$max_dense_cells`;
- R has future PEV/reliability extractor contracts;
- Julia has dense low-level PEV/reliability functions;
- Julia `result_payload()` does not yet include PEV or reliability.

Blocked wording:

- sparse production fitting works;
- R sparse marshalling is wired;
- PEV/reliability are returned through the R bridge payload;
- Mrode validation is complete;
- GPU, QTL/eQTL, genomic, or GLLVM support is implemented.

## Limitations

- The guard does not remove dense computation; it only fails early.
- The guard counts the dominant dense covariance and relationship matrices, not
  every temporary allocation.
- No external comparator validation was added.
- No R files were edited.

## Next Actions

1. Coordinate R-side sparse CSC marshalling into `sparse_csc_matrix()`.
2. Decide when PEV/reliability enter `result_payload()` and update both twins in
   one lockstep slice.
3. Add Mrode/simple comparator validation before promoting animal-model fitting.
4. Replace dense covariance equations with sparse production computations.

Rose verdict: clean with limitations.
