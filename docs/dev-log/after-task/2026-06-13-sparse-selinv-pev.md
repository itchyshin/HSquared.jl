# Sparse Selected-Inversion PEV/Reliability

Active lenses: Gauss, Karpinski, Curie, Fisher, Rose (inline perspectives).
Spawned subagents: none.

## Goal

Add a production-scale sparse path for prediction error variance (PEV) and
reliability: the diagonal of the Henderson MME coefficient-matrix inverse `C⁻¹`
via a Takahashi selected inverse in `O(nnz(L))`, reusing the MIT sibling kernel
rather than reinventing it. Coordination point (touches the PEV/reliability
extractors); the additive heads-up was posted to issue #6 before the change.

## Files Changed

- `src/takahashi_selinv.jl` (new; adapted from DRM.jl, MIT)
- `src/HSquared.jl` (include `takahashi_selinv.jl` before `likelihood.jl`)
- `src/likelihood.jl` (`_selinv_mme_random_pev`, `_pev_values`, `method` kwarg
  on `prediction_error_variance`/`reliability` for fit and MME paths)
- `src/validation_status.jl` (row `V1-SELINV-PEV`)
- `test/runtests.jl` (new testset; `length(validation)` 12 → 13)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`,
  `docs/dev-log/after-task/2026-06-13-sparse-selinv-pev.md`

## Implementation

`takahashi_diag(ch)` returns `diag(C⁻¹)` in the original ordering in `O(nnz(L))`.
`_selinv_mme_random_pev(spec, σ²a, σ²e)` builds the sparse MME from
`_sparse_mme_system`, factorizes with sparse Cholesky, takes the selected-inverse
diagonal at the random-effect rows. `prediction_error_variance`/`reliability`
gained a `method::Symbol = :dense` keyword (`:dense` is the existing behaviour;
`:selinv` uses the new path). `result_payload()` is unchanged.

The dense MME (`_dense_mme_random_inverse_block`) and the sparse MME
(`_sparse_mme_system`) build the IDENTICAL coefficient matrix
(`Z'Z/σ²e + Ainv/σ²a` block), so the two PEV paths agree to machine precision.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. New testset
  "Phase 1 sparse selected-inversion PEV/reliability" = 10 checks. Direct smoke:
  `:selinv` vs `:dense` PEV and reliability max |Δ| = 3.3e-16.
- Kernel test: `takahashi_diag`/`takahashi_selinv` diagonal == `diag(inv(C))` on
  a small SPD matrix.
- Edge guards: invalid `method` rejected; `:selinv` == `:dense` on the fit path
  (with `atol` for near-zero reliability values).

## Public Claim Audit

Allowed: an experimental `method = :selinv` sparse PEV/reliability path exists,
exact at the `L+Lᵀ` pattern (the diagonal, hence PEV, is exact), matching the
dense path to machine precision on tiny + Mrode9 fixtures.

Blocked: production-scale/large-pedigree validation; external comparator parity;
AI-REML; fitted Mrode; any `result_payload()` widening; arbitrary off-pattern
covariances (NOT computed by selected inversion).

## Tests Of The Tests

The agreement test would fail for a wrong selected inverse (it pins the selinv
diagonal against the dense inverse diagonal, and `:selinv` PEV against `:dense`
PEV). The fit-path reliability check uses `atol` because reliability can be near
zero for a poorly-informed animal, where an `rtol`-only check is brittle.

## Coordination Notes

Additive change. The default extractor path stays `:dense` and `result_payload()`
is unchanged, so no R bridge change is required; R can opt in via its existing
PEV/reliability extractor enrichment. Heads-up posted to issue #6 before landing;
evidence note to follow on push. Reuse provenance: `DRM.jl/src/takahashi_selinv.jl`
(MIT), per `docs/dev-log/scout/2026-06-13-sister-reuse-map.md`.

## What Did Not Go Smoothly

- Initial fit-path reliability test used `rtol` and failed on a near-zero
  reliability value (absolute diff ~1e-15 but value ~0); fixed with `atol`. The
  selected inverse itself was correct (PEV agreed to 3.3e-16).

## Known Limitations

- Exact only at the `L+Lᵀ` pattern; off-pattern covariances are not computed.
- No large-pedigree / production-scale benchmark or external comparator yet.
- Not wired into `result_payload()` (deliberately, to keep the bridge contract
  unchanged).

## Next Actions

1. Post the CI-green evidence note to issue #6.
2. (Later) production-scale validation + external comparator (V1-SELINV-PEV →
   covered); fold the selinv trace machinery toward sparse REML/AI-REML gradients
   per the reuse map.
