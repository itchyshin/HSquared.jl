# 2026-06-27 — Small-sample interval calibration debt + smoke harness

- Added `V1-HERIT-TCAL` to `docs/design/validation-debt-register.md` as a planned
  validation debt row for small-sample t-calibration of Gaussian variance-component
  and h² intervals.
- Added `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-plan.md`
  as the ADEMP checkpoint for a future coverage study.
- Added `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-df-and-grid.md`
  as the pre-implementation df-probe and named-grid checkpoint. It records the
  residual-df probe, the half-sib family-df probe, and the tiny/small/medium
  triage grid without endorsing either df as a production rule.
- Added `docs/dev-log/scout/2026-06-27-freqtls-t-calibration-transfer.md`
  after inspecting the local `freqTLS` folder. The transferable precedent is the
  Bates-Watts cutoff form plus the coverage-evidence standard; the non-transferable
  piece is `n_obs - length(par)` because HSquared.jl integrates BLUPs.
- Added `docs/dev-log/scout/2026-06-27-notebooklm-sw-mixed-model-calibration.md`
  after querying the NotebookLM algorithm notebook. The update separates fixed-effect
  Satterthwaite/Kenward-Roger denominator-df machinery from variance-component
  Satterthwaite-style scaled-chi-square candidates.
- Added `sim/phase1_small_sample_interval_calibration.jl`, an opt-in Gaussian
  coverage smoke harness comparing current z/delta, profile-LRT, bootstrap, and
  explicitly labelled t-probe intervals. The harness now accepts named half-sib
  designs via `--designs=label:nsire:ndam:noffspring`. It also includes a
  prototype-only `sigma_a2_satterthwaite_chisq_probe` using moment-matched
  scaled-chi-square intervals with a low-df failure guard. These are simulation
  labels only; they are not public interval methods.
- Recorded a smoke-only output table at
  `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
  from `reps=2`, `n_boot=3`, seed `20260627`, design `default`, pedigree `n=36`,
  residual df `33`, family-proxy df `9`. This table checks shape and wiring only.
  It is not coverage calibration evidence.
- Claim boundary: documentation/status debt only. The current implementation remains
  asymptotic: delta/Wald intervals use `_standard_normal_quantile`, and profile-LRT
  intervals use a chi-square-one cutoff via `q = z * z`. No `qt`/degrees-of-freedom
  path, no API change, no default change, no `validation_status()` row, no R-facing
  wording, no interval-method implementation, and no covered promotion.
- Required evidence now named before interval-method implementation: choose a defensible animal-model
  degrees-of-freedom target (not naive `n - p`, because BLUPs are integrated out);
  add only an explicit prototype/method label; test quantile/df dispatch and returned
  labels; run a predeclared small-sample coverage simulation comparing delta, profile,
  bootstrap, and t-calibrated intervals; record seeds/versions/coverage/MCSE; and pass
  Fisher + Curie + Rose review.
- Checks:
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=1 --bootstrap=false --out=/tmp/hsq_tcal_smoke.tsv`
    -> passed after correcting the harness to use the existing `fit.variance_components`
    and bootstrap result-shape fields.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=2 --nboot=3 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
    -> passed; wrote 10 summary rows (`h2` and `sigma_a2` x five methods), then
    was refreshed after the named-design schema was added.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=1 --bootstrap=false --designs=tiny:2:4:8,small:4:8:24 --h2=0.1,0.4 --levels=0.9,0.95 --out=/tmp/hsq_tcal_grid_smoke.tsv`
    -> passed; wrote the multi-design smoke table with design metadata (`tiny`
    pedigree `n=14`, residual df `11`, family df `3`; `small` pedigree `n=36`,
    residual df `33`, family df `9`). Some toy-design non-convergence is reported
    through `fit_success` and is expected at this scale.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=2 --nboot=3 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
    -> passed again after the named-design schema update; committed smoke TSV now
    includes `design`, `n_animals`, `residual_df`, and `family_df` columns.
  - Local freqTLS scout:
    `docs/dev-log/after-task/2026-06-24-freqtls-phase-5-calibration.md`,
    `R/utils.R`, `R/profile.R`, `data-raw/calibration-study.R`, and
    `tests/testthat/test-calibration.R` were inspected. Result: t cutoff form
    and evidence pattern are relevant; `n_obs - length(par)` is not adopted.
  - NotebookLM algorithm scout:
    `notebooklm auth check --test --json` -> authenticated (`token_fetch=true`);
    `notebooklm list --json` -> selected notebook
    `3b3d2ec5-7779-41ee-b968-22623c80278b`; NotebookLM query returned the key
    split that KR/Satterthwaite are mainly fixed-effect DDF tools, while
    variance-component calibration should consider Satterthwaite-style scaled
    chi-square moment matching, profile likelihood, and bootstrap.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=1 --bootstrap=false --designs=tiny:2:4:8 --h2=0.4 --levels=0.95 --out=/tmp/hsq_sw_probe_smoke.tsv`
    -> first exposed a near-infinite SW interval when moment-matched df was too
    small; after adding `df_eff < 2` as a failed-interval guard, passed with the
    SW probe reporting `interval_success=0` for that unstable toy fit.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=2 --nboot=3 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
    -> passed after adding `sigma_a2_satterthwaite_chisq_probe`; committed smoke
    TSV now has 11 rows.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=200 --bootstrap=false --designs=tiny:4:8:24,small:8:16:96,medium:16:32:192 --h2=0.1,0.4,0.7 --levels=0.9,0.95 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage.tsv`
    -> passed; wrote 162 summary rows. Result: residual/family t probes are
    baselines, not clear winners; the scaled-chi-square SW probe is unstable in
    low-h2 small designs (for example, tiny h2=0.1 at 95%: 31 successful intervals
    out of 110 successful fits, conditional coverage 0.226, mean width 6.994);
    medium h2=0.4/0.7 behaves better but wider than profile-LRT.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. -e 'using Pkg; Pkg.test()'`
    -> passed.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. -e 'using HSquared; rows = validation_status(); println("rows=", length(rows)); println("planned=", count(r -> string(getproperty(r, :status)) == "planned", rows));'`
    -> `rows=48`, `planned=1`.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=. -e 'using HSquared; rows=validation_status(); println("rows=", length(rows)); println("planned=", count(r -> getproperty(r, :status) == "planned", rows)); println("covered=", count(r -> getproperty(r, :status) == "covered", rows));'`
    -> `rows=48`, `planned=1`, `covered=5`.
  - `PATH="$HOME/.juliaup/bin:$PATH" HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" NOT_CRAN=true julia --project=docs docs/make.jl`
    -> passed; retained existing Documenter docstring-list warnings and npm audit
    warnings, Vitepress build complete.
  - `git diff --check` -> passed.
  - `rg -n "V1-HERIT-TCAL|small-sample t-calibration|t-calibrated intervals" docs/design/validation-debt-register.md`
    -> found the new row.
- Rose pre-public audit:
  - Read `README.md`, `ROADMAP.md`, `docs/design/06-public-claims-register.md`,
    `docs/design/capability-status.md`, and `docs/design/validation-debt-register.md`;
    `DESCRIPTION` is not present in this Julia repo, so that R-package checklist item
    is not applicable.
  - Ran Rose overclaim greps for `fits|estimates|fast|ASReml-level|implemented|supports|Julia speed`
    and targeted interval-calibration wording. Existing hits are fenced as experimental,
    planned, not-default, or not coverage-calibrated; the new `V1-HERIT-TCAL` text says
    planned + smoke-only and explicitly blocks public/R-facing claims.
  - Verdict: clean-with-limitations. Limitation is the deliberate one: the committed
    `reps=2` smoke TSV and the multi-design smoke command are wiring evidence only,
    not calibration evidence.
