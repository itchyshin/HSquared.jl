# Experimental Arc1 Gaussian routes

Status on 2026-10-03: Arc1 is an opt-in experimental implementation programme. The retained v1 source passed 1,678 focused assertions, mandatory live R parity, full Julia/R package checks and a local HTML documentation build. A bounded profile v2 revision is now in progress, so those source-pinned receipts do not validate the changed implementation. No allocated development, pilot or confirmation study has run. All current Arc1 gates G0-G8 remain open; no selection-reliability or interval-calibration result is available. The public covered count remains seven.

This note describes narrow expert routes in the Julia engine and paired R code. It does not change the default fit path or enable general factor-analytic formula syntax. Read the [capability status](capability-status.md) for current scope and the [Arc1 design record](arc1-gaussian-reliability-20261002.md) for the frozen study plan.

## Automatic K0/K1 selection

The automatic selector compares a diagonal genetic covariance (K0) with a one-factor genetic covariance (K1) for four complete Gaussian traits. The supported design uses a validated pedigree, one record per observed animal, trait intercepts, and an unstructured residual covariance. Other numbers of traits, missing responses, repeated records, other fixed effects, and genomic or custom relationship inputs are outside this route.

In Julia, `select_fa_rank` accepts the optional `optimizer_policy="arc1_v1"` with a validated `Pedigree`:

```julia
selection = select_fa_rank(Y, X, Z, pedigree;
    ids=pedigree.ids,
    traits=["trait1", "trait2", "trait3", "trait4"],
    optimizer_policy="arc1_v1")
```

Without `optimizer_policy`, the existing selector behavior applies. The `arc1_v1` policy uses a frozen 2,000-iteration budget per start, retains attempted and unfinished starts, and reports optimizer diagnostics. Supplying a different iteration count is refused. A completed eligible fit or a selected rank is not evidence that selection will be reliable across datasets.

The paired R control is explicit. `dat` must contain columns `id`, `trait1` through `trait4`, with one complete row per observed animal. `ped` must be a validated pedigree data frame with `id`, `sire`, and `dam` columns; unobserved parents may appear in `ped` without phenotype rows.

```r
selection <- hsquared(
  cbind(trait1, trait2, trait3, trait4) ~ animal(1 | id, pedigree = ped),
  data = dat,
  control = hs_control(engine = "julia", engine_control = list(
    target = "multivariate",
    rank_selection = "auto",
    optimizer_policy = "arc1_v1"
  ))
)
print(selection)
fit_diagnostics(selection)
```

Automatic selection remains distinct from a fixed-rank call. It does not open `cov = fa()` formula syntax, other ranks, or default activation. The earlier [automatic-rank implementation note](auto-fa-rank-experimental-usage.md) records a separate completed bounded-mechanics programme; its eight gates do not satisfy Arc1's G0-G8.

## Repeatability profile intervals

`arc1_profile_v1` profiles five quantities: additive variance (`Va`), permanent-environment variance (`Vpe`), residual variance (`Ve`), heritability (`h2`), and repeatability (`t`). The model is univariate Gaussian, with a pedigree animal effect and a permanent-environment effect. Each observed animal must have exactly two records. The current R route also requires the dense scale path and does not accept `initial`, `iterations`, or `max_dense_cells` overrides. The profile route cannot apply the legacy dense-cell cap. The likelihood-ratio cutoff is fixed at 3.841458820694124, the candidate nominal 95% cutoff; coverage remains unvalidated.

This complete R example uses six pedigree animals, including four descendants, and two records per animal. The values provide a small software-use example only:

```r
ids <- paste0("a", 1:6)
ped <- data.frame(
  id = ids,
  sire = c(NA, NA, "a1", "a1", "a2", "a2"),
  dam = NA_character_
)
dat_rep <- data.frame(
  id = rep(ids, each = 2),
  y = c(1.1, 1.4, 0.7, 1.0, 1.8, 1.5,
        0.3, 0.8, 2.0, 1.6, 1.2, 1.7)
)
profile <- hsquared(
  y ~ animal(1 | id, pedigree = ped) + permanent(1 | id),
  data = dat_rep,
  control = hs_control(engine = "julia", engine_control = list(
    target = "repeatability",
    scale_method = "dense",
    uncertainty_method = "arc1_profile_v1"
  ))
)
confint(profile, method = "arc1_profile_v1")
```

The Julia engine entry points are `arc1_profile_repeatability(y, X, Z, pedigree; ids=pedigree.ids)` and `arc1_confint(profile_result)`. Supply a validated `Pedigree`, a finite full-column-rank fixed-effect matrix `X` with fewer columns than response rows, an incidence matrix `Z`, and two responses per observed animal. The interface does not impose an intercept-only design; the R example above uses an intercept. The result may retain separate rows for disconnected confidence-set segments. A refused or unresolved target has no interval bounds; formation on a single dataset does not establish repeated-sampling coverage.

## Full-reselection bootstrap intervals

`arc1_bootstrap_v1` targets the four trait heritabilities from the automatic K0/K1 selector. Every bootstrap sample reruns the complete selector. The user supplies a fixed bootstrap budget `B` and exactly `B` distinct UInt64 seeds; no seed schedule is chosen implicitly. In R, provide seeds as decimal strings when needed so each UInt64 value remains exact.

```r
seeds <- c("101", "102", "103")
selection_with_bootstrap <- hsquared(
  cbind(trait1, trait2, trait3, trait4) ~ animal(1 | id, pedigree = ped),
  data = dat,
  control = hs_control(engine = "julia", engine_control = list(
    target = "multivariate",
    rank_selection = "auto",
    optimizer_policy = "arc1_v1",
    uncertainty_method = "arc1_bootstrap_v1",
    bootstrap_B = length(seeds),
    bootstrap_seeds = seeds
  ))
)
arc1_uncertainty(selection_with_bootstrap)
confint(selection_with_bootstrap, method = "arc1_bootstrap_v1")
```

The three-seed example demonstrates argument shape only. The current formation rule requires at least 99% usable fits, so all three would have to succeed at `B=3`; that arithmetic threshold does not make three replicates adequate for estimating useful endpoints or assessing coverage. Use a study budget only after runtime is measured and the approved study plan admits it.

The Julia entry point is `arc1_bootstrap(selection, Y, X, Z, pedigree; selector=:arc1_v1, B, seeds, ids=pedigree.ids, traits)`. Supply one explicit seed per requested bootstrap attempt. Failed inner fits remain part of the retained attempts and are not silently replaced. The R extractor `arc1_uncertainty()` returns a long interval table; refused targets remain as rows with missing bounds. `confint()` requires the explicit method name shown above. Bootstrap intervals use fixed nominal 95% percentile bounds; coverage remains unvalidated.

## Interpretation boundary

These routes are experimental and opt-in. Engineering evidence includes a 12-record fixture and one later centered replay of the saved N=80 profile fixture; that replay formed all five profile intervals in 68.54 seconds (receipt: `.unlazy/arc1-gaussian-reliability/evidence/profile80-centered-replay/receipt.json`). An earlier replay of that N=80 fixture formed four targets and refused residual variance as nuisance-unresolved; the later result resolves that one fixture-level refusal only. No Arc1 selection-reliability study, coverage study, or confirmation campaign has run. Three retained strong-association engineering datasets at 80, 160 and 320 offspring selected K1 from ordinary starts on Totoro. These are implementation witnesses, not a selection-rate or reliability study. Profile refusal, bootstrap failures, and disconnected profile segments must remain visible in the returned results. Do not report the Arc1 methods as reliable, calibrated, production-ready, generally supported FA syntax, or part of the default path. No capability has been promoted and `public_covered_count` remains seven.

A later engineering check across null, weak and strong association formed only 6 of 16 B=19 bootstrap intervals. There were 21 failed inner selectors among 304 fixed attempts. These small, inspected engineering examples do not estimate population coverage, but their failures prevent a reliability claim. Astra v9 accepted the retained v1 centered-profile source repair; its saved N=80 replay is evidence for one fixed fixture under that recorded source only. The FA covariance-representation decision remains pending. Earlier component and live-parity checks apply to their recorded source versions; current-source selection reliability and interval coverage/calibration remain outstanding.

The Arc1 G0-G8 gates and study evidence are tracked in the [lane checkpoint](../../LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md). Component tests and formed intervals on engineering fixtures do not establish the scientific gates.

The later six-case v1 engineering run formed 28 of 30 target intervals. N=160 near-zero additive variance left residual variance unresolved; N=320 near-zero additive variance left permanent-environment variance unresolved. These retained refusals motivated the explicit bounded `arc1_profile_v2` refinement contract. The revision keeps the v1 default and requires a separate method request, source review, fresh tests and replay. Its implementation is not yet accepted and no v2 reliability or coverage result is available.
