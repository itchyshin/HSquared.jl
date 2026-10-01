# Ordinary-start unit and trait-order diagnostic

This scratch harness implements Minimum check 2 in
`/private/tmp/a2-remaining-acceptance-design-20260930.md`. The parent owns the
candidate and integration. No package source, tests, or recovery driver are changed.

The five calls are fixed: baseline, units `(2, 0.5, 1.5, 0.8)`, inverse units,
trait order `(3, 1, 4, 2)`, and reversed order `(4, 3, 2, 1)`. Every call omits
`initial` and caps each of the default and balanced starts at 10,000 iterations.
This cap differs from the primary recovery campaign's 5,000. No replacement seed,
retry, optional mapped start, or population pass cutoff is supplied.

The generator is copied from the frozen test's lines 181–203, seed 20260929,
40 founder animals, five records each, four traits and one factor. Only package
function qualification and the enclosing function were added. The same random
draw order, covariance, means, and record order are retained. The generating
covariance supplies oracle checks and the common comparison metric only.

Before a launch, state and confirm the runtime estimate from existing logs.
The parent estimated at most one hour on Totoro CPU. This is an estimate to be
checked before execution, not a measured runtime. Stop and report an overrun.
This preparation ran no fits or simulations. Launch on the frozen source using
the existing Totoro connection, with at most four Julia threads and one BLAS
thread. Replace the example paths with the corresponding staged paths; output
must not exist:

```sh
HSQ_RUN_ORDINARY_UNIT_ORDER=YES OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 \
  julia --startup-file=no --project=/path/to/frozen/HSquared.jl \
  /path/to/fa_ordinary_unit_order_check.jl \
  /path/to/frozen/HSquared.jl /path/to/new-output-directory
```

The harness refuses an existing output path, a different active project, more
than four Julia threads, or changed source and fixture fingerprints. It checks
the loaded package location and the fixed `1e-4` uniqueness floor. It imports
the package once and never includes the test suite. Only package dependencies
and Julia standard libraries are used.

Git identity is optional provenance for a source-only snapshot. If Git, HEAD,
branch, or status is unavailable, the manifest records `unavailable` and the
metadata-only exception for that field. Git stderr is suppressed. The exact
source-tree and fixture fingerprints remain mandatory.

The parent reported that the first Totoro launch stopped at Git HEAD metadata
before fixture generation or any fit. Its failure log and output are retained.
The repair permits the same five cases to run in a new output directory ending
in `retry1`; this is a launch retry with zero prior fit attempts. No seed, case,
start, cap, or comparison target changed.

At truth and at every finite fitted covariance pair, all five maps check the
exact fixed-covariance REML shift to absolute tolerance `1e-8`. Fixed-covariance
GLS coefficients and breeding values must agree after reverse mapping at
relative and absolute tolerance `1e-9`. Returned likelihood, predictions,
trait labels, animal IDs, genetic covariance reconstruction, and selected-start
status are checked independently of optimizer agreement. These failures, any
nonfinite return, and any named call exception make the final exit code 2.
All five calls remain in the denominator. If the package throws before returning,
both named start rows explicitly say their inner status is unavailable.

Each finite covariance, uniqueness vector, loading matrix, coefficient matrix,
and breeding-value matrix is reverse mapped into the original units and order.
Covariance differences use the single generating trait metric
`diag(sqrt(diag(Gtrue + Rtrue)))`. Comparison targets are corrected likelihood
difference `2e-3`, covariance relative difference `2e-3`, and mapped predictions
with relative `2e-3` plus absolute `1e-5`. Uniqueness and loadings are recorded as
secondary comparisons; loadings receive one global sign alignment. Raw package
start-disagreement norms are retained in the input units in the serialized fit.
Iteration counts and selected-start names may differ.

The interior screen requires uniqueness above `0.01` in the original fit, the
transformed fit, its reverse mapping, and the forward-mapped baseline point.
Cases outside that screen are conservatively marked `floor_constrained`, with
actual floor distances retained. This includes points failing the declared
interior screen even when not flagged near the floor by the package. Optimizer
sensitivity is also recorded as a separate flag, including in floor-constrained
cases. Passing the screen does not prove equality of global feasible sets or a
global optimum. Exact oracle or status failures take precedence as
`correctness_failure`; interior converged agreement is `interior_agreement`;
remaining interior cases are `optimizer_sensitivity`.

Results are written and flushed after each case. `manifest.toml` records all
five maps, source and script hashes, fixture and generator hashes, interpreter,
host, thread settings, array hashes, thresholds, and metric. `fixture.jls` holds
the complete immutable input. `fits.tsv`, `starts.tsv`, `oracles.tsv`, and
`comparisons.tsv` give readable diagnostics. Per-case `.jls` files retain raw
fits, complete G/R/uniqueness, labels, IDs, coefficients, breeding values,
reverse mappings, direct evaluations, and exceptions. `summary.toml` includes
the full denominator and elapsed time. `artifact_hashes.toml` hashes every prior
artifact, excluding itself. Julia Serialization artifacts should be read using
the recorded Julia version and frozen project.

Exit code 0 means the finite diagnostic and its correctness checks completed;
it does not require optimizer agreement. The final status is
`diagnostic_complete`, with `A2_complete=false`. Population reliability,
calibrated intervals, general unit/order robustness, and panel acceptance remain
outside this artifact's claim.

To check syntax without evaluating the script or importing the engine:

```sh
julia --startup-file=no -e 'Meta.parseall(read(ARGS[1], String)); println("syntax parsed; no fits evaluated")' \
  /private/tmp/fa-ordinary-invariance-20260930/fa_ordinary_unit_order_check.jl
```

The metadata regression below uses the unversioned scratch directory. Including
the script defines helpers and imports standard libraries; the CLI entry guard
prevents an engine import, generator call, or fit:

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --startup-file=no -e \
  'include(ARGS[1]); m=git_metadata(ARGS[2]); @assert m["git_metadata_status"]=="unavailable"; @assert all(m[k]=="unavailable" for k in ("git_head","git_branch","git_status_porcelain")); @assert length(m["git_metadata_errors"])==3; TOML.print(IOBuffer(),m); println("no-Git metadata regression passed; no RNG or fits")' \
  /private/tmp/fa-ordinary-invariance-20260930/fa_ordinary_unit_order_check.jl \
  /private/tmp/fa-ordinary-invariance-20260930
```
