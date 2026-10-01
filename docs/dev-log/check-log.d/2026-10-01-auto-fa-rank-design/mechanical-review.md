# Automatic FA-rank design mechanical review

Review mode: read-only, against base `28f90e095baa827682d416fc0be8e1fc7f2446c2` in `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl`.

## Verdict

**PASS ;  mechanical packet and preservation checks.** This does not discharge the separate manual method/user review gate or certify the scientific merit of the proposed REML-AIC rule. Those reviews and the final owner acceptance remain required before the design arc closes.

## Evidence

- The contract, validation plan, all three producer receipts, and ignored Unlazy leaf gate exist. The contract and plan are nonempty; all their relative Markdown links to the design plan, contract, and producer receipts resolve.
- `git diff --exit-code 28f90e09 -- src test Project.toml docs/design/capability-status.md docs/design/validation-debt-register.md` is clean. The only tracked change against base is the design-plan update; the two design deliverables and producer receipts are untracked at this review point. `git diff --check 28f90e09` is clean.
- The contract's source anchors in `src/multivariate.jl` support the stated rank-zero refusal for FA, un-floored public diagonal versus floored FA parameterizations, shared `A ⊗ G` covariance construction, full-constant REML objective, and nominal FA parameter count. The record-major Kronecker expressions are internally consistent with that source construction.
- The final contract and validation plan agree on K={0,1}, an internal floor-matched diagonal comparator, the experimental `reml_aic_covariance` score and signed difference, the `1e-6` tie rule, strict two-candidate eligibility, one bounded FA retry, full attempt retention, conditional uncertainty, and the stated implementation/validation obligations. The older user-contract scout preserves earlier recommendations as a proposal; it is not represented as the final contract.
- The plan clearly labels all future fits/simulations as unlaunched, gives a bounded future pre-run proposal, and distinguishes V0 design from V1–V4 implementation/evidence. Nothing in this review ran a fit, simulation, Julia test, or package test.
- The engine receipt explicitly qualifies the earlier Graft hits, separates the non-Gaussian GLLVM fitter from the Gaussian pedigree route, and anchors the contract in current source. I found no stale Graft result promoted into a current capability claim.

## Ledger interpretation

D1 and D2 are executable presence checks only; their accompanying evidence fields correctly require human review. D3 is an executable preservation diff and passed. D4 is still pending because the independent source-review report is not yet present, as anticipated by the review brief. M1 is a manual judgment gate: file presence alone cannot satisfy it. These pending final receipts are not counted as defects in this mechanical review.

## Coordination note

The required lane preflight showed this shared checkout has another active Codex lane and an active lease overlapping the design paths; the project router also returned no LOAD-FIRST manifest. I made no repository or hub edits and limited this review to read-only inspection. The owner should preserve the existing lane/lease coordination when adding final receipts.

## Actionable issues

No mechanical blocker found. Before closure, retain the independent method/user judgment and this independent mechanical review in the designated source-review/after-task evidence, then run the ledger's actual checks and resolve any manual gate findings. Do not describe this result as validation of selector performance or statistical calibration.
