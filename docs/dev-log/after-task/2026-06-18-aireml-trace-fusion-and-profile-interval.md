# AI-REML selinv trace fusion + profile-likelihood heritability interval

Date: 2026-06-18 (overnight autonomous session)

Two related Phase-1 inference/numerics slices landed together, both via TDD with
full local-suite verification.

## Slice A — fused AI-REML selinv score trace (`selinv_trace_against`)

### Goal
Numerical-equivalence refactor: `fit_ai_reml` computed the REML score trace
`tr(A⁻¹ C^uu)` as
`sum(Ainv .* takahashi_selinv(factor)[(nfixed+1):end, (nfixed+1):end])`, which
materialises the full selected-inverse `SparseMatrixCSC` and a dense slice each
AI-REML iteration — the dominant per-iteration cost, undermining the
`O(nnz(L))` advantage of the selected inverse. Replace it with a fused kernel
that accumulates over `Ainv`'s nonzeros without building the output matrix.

### What landed
- `src/takahashi_selinv.jl`: extracted the shared Takahashi recursion into
  `_selinv_zvals(ch)` (removing the pre-existing duplication between
  `takahashi_selinv` and `takahashi_diag`, which now both call it), and added
  `selinv_trace_against(ch, Ainv, nfixed)` — it runs the recursion once and
  accumulates `Σ Ainv[i,j]·C⁻¹[nfixed+i, nfixed+j]` over `Ainv`'s CSC nonzeros,
  looking up each `C⁻¹` entry in the recursion's `Zvals` via the existing
  `_csc_rowidx` binary search and the inverse permutation. `Ainv`'s pattern ⊆
  the random block of `C` ⊆ the `L+Lᵀ` pattern, so every entry is in-pattern
  (exact). No output `SparseMatrixCSC` is built.
- `src/likelihood.jl`: `fit_ai_reml` now calls
  `trace_AC = selinv_trace_against(factor, Ainv, nfixed)`.

### Tests of the tests
`test/runtests.jl` testset "Phase 1 fused AI-REML selinv trace": the fused
kernel equals the prior materialise-and-broadcast formula to **rtol 1e-10** on a
tiny 3-animal fixture and an 8-animal pedigree at two variance ratios; and
`fit_ai_reml`'s recovered optimum is unchanged (matches `fit_sparse_reml` —
loglik rtol 1e-5, variance components rtol 2e-2, the established AI-REML
tolerance for the flat n=8 surface). The selinv PEV/reliability testset (10/10)
still passes, confirming the `_selinv_zvals` extraction is regression-free.

### Claim boundary (Rose)
Internal performance refactor only. The public claim surface is **unchanged**:
no new fitting capability, no `result_payload()` change, no R bridge change. The
V1-SELINV-PEV capability/validation rows gained the fused-trace **evidence**
(equivalence test) but the claim boundary ("no large-pedigree or
external-comparator validation yet") is untouched, per the task scope. Not
benchmarked here — the equivalence and complexity are by construction; a
large-pedigree benchmark remains future work under the production-sparse slice.

## Slice B — profile-likelihood heritability interval

### Goal
Close the `V1-HERIT-CI` validation-debt item "profile-likelihood alternative" to
the existing logit-delta `heritability_interval`.

### What landed
- `src/likelihood.jl`: `heritability_interval(fit; level, method = :delta)` now
  dispatches `method = :profile` to `_heritability_interval_profile`, which
  inverts the REML likelihood-ratio statistic: it profiles the REML loglik over
  the total variance at each fixed h² (`_profile_reml_loglik`, 1-D Brent
  maximisation reusing `sparse_reml_loglik`) and root-finds (`_profile_root`,
  bisection) the h² where `2·(ℓmax − ℓprofile(h²)) = χ²₁,level`. Endpoints that
  reach the `(0,1)` search bounds are clamped. The default stays `:delta`
  (unchanged behaviour); the delta return gained a `method` field.

### Tests of the tests
The profile maximum at ĥ² recovers the fitted REML optimum (≈ `sparse_reml_loglik`
at the fitted VCs) and is an upper envelope of fixed-variance slices; the
interval contains ĥ² and lies in (0,1); weak nesting (95% ⊇ 50%). On the n=8
fixture the REML profile is **very flat** (`ĥ²=0.854`, max deviance over (0,1)
≈ 0.22 < the 50% threshold 0.455), so the interval correctly **clamps** to
(1e-6, 1-1e-6) — pinned as the honest "data barely constrain h²" behaviour. The
LRT-inversion root-finder is unit-tested on a synthetic deviance with known
crossings (0.3, 0.7) and on a never-crossing case (clamps to the bound).

### Note on the debugging
The first full-suite run surfaced 3 failures here that were **test-assumption
bugs, not implementation bugs**: the test assumed the 50% interval would be
interior (so the LRT threshold holds at the endpoints and nesting is strict). A
diagnostic of the actual profile showed the surface is too flat on this tiny
fixture for the deviance to reach even the 50% threshold, so the interval
clamps — the correct behaviour. The test was rewritten to assert the real
behaviour (validity, weak nesting, the documented clamp) plus a precise
root-finder unit test, rather than weakened.

## Checks run
- `julia --project=. -e 'using Pkg; Pkg.test()'`: **passed, exit 0, 1468/1468
  checks** (up from 1447: +7 fused-trace, +14 profile-interval).
- Low-core env: `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
  VECLIB_MAXIMUM_THREADS=1 nice -n 15`.
- Documenter build: not re-run this slice (no docstring/manual structure change
  beyond two internal-function docstrings); to be run in the next docs touch.

## Limitations / not claimed
- No large-pedigree benchmark of the fused trace (equivalence + complexity only).
- The profile interval is asymptotic, REML-only, and (like the delta interval)
  not coverage-calibrated; on small/flat fixtures it clamps to (0,1).
- Local-only commit; not pushed, no CI run yet (overnight autonomous policy:
  push/PR/merge wait for the maintainer).
