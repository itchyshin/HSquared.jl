# Small-sample interval calibration triage summary

Date: 2026-06-27

Input:
`docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage.tsv`

Command:

```sh
julia --project=. sim/phase1_small_sample_interval_calibration.jl \
  --reps=200 \
  --bootstrap=false \
  --designs=tiny:4:8:24,small:8:16:96,medium:16:32:192 \
  --h2=0.1,0.4,0.7 \
  --levels=0.9,0.95 \
  --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage.tsv
```

Status: triage evidence only. This is not promotion-grade coverage evidence and
does not change any interval implementation, default, R surface, or public claim.

## Grid

- Replicates: 200 per design x truth cell.
- Designs:
  - `tiny`: 36 animals, residual df probe 33, family df probe 9.
  - `small`: 120 animals, residual df probe 117, family df probe 21.
  - `medium`: 240 animals, residual df probe 237, family df probe 45.
- Truths: `h2 = 0.1, 0.4, 0.7`.
- Levels: `0.90`, `0.95`.
- Bootstrap: off for this run.

Coverage in the TSV is conditional on `interval_success`; failed fits and failed
intervals are separately reported through `fit_success` and `interval_success`.

## Fit Success

Fit success was weakest at low heritability:

| Design | h2 | Fit success |
| --- | ---: | ---: |
| `tiny` | 0.1 | 110 / 200 |
| `tiny` | 0.4 | 163 / 200 |
| `tiny` | 0.7 | 176 / 200 |
| `small` | 0.1 | 167 / 200 |
| `small` | 0.4 | 198 / 200 |
| `small` | 0.7 | 197 / 200 |
| `medium` | 0.1 | 178 / 200 |
| `medium` | 0.4 | 200 / 200 |
| `medium` | 0.7 | 200 / 200 |

This means low-h2 small-sample interval coverage must be read together with the
non-convergence rate. A method that only covers after dropping many fits is not
ready.

## h2 Read

The t probes do not provide a clean win over the current z/logit-delta and
profile paths. They mostly widen the delta interval and sometimes over-cover in
tiny designs. Profile intervals are often competitive or narrower, with no
evidence here that a residual-df or family-df t multiplier is the right animal
model correction.

Examples at 95%:

| Design | h2 | `h2_delta_z` | `h2_delta_t_family_df_probe` | `h2_profile_chisq` |
| --- | ---: | ---: | ---: | ---: |
| `tiny` | 0.1 | 0.927 | 0.982 | 0.973 |
| `small` | 0.4 | 0.965 | 0.975 | 0.955 |
| `medium` | 0.7 | 0.950 | 0.960 | 0.950 |

Conclusion: keep h2 t-calibration exploratory. The bounded-ratio target needs a
better derivation or a stronger simulation win before implementation.

## sigma_a2 Read

The Satterthwaite scaled-chi-square probe is useful diagnostically but unstable
as currently defined. It has a low-df guard (`df_eff < 2` -> interval failure).
Even after that guard, low-h2 cells have many failed probe intervals and poor
conditional coverage.

Selected 95% `sigma_a2` cells:

| Design | h2 | Method | Interval success | Coverage | Mean width |
| --- | ---: | --- | ---: | ---: | ---: |
| `tiny` | 0.1 | `sigma_a2_delta_z` | 110 | 1.000 | 0.943 |
| `tiny` | 0.1 | `sigma_a2_profile_chisq` | 110 | 0.982 | 1.464 |
| `tiny` | 0.1 | `sigma_a2_satterthwaite_chisq_probe` | 31 | 0.226 | 6.994 |
| `small` | 0.4 | `sigma_a2_delta_z` | 198 | 0.904 | 0.774 |
| `small` | 0.4 | `sigma_a2_profile_chisq` | 198 | 0.955 | 0.873 |
| `small` | 0.4 | `sigma_a2_satterthwaite_chisq_probe` | 188 | 0.910 | 1.640 |
| `medium` | 0.4 | `sigma_a2_delta_z` | 200 | 0.915 | 0.552 |
| `medium` | 0.4 | `sigma_a2_profile_chisq` | 200 | 0.940 | 0.578 |
| `medium` | 0.4 | `sigma_a2_satterthwaite_chisq_probe` | 199 | 0.955 | 0.769 |
| `medium` | 0.7 | `sigma_a2_delta_z` | 200 | 0.925 | 0.647 |
| `medium` | 0.7 | `sigma_a2_profile_chisq` | 200 | 0.955 | 0.653 |
| `medium` | 0.7 | `sigma_a2_satterthwaite_chisq_probe` | 200 | 0.975 | 0.735 |

Conclusion: the scaled-chi-square probe can approach nominal coverage in some
medium/high-information cells, but it is too unstable and too wide in the cells
where small-sample calibration matters most. It should not be promoted. If this
lane continues, the next step is to refine the moment-matching target and
boundary/failure rule, not expose a method.

## Decision

No interval method is promoted.

Recommended next steps:

1. Keep profile-LRT and bootstrap as the main finite-sample interval families.
2. Treat residual/family t probes as baselines only.
3. Treat the current Satterthwaite scaled-chi-square probe as a diagnostic
   negative/partial result.
4. Before any larger run, make the harness resumable by writing per-cell output.
5. If continuing SW, derive a better effective-df target for `sigma_a2` and only
   then rerun the grid.
