# 2026-07-01 v0.6 QGglmm external comparator — Poisson + Binomial(n>1) observation scales

## Goal
Lens: Fisher/Curie + Rose. Extend the QGglmm same-estimand external comparator (doc-19 §5; the
logit + binary-probit slice on #221) to the remaining two QGglmm-**builtin** observation scales —
**Poisson (count)** and **Binomial n>1 (proportion)**. Extends `V6-NS-H2` (stays `partial`, count 50).
Folded into #221 (the QGglmm-comparator extension).

## What was done
- **Generalized the comparator harness** `comparator/qgglmm_probit_observed/compare.R` to a
  6-column CSV (`mu,V_A,V_fixed,model,n_obs,engine_h2obs`) dispatching `QGparams(model=...)` across all
  four QGglmm builtins (`binom1.logit`, `binom1.probit`, `Poisson.log`, `binomN.logit` with `n.obs`).
- **Ran the 4-family comparison** (`engine_h2obs.csv`, `result.txt`): 25 comparisons total.
  - `Poisson.log` (engine `:poisson`, count estimand): agree to ≤**1.7e-16** (machine precision — the
    engine's log-normal–Poisson closed form and QGglmm cubature coincide).
  - `binomN.logit` (engine `:binomial`, n=10, proportion estimand): agree to ≤**1.2e-8**.
  - (logit + binary-probit from #221 re-run in the same harness: ≤4.5e-6.)
  - `max |engine − QGglmm| = 4.45e-6` over all 25 → `PASS`.
- **Owed field discharged** on all 3 surfaces: the QGglmm external comparator now covers all four
  builtins (logit, probit, Poisson, Binomial n>1); only the **ordinal (K>2)** and **Gamma-data**
  observation scales remain owed (non-builtin — QGglmm ordinal support + a custom Gamma model).
- Checkpoint `2026-07-01-qgglmm-probit-observed-comparator.md` extended to all four families.

## Commands / results
- `Rscript comparator/qgglmm_probit_observed/compare.R comparator/qgglmm_probit_observed/engine_h2obs.csv`
  → `PASS`, max 4.45e-6 (25 rows).
- `using HSquared` loads; `validation_status()` = 50 UNCHANGED.
- Real `rose-systems-auditor` audit (recorded in the PR).

## Claim boundary
The engine's observation-scale h² matches the QGglmm REFERENCE implementation for all four builtin
families to ≤4.5e-6 — a genuine same-estimand external comparator (doc-19 §5), NOT a covered claim.
`validation_status()` = 50 UNCHANGED; public-covered fitting = 1 UNCHANGED; V6-NS-H2 stays `partial`.
The ordinal + Gamma observation scales remain owed (careful non-builtin work); MCMCglmm, a
Fisher/Falconer sign-off, and G10 also remain owed for the covered path.
