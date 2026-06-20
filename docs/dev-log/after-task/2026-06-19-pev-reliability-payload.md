# After-task — #43 PEV/reliability into the standard result payload (2026-06-19)

Part of the overnight autonomous runway run (Ada orchestrating). First slice of
the BT2 bridge-readiness batch; the lowest-delta, contract-confirmed win.

## Goal

Deliver the engine half of the locked #61 / hsquared#21 decision: make
`prediction_error_variance` and `reliability` standard fields of the univariate
bridge payload `result_payload(::AnimalModelFit)`, computed through the
`O(nnz(L))` (sparse-scalable) Takahashi selected inverse (`:selinv`), so the R
twin can make its PEV/reliability enrichment unconditional and close hsquared#21.

## What landed

- `result_payload(fit::AnimalModelFit)` (src/likelihood.jl) now carries
  `prediction_error_variance = (ids, values)` and `reliability = (ids, values)`,
  placed after `predictions`. PEV is computed once via `:selinv` and reused by
  `reliability` (new optional `pev` kwarg → no second Cholesky).
- Shape matches the R unpack: the R twin reads top-level
  `raw$prediction_error_variance` / `raw$reliability`, each `(ids, values)`, via
  `hs_julia_id_values()` (`../hsquared/R/julia-bridge.R`, hsquared#21).
- Tests (`test/runtests.jl`): widened the strict `propertynames(payload)` tuple;
  pinned payload PEV ≈ both `:selinv` and `:dense` and reliability ≈ `:selinv`;
  added an 8-animal Mrode9-shaped, `nfixed = 2` non-trivial fixture in the
  selinv testset pinning PEV/reliability `:selinv` == `:dense` and the payload
  values on a non-benign fit (off-diagonal `Ainv`, interior supplied variances).
- Rows: capability-status "R result payload shape"; validation-debt `V1-RESULT`
  and `V1-SELINV-PEV`.

## Review (3-lens adversarial workflow)

Hopper / Gauss / Rose → all **pass_with_nits**, no blockers. In-lane findings
addressed: PEV dedup (Gauss); scoped "machine precision" + softened
"production-direction" + documented the dense `inv(Ainv)` denominator
(Gauss/Rose); added the 8-animal PEV-diagonal fixture so the V1-SELINV-PEV
wording is backed, and filled the check-log docs/review placeholders (Rose).

## Local checks

- `Pkg.test()` → exit 0 (before and after the review fixes).
- `docs/make.jl` → exit 0.

## Cross-lane (flagged on #61, NOT edited from this lane)

- The R bridge's opportunistic `merge()` (`julia-bridge.R:51-58`) is last-wins and
  would overwrite the payload's `:selinv` PEV/reliability with the standalone
  extractors' `:dense` default (numerically identical today, but the live R fit
  route then never delivers the `:selinv` payload). R-lane should drop the merge
  so the base payload passes through, then close hsquared#21 on the de-duplicated
  path.
- hsquared#21 is now unconditional only on the `AnimalModelFit`/REML route; the
  Henderson-MME R route still rides opportunistic enrichment (separate slice if
  always-present is required there too).

## Follow-ups (noted)

- Production-direction reliability denominator: `diag(A)` via a selected inverse
  of `Ainv` (`O(nnz)`) instead of the dense `inv(Ainv)`.

## Claim boundary

Validation-scale bridge-shape change only. No production large-pedigree
reliability claim; no external comparator for PEV/reliability. No capability
moved to covered.
