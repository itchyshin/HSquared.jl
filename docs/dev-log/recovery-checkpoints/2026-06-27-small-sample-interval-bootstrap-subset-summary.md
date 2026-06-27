# Small-sample interval calibration bootstrap subset summary

Date: 2026-06-27

Status: focused bootstrap-path triage after the resumable harness refactor. This
is not promotion-grade coverage evidence and does not change any interval
implementation, default, R surface, or public claim.

## Command

```sh
PATH="$HOME/.juliaup/bin:$PATH" \
HSQUARED_JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/HSquared.jl" \
NOT_CRAN=true \
julia --project=. sim/phase1_small_sample_interval_calibration.jl \
  --reps=10 \
  --nboot=9 \
  --resume=false \
  --designs=small:8:16:96,medium:16:32:192 \
  --h2=0.4,0.7 \
  --levels=0.95 \
  --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset.tsv
```

Output:

- Summary TSV:
  `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset.tsv`
- Replicate/detail TSV:
  `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset-replicates.tsv`

The same command with `--resume=true` was rerun and left the detail file at 441
lines, confirming completed replicate/method rows were reused rather than
duplicated.

## Grid

- Replicates: 10 per design x truth cell.
- Bootstrap samples: 9 per converged fitted replicate.
- Designs:
  - `small`: 120 animals, residual df probe 117, family df probe 21.
  - `medium`: 240 animals, residual df probe 237, family df probe 45.
- Truths: `h2 = 0.4, 0.7`.
- Level: `0.95`.

This grid is deliberately small. At 10 interval-successful replicates, nominal
95% coverage MCSE is about 6.9 percentage points, so apparent coverage
differences are not interpretable as calibration.

## Read

All cells had 10/10 converged fits and 10/10 successful bootstrap intervals.
There were no detail-row boundary flags or interval-failure reasons in this
subset.

Selected 95% rows:

| Target | Design | h2 | Method | Coverage | Mean width |
| --- | --- | ---: | --- | ---: | ---: |
| h2 | small | 0.4 | `h2_bootstrap_percentile` | 0.700 | 0.515 |
| h2 | small | 0.4 | `h2_profile_chisq` | 1.000 | 0.622 |
| h2 | medium | 0.4 | `h2_bootstrap_percentile` | 0.700 | 0.312 |
| h2 | medium | 0.4 | `h2_profile_chisq` | 0.900 | 0.466 |
| sigma_a2 | small | 0.4 | `sigma_a2_bootstrap_percentile` | 0.800 | 0.746 |
| sigma_a2 | small | 0.4 | `sigma_a2_profile_chisq` | 0.900 | 1.022 |
| sigma_a2 | medium | 0.7 | `sigma_a2_bootstrap_percentile` | 0.800 | 0.534 |
| sigma_a2 | medium | 0.7 | `sigma_a2_profile_chisq` | 1.000 | 0.666 |

The `sigma_a2_satterthwaite_chisq_probe` detail rows had effective df in this
subset ranging from about 3.82 to 58.59, with mean about 20.39. That is a useful
diagnostic, but the earlier 200-rep no-bootstrap triage still found the probe
unstable in low-h2 small designs.

## DRAC note

SSH aliases were reachable for `vulcan`, `trillium`, `rorqual`, `nibi`, `narval`,
and `fir`; `mibi` did not resolve and appears to be a typo for `nibi`. No
existing `HSquared.jl` checkout was found by a shallow search under
`/project/aip-snakagaw`, `/project/def-snakagaw`, or `/home/snakagaw` on
Vulcan/Fir. No compute was run on a login node. A larger DRAC run should first
stage or clone the repo on `/project`, then submit through SLURM.

## Decision

Keep bootstrap as the finite-sample-aware reference path, but do not treat this
subset as calibration evidence. The next credible bootstrap run needs DRAC
setup, a predeclared grid, and at least hundreds of replicates per cell.
