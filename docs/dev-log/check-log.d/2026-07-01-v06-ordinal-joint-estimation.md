# 2026-07-01 v0.6 ordinal JOINT cutpoint estimation (doc-20 Step 1)

## Goal

Lens: Gauss/Fisher (estimator + identifiability) + Rose. Phase 1 of the post-merge 7-hour plan:
extend the ordinal family from SUPPLIED cutpoints (the merged #212 kernel) to JOINT estimation of
`(σ²a, cutpoints)` via `fit_laplace_reml(...; family = :ordered_probit)`. Extends the covered-path
(doc-20 Step 1) for the T1 calving-ease trait. EXPERIMENTAL/`partial`; extends the `V6-ORDINAL` row
(no new `validation_status()` row → count stays 50). Branch `feat/2026-07-01-v06-ordinal-joint-estimation`.

## What was done

- **`src/nongaussian.jl`:** `:ordered_probit` case in `fit_laplace_reml` — joint `(σ²a, θ_2..θ_{K-1})`
  by an IDENTIFIED reparam (`θ_1 = 0`, `θ_j = θ_{j-1} + exp(δ_j)` → strict ordering automatic; K from
  the data). Guarded outer NelderMead: a σ²a **safety rail** (`|log σ²a − log σ²a₀| ≤ 8`) + a
  singular/non-finite penalty (`SingularException`/`PosDefException`/`DomainError` → `1e12`), so the
  weakly-identified small-data MLE cannot run to the boundary. K=2 uses 1-D Brent (θ = [0]).
- **`test/runtests.jl`:** T1-fit testset — the FITTED K=2 → `:bernoulli_probit` reduction (σ²a rtol
  1e-3, marginal loglik atol 1e-5, `cutpoints==[0]`), a K=3 fit on a structured pedigree (ordered
  cutpoints, rail-bounded σ²a, self-consistent marginal loglik, converged), and guards (`<1`/non-integer
  codes, `:variational`). Count guard unchanged at 50.
- **Status (all 3 surfaces):** `V6-ORDINAL` evidence/owed/boundary extended (joint estimation landed;
  the ≥3-category weak-identification caveat retained).

## Commands / results

- Kernel smoke: K=2 fit == `:bernoulli_probit` (Δσ²a 1.15e-7, loglik Δ 1.8e-15); K=3/K=4 ordered
  cutpoints, rail-bounded σ²a, self-consistent.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → PASS (T1-fit testset 10/10; count 50).
- `julia --project=docs docs/make.jl` → exit 0.

## Claim boundary

EXPERIMENTAL, INTERNAL, Laplace-only. `validation_status()` = 50 UNCHANGED (extends V6-ORDINAL);
public-covered fitting = 1 UNCHANGED; NOT a covered claim; not the public default; the `:ordered_probit`
fit path exists but is not exported/R-wired. **Honest finding:** ≥3-category σ²a is WEAKLY IDENTIFIED
on small/uninformative data (confounded with the fixed unit probit residual absent relatedness /
replication) — a documented threshold-model property, not a defect; the safety rail bounds it and
CREDIBLE ≥3-category identification is exercised by the recovery gate (Phase 5) on informative
simulated data. STILL OWED: the `:symbol` payload + scale-labelled h², a VA kernel, the `ordinal::clmm`
comparator, a recovery gate. Real Rose audit pending.
