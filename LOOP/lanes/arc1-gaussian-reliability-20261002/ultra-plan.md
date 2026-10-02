# Arc1 approved execution plan: H² Gaussian reliability

## Goal

Reliable ordinary FA fitting, evaluated automatic K0/K1 selection, and validated Gaussian uncertainty through Julia and R. The immutable scientific and compute contract is in `GOAL.md`; original gate IDs and acceptance outcomes are in `.unlazy/arc1-gaussian-reliability/GATES.md`.

## Current state

S0's deterministic protocol and math contract are frozen. S1's exact objective/gradient core and focused tests are present; independent G1 review is pending, while optimizer dispatch and policy integration remain outstanding. S2 core profile work and S3 seed-manifest/checker work are in progress. G0–G8 outcomes remain unchanged; no gate is marked complete by these core files.

## S0–S5 sequence

1. **S0: freeze:** reconcile the exact REML mathematics and covariance/ordering identities; record the complete approved protocol and seed-partition rule; preserve all original gates G0–G8. The namespace is `h2-arc1-gaussian-reliability-20261002-v1`. S3 generates and validates exact manifests before any study.
2. **S1: exact FA and selection policy:** prove the exact spectral REML objective and analytic gradient. Implement ordinary FA fitting and the opt-in `optimizer_policy="arc1_v1"`, retaining legacy behavior when omitted. Implement and validate prescribed starts, convergence rule, score, tie, and expanded ordinary-start reference. Depends on S0; disjoint ownership allows parallel work with S2.
3. **S2: five univariate repeatability profiles:** implement exact profile likelihood intervals for `Va`, `Vpe`, `Ve`, `h²`, and `t`, including analytic scale where available, explicit zero reduced models, LR cutoff, statuses, and disconnected sets. Depends on S0; disjoint ownership allows parallel work with S1.
4. **S3: independent evidence checker:** build checks that independently measure the objective, gradients, covariance identities, K1 numerical reliability, selection decisions, interval formation/coverage, and all-attempt denominators. Retain failures; never replace them.
5. **S4: R and live twin contract:** add explicit R expert controls and validate live Julia/R parity, interruption, and failure propagation against the same fitted contract.
6. **S5: studies and closeout:** run approved development and pilot allocations, review pilot qualification, then independent confirmation using only the frozen confirmation namespace. Complete independent scientific review and reconcile each original G0–G8 gate. A failed pilot holds confirmation; a failed confirmation leaves the gate unmet.

## Frozen numeric protocol

`GOAL.md` carries the full DGP, pedigree, optimizer, score, replicate allocation, selection-bound, and interval rules. Key facts are four traits with means `[0,1,-1,2]`; rho values 0, 0.15, 0.70; genetic diagonal 0.5; residual diagonal 0.5 and off-diagonal 0.1; N counts offspring at 80, 160, 320; REML AIC parameter counts 14/18 and penalty terms 28/36; nine selection and univariate repeatability cells; and the stated pilot/confirmation allocations. Both-candidates-eligible rate lower Wilson 95% bound is `≥0.90`; null K1 selection upper bound `≤0.20`; strong N=320 K1 selection lower bound `≥0.80`. All-attempt denominators include failures. No covariance-recovery tolerance is to be invented; recovery is descriptive.

## S0 items still to freeze

- S0 freezes namespace and canonical SHA-256 seed rule in `GOAL.md`; S3 generates/validates exact seed manifests and proves non-overlap before any study. Historical seeds are never confirmation seeds.
- The exact objective and score derivation, including the full fixed-effect correction, is frozen; independent G1 review and acceptance remain pending.
- Record the qualification decision that enables `B=499` confirmation and retain the designated `B=499/999` endpoint pilot. No selection of qualification thresholds may be invented in implementation.
- Confirm execution receipts and resource estimate. Planned campaign allocation is Totoro, four workers × four Julia threads, BLAS one. Estimate before every fit/campaign; the >3-hour approval rule still applies.
- Planning panel: Astra high for scientific plan/review; Luna high for S1/S2; Luna medium for S0/S3/S4/S5 routine work. Preliminary engineering estimate 20–35 hours and 12–24 elapsed hours; campaign runtime remains unmeasured and requires a pre-run estimate.

## Provenance and boundaries

Julia source baseline `8fd54b7b`; clean isolated R source `/private/tmp/hsquared-auto-fa-r-20261001` at `c9b15af350e0c5ca62e5e698716b66101251bcdc`. Preserve the dirty original Dropbox R checkout and protected `.claude/settings.json` / `.cursor/hooks.json` edits. The existing root `LOOP/GOAL.md` is a separate older H² programme and remains untouched; the application goal is tracked separately through its goal API. Authorized work includes scoped implementation, tests, and local commits. No release, push, publication, default activation, or capability promotion is authorized.
