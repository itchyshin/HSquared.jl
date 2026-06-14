# 2026-06-14 Multivariate Recovery Calibration Summary

## Overall Result

The predeclared calibration protocol was executed and did **not** pass. All fits
converged, but at least one seed failed the predeclared relative-error
thresholds in each case. This is negative calibration evidence, so no broad
multi-seed calibration claim is allowed.

## Case Summary

| case | seeds | converged | passed | pass proportion | Wilson 95% interval | mean G error | median G error | max G error | mean R error | median R error | max R error |
| --- | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| unstructured | 10 | 10 | 6 | 0.600000 | 0.312674-0.831820 | 0.261218 | 0.243217 | 0.478375 | 0.115135 | 0.100937 | 0.206494 |
| factor_analytic | 10 | 10 | 8 | 0.800000 | 0.490162-0.943318 | 0.315296 | 0.251020 | 0.577749 | 0.152755 | 0.155341 | 0.252226 |
| lowrank | 10 | 10 | 9 | 0.900000 | 0.595850-0.982124 | 0.230207 | 0.193943 | 0.422179 | 0.154342 | 0.146022 | 0.262608 |

## Seed-Level Table

| case | seed | converged | iterations | G error | G threshold | R error | R threshold | pass |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | --- |
| unstructured | 20260616 | true | 244 | 0.174500 | 0.250000 | 0.131056 | 0.200000 | true |
| unstructured | 20260617 | true | 257 | 0.157752 | 0.250000 | 0.062275 | 0.200000 | true |
| unstructured | 20260618 | true | 211 | 0.327252 | 0.250000 | 0.096695 | 0.200000 | false |
| unstructured | 20260619 | true | 259 | 0.416039 | 0.250000 | 0.093377 | 0.200000 | false |
| unstructured | 20260620 | true | 250 | 0.247717 | 0.250000 | 0.086263 | 0.200000 | true |
| unstructured | 20260621 | true | 231 | 0.261302 | 0.250000 | 0.206494 | 0.200000 | false |
| unstructured | 20260622 | true | 202 | 0.238716 | 0.250000 | 0.107839 | 0.200000 | true |
| unstructured | 20260623 | true | 214 | 0.169861 | 0.250000 | 0.193753 | 0.200000 | true |
| unstructured | 20260624 | true | 207 | 0.140662 | 0.250000 | 0.068421 | 0.200000 | true |
| unstructured | 20260625 | true | 228 | 0.478375 | 0.250000 | 0.105180 | 0.200000 | false |
| factor_analytic | 20260614 | true | 2362 | 0.200897 | 0.450000 | 0.167222 | 0.250000 | true |
| factor_analytic | 20260615 | true | 2233 | 0.442116 | 0.450000 | 0.159929 | 0.250000 | true |
| factor_analytic | 20260616 | true | 2151 | 0.559690 | 0.450000 | 0.150753 | 0.250000 | false |
| factor_analytic | 20260617 | true | 656 | 0.150967 | 0.450000 | 0.206706 | 0.250000 | true |
| factor_analytic | 20260618 | true | 1899 | 0.188808 | 0.450000 | 0.105089 | 0.250000 | true |
| factor_analytic | 20260619 | true | 2226 | 0.577749 | 0.450000 | 0.252226 | 0.250000 | false |
| factor_analytic | 20260620 | true | 1268 | 0.383702 | 0.450000 | 0.144246 | 0.250000 | true |
| factor_analytic | 20260621 | true | 688 | 0.298427 | 0.450000 | 0.176012 | 0.250000 | true |
| factor_analytic | 20260622 | true | 2490 | 0.146994 | 0.450000 | 0.070665 | 0.250000 | true |
| factor_analytic | 20260623 | true | 2653 | 0.203613 | 0.450000 | 0.094706 | 0.250000 | true |
| lowrank | 20260614 | true | 446 | 0.149899 | 0.450000 | 0.217969 | 0.250000 | true |
| lowrank | 20260615 | true | 423 | 0.376322 | 0.450000 | 0.133646 | 0.250000 | true |
| lowrank | 20260616 | true | 440 | 0.299148 | 0.450000 | 0.145071 | 0.250000 | true |
| lowrank | 20260617 | true | 408 | 0.192377 | 0.450000 | 0.201773 | 0.250000 | true |
| lowrank | 20260618 | true | 442 | 0.128983 | 0.450000 | 0.098467 | 0.250000 | true |
| lowrank | 20260619 | true | 412 | 0.422179 | 0.450000 | 0.262608 | 0.250000 | false |
| lowrank | 20260620 | true | 368 | 0.224385 | 0.450000 | 0.146974 | 0.250000 | true |
| lowrank | 20260621 | true | 298 | 0.184473 | 0.450000 | 0.158085 | 0.250000 | true |
| lowrank | 20260622 | true | 429 | 0.128799 | 0.450000 | 0.075919 | 0.250000 | true |
| lowrank | 20260623 | true | 485 | 0.195509 | 0.450000 | 0.102907 | 0.250000 | true |

## Failed Seeds

- unstructured: `20260618` (`G = 0.327252`, `R = 0.096695`); `20260619`
  (`G = 0.416039`, `R = 0.093377`); `20260621` (`G = 0.261302`,
  `R = 0.206494`); `20260625` (`G = 0.478375`, `R = 0.105180`).
- factor_analytic: `20260616` (`G = 0.559690`, `R = 0.150753`);
  `20260619` (`G = 0.577749`, `R = 0.252226`).
- lowrank: `20260619` (`G = 0.422179`, `R = 0.262608`).

## Raw Output

- `docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-unstructured.log`
- `docs/dev-log/recovery-checkpoints/2026-06-14-multivariate-recovery-calibration-structured.log`
