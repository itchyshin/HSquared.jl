# FA policy review and next repair

The parent independently reran the exact objective and optimizer-contract tests: 70 and 132 assertions passed, respectively. The real engineering fixture remained unavailable. Astra reviewed source `ec652d86ddc0f30a9c801e47e3fdb9277546258208cdaeffd8bc7478d94641cd` and repeated the same fixture in 6.54 seconds, retaining the full result.

The fixture was mislabeled as 80 offspring. It contains 76 offspring plus four observed parents in two large families. All fitted K1 residual covariances were numerically singular, with minimum eigenvalues around 1e-17 in magnitude. Seventeen starts failed final Wolfe verification. The default start met the optimizer gradient criterion but failed independent finite differences. Retain this case as a boundary adversary. It does not establish performance in the approved pedigree cells.

## Required source repairs

1. In `src/fa_rank_selection.jl`, allow any unaccepted K1 start with a finite independently reevaluated likelihood and successful covariance/objective checks to trigger the better-failed-fit refusal. The existing `status == :completed` filter wrongly excludes finite line-search failures. Test an eligible K1 fit alongside a better finite failed start.
2. Carry actual `optimizer_converged`, `optimizer_assessment_status` and `optimizer_assessment_reason` separately from acceptance. Preserve numerical-gradient failures; do not replace them with a claim that the optimizer failed to converge.
3. Return `source_identity`, policy/version and policy diagnostics on the top-level result and published ledger for unavailable and interrupted results too. Coordinate flat fields with the R bridge.
4. Count actual objective computations in the evaluator cache-miss branch. Keep callback requests, computations, rejected trials and restarts distinct.
5. Restore origin caches and scratch coordinates before rethrowing an unexpected final-verification callback exception. Remove its duplicate rejected-trial increment.

The guarded Hager-Zhang values, gradients, standard/approximate Wolfe formulas, and zero-step failure restoration passed Astra's source review. Preserve their criteria. Actual Optim 1.13.3 uses `result.stopped_by.ls_failed`; it has no `ls_success` result field.

## Correct ordinary witness

Use one engineering dataset with retained seed `20261002`, without true starts or a seed search. Generate 80 observed offspring from 10 unrelated sires, two unrelated dams per sire and four offspring per dam. The 30 parents are unobserved; the pedigree contains 110 animals. Use means `[0,1,-1,2]`, `G = 0.35*s*s' + 0.15*I` for `s=[1,1,-1,-1]`, and residual covariance with diagonal 0.5 and off-diagonal 0.1.

Generate independent founder genetic effects; each offspring receives half of each parent's effect plus an independent Mendelian term scaled by `sqrt(0.5)`. Map observed offspring into the validated pedigree explicitly. Retain the complete fit, per-start results, source hashes and runtime. Estimate 10-30 seconds and stop at 60 seconds, based on the previous engineering run. This is an implementation witness, with no confirmation or population-reliability claim.

The old fixture, logs and full diagnostic are retained under `.unlazy/arc1-gaussian-reliability/evidence/fa-boundary-ec652d86/`. G2 remains unmet.
