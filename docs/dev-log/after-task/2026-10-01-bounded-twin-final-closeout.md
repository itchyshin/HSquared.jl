# After-task: bounded HSquared twin programme final closeout

## 1. Goal

Close the approved bounded HSquared FA/GLLVM programme by reconciling final local evidence with exact hosted checks and ordinary landing in both package repositories. The scope excludes GPU work, new release submissions, registry submission, and release tags.

## 2. Implemented

Closed the final V3 evidence gap. Rose reviewed the exact closeout and required a current-status reconciliation; the coordination-board summary and GATES pointer now distinguish current state from preserved history. Julia PR #401 landed at `829e86ce67b61118eae8aa7e1fdda1d3899c6f9f`. R PR #259 landed at `e82f5c95e514028a7126fdd667c4ac7a840c9e6b`. Updated the gate ledger, check log, coordination board, and exact-source disposition receipt to record the completed landing state without rewriting earlier dated status entries.

## 3a. Decisions and Rejected Alternatives

Retained the bounded experimental capability boundaries. Fixed-rank Gaussian FA remains the four-trait, one-factor, pedigree, complete-response route with estimated unstructured residual covariance. Genetic GLLVM remains the three-trait, two-factor Poisson-log, complete balanced response route. The public covered count remains seven. Automatic rank selection remains a separately validated follow-on. No capability promotion or release action was made.

## 4. Files Touched

In the isolated Julia closeout branch: `GATES.md`, the final source-disposition JSON and Markdown receipt, `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`, and this report. Both twin implementation PRs were already merged before this reporting branch was created. No protected platform settings or model source were changed in this closeout branch.

## 5. Checks Run

- The three installed exact-source evidence modes passed on the reviewed candidate before landing, as recorded in the preserved exact-source receipt. A rerun from this clean closeout clone could not start because the ignored local `Manifest.toml` used by the checker is not present here.
- Julia PR #401 post-merge CI run `36814495496` passed Julia 1.10 and latest Julia on Ubuntu and Windows.
- Julia Documenter run `36814495443` passed build and deploy at merge SHA `829e86ce67b61118eae8aa7e1fdda1d3899c6f9f`.
- R PR #259 post-merge R CMD check `36792219254` passed at merge SHA `e82f5c95e514028a7126fdd667c4ac7a840c9e6b`.
- R pkgdown run `36792696953` passed at that same merge SHA.
- GitHub API access was unavailable during this final local pass. I did not refresh hosted state directly; the merge and run outcomes above come from retained exact-SHA receipts, and Rose also could not query the API during the independent recheck.
- Final source aggregate: `59d4a803e4d290a840927b4bce26ea4722f4404c009c171d173ba0c300c7d76e`; test runner hash: `27b7adbfe0b1c8d397e9041710fe713410d6692d9ef8ebf50af4354a0429adf3`.

## 6. Tests of the Tests

The objective-range portability assertion now compares the optimizer's default fit with the exact balanced initializer used internally. Independent review accepted this correction. The complete Julia test suite passed locally before landing and the exact merged commit then passed all four OS/runtime CI jobs. This validates the corrected oracle on the hosted matrix; it does not establish general FA recovery or inference.

## 7a. Issue Ledger

V3 is closed for the bounded final R package/bridge checks, source-bound evidence, reports, and ordinary hosted landing. The after-task section-structure validator passed; its combined command then stopped because the only discoverable `.unlazy` ledger is the historical `h2-twin-0.5.0` checklist with zero live gates. The report and GATES.md contain the current 0.10/0.11 ledger. A2 and E1 are accepted within their documented reviewed scope, with residual findings carried in the source-disposition inventory. V1/V2 local checks passed on current inputs and Julia documentation passed hosted deployment. No acceptance statement extends to remaining broad calibration or inference debt.

## 8. Consistency Audit

Hosted evidence does not change `docs/design/capability-status.md` or its validation-debt rows. The two routes remain experimental, and `public_covered_count` remains seven. The 200-seed FA campaign remains frozen with 110/200 diagnostic recovery and all nonconverged outcomes retained. There is no new CRAN submission, Julia registry submission, release tag, or GPU claim.

## 9. What Did Not Go Smoothly

The first hosted Julia candidate exposed a numerical lower-boundary issue, a true-residual PCG stopping defect, a missing documentation-test dependency, and runtime-sensitive FA outcome assumptions. Those defects were repaired and independently reviewed in the preceding receipts. A final shared objective-range assertion was then repaired and the refreshed candidate passed local and hosted checks. Prior failures and incomplete attempts remain preserved in their original logs.

## 10. Known Residuals

FA calibration and routine-start recovery remain limited; the frozen campaign has substantial nonconvergence. Non-Gaussian FA uniqueness, broader GLLVM families, missing data, response-scale heritability, loading inference, automatic rank selection, genomic scaling evidence, and unusual inheritance remain outside the accepted cells. Several component-level numerical and bridge findings remain carried in the source-review inventory. No GPU execution occurred.

## 11. Team Learning

Keep each acceptance claim tied to a precise estimand, exact source and test pins, and the next unproven rung. Hosted landing closes integration risk for tested platforms; it does not expand scientific validity beyond reviewed and validated cells.

## 12. Cross-Product Coverage

This closeout records the already-landed bounded R and Julia implementation, local evidence modes, hosted checks, and documentation deployment. It does NOT cover automatic rank selection, general FA/GLLVM use beyond the named cells, unusual inheritance, GPU execution, broad inference or calibration, new package submissions, or release tagging.
