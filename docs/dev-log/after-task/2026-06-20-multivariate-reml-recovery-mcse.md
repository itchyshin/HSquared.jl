# After-task — Multivariate REML recovery bias/MCSE evidence (V4-MV-REML)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/s4-mv-recovery-evidence`. Type: EVIDENCE slice (no new capability).

## Summary

Enhanced the opt-in multivariate REML recovery harness to report per-parameter
Monte Carlo bias ± 2·MCSE, per-trait EBV accuracy, and a Wilson CI on the pass
proportion, then ran 12 seeds and recorded the result. The bare "6/10 failed" line
overstated the gap: the dense unstructured multivariate REML estimator is
**unbiased** at this design (all six covariance parameters |bias| ≤ 2·MCSE; EBV
accuracy ≈ 0.90 both traits; 12/12 converged). The per-seed Frobenius relative-error
gate fails ~40% of the time (7/12; Wilson 95% [0.32, 0.81]) because the genetic
covariance `G` has high sampling variance at q=80/n=240 — not because the estimator
is biased. This is the highest-leverage solo engine action identified by the
ultracode synthesis: it advances the V4-MV-REML evidence without the R lane or
external software.

## Definition of Done (evidence slice)

- implementation — `sim/phase4_multivariate_reml_recovery.jl` aggregate reporting
  (`_pearson`, `_wilson`, bias/MCSE table, EBV accuracy, Wilson CI); opt-in, RNG-
  isolated, outside CI.
- tests — none added (the harness is deliberately outside the RNG-free test suite,
  consistent with all other `sim/` harnesses); `Pkg.test()` re-run green (36 rows).
- documentation — recovery checkpoint
  `docs/dev-log/recovery-checkpoints/2026-06-20-multivariate-reml-recovery-mcse.md`.
- honest-status update — V4-MV-REML evidence updated in `src/validation_status.jl`
  and `docs/design/validation-debt-register.md`; status stays `partial`.
- check-log — `docs/dev-log/check-log.d/2026-06-20-multivariate-reml-recovery-mcse.md`.
- after-task — this file.
- Rose audit — the claim is "estimator unbiased at this design; per-seed gate
  failures are G sampling variance; NOT promoted to covered" — bounded and honest.
- clean local checks — `Pkg.test()` exit 0; no docs/API change.

## Result (m = 12 seeds)

| param | true | mean | bias | MCSE | within ±2·MCSE |
| --- | --- | --- | --- | --- | --- |
| G[1,1] | 1.00 | 0.999 | −0.001 | 0.079 | yes |
| G[1,2] | 0.35 | 0.366 | +0.016 | 0.046 | yes |
| G[2,2] | 0.70 | 0.742 | +0.042 | 0.050 | yes |
| R[1,1] | 0.80 | 0.794 | −0.006 | 0.028 | yes |
| R[1,2] | 0.20 | 0.202 | +0.002 | 0.012 | yes |
| R[2,2] | 0.55 | 0.546 | −0.005 | 0.017 | yes |

EBV accuracy: trait 1 = 0.902, trait 2 = 0.910. Converged 12/12. Pass 7/12
(Wilson 95% [0.32, 0.81]).

## Claim boundary

Estimator unbiased + accurate EBVs at this validation-scale design. NOT promoted to
covered — still needs external-comparator parity (sommer/ASReml/JWAS) and a
passing/re-declared recovery gate. Recovery study is opt-in (outside CI).

## Next

- Cross-lane: R lane runs sommer/ASReml/BLUPF90 against
  `test/fixtures/phase4_multitrait_parity/` (the existing serialized Julia target) —
  the remaining covered-blocker (#10/#49 on #61).
- Engine follow-ups (deferred): a relatedness-richer / larger design to drive G MCSE
  down under a pre-declared gate; a cold-start basin variant.
