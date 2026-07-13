# v0.7 genomic recovery-v2 precision blocker

- Totoro pilot: 432/432 successful and converged; no dropped/replaced seeds.
- Driver R and independent base R summaries: byte-identical.
- Independent Julia summary: maximum absolute numeric difference `3.33e-16`
  versus driver R; zero fields outside `1e-10`.
- Campaign result: `PRECISION_BLOCKER`; five cells above the frozen 2,000-fit
  ceiling; maximum required N 16,325.
- No adjudication receipt and no confirmation manifest; offsets 7101:7148
  retired.
- Recomputer self-test: green, including retired-offset mutation.
- Full `Pkg.test()`: green.
- Documenter/Vitepress build: green; existing missing-docstring and npm audit
  warnings remain non-blocking and unrelated.
- `bash tools/preamble_cap.sh`: green.
- `git diff --check`: green.
- No capability row, count, G10, merge, or release change.

## Exact commands

The sealed Totoro campaign used these canonical paths and launcher stages:

```sh
ROOT=/home/snakagaw/hsq_work/v07-genomic-recovery-v2-offset7101
DRIVER=/home/snakagaw/hsq_work/hsquared-v07-recovery-v2-driver
RUNTIME=/home/snakagaw/hsq_work/hsquared-v07-recovery-v2-runtime
JULIA=/home/snakagaw/hsq_work/HSquared-v07-recovery-v2
LAUNCHER="$DRIVER/tools/run-v07-genomic-recovery-v2.sh"

"$LAUNCHER" pilot-manifest "$ROOT" "$DRIVER" "$RUNTIME" "$JULIA"
"$LAUNCHER" run-tier "$ROOT" "$DRIVER" "$RUNTIME" "$JULIA" pilot 16
"$LAUNCHER" summarize "$ROOT" "$DRIVER" "$RUNTIME" "$JULIA" pilot
"$LAUNCHER" recompute-base-r "$ROOT" "$DRIVER" "$RUNTIME" "$JULIA" pilot
"$LAUNCHER" recompute-julia "$ROOT" "$DRIVER" "$RUNTIME" "$JULIA" pilot
"$LAUNCHER" adjudicate "$ROOT" "$DRIVER" "$RUNTIME" "$JULIA" pilot
```

The final command failed closed before writing
`pilot_adjudication_receipt.tsv`; therefore `confirmation-manifest` and
`run-tier ... confirm` were not run. Local successor-tooling verification used:

```sh
~/.juliaup/bin/julia --project=. sim/phase2_v07_genomic_recovery_v2_recompute.jl --mode=selftest
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
~/.juliaup/bin/julia --project=docs docs/make.jl
bash tools/preamble_cap.sh
git diff --check
```
