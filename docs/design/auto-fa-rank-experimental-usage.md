# Experimental automatic genetic FA rank selection

Status: bounded experimental Julia/R mechanics locally accepted, 2026-10-02. All eight programme gates pass, including focused and full package checks, mandatory live parity, three independent source judgments and final reconciliation. Public covered count remains seven. Selection reliability and ordinary optimizer-driven K1 selection remain untested.

This comparison asks whether four traits are better described by separate genetic variances or by those variances plus one shared genetic factor. It compares K0 and K1 on the same observations. K0 still estimates a genetic variance for each trait. K counts shared factors; positive uniqueness variances keep the full genetic covariance matrix of full rank.

The supported input is complete four-trait Gaussian data, a pedigree, an intercept for each trait, and one observation per observed animal. Both candidates estimate an unstructured residual covariance. Missing responses, repeated observations, other trait counts, other fixed effects and genomic/custom relationships are outside this route.

## Julia

```julia
selection = select_fa_rank(Y, X, Z, pedigree; ids=pedigree.ids,
                         traits=["t1", "t2", "t3", "t4"])
selection.selection_status
selection.candidate_summary
selection.attempts
selection.selected_fit
```

The experimental `reml_aic_covariance` score is minus twice the restricted log likelihood plus twice the nominal covariance parameter count. K0 has 14 parameters and K1 has 18. The reported difference is K1 minus K0, so a negative difference favors K1. Differences within 1e-6 are numerical ties and choose K0.

Both candidates need an eligible converged fit. If either lacks one after the bounded start budget, selection is unavailable and there is no selected fit. Genetic and residual covariance must also be distinguishable after removing the trait intercepts. An identity relationship matrix and the stated all-half-sib design are refusal cases.

## R

Point `HSQUARED_JULIA_PROJECT` at the matching Julia checkout, then use the explicit expert control:

```r
selection <- hsquared(
  cbind(t1, t2, t3, t4) ~ animal(1 | id, pedigree = ped),
  data = dat,
  control = hs_control(
    engine = "julia",
    engine_control = list(target = "multivariate", rank_selection = "auto")
  )
)
print(selection)
fit_diagnostics(selection)
selection$candidate_summary
selection$attempts
fit <- selection$selected_fit
```

When selection succeeds, `fit` is an ordinary `hsquared_fit` and its existing extractors apply. When selection is unavailable, it is NULL. Omitted rank alone never requests automatic selection, and explicit rank, genetic structure or initialization cannot be combined with this control.

The default iteration budget is 2000. In the retained eight-animal execution witness, both ranks were unavailable at that budget because all three starts were unconverged. The same ordinary starts converged at 10000 iterations and selected K0. Increasing the budget can help a particular fit; it does not guarantee convergence or reliable rank selection. Use `iterations = 10000` in Julia, or add it to R's `engine_control`, when inspecting that retained fixture.

## Reading the result

Both candidate-summary rows remain visible, including refused or unattempted candidates. The attempt table retains actual optimizer starts and their failure reasons. Its `optimizer_objective` column stores the raw negative log likelihood reported by the optimizer for troubleshooting. The comparison fields `loglik` and `criterion` are populated only after the independent same-covariance check passes; rejected or unfinished scores remain missing. The independently reevaluated likelihood and discrepancy can remain visible on a rejected attempt as diagnostics. Candidate ranges, covariance disagreement and start sensitivity use completed, verified attempts, including verified attempts that did not converge. Cancellation propagates and retains a partial ledger with no completed winner.

In R, a propagated cancellation condition has class `hsquared_fa_rank_interrupt`. Its `partial_ledger` contains the candidate-summary and actual-attempt tables captured before interruption. Unfinished likelihood, iteration and convergence fields stay missing. It is an interrupted record, with no selected fit.

The uniqueness floor is 1e-4 in each trait's squared units, so changes in trait units can affect the admissible candidates. Near-floor and start-sensitivity flags are visible. The score is an experimental comparison rule for this singular covariance family. It does not give a probability that a biological rank is true. Fit uncertainty is conditional on the selected rank; selection reliability and selection-adjusted interval coverage require separate evidence.

The retained ordinary optimizer fixtures select K0. Selected-K1 fit construction and R transport have controlled witnesses built around eligible K1 fits; an ordinary optimizer-driven K1 selection has not been demonstrated. This execution gap is distinct from rank-recovery or reliability studies, which remain separate work.

## Separate Arc1 optimizer policy

The `optimizer_policy = "arc1_v1"` control is a separate opt-in optimizer policy introduced by the Arc1 Gaussian reliability programme. The examples above document the earlier bounded selector route and retain their original meaning. To select the newer policy in R, add it explicitly:

```r
selection <- hsquared(
  cbind(t1, t2, t3, t4) ~ animal(1 | id, pedigree = ped),
  data = dat,
  control = hs_control(engine = "julia", engine_control = list(
    target = "multivariate", rank_selection = "auto",
    optimizer_policy = "arc1_v1"
  ))
)
print(selection)
fit_diagnostics(selection)
```

The corresponding Julia call supplies a validated `Pedigree`:

```julia
selection = select_fa_rank(Y, X, Z, pedigree;
    ids=pedigree.ids, traits=["t1", "t2", "t3", "t4"],
    optimizer_policy="arc1_v1")
```

This policy fixes the per-start iteration budget at 2,000; do not also supply an `iterations` override. Omitting the policy preserves the earlier route. The earlier implementation programme's eight completed gates concern bounded selector mechanics and do not satisfy Arc1's separate G0-G8 reliability gates. The [Arc1 Gaussian usage note](arc1-experimental-usage.md) documents profile and full-reselection bootstrap controls, current evidence, and remaining limits. No Arc1 study or campaign has run, and selection reliability and interval calibration remain unestablished.
