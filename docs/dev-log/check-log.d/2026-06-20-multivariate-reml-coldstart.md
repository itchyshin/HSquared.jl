# 2026-06-20 Multivariate REML recovery — cold-start replication (V4-MV-REML)

- Goal: close the warm-start caveat Rose flagged on the bias/MCSE evidence (PR #78)
  — does the multivariate REML optimizer find the optimum WITHOUT being warm-started
  at the true G0/R0? Follow-on EVIDENCE slice; no new capability.
- Lenses: Curie + Fisher (recovery design); Rose (claim gate).

## What was done

- Added a `--cold-start=true` flag to `sim/phase4_multivariate_reml_recovery.jl`
  (opt-in, outside CI): when set, `fit_multivariate_reml` is called WITHOUT
  `initial`, using its phenotypic-scale default start instead of warm-starting at
  truth. `MultivariateRecoveryConfig` gained a `cold_start::Bool` field; `main` prints
  the mode.
- Re-ran the identical 12-seed set cold (20260616–20260627). Result: cold-start
  reaches the SAME optimum as warm-start on all 12 seeds — per-seed relative errors
  agree to optimizer tolerance (max |Δrel_G| = 2.7e-5; e.g. seed 20260616 rel_G
  0.174489 cold vs 0.174500 warm), 12/12 converged, identical aggregate (all six
  params |bias| ≤ 2·MCSE, EBV accuracy 0.902/0.910, 7/12 pass).
- Conclusion: at this design the REML surface has a single dominant basin the
  optimizer finds unaided, so the bias/MCSE finding is not a warm-start artifact.
  Recorded as a "Cold-start replication" section in the recovery checkpoint; updated
  the V4-MV-REML honest status in `src/validation_status.jl` +
  `docs/design/validation-debt-register.md` (warm-start caveat resolved).

## Commands / results

- `env JULIA_NUM_THREADS=1 ... julia --project=. sim/phase4_multivariate_reml_recovery.jl --cold-start=true --seeds=20260616,...,20260627`
  → 12/12 converged; cold ≈ warm (max |Δrel_G| 2.7e-5); exit 1 by design (7/12 pass
  the per-seed gate; aggregate flushes first).
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (36 rows; harness + evidence-string edits only, no behavioral change to `src/`).

## Claim boundary

EVIDENCE only; characterises basin behaviour at THIS design (not a global convergence
guarantee for arbitrary multi-trait problems). V4-MV-REML stays `partial` — still
needs external-comparator parity. The cold-start study is opt-in (outside CI).
