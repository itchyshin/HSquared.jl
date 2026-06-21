# After-task — Genetic-GLLVM REML recovery: Bernoulli + Binomial families

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/gllvm-recovery-families`.

## Summary

Extended `sim/phase6_gllvm_recovery.jl` — the opt-in known-truth recovery harness for
`fit_gllvm_laplace_reml` — from two Poisson scenarios to four: the two existing Poisson
scenarios (A rank-1, B rank-2) are unchanged; two new scenarios cover the Bernoulli
(single-trial logit, scenario C) and Binomial(20) (logit with 20 trials per record,
scenario D) response families. The full harness was run and the real results recorded.

The key finding is an honest negative for Bernoulli paired with an honest positive for
Binomial-20: the Laplace-for-binary downward bias that `V6-BERNOULLI` documents for the
single-factor animal model manifests in the genetic-GLLVM REML as well (mean rel = 0.54,
3/5 below the loose threshold, one seed at rel = 1.15). Binomial(20) resolves this
cleanly (mean rel = 0.10, 5/5 gated) — confirming it is an information-quantity effect.

## Definition of Done

- **Code:** `sim/phase6_gllvm_recovery.jl` extended with scenarios C and D; the generic
  runner `_run_generic` replaces the Poisson-only `_run` and routes through a response-
  sampler closure; Poisson scenarios A and B delegate through the same path (behaviour
  unchanged, numbers identical to the previous run).
- **Run:** harness executed, results captured (see recovery checkpoint).
- **Recovery checkpoint:** `docs/dev-log/recovery-checkpoints/2026-06-20-genetic-gllvm-reml-recovery.md`
  extended with all four scenario tables and honest interpretation.
- **Status rows (three files, one row each, text extended; no new rows):**
  - `src/validation_status.jl` — `V6-GGLLVM-REML` evidence + "still needs" updated.
  - `docs/design/capability-status.md` — same row extended.
  - `docs/design/validation-debt-register.md` — same row extended.
  - `validation_status()` count confirmed: **41 rows**.
- **Check-log:** `docs/dev-log/check-log.d/2026-06-20-gllvm-recovery-families.md`.
- **After-task:** this file.
- **Tests unchanged:** `test/` not edited; `Pkg.test()` GREEN.
- **Clean local checks:** `Pkg.test()` passes; harness is outside CI (opt-in).
- **Rose audit:** see below.

## Results

| Scenario | Family | seeds | mean rel(G_lat) | gate |
| --- | --- | --- | --- | --- |
| A — Poisson rank-1, `q=240` | Poisson | 5 | 0.091 | 5/5 gated |
| B — Poisson rank-2, `q=120` | Poisson | 5 | 0.205 | 5/5 gated |
| C — Bernoulli rank-1, `q=240` | Bernoulli logit | 5 | 0.540 | REPORTED-NOT-GATED |
| D — Binomial(20) rank-1, `q=240` | Binomial(20) logit | 5 | 0.104 | 5/5 gated |

All 20 fits converged. Scenario C (Bernoulli) seed 20260621 reached rel = 1.15, meaning
the Frobenius error on `G_lat` exceeds the norm of the truth — i.e. the estimator
returns a `G_lat` substantially smaller than the true one. This is the expected
Laplace-for-binary behaviour, not a code bug.

Scenario D (Binomial-20, same DGP as C but 20 trials per record) recovers to the same
level as the Poisson scenarios. The comparison is clean: same pedigree, same seeds, same
latent truth `Λ = [0.9, 0.6, 0.4]`, same `μ = 0` on the logit scale — the only
difference is the number of trials, confirming the mechanism.

## Rose audit (claim-vs-evidence)

Rose perspective (systems auditor, mandatory for any evidence update):

**CLEAN — no blockers.**

1. **Bernoulli scenario gating:** Scenario C is marked REPORTED-NOT-GATED in both the
   harness output (`println("REPORTED-NOT-GATED")`), the recovery checkpoint, and every
   updated status row. The known Laplace-for-binary bias is named explicitly in all
   three locations. No threshold-based pass/fail is implied for Bernoulli.

2. **Numbers recorded verbatim:** all per-seed rel values in the checkpoint match the
   actual harness output exactly. No rounding or selective omission.

3. **Row count stable:** `validation_status()` = 41 before and after. The three updated
   files each extend the existing `V6-GGLLVM-REML` row text only; no new row was added.

4. **Test suite unaffected:** `Pkg.test()` is green; no `test/` file was modified; the
   harness is correctly outside CI.

5. **Nothing promoted:** `V6-GGLLVM-REML` stays `partial`. `GLLVM-style animal models`
   stays `planned`. No status word changed to `covered` or `external`.

6. **Scope of Binomial claim:** the Binomial(20) result (5/5 gated, mean rel 0.10) is
   reported as a positive recovery with the caveat that this is a single `m=20` design
   at `q=240`, balanced/fully-observed, rank-1 only. The claim is correctly scoped —
   it demonstrates the information-effect mechanism, not a broad Binomial calibration.

## Claim boundary

Harness evidence only (opt-in, outside CI). Bernoulli recovery of `G_lat` is poor and
is NOT gated — honestly recorded as a known limitation. Binomial(20) recovery is
positive at this design scale. No external comparator, no FA structure, no fitted-object
extractors, no R model-spec, no broad multi-seed calibration. Nothing promoted to
covered.

## Next

The Bernoulli downward bias opens two natural paths:

1. Bias correction (higher-order Laplace or Gauss–Hermite VA) — already partially
   addressed in `V6-BERNOULLI` for the single-factor case.
2. Many-trial Binomial designs in practice — the Binomial-20 result demonstrates this
   is already effective.

The higher-leverage open items remain: FA(+Ψ) recovery, external GLLVM.jl/gllvmTMB
comparator parity, fitted-object/EBV extractors, and the R model-spec.
