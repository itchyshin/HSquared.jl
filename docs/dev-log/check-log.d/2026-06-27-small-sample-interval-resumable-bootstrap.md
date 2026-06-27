# 2026-06-27 — Small-sample interval harness resumability + bootstrap subset

- Refactored `sim/phase1_small_sample_interval_calibration.jl` so every run now
  writes a replicate-level detail TSV as well as the summary TSV.
- Added `--detail-out=PATH` and `--resume=true|false`.
- Replicate seeds are now deterministic by `(master seed, design index, h2 index,
  replicate)`, so skipping completed rows does not change later simulated data.
- Detail rows include diagnostics: cell id, seed, replicate, fit status,
  near-boundary flag, interval failure reason, interval bounds/width, `h2_hat`,
  `sigma_a2_hat`, `sigma_e2_hat`, `vc_se`, Satterthwaite `df_eff`, `n_boot`,
  and bootstrap convergence count.
- Summary output now includes `n_boot` so bootstrap rows with different
  resampling depths cannot be silently merged.
- Refreshed the smoke output:
  - `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
  - `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke-replicates.tsv`
- Added focused bootstrap subset outputs:
  - `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset.tsv`
  - `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset-replicates.tsv`
  - `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-bootstrap-subset-summary.md`
- Added decision checkpoint:
  - `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-decision.md`

## Checks

- Non-bootstrap resume smoke:
  - `julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=1 --bootstrap=false --designs=tiny:2:4:8 --h2=0.4 --levels=0.95 --out=/tmp/hsq_tcal_resume_summary.tsv --detail-out=/tmp/hsq_tcal_resume_detail.tsv --resume=false`
    -> passed; wrote one header plus 9 method rows.
  - Same command with `--resume=true`
    -> passed; detail file remained at 10 lines, confirming skip/no duplicate append.
- Refreshed committed smoke:
  - `julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=2 --nboot=3 --resume=false --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
    -> passed; summary has 11 method rows plus header; detail file has 22 method rows plus header.
  - Same command with `--resume=true`
    -> passed; detail file remained at 23 lines.
- Focused bootstrap subset:
  - `julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=10 --nboot=9 --resume=false --designs=small:8:16:96,medium:16:32:192 --h2=0.4,0.7 --levels=0.95 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset.tsv`
    -> passed; summary has 44 method rows plus header; detail file has 440 method rows plus header.
  - Same command with `--resume=true`
    -> passed; detail file remained at 441 lines.
- DRAC access probe:
  - `vulcan`, `trillium`, `rorqual`, `nibi`, `narval`, and `fir` SSH aliases responded.
  - `mibi` did not resolve.
  - Shallow Vulcan/Fir searches found no existing `HSquared.jl` checkout under the checked project/home roots.
  - No compute was run on a login node.
- `git diff --check` -> passed.
- `julia --project=. -e 'using HSquared; rows=validation_status(); println("rows=", length(rows)); println("planned=", count(r -> getproperty(r, :status) == "planned", rows)); println("covered=", count(r -> getproperty(r, :status) == "covered", rows));'`
  -> `rows=48`, `planned=1`, `covered=5`.
- `julia --project=. -e 'using Pkg; Pkg.test()'`
  -> passed; retained the existing stale-manifest warning recommending `Pkg.resolve()`.
- `julia --project=docs docs/make.jl`
  -> passed; retained existing Documenter docstring-list warnings and npm audit warnings.
- Rose targeted scan for t-calibration / Satterthwaite / promotion wording:
  -> clean-with-limitations; hits are fenced as "do not expose", "triage only",
  "not promotion-grade", or "no public/R-facing claim".

## Claim audit

Clean-with-limitations. This is harness and triage evidence only. It does not
implement an interval method, change defaults, update `validation_status()`, or
add R-facing wording. The bootstrap subset is too small for calibration claims.
