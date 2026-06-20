# 2026-06-20 Multivariate REML recovery — bias/MCSE evidence (V4-MV-REML)

- Goal: convert the bare "6/10 failed" multivariate recovery line into durable,
  honest evidence that distinguishes estimator bias from sampling variance — the
  highest-leverage SOLO engine action from the ultracode synthesis (no R lane / no
  external software needed). EVIDENCE slice, not a new capability.
- Lenses: Curie + Fisher (recovery design / honest reporting); Rose (claim gate).

## What was done

- Enhanced the opt-in harness `sim/phase4_multivariate_reml_recovery.jl` (outside
  CI, RNG-isolated): it now reports, across seeds, per-parameter Monte Carlo bias ±
  2·MCSE (G[1,1]/G[1,2]/G[2,2]/R[1,1]/R[1,2]/R[2,2]), per-trait EBV accuracy
  (correlation of EBV-hat with the true simulated breeding values), and a Wilson 95%
  CI on the pass proportion. Dependency-free `_pearson`/`_wilson` helpers.
- Ran 12 seeds (20260616–20260627). Result: NO DETECTABLE bias at this
  (truth-warm-started) design — all six covariance params |bias| ≤ 2·MCSE (largest
  0.84·MCSE, a low-power non-rejection at m=12), EBV accuracy ≈ 0.90 both traits,
  12/12 converged. Per-seed gate 7/12 (Wilson 95% [0.32, 0.81]), failures
  G-dominated (4 G-only + 1 marginal G+R; R exceeds its gate once at 0.206).
- Recorded `docs/dev-log/recovery-checkpoints/2026-06-20-multivariate-reml-recovery-mcse.md`
  (question, setup, reproduce command, full table, honest conclusion, follow-ups).
- Updated the V4-MV-REML honest status in `src/validation_status.jl` and
  `docs/design/validation-debt-register.md` to cite the bias/MCSE finding. Status
  stays `partial` — NOT promoted (no external comparator; per-seed gate not
  re-declared in bias/MCSE terms).

## Commands / results

- `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 ... julia --project=. sim/phase4_multivariate_reml_recovery.jl --seeds=20260616,...,20260627`
  → 12/12 converged, 7/12 pass; AGGREGATE: all params |bias| ≤ 2·MCSE; EBV accuracy
  0.902 / 0.910 (exit 1 by design when not all seeds pass the per-seed gate; the
  summary + aggregate flush first).
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**
  (`validation_status()` 36 rows; evidence-string edit only, no behavioral change).
- No `docs/make.jl` API change (no new export); docs unaffected.

## Claim boundary

EVIDENCE/characterization only. The dense multivariate REML estimator is shown
unbiased with accurate EBVs at this validation-scale design; this does NOT promote
V4-MV-REML to covered — promotion still needs external-comparator parity
(sommer/ASReml/JWAS) and a passing/re-declared recovery gate. The recovery study is
opt-in (outside CI); CI on a clean checkout remains the authoritative gate for the
committed surfaces.
