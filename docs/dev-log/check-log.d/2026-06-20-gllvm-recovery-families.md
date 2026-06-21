# 2026-06-20 Genetic-GLLVM REML recovery — Bernoulli + Binomial families

- **Goal:** extend the existing `sim/phase6_gllvm_recovery.jl` harness to cover
  Bernoulli and Binomial response families and run the full four-scenario harness.
- **Active lenses:** Curie (simulation design) + Fisher (estimand/recovery) + Rose
  (claims, mandatory for any public claim/evidence update).
- **What landed:**
  - Extended `sim/phase6_gllvm_recovery.jl`: scenarios A/B (Poisson, unchanged) +
    scenario C (Bernoulli rank-1 logit, reported-not-gated) + scenario D (Binomial(20)
    rank-1 logit, gated).
  - Updated `docs/dev-log/recovery-checkpoints/2026-06-20-genetic-gllvm-reml-recovery.md`
    with all four scenario tables and honest interpretation.
  - Extended `V6-GGLLVM-REML` row (text only) in `src/validation_status.jl` (41 rows
    confirmed), `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`.
  - After-task report: `docs/dev-log/after-task/2026-06-20-gllvm-recovery-families.md`.

- **Results (ran):**

  | Scenario | Family | mean rel(G_lat) | result |
  | --- | --- | --- | --- |
  | A — Poisson rank-1 (q=240) | Poisson | 0.091 | 5/5 gated |
  | B — Poisson rank-2 (q=120) | Poisson | 0.205 | 5/5 gated |
  | C — Bernoulli rank-1 (q=240) | Bernoulli logit | 0.540 | 3/5 REPORTED-NOT-GATED |
  | D — Binomial-20 rank-1 (q=240) | Binomial(20) logit | 0.104 | 5/5 gated |

  All 20 fits converged. Scenario C seed 20260621 reached rel = 1.15 — the Laplace-
  for-binary downward bias puts the estimate below the truth Frobenius norm.

- **Honest scope:** Bernoulli scenario DELIBERATELY NOT GATED; the bias is the known
  Laplace-for-binary information effect (documented in `V6-BERNOULLI`). Binomial(20)
  confirms the bias is information-limited. No family promotion, no new validation row.

- **`validation_status()` row count:** 41 (unchanged).
- **`Pkg.test()` result:** GREEN (all testsets pass, suite unaffected — harness is
  outside `test/`).
- **Rose audit:** CLEAN. All four results recorded verbatim; scope honestly bounded;
  Bernoulli not gated and bias explicitly named; nothing promoted to covered.
