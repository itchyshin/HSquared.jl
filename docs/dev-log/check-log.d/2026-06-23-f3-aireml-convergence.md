# Check log — F3 AI-REML scale-invariant convergence (Wave F, Track A)

**2026-06-23 · branch `claude/f3-aireml-convergence`.**

## Measure-first (overturned F2/METIS)

F1's after-curve flagged `fit_ai_reml` as the next q=300k wall (35.6 s, non-converged).
The plan + scout research said "factorization ordering → METIS". An experiment on the REAL
MME (`sim/drac/f2_ordering_experiment.jl`, fir) overturned that:

```
q=100000  AMD nnz(L)=388001 t=0.17s | METIS nnz(L)=384001 t=0.04s | fill x1.01
q=300000  AMD nnz(L)=1164001 t=0.15s | METIS nnz(L)=1152001 t=0.12s | fill x1.01
```

The sparse Cholesky is **0.15 s** at q=300k; METIS reduces fill by ~1% (half-sib MME barely
fills in). **METIS NOT implemented** — it would optimize a non-bottleneck + add a dependency
for ~0 gain. The 35.6 s was `fit_ai_reml` iterating to its 100-cap.

## Change

- `src/likelihood.jl` (`fit_ai_reml`): added a **scale-invariant** convergence check — also
  stop when the RELATIVE change in the variance components `max(|Δσ²|/σ²) < tol`. The
  existing `hypot(score) < tol` (absolute REML score) is unreachable at large q because the
  score scales with n. 6 lines, no other behavior change.
- `test/runtests.jl` ("Phase 1 AI-REML estimator"): `@test ai.iterations < 50` (pins
  efficient convergence; was implicitly ~100 at scale).

## Evidence

- **DRAC scale (opt-in, `sim/drac/f0_scale_benchmark.jl`):** q=300k **35.6 s/non-converged →
  2.3 s/converged** (15.5×; correctness fix — σ̂² was already at truth, the status was a false
  negative); q=100k 2.82 → 0.875 s. `sim/drac/results/f0_scale2_45512689.tsv`.
- **Local `Pkg.test()`:** green (`JULIA_EXIT=0`, "Testing HSquared tests passed") —
  regression-clean; the convergence change is additive (small fits still stop by score).
- In-CI cannot reproduce the large-n non-convergence (it only manifests ~q≥200k); the
  in-suite test guards efficient convergence, the DRAC checkpoint demonstrates the scale fix.

## Boundaries

- Correctness + speed fix on the EXISTING experimental AI-REML path; nothing promoted to
  `covered`. Not a competitive/performance claim — opt-in single-machine DRAC measurement.
- METIS remains a candidate ONLY if a deep multi-generation pedigree re-measures as
  factorization-bound (re-measure first). Scout doc updated with the measured outcome.
