# Check-log: CPU Fit Benchmark Baseline (2026-06-20)

## Slice

`sim/cpu_fit_benchmark.jl` — opt-in CPU benchmark harness; NOT part of CI suite.

## Goal

Record representative single-threaded wall-clock timings of `fit_ai_reml` and
`prediction_error_variance` at several pedigree sizes as a CPU baseline for a
future GPU comparison.  No performance claim is made; no CI gate is set.

## Files changed

- `sim/cpu_fit_benchmark.jl` — new opt-in harness (outside `test/`)
- `docs/dev-log/2026-06-20-cpu-fit-benchmark-baseline.md` — recorded timings note
- `docs/design/capability-status.md` — one clause added to the Sparse production
  fitting row: points to the opt-in harness and the baseline note; framing
  is explicit "measurement, not a claim, not a CI gate"

## Checks executed

### Pkg.test() — committed CI suite unaffected
```
Testing HSquared tests passed
```
The harness lives in `sim/`, not `test/`; zero new test assertions were added.

### docs/make.jl — Documenter build
```
build complete in 4.43s
```
No documentation pages reference the new sim file directly; the capability-status
clause addition renders correctly.

### Benchmark run (opt-in, single-threaded)
```
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
    ~/.juliaup/bin/julia --project=. sim/cpu_fit_benchmark.jl
```
Output:
```
HSquared.jl — CPU fit benchmark baseline
=========================================
Opt-in measurement only.  NOT a performance claim.
Machine: developer laptop (arm64-apple-darwin22.4.0), single-threaded
Julia:   1.10.0
BLAS:    LBTConfig([ILP64] libopenblas64_.dylib)

  Benchmarking q≈100  (nsire=5 ndam=10 noffspring=85)...
  Benchmarking q≈500  (nsire=20 ndam=40 noffspring=440)...
  Benchmarking q≈2000  (nsire=80 ndam=160 noffspring=1760)...
  Benchmarking q≈8000  (nsire=320 ndam=640 noffspring=7040)...

Results
-------
Label              q   nnz(Ainv)  fit_ai_reml(s)    selinv-PEV(s)        dense-PEV(s)
----------  --------  ----------  --------------  ---------------  ------------------
q≈100            100         460          0.0072           0.0000              0.0002
q≈500            500        2340          0.0230           0.0002              0.0125
q≈2000          2000        9360          0.0840           0.0007       (skipped)
q≈8000          8000       37440          0.3340           0.0027       (skipped)

Notes
-----
  - Median of 3 timed runs after one JIT warm-up run.
  - dense-PEV skipped at q > 500 (O(q³) cost).
  - JULIA_NUM_THREADS=1, OPENBLAS_NUM_THREADS=1 for single-threaded baseline.
  - These numbers are machine-dependent.  No performance claim is made.
```

## Rose audit (claim-vs-evidence gate)

This slice makes NO new fitted capability claim and NO performance claim.  The
harness records wall-clock measurements and states plainly in both the source
file header and the dev-log note that:

1. The numbers are machine-dependent.
2. They are NOT a competitive comparison to any other package.
3. They are NOT asserted by CI.
4. They are a CPU baseline for a future GPU comparison (GPU work not started).

The capability-status row update adds exactly one honest clause: "opt-in CPU
benchmark harness records representative single-threaded timings — a measurement,
not a performance claim."  No row is added to `validation_status()`
(remains 41 rows).  No `experimental→covered` promotion.

**Rose: no unsupported claim detected.  The framing is correct.**

## validation_status() row count (unchanged)
41 rows — confirmed by `julia --project=. -e 'using HSquared; vs = validation_status(); println(length(vs.rows))'`.
