# Arc1 documentation and integration gap audit

Scope: documentation only. The protected Dropbox `hsquared` checkout was not opened; R help and API were inspected in `/private/tmp/hsquared-auto-fa-r-20261001`.

## Status boundary

The lane checkpoint is the active evidence source. At its latest retained checkpoint, engineering assertions and one profile-formation fixture passed, but no Arc1 study or campaign had run, all original Arc1 gates remained unmet, and no coverage calibration, reliability, promotion, default activation, publication, or release claim was supported. The one profile fixture's five formed intervals are computational formation evidence only. `LOOP/lanes/arc1-gaussian-reliability-20261002/GOAL.md` likewise says seed-manifest validation and studies remain outstanding.

Keep Arc1 distinct from the earlier automatic-FA-rank implementation programme. The earlier programme's completed eight-gate receipt and the capability row for bounded mechanics describe selector implementation and transport. They do not establish Arc1's G0-G8 reliability programme. The current `docs/design/auto-fa-rank-experimental-usage.md` correctly says automatic selection reliability and ordinary optimizer-driven K1 selection are untested. Its status is not a substitute for Arc1 status.

## Narrow documentation work for the Arc1 G7 documentation gate

1. `docs/design/arc1-gaussian-reliability-20261002.md`, opening status and the implementation-state paragraphs under “Frozen model and algorithm” and “Execution sequence and acceptance”. Its opening “S0 planning and freeze are in progress” is an initial-state snapshot, while later sections contain decisions approved on 2026-10-02. Label the initial-state wording as historical or replace it with a current-status pointer to the lane checkpoint. The checkpoint records component engineering evidence, but all Arc1 acceptance gates remain unmet. Reconcile each G0-G8 state from the gate ledger and retained receipts; do not infer gate completion from component assertions or rewrite the frozen scientific protocol.

2. `docs/design/capability-status.md`, row “Automatic genetic FA factor-count comparison, T4 K0/K1” (line 116), and row “factor-analytic G matrices” (line 55). These existing rows are appropriately experimental and preserve covered count seven. Keep their evidence scoped to their respective claims. If the Arc1 implementation adds a new usable expert policy/profile/bootstrap surface, add only a short cross-reference or update the evidence boundary to say that the new controls are opt-in and the Arc1 study/calibration remains open. Do not replace the separate earlier eight-gate receipt with Arc1 status, or imply that a formed profile is calibrated.

3. `docs/design/validation-debt-register.md`, row “factor-analytic G matrix” (line 47), and a new narrowly scoped debt row for Arc1 model-selection reliability and interval calibration. The existing FA debt already keeps the broad fitted-covariance claim partial. Extend it only to distinguish engineering formation from still-unrun Arc1 evidence: ordinary selected-K1 behaviour, selection reliability, selection-adjusted h2 interval coverage, the five repeatability targets' coverage, and the frozen study/admission gates. Preserve the requirement that the public covered count stays seven. Avoid calling a blocked or refused profile target a formed interval.

4. `docs/design/auto-fa-rank-experimental-usage.md`, “R” example and “Reading the result”. Its current example requests `rank_selection = "auto"` without the separately approved `optimizer_policy = "arc1_v1"`. Add the explicit policy to the expert example, explain that omitting it leaves the existing optimizer route in place, and note that the policy freezes 2,000 iterations per start and rejects an `iterations` override. Keep its current ordinary-K1 and calibration limits. Add a link from the README's experimental capability list to this note only if the README edit remains a small index entry.

5. R user help in the isolated checkout: `R/hs_control.R` and generated `man/hs_control.Rd`, under the multivariate target description; `R/arc1-uncertainty.R` and generated `man/arc1_uncertainty.Rd`; and `R/extractors.R` plus generated help for `confint.hsquared_fit` / `confint.hsquared_fa_rank_selection`. `hs_control` already documents the selector control and exact seed representation, while `arc1_uncertainty` says formation does not establish calibration. Add the profile's actual restrictions and target names, the bootstrap's whole-selector reselection and fixed-seed/B requirements, the exact method names required by `confint()`, and refusal-row behavior. Clarify that `bootstrap_B` is computational budget, not evidence quality, and that a small illustrative B does not support an interval-coverage claim. Keep legacy fields/intervals explicitly unchanged.

6. Julia API docs: `src/fa_rank_selection.jl` docstring for `select_fa_rank` and the new public docstrings in `src/arc1_interfaces.jl` for `arc1_profile_repeatability`, `arc1_confint`, and `arc1_bootstrap`. The latter already state several experimental boundaries. The `select_fa_rank` docstring omits its `optimizer_policy` argument and what the opt-in `arc1_v1` policy means. Add the policy argument, fixed budget, pedigree restriction, and statement that optimizer eligibility is not a reliability result. In the uncertainty docstrings, make sure all five targets and the exact-two-record design restriction are visible, and retain the no-calibration wording. Link these pages from `docs/src` navigation if needed; no API outside the current exported functions is required.

7. `docs/dev-log/check-log.md` and a dated `docs/dev-log/check-log.d/` receipt should record only completed Arc1 gates after their evidence exists. The check log currently contains earlier FA design/implementation entries that say selection reliability is future work; those are historical and should remain intact. Append a new receipt for Arc1, with exact source/test hashes and an explicit statement that no campaign ran and scientific gates remain open until the lane produces stronger evidence. Do not record this audit as a package-check pass.

## Suggested user-facing wording

> Automatic FA rank selection compares a diagonal genetic covariance (K0) with a one-factor genetic covariance (K1) for four complete Gaussian traits measured once per pedigree animal. The comparison is an experimental, opt-in Julia route. To use its bounded optimizer policy, request `optimizer_policy = "arc1_v1"`; the policy uses a fixed 2,000-iteration budget per start and retains failed and unfinished starts in the result. This is not a default or general FA formula feature. Successful optimization does not establish that rank selection is reliable across datasets.

> The experimental `arc1_profile_v1` route profiles additive variance, permanent-environment variance, residual variance, heritability, and repeatability for a univariate Gaussian pedigree repeatability model with exactly two records per observed animal. It uses a fixed 95% likelihood-ratio cutoff. The experimental `arc1_bootstrap_v1` route reruns automatic K0/K1 selection for each supplied bootstrap seed and retains failed attempts. Both routes may refuse an estimand or return missing limits when the search cannot certify an interval. A formed interval is a computation result, not evidence of 95% coverage or calibration. Arc1 study results are not yet available.

## Concrete R API examples for the later paired docs update

These examples use the existing `hsquared()` / `hs_control()` APIs. The selector example follows the live-parity fixture shape; callers supply a validated pedigree (`id`, `sire`, `dam`) and a data frame with one complete record per observed animal. The displayed fields were verified in the R normalizer and controls tests: `selection_status`, `candidate_summary`, and `attempts` belong to the returned `hsquared_fa_rank_selection` object.

```r
selected <- hsquared(
  cbind(t1, t2, t3, t4) ~ animal(1 | id, pedigree = ped),
  data = dat,
  control = hs_control(engine = "julia", engine_control = list(
    target = "multivariate", rank_selection = "auto",
    optimizer_policy = "arc1_v1"
  ))
)
selected$selection_status
selected$candidate_summary
selected$attempts
```

Request bootstrap uncertainty during fitting, with an exact B and distinct decimal seeds in the same control. With B=3, all three replicates must be usable to meet the formation rule, `ceil(0.99 * B) = 3`. A three-replicate example illustrates the API only; it is inadequate for estimating interval endpoints or coverage calibration:

```r
selected_with_bootstrap <- hsquared(
  cbind(t1, t2, t3, t4) ~ animal(1 | id, pedigree = ped),
  data = dat,
  control = hs_control(engine = "julia", engine_control = list(
    target = "multivariate", rank_selection = "auto",
    optimizer_policy = "arc1_v1", uncertainty_method = "arc1_bootstrap_v1",
    bootstrap_B = 3L, bootstrap_seeds = c("101", "102", "103")
  ))
)
arc1_uncertainty(selected_with_bootstrap)
confint(selected_with_bootstrap, method = "arc1_bootstrap_v1")
```

The five-target profile example uses two records per animal and requests its method before extracting the confidence set. The data values are an illustrative example, not a calibrated design:

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
    target = "repeatability", scale_method = "dense",
    uncertainty_method = "arc1_profile_v1"
  ))
)
confint(profile, method = "arc1_profile_v1")
```

Before publishing these examples, run them against the final paired R/Julia source and update `bootstrap_B` to a scientifically meaningful allocated value only when its runtime is measured and study approval allows it. Do not present B=3 as a useful interval budget.

## Review cautions

- `docs/design/auto-fa-rank-experimental-usage.md` is not the Arc1 uncertainty guide. A single Arc1 usage section or linked note should explain the new routes without expanding the generic README into a methods paper.
- `docs/dev-log/check-log.d/2026-10-01-auto-fa-rank-implementation/README.md` and the capability row's “all eight original gates pass” wording concern that earlier automatic-rank programme. Keep that provenance explicit so it cannot be mistaken for Arc1 G0-G8 completion.
- The current Arc1 profile witness formed five intervals on one engineering fixture. That does not test repeated-sampling coverage. No selection-reliability, global-optimum, nominal-coverage, or selection-adjusted interval claim is supported by the checkpoint.
- Documentation leaf completed on 2026-10-02: `README.md`, `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`, `docs/design/auto-fa-rank-experimental-usage.md`, and the new `docs/design/arc1-experimental-usage.md` now distinguish prior mechanics evidence from Arc1's open scientific gates and describe the explicit controls. No source, tests, R package help, or Julia docstrings were changed.
- Remaining G7 work: update paired R source comments/help and generated Rd for `hs_control`, `arc1_uncertainty`, and `confint()` after the live bridge stabilizes; update Julia docstrings for `select_fa_rank`'s `optimizer_policy` and ensure profile/bootstrap restrictions and no-calibration limits are discoverable from Documenter navigation. Recheck any R object-field documentation against the final integrated tree before describing fields publicly. These changes were left to the R integration owner and parent lane.
