# G2 K0 multistart diagnostic decision

Date: 2026-10-08  
Decision owner: Arc 1 driver, following Astra's independent method review  
Status: bounded diagnostic candidate approved; active selector unchanged.

## Evidence prompting this decision

On the retained outer10 input, the current ordinary default and expanded-reference split0.5 reproduce the same K0 trajectory, while split0.3 reaches a higher likelihood. The K0 shortfall is `0.16953374156236123`, above the frozen `0.0001` limit. Astra confirmed matching data, ordering, execution identity, and objective, and found that other deterministic reference splits reach the better point. The evidence supports start dependence or boundary stopping; global optimality remains unproved. The exact record is in `docs/dev-log/source-review/2026-10-08-g2-outer10-k0-reference-comparison.md`.

## Bounded diagnostic candidate

Evaluate an ordinary K0 schedule using all six existing deterministic splits: `0.05, 0.15, 0.3, 0.5, 0.7, 0.9`. Retain the current `0.5` default. Use the existing `arc1_v1` optimizer, at most 2,000 iterations per start, the current eligibility and refusal checks, and deterministic best-eligible K0 selection. Preserve the existing 18 K1 starts exactly: the phenotypic `default` and `balanced` starts remain unchanged, and the 16 `_arc1_derived_starts` are generated from the best eligible K0 result. This yields 24 planned starts per case.

Run only on already-consumed outer7 and outer10 data. Preserve every failed and unaccepted attempt and the original ledgers. Require exact source/runtime/input identity, complete deterministic ledgers, unchanged nesting and better-unaccepted safeguards, and best-found raw log-likelihood shortfall at most `0.0001`. Record covariance, boundary, gradient, refusal, and runtime outcomes. These cases remain historical and count as zero new G2 observations.

## Boundaries

This decision does not change the active selector, public API, frozen G2 criteria, seeds, outer-case denominator, or any scientific claim. Do not launch the numerical candidate until its exact source and adversarial tests receive independent review. A passing two-case diagnostic establishes feasibility only; adopting the method requires an explicit follow-up decision and evaluation on untouched cases. Pilot and confirmation remain held. No GPU, release, publication, or capability promotion is included.
