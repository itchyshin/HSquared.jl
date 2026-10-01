# Automatic FA-rank design review ;  applied user, R-bridge, and claims lens

Initial verdict (before documentation corrections): **HOLD**. Follow-up resolution after corrections: **PASS for V0 design closure**; see the final section below. The core `auto-fa-rank-contract.md` is careful and substantially resolves the earlier user-contract concerns, but the producer user-contract supplied for review still makes conflicting claims and policies. Reconcile or explicitly supersede that note before calling the design packet review-ready. This is a documentation-consistency hold, not evidence against the bounded selector design itself.

## What passes in the core contract and validation plan

- K=0 is clearly the positive, trait-specific diagonal genetic covariance candidate, not zero genetic signal and not FA rank zero. K=1 is one shared genetic factor plus positive uniquenesses; the distinction between shared-factor count and full covariance rank is stated.
- The selector is explicitly opt-in; omitted rank does not select automatically, and fixed-rank calls keep their current meaning. The validation plan requires fixed-rank compatibility checks.
- A rank cannot win solely because the other candidate failed. Both candidates must be eligible; failure after the bounded budget yields `unavailable`, no selected rank/fit, reasons, and retained attempts.
- Criterion, parameter counts, penalty, signed difference, tie band, exact tie behavior, and conditional uncertainty scope are explicit. The documents correctly avoid interpreting the score as a biological-rank probability or regular likelihood-ratio test.
- Floor and start sensitivity are surfaced. A near-floor result may remain eligible but must set `boundary_sensitive`; this is a defensible, explicit policy for an experimental score. The floor's unit dependence and need for separate unit-change validation are stated.
- Design-only status is prominent: no selector implementation, fit, simulation, validation, public activation, default change, or covered-count change is claimed. The staged acceptance ladder keeps V0 separate from implementation and measured behavior.

## Required reconciliation

1. `docs/dev-log/scout/2026-10-01-auto-fa-rank-design/user-contract.md` says at its opening that the bounded R expert-control route “remains partial,” then later correctly cites immutable landed merge `e82f5c95e514028a7126fdd667c4ac7a840c9e6b` and documents the bounded fixed-rank bridge. The opening claim is stale and contradicts its own evidence. Preserve the distinction: bounded fixed-rank R transport exists at that immutable merge; automatic-selection payload/grammar does not.
2. The producer user-contract says floor- or boundary-flagged candidates should be ineligible and its example selects K=0 when K=1 lies at the floor. The frozen core contract instead permits near-floor candidates to remain eligible with `boundary_sensitive=true`, while at/below-bound candidates fail admissibility. Choose the core contract as controlling (it is the frozen design) and update the user-contract examples/policy, or explicitly label that note superseded. This affects user-visible selection outcomes.
3. The producer user-contract proposes status names `no_eligible_candidate` and `preflight_refusal`; the core contract specifies `unavailable` and `unsupported_input`. Align names across the design packet so future R/Julia parity does not inherit two schemas.
4. The producer user-contract leaves the criterion/tolerance unresolved and proposes two starts per candidate, whereas the core contract freezes `reml_aic_covariance`, `tau=1e-6`, one diagonal start and at most three FA starts. Mark the earlier proposal as superseded and keep its examples clearly illustrative, or update it to the frozen decisions.
5. Make the row-level representation of preflight-unattempted candidates unambiguous. The core contract requires candidate summaries for every rank and says preflight refusals retain candidates as unattempted; the attempt table is described as one row per start/retry. State explicitly whether unattempted ranks also receive synthetic attempt rows, or that candidate_summary is the authoritative retained row for those cases. The validation plan already requires preservation of unattempted outcomes.

## Claim boundary

After reconciliation, the supportable V0 statement is “design ready for a bounded implementation proposal,” subject to independent reviews. Nothing here supports a claim that automatic rank selection exists, works, is calibrated, is covered, or is available through R. The existing fixed-rank R bridge at e82f5c95 is a separate, already-landed bounded route and should not be erased by the stale opening sentence.

Review was read-only. No fitting, computation, publication, or repository edits were performed. Graft reported approximately 114,660 tokens saved on the required graph lookup.

## Narrow follow-up ;  final reconciliation check (2026-10-01)

The initial HOLD findings above are retained as the first-pass record. I re-read the revised controlling contract and producer user-contract after the requested corrections. **Current resolution: PASS for V0 design closure from the applied user/R-bridge/claims lens.** The documentation changes resolve the prior blockers:

- The core contract now says explicitly that `candidate_summary` is authoritative for every requested rank, including preflight-unattempted ranks; `attempts` contains actual starts only, with no synthetic start rows. Preflight refusal marks both candidate-summary rows unattempted with reasons.
- The producer user-contract now labels itself historical and superseded, gives a prominent final-disposition table matching the controlling contract, fixes its opening R-bridge fact at immutable `e82f5c95`, and identifies the old at-floor sole-survivor example as superseded. It also states the final `unavailable` status for the no-eligible case.
- K=0 meaning, explicit opt-in and fixed-rank compatibility, both-candidates eligibility, near-floor boundary flagging, conditional uncertainty, and the design-only/implemented boundary remain clear and consistent in the controlling contract.

The historical alternatives remain visible in the superseded note, but the new status and disposition are prominent enough to prevent treating them as current API decisions. This PASS means the design packet is ready for the V0 design claim only; it does not validate or implement the selector and does not change public support or covered count. The validation plan continues to reserve implementation, fitting, diagnostics, and bridge integration for later acceptance stages.

Follow-up was read-only. No source edits or compute were performed. Graft total for the original graph lookup remains approximately 114,660 tokens saved.
