# After-task — small-sample interval calibration debt + smoke harness — 2026-06-27

## Task goal

Bank the small-sample t-calibration finding as repo-visible validation debt, then add the
small follow-up scaffold: an ADEMP simulation checkpoint and an opt-in Gaussian coverage
smoke harness. No new interval method, public default, R surface, or covered claim is
introduced.

## Active lenses and spawned agents

Active lenses: Fisher, Curie, Rose, Grace.

Spawned agents: none.

## Live phase snapshot

HSquared.jl `main` is at `5f378a8d` locally, with `origin/main` aligned at pickup.
The R twin `hsquared` was checked at `8c5c886` during rehydrate. Public-default covered
surface remains the v0.1 univariate Gaussian model only. This slice does not change
covered status, engine behavior, or the R surface.

## Files changed

- `docs/design/validation-debt-register.md`
- `docs/dev-log/check-log.d/2026-06-27-small-sample-interval-calibration-debt.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-06-27-small-sample-interval-calibration-debt.md`
- `docs/dev-log/scout/2026-06-27-freqtls-t-calibration-transfer.md`
- `docs/dev-log/scout/2026-06-27-notebooklm-sw-mixed-model-calibration.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-plan.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-df-and-grid.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage-summary.md`
- `sim/phase1_small_sample_interval_calibration.jl`

## What changed

Added planned row `V1-HERIT-TCAL` after `V1-HERIT-CI`. The row records:

- current Gaussian interval helpers are asymptotic;
- delta/Wald paths use normal-z from `_standard_normal_quantile`;
- profile-LRT paths use a chi-square-one cutoff through `q = z * z`;
- no design-based degrees-of-freedom or `qt` path exists;
- the C6 parametric bootstrap is finite-sample-aware but still opt-in and not
  coverage-calibrated.

Added the ADEMP checkpoint for a future coverage study, including aims, DGP, estimands,
methods, performance measures, and a Williams-style reporting self-audit. Added an opt-in
simulation harness that compares current z/delta, profile-LRT, bootstrap percentile, and
explicitly labelled t-probe intervals for `h2` and `sigma_a2`.

Extended the harness to accept named half-sib designs with
`--designs=label:nsire:ndam:noffspring`, emit the design label and df probes in the
summary table, and group coverage summaries by design. Added a separate df/grid
checkpoint recording the two current t probes (`residual_df_probe` and
`family_df_probe`) plus the predeclared tiny/small/medium triage grid. Neither probe is
endorsed as an animal-model df rule.

Inspected the local `freqTLS` folder because its t-calibration path is relevant.
The transferable precedent is the Bates-Watts cutoff form (`qt(df)` for Wald,
`qt(df)^2` for profile) plus a coverage simulation before making a calibration
claim. The non-transferable piece is its df rule (`n_obs - length(par)`), because
freqTLS itself flags that this can overstate df for random-effects fits.

Queried the NotebookLM algorithm notebook for SW/Satterthwaite/Kenward-Roger
guidance. The design consequence is sharper: KR/Satterthwaite denominator-df
corrections mainly target fixed-effect inference; for variance components the
serious candidate is Satterthwaite-style scaled-chi-square moment matching, with
profile likelihood and bootstrap still treated as the stronger interval families.

Added `sigma_a2_satterthwaite_chisq_probe` to the harness. It moment-matches the
additive-variance estimate to a scaled chi-square reference with
`df_eff = 2 * estimate^2 / SE^2`, uses the package's internal chi-square survival
function plus local bisection for quantiles, and treats `df_eff < 2` as a failed
probe interval.

The committed smoke TSV is intentionally tiny (`reps=2`, `n_boot=3`). It proves the harness
is wired and produces the expected method rows; it is not calibration evidence.

The 200-replicate no-bootstrap triage grid is also not promotion evidence, but it
is useful directionally. It found no clear h2 win for the residual/family t probes.
For `sigma_a2`, the SW scaled-chi-square probe behaved poorly in low-h2 small
designs and was often much wider than profile-LRT. It is not ready to become an
interval method.

## Checks run and exact outcomes

- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. -e 'using HSquared; rows = validation_status(); println("rows=", length(rows)); println("planned=", count(r -> string(getproperty(r, :status)) == "planned", rows));'`
  → `rows=48`, `planned=1`.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=1 --bootstrap=false --out=/tmp/hsq_tcal_smoke.tsv`
  → passed after correcting result-shape assumptions in the harness.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=2 --nboot=3 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
  → passed; wrote 10 summary rows (`h2` and `sigma_a2` x five methods), seed `20260627`,
  pedigree `n=36`, residual df `33`, family-proxy df `9`; refreshed after the named-design
  schema update.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=1 --bootstrap=false --designs=tiny:2:4:8,small:4:8:24 --h2=0.1,0.4 --levels=0.9,0.95 --out=/tmp/hsq_tcal_grid_smoke.tsv`
  → passed; exercised multi-design grouping and emitted design metadata (`tiny`
  pedigree `n=14`, residual df `11`, family df `3`; `small` pedigree `n=36`,
  residual df `33`, family df `9`).
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=2 --nboot=3 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
  → passed after the named-design schema update; committed smoke TSV now includes
  `design`, `n_animals`, `residual_df`, and `family_df` columns.
- Local freqTLS scout:
  inspected `docs/dev-log/after-task/2026-06-24-freqtls-phase-5-calibration.md`,
  `R/utils.R`, `R/profile.R`, `data-raw/calibration-study.R`, and
  `tests/testthat/test-calibration.R` in `/Users/z3437171/Dropbox/Github Local/freqTLS`.
  Result: useful precedent for cutoff form and evidence standard; no df rule imported.
- NotebookLM algorithm scout:
  `notebooklm auth check --test --json` authenticated successfully; `notebooklm list --json`
  identified notebook `3b3d2ec5-7779-41ee-b968-22623c80278b`; `notebooklm ask --json`
  returned the fixed-effect versus variance-component split recorded in the scout note.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=1 --bootstrap=false --designs=tiny:2:4:8 --h2=0.4 --levels=0.95 --out=/tmp/hsq_sw_probe_smoke.tsv`
  → passed after adding the `df_eff < 2` failure guard for the SW probe.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=2 --nboot=3 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
  → passed after adding `sigma_a2_satterthwaite_chisq_probe`; committed smoke TSV now has 11 rows.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=200 --bootstrap=false --designs=tiny:4:8:24,small:8:16:96,medium:16:32:192 --h2=0.1,0.4,0.7 --levels=0.9,0.95 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage.tsv`
  → passed; wrote 162 summary rows. Summary recorded in
  `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage-summary.md`.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. -e 'using Pkg; Pkg.test()'`
  → passed.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=docs docs/make.jl`
  → passed; Vitepress build complete. Existing Documenter docstring-list warnings and npm
  audit warnings remain.
- `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. -e 'using HSquared; rows=validation_status(); println("rows=", length(rows)); println("planned=", count(r -> getproperty(r, :status) == "planned", rows)); println("covered=", count(r -> getproperty(r, :status) == "covered", rows));'`
  → `rows=48`, `planned=1`, `covered=5`.
- `git diff --check` → passed.
- `rg -n "V1-HERIT-TCAL|small-sample t-calibration|t-calibrated intervals" docs/design/validation-debt-register.md`
  → found the new row.

## Public claim audit

Clean. This is debt plus harness scaffolding, not evidence. It does not say t-calibrated
intervals exist, does not change `validation_status()`, does not add a capability-status row,
and does not promote any interval method. The row explicitly blocks interval-method
implementation or R-facing wording until the df target and coverage simulation are recorded.

Rose pre-public audit verdict: clean-with-limitations. I read `README.md`, `ROADMAP.md`,
`docs/design/06-public-claims-register.md`, `docs/design/capability-status.md`, and
`docs/design/validation-debt-register.md`; `DESCRIPTION` is not present in this Julia repo.
The Rose overclaim grep found existing long-ledger hits for "fits", "estimates",
"implemented", and "fast", but the nearby wording remains fenced as experimental, planned,
not-default, or not coverage-calibrated. New t-calibration wording is planned + smoke-only;
the named-grid text says the df formulas are probes, not production rules. The new SW wording
is also explicitly prototype-only and records the negative/unstable triage result.

## Tests of the tests

The live `validation_status()` check guards against accidental Julia diagnostic-row churn.
The harness smoke tests cover both non-bootstrap and bootstrap paths at toy scale. Full
`Pkg.test()` guards package behavior, while `docs/make.jl` confirms the docs still render.

## Coordination notes

No R files changed. If this becomes an R-facing method later, the R twin must get matching
wording and tests only after the Julia estimator/coverage evidence exists.

## What did not go smoothly

Nothing material. The local R dev stack is not installed in this desktop session, but no R
package work was required.

## Known limitations

The hard part is still unresolved: the degrees of freedom are not `n - p` for an animal
model because random effects are integrated out. The current t probes are labelled
comparators, not endorsed df choices. A design-based or simulation-calibrated effective df
must be chosen before interval-method code.

## Next actions

1. Make the harness resumable with per-cell output before larger runs.
2. If continuing SW, derive a better effective-df target and boundary/failure rule for `sigma_a2`.
3. Add bootstrap to a smaller, targeted subset only after the non-bootstrap candidates are narrowed.
4. Only then add a prototype-only interval method behind an explicit label, followed by Rose before any public or R-facing wording.
