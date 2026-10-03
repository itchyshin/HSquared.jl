# Remaining execution and scientific checks

Current authorization clarification, 2026-10-03: the user explicitly approved implementation of the plan with 400 confirmation datasets per cell and unchanged acceptance criteria. Astra confirmed that the operating-characteristic calculation shows low joint certification power, not invalid inference or an impossible gate. The earlier recommendation for another allocation decision is superseded. Retain the warning and all failed gates. No 1600 allocation, seed or criterion change is adopted. Qualified pilots, matching source/protocol admission and approval of any campaign projected above three hours remain required.

Historical record below; the clarification above governs the allocation authorization.

These are engineering tasks within the approved programme. They do not authorize an allocated study, confirmation run or campaign above three hours. Keep candidate manifests unadmitted until the numerical, interface and harness sources are frozen and independently checked.

## Expanded FA reference

Implement the larger ordinary-start reference in a separate simulation module, with focused tests. Reuse the reviewed exact objective and parameter packing. Generate no starts from the true covariance or a separately generated outcome. The reference receives the same observed dataset as the ordinary selector.

Use the frozen six K0 split starts and 64 K1 sign/amplitude starts. Run BFGS with 10,000 iterations per start. Rank finite results separately within K0 and K1. Continue the best four in each rank through Nelder-Mead with 20,000 iterations, then BFGS with 10,000. Retain every attempted start, intermediate maximum, optimization status and final independent gradient assessment. Record best found rather than a global-optimum claim. Preserve the exact objective, raw likelihood convention, covariance ordering and uniqueness floor.

The audit compares each ordinary rank with its corresponding reference rank. A likelihood shortfall above 1e-4 remains a failure. Numerical refusals and nonfinite results need explicit outcomes. Test the four-per-rank rule, raw versus scaled likelihood, different optimizer exit states, fixed dataset identity and failure retention with controlled objectives before a real engineering smoke.

## Actual study executor

The existing attempt store and seed manifest are foundations. Add an executor that verifies the exact loaded Julia source and environment against the admission before fitting. Load one canonical outer seed and independent DGP for each allocated attempt. Dispatch the appropriate FA selector, profile method or selector-repeating bootstrap. The engineering-probe route must be explicitly separate from development, pilot and confirmation partitions.

Retain the original data identity, model truth, exact seed strings, point result, every interval segment and refusal, selector candidate/start records, timings, source hashes, environment and error/interruption state. Save large detailed results losslessly and provide a machine-readable receipt with hashes linking to them. Successful serialization alone is not a successful fit. Preserve every attempted failure and prevent replacement after interruption or resumption.

Nested FA interval streams need distinct B=199 pilot and B=499/B=999 stability summaries. Use the original outer point fit in every summary. Reference runs must point to the same retained data. Retain all planned attempts even when a pilot fails, while preventing confirmation admission until its pilot gates pass.

## Scientific gate summaries

Build the original G2-G5 checks over verified per-attempt receipts. Reject missing cells, missing attempts, changed source or protocol, duplicate or wrong seeds, changed denominators and fabricated source identities. Enforce the frozen rank-selection requirements, required reference audits, formation and all-attempt coverage rules. Report formed-only coverage separately. Profile coverage uses the union of formed confidence-set segments, never the envelope across a gap.

Keep null, weak and strong signals separate. Report weak-signal selection and covariance recovery with uncertainty without inventing a new acceptance threshold. Exact-zero repeatability cells remain diagnostic. Check all five repeatability targets and all four trait-specific FA heritabilities. Retain failures in every denominator. Corruption tests must demonstrate that a bad penalty, covariance order, estimand, boundary reduction, source, seed, denominator or skipped bootstrap reselection causes a nonzero checker exit.

The current confirmation allocation remains 400 per cell. The independently confirmed coverage-design issue requires an explicit pre-study allocation decision alongside measured compute costs. Do not change the allocation or acceptance margins in an implementation leaf.
