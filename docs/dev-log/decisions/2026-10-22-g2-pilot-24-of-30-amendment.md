# G2/G3 FA pilot usability threshold amendment

Date: 2026-10-22  
Decision owner: HSquared Arc 1 driver  
Status: Owner-approved; independent scientific review approved the revised interpretation; versioned implementation pending

## Decision

The user approved lowering the FA rank pilot numerical-usability minimum from 29/30 to 24/30 in each of the nine G2/G3 pilot cells. Each cell still requires exactly 30 allocated attempts. The denominator remains all 30 attempts, and no failed attempt may be replaced.

This allows up to six unusable attempts per cell, compared with one under 29/30. It lowers the usability screen from 96.7% to 80%. This is an owner-selected, post-outcome exploratory feasibility screen, not a threshold derived from statistical theory or evidence that 80% eligibility is adequate for final validation. Results under it must be labelled as post-outcome and shown alongside the original 29/30 result.

## Unchanged requirements

- Required expanded-reference comparisons remain mandatory. An available rank without a reference maximum remains unresolved.
- The reference audit still covers the first 20 attempts, every unusable attempt, and every flagged near-tie or near-floor attempt. Each available ordinary rank must have a finite reference maximum and log-likelihood shortfall no greater than 1e-4.
- G2 still requires an ordinary K1 witness.
- G3 still requires no more than 6/30 null K1 selections at each sample size and at least 24/30 strong K1 selections at N=320.
- For each pilot cell, report selected K0, selected K1, and unusable attempts separately. Also report K1 selection conditional on usable fits, alongside the all-attempt count. Unusable attempts are not correct K0 selections. This reveals when a higher failure count makes the all-attempt K1 count look artificially favorable.
- Confirmation requirements, interval-formation thresholds, uncertainty coverage criteria, and all-attempt denominators are unchanged.
- A pilot usability pass is not confirmation, validation, or permission to promote a covered capability.

## Evidence and limits

The retained handoff reports 25/30 usable attempts in N80/null; that cell clears the amended count threshold only. Other cells and the full set of required reference audits are not established by this count. The retained handoff also reports missing reference maxima for two attempts; those remain unresolved under this amendment. Reference obligations continue to apply to every required case, including unusable attempts.

Because the amendment follows inspection of pilot outcomes, reports must show both the original 29/30 result and the amended 24/30 result. The independent scientific review approved the revised interpretation: 24/30 is defensible only as an exploratory feasibility screen, not as validation of the confirmation eligibility bound. It requires the separate K0/K1/unusable counts and conditional K1 rates above. The review approves the interpretation only, not implementation or any gate result.

## Implementation status

The additive evaluator is `tools/arc1_rank_pilot_amendment.py`. It first calls the unchanged frozen aggregator, preserves the original protocol hash and 29/30 result, then emits a separately hashed 24/30 result with a distinct success marker. Its marker is not accepted by the current confirmation-admission validator, and confirmation allocation remains held. The frozen experiment manifest and GATES files remain unchanged at 29/30.

Eight synthetic amendment tests and two existing rank-gate regression tests pass. No retained pilot bundle was evaluated by the new evaluator, so this adds no gate credit. Source-match, required-reference results, and all remaining pilot cells still need evidence.
