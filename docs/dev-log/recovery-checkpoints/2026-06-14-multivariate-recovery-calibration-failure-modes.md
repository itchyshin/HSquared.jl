# 2026-06-14 Multivariate Recovery Calibration Failure Modes

This deterministic summary was generated from the committed raw calibration logs
without rerunning simulations. It classifies failed seeds by the predeclared
threshold that failed:

- `G`: genetic covariance relative error exceeded its threshold only;
- `R`: residual covariance relative error exceeded its threshold only;
- `G+R`: both thresholds failed;
- `reported fail`: the log reported failure but neither threshold exceeded its
  limit, which would indicate a parser or harness inconsistency.

## Failure Modes

| case | failed seeds | G only | R only | G+R | reported fail |
| --- | ---: | ---: | ---: | ---: | ---: |
| factor_analytic | 2 | 1 | 0 | 1 | 0 |
| lowrank | 1 | 0 | 1 | 0 | 0 |
| unstructured | 4 | 3 | 0 | 1 | 0 |

## Failed Seeds

- factor_analytic: `20260616` (`G`; G = 0.559690, R = 0.150753);
  `20260619` (`G+R`; G = 0.577749, R = 0.252226).
- lowrank: `20260619` (`R`; G = 0.422179, R = 0.262608).
- unstructured: `20260618` (`G`; G = 0.327252, R = 0.096695);
  `20260619` (`G`; G = 0.416039, R = 0.093377);
  `20260621` (`G+R`; G = 0.261302, R = 0.206494);
  `20260625` (`G`; G = 0.478375, R = 0.105180).

## Interpretation Boundary

This is triage of negative evidence, not a new validation pass. The pattern
suggests the next predeclared response should distinguish genetic-covariance
sampling/identifiability issues from residual-covariance threshold failures, but
it does not justify dropping seeds, relaxing thresholds, or rerunning until the
pass count improves.
