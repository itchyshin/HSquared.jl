# Independent FA campaign and A2 scientific disposition

Date: 2026-09-30. Curie validation panel verdict: **PASS for closeout of the scientific diagnostic portion of A2 in the retained bounded experimental Gaussian T4/K1 complete-record pedigree scope. Whole A2 remains HOLD.** The remaining engine/R-route source review, exact-current comparator reconciliation, wording cleanup and whole-wave panel signoff are not supplied here. No fit, seed replacement, simulation restart or live edit occurred.

## Campaign integrity and exact pins

Retained packet: `docs/dev-log/recovery-checkpoints/fa-primary-complete-20260930/` in `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`. Every entry in artifact-sha256.json independently matches. All 200 seeds are present exactly once and ordered 20261200 through 20261399; every row has 23 columns. Complete-mode strict validation succeeds with the exact source/driver trust anchors and log, and its JSON is identical to retained summary.json.

| Artifact | SHA-256 |
| --- | --- |
| Frozen source tree | `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a` |
| Frozen driver | `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b` |
| Current multivariate source | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| Validator | `2b2d7d60c313180b0a0668cb7d51929bdccb95d80d8f1279cbcd27c578420abb` |
| Primary TSV | `048483ae6620c6791a83841a1b56cb85ac2ce6bf17e678b93865a4bcef8700f8` |
| Primary log | `cfc1836b92698b897af4ba998d8fd4e19b16e2db525bbf3bb9331ac72082d167` |
| Retained summary | `4de842f8d538638393b7a65014fd2fd1616b5b73324399e4d34d2006dc2ae97e` |
| Completion witness | `86d9b1b7243f346103d7ba0c707ed7492007c35f2e05f95508a98e9050cc3166` |

Source tree and driver were recomputed locally and remain unchanged; retained witness records the same remote pins. The log ends with SUMMARY n=200 and WROTE. The remote ps lookup found PID 676046 absent. Together these establish complete retained output. The original launch shell wait exit code is unavailable; ps exit 1 is not a substitute for it.

## Independent no-fit tally

Estimate before checks: under one minute. Python stdlib validator and independent CSV/count/binomial calculations completed without numerical fitting. Own validator output: `/private/tmp/e1-fa-primary-strict-validator-20260930.json`.

| Driver outcome | Count | Fraction of all attempts |
| --- | --- | --- |
| Recovered | 110 | 55.0% |
| G_error | 20 | 10.0% |
| R_error | 11 | 5.5% |
| Nonconverged | 59 | 29.5% |
| Total | 200 | 100% |

Independent recovery MCSE is **0.0351781182** and Wilson 95% interval **[0.4807561514, 0.6173593160]**. All 200 attempts remain in the denominator. There are 141 selected converged fits; the 31 remaining converged outcomes fail covariance diagnostics. No recorded exceptions, nonfinite classes or below-truth-objective classes occur. Overlapping failures remain separate: 32 definite G threshold failures and 20 definite R failures include rows assigned earlier to nonconvergence or another primary class.

Thirteen rows are flagged near the uniqueness floor, including six recovered rows. Two have a better nonconverged start, including one recovered row. Seeds 20261231 and 20261359 have rounded min_psi boundary ambiguity. They are retained; no success is downgraded or failure removed using rounded values. Every reported scalar metric has 200 finite values, while recovered-only summaries condition on 110 rows. Scalar TSVs cannot reconstruct full matrix finiteness or exact unrounded covariance errors and start objectives; classification verification remains conditional on the frozen scalar projection.

The preregistration has no campaign-wide rate cutoff. Therefore 55% supplies measured ordinary-start usability evidence, without a retrospective numerical pass threshold or a general reliability claim. The likelihood-at-truth check is a diagnostic and gives no global-optimum certificate.

## Retained scientific acceptance checks

The A2 remaining design at docs/dev-log/source-review/2026-09-30-a2-remaining-acceptance-design.md:5–11,77–95 asks for honest campaign closeout, a deterministic weak-direction check, and ordinary-start unit/order sensitivity. Those requirements are now represented:

- Weak-direction receipt reports 36 new plus four helper assertions, ranks 17/18 at sparse loadings and 18/18 for epsilon perturbations, contraction ratio 0.00999835, mapped unit/order invariance and wrong-direction controls. This is expected information, without observed-curvature or calibrated-interval evidence.
- Five retained ordinary-start transformed fits use no generating-covariance initialization. All are finite/converged and pass the declared interior agreement targets; mapped G/R differences are below 8e-6. The independent dense trait-major likelihood, GLS and EBV oracle passed. This is one fixed fixture with a 10,000-iteration cap per start; the campaign has a 5,000 cap. It does not establish population unit invariance or equality of global feasible sets under the absolute uniqueness floor.
- The current component review's four engine/test pins supply bounded mathematical/source checks; they were not upgraded to whole-source signoff. Specific genetic uniqueness, residual covariance and full G retain their separate meanings.

## Comparator reconciliation and remaining holds

The older same-model independent R/Julia comparison is at multivariate source SHA `68f1ec986764e06417381008405f492a3bd8da9d8399bbf8511f4467f31ecc55`, with truth-informed starts and near-floor estimates. It is not current-source ordinary-start evidence. A bounded search of all 33 available multivariate file history versions did not recover that exact source, so an exact old/current source-difference attestation could not be made. Later overflow/residual-guard receipts describe narrow repairs but do not by themselves reproduce the old comparator pin. The current independent dense unit/order oracle supplies separate current-source evidence; it does not turn the historical R fit into an exact-current comparator.

Accordingly the scientific diagnostic portion can be accepted with the 55% result and explicit limitations attached. Whole A2 remains held for remaining engine/R-route spans, focused comparator change-impact reconciliation, source docstring RNG-free cleanup at multivariate:939–940 after freeze, and whole-wave panel signoff. No loading/uniqueness/evolvability interval calibration, other-rank identification, missingness coverage, reliable general optimization, R-public promotion, GPU approval, release or full E1 closure follows.

All review writes are confined to this report and its scalar validator output. No fresh Graft/source-wide numerical audit was needed; retained exact component/design reviews supplied scope.
