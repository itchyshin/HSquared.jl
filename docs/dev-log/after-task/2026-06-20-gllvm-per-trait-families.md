# After-task report — 2026-06-20: Genetic-GLLVM per-trait response families

## 1. Slice identity

**Branch:** `julia/gllvm-per-trait-families`  
**Issue:** #50 (genetic GLLVM) — extension to `gllvm_laplace_marginal_loglik`  
**Scope:** Per-trait response families in the K-factor genetic GLLVM Laplace marginal. Internal, experimental; nothing promoted to covered.

## 2. What was done

`gllvm_laplace_marginal_loglik` in `src/genetic_gllvm.jl` now accepts `family` as
`Union{ResponseFamily, AbstractVector}`. When a `Vector` of `T` `ResponseFamily`
objects is supplied, the function:

1. Validates `length(families) == T`; throws `ArgumentError` otherwise.
2. Runs `_check_counts` per-column (each trait column against its own family).
3. Builds a per-record `fam_of_r` lookup array (`fam_of_r[r] = families[t(r)]`).
4. Routes the `_fam_score`, `_fam_weight`, and `_fam_loglik` calls in both the
   Newton loop and the final loglik evaluation through small inline closures
   (`_score`, `_weight`, `_loglik_r`) that dispatch on the per-record family.

The scalar family path is untouched: when `family isa ResponseFamily` (not a
`Vector`), `fam_of_r` is `nothing` and the original dispatch fires identically
— no numeric change.

`fit_gllvm_laplace_reml` was NOT modified; it remains single-family and passes
its scalar `family` argument to the marginal. The per-trait path is available via
`gllvm_laplace_marginal_loglik` directly. This was the clean choice: the REML
optimizer sweeps over the loadings `Λ` and does not require per-trait families for
the existing recovery tests; threading them through the REML estimator is noted as
future work in the validation-debt register.

## 3. Tests (TDD)

Tests were written BEFORE implementation (the suite errored on the missing method).
Added testset `"Genetic-GLLVM per-trait response families (#50 slice 2 extension)"`
appended after the existing `"Genetic-GLLVM REML over G_lat (#50 slice 3)"` testset
in `test/runtests.jl`. Eight assertions:

1. **Reduction (exact):** `Vector` of 2 identical `PoissonResponse()` families gives
   the same `loglik` as the scalar `PoissonResponse()` — `==` (not just `≈`), same
   Newton path, bit-for-bit. Output shapes and `converged` also checked.
2. **Mixed families:** `[PoissonResponse(), GaussianResponse(1.2)]` on a matrix with
   integer count column 1 and continuous column 2; fit converges, `loglik` is finite,
   shapes `(1,2)` and `(q,2)` correct.
3. **Guard (length 1):** wrong-length vector (1 element, `T=2`) throws `ArgumentError`.
4. **Guard (length 3):** wrong-length vector (3 elements, `T=2`) throws `ArgumentError`.

## 4. Files changed

- `src/genetic_gllvm.jl` — implementation + docstring update.
- `test/runtests.jl` — 8-assertion testset appended.
- `docs/design/capability-status.md` — `V6-GGLLVM-MARGINAL` row extended; "planned"
  GLLVM row updated to remove "per-trait families" from the remaining list.
- `docs/design/validation-debt-register.md` — `V6-GGLLVM-MARGINAL` row extended;
  `V6-GGLLVM-REML` missing-evidence field updated to note the REML estimator still
  takes a single family.
- `src/validation_status.jl` — `V6-GGLLVM-MARGINAL` and `V6-GGLLVM-REML` entries
  updated (row count unchanged: **41 rows**; `[end].id == "V6-GGLLVM-REML"`).
- `docs/dev-log/after-task/2026-06-20-gllvm-per-trait-families.md` — this file.
- `docs/dev-log/check-log.d/2026-06-20-gllvm-per-trait-families.md` — check-log entry.

## 5. Local checks

```
Pkg.test()  →  "Testing HSquared tests passed"
              Genetic-GLLVM per-trait response families (#50 slice 2 extension) | 8/8
              Full suite: passed (no failures, no errors)
validation_status() → 41 rows, last = "V6-GGLLVM-REML"
docs/make.jl → "build complete in 4.13s."
```

## 6. Rose audit — claim vs evidence

**Claims in this slice:**

- "A `Vector` of `T` identical families gives EXACT equality with the scalar path."  
  Evidence: test asserts `r_scalar.loglik == r_vector.loglik` (exact `==`). Correct
  by construction: the per-record closures reduce to the identical calls.

- "Mixed families (Poisson + Gaussian) converge and return a finite loglik."  
  Evidence: `r_mix.converged && isfinite(r_mix.loglik)` asserted. No numerical
  pathology on the 8-animal fixture with reasonable data. The Hessian is PD (Poisson
  weight `exp(η) > 0`; Gaussian weight `1/σ²e > 0`), so Newton converges. Honest:
  this is a small dense fixture; scaling behaviour untested.

- "Wrong-length vector throws `ArgumentError`."  
  Evidence: `@test_throws ArgumentError` for length 1 and length 3 with `T=2`.

**What is NOT claimed:**

- No recovery claim for mixed-family REML (that path does not exist in this slice).
- No external comparator.
- `fit_gllvm_laplace_reml` is explicitly noted as single-family only.

**Rose verdict:** the claims are backed by the tests. Status remains `partial` /
`experimental`; `GLLVM-style animal models` stays `planned`. Nothing promoted to
covered. The slice is narrow, clean, and reviewable.

## 7. Honest status

`gllvm_laplace_marginal_loglik` now supports per-trait families (experimental,
internal, dense/validation-scale). `fit_gllvm_laplace_reml` is left single-family —
noted explicitly in the after-task and validation-debt register. Nothing covered.

## 8. Lenses applied (review perspectives, not running agents)

Gauss (Newton loop unchanged; closures are thin wrappers, no new numerical code),
Karpinski (no new allocations on the hot path beyond the small `fam_of_r` vector
and three closures; the sentinel `nothing` avoids the vector entirely on the scalar
path), Noether (per-record dispatch is the natural generalization — `fam_of_r[r]`
replaces `family` everywhere; no equation changes), Curie (three test assertions
cover the reduction, a non-trivial mixed case, and two guard cases), Rose (above).

## 9. Definition of Done checklist

- [x] Implementation in `src/genetic_gllvm.jl`
- [x] Docstring updated
- [x] Tests added (8 assertions, appended after "REML over G_lat" testset)
- [x] `Pkg.test()` GREEN
- [x] `validation_status()` = 41 rows (unchanged)
- [x] `docs/make.jl` build complete
- [x] `V6-GGLLVM-MARGINAL` row extended in all three status files
- [x] `V6-GGLLVM-REML` row notes the REML estimator is still single-family
- [x] After-task report written
- [x] Check-log written
- [x] Rose audit completed
- [x] Committed to branch `julia/gllvm-per-trait-families`
- [ ] CI (push not done — orchestrator will land)

## 10. `fit_gllvm_laplace_reml` threading decision

Left single-family deliberately. The REML estimator optimizes `vec(Λ)` via
NelderMead; the inner call to `gllvm_laplace_marginal_loglik` can already receive
a family vector if the caller builds one. Wiring a per-trait-family argument through
the outer optimizer would not change the correctness of the already-validated
single-family REML path, and the recovery harness does not need it. The debt register
now documents this explicitly.

## 11. Next

The per-trait family extension opens the path to joint Poisson+Gaussian (or
Poisson+Bernoulli) multivariate GLLVM inference, which is the key use case for
mixed-response ecological data. Threading it through `fit_gllvm_laplace_reml` is
the immediate next step if the user wants per-trait-family REML.
