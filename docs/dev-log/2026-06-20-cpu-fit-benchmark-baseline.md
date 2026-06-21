# CPU Fit Benchmark Baseline — 2026-06-20

## Purpose and framing

This note records representative wall-clock timings of the sparse CPU fit path
(`fit_ai_reml`) at four pedigree sizes.  It is a **pure MEASUREMENT**:

- Recorded on a single developer machine (Apple Silicon, arm64-apple-darwin22.4.0).
- Single-threaded: `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`.
- Median of 3 timed runs, after one JIT warm-up run to exclude compilation.
- **NOT a competitive claim** ("the engine is fast", "beats package X").
- **NOT a production-scale claim** (these are deterministic half-sib pedigrees,
  not real genomic or large-scale datasets).
- **NOT a CI gate** — these numbers do not gate any test, and are not asserted
  by `Pkg.test()`.
- **NOT a performance-claim boundary** within the meaning of `AGENTS.md`.  No
  row is added to `validation_status()`.

The **sole purpose** of this baseline is to give a CPU reference point that a
future GPU port (Apple Metal / Compute Canada CUDA) would be compared against.
GPU work is parked and not started.  This note will be updated when a GPU
comparator exists.

---

## Harness

`sim/cpu_fit_benchmark.jl` — opt-in, outside `test/`.

For each size:

1. Build a deterministic half-sib pedigree (no RNG).
2. Invert it: `Ainv = pedigree_inverse(ped)`.
3. Construct a deterministic `y` (structured linear function of index, no RNG).
4. Build `AnimalModelSpec`.
5. Warm-up run (JIT), then 3 timed runs of `fit_ai_reml(spec)`.
6. At q ≤ 500: additionally time `prediction_error_variance(fit; method = :selinv)`
   and `prediction_error_variance(fit; method = :dense)`.
7. Report median times.

Dense PEV is O(q³) and is deliberately skipped at q > 500.

---

## Recorded timings

Machine: Apple M-series developer laptop, single-threaded  
Julia: 1.10.0  
BLAS: LBTConfig([ILP64] libopenblas64_.dylib)  
Date: 2026-06-20

| Label  |    q | nnz(Ainv) | fit_ai_reml (s) | selinv-PEV (s) | dense-PEV (s) |
| ------ | ---: | --------: | --------------: | -------------: | ------------: |
| q≈100  |  100 |       460 |          0.0072 |         0.0000 |        0.0002 |
| q≈500  |  500 |      2340 |          0.0230 |         0.0002 |        0.0125 |
| q≈2000 | 2000 |      9360 |          0.0840 |         0.0007 |     (skipped) |
| q≈8000 | 8000 |     37440 |          0.3340 |         0.0027 |     (skipped) |

Pedigree design: half-sib (`nsire` : `ndam` : `noffspring` ≈ 1:2:8.5).  
Incidence: identity `Z = I_q`, single fixed effect (intercept).

---

## What these numbers say and do not say

**They say:** On this developer machine, single-threaded, the sparse AI-REML
fit completes in under a second for q up to 8000, and the selinv PEV is
consistently faster than the fit itself.

**They do NOT say:** anything about performance relative to other software,
about multi-threaded or GPU throughput, about real genomic datasets, about
sparse vs dense scaling beyond these sizes, or about production readiness.
Dense PEV was not measured at q > 500 and no extrapolation is warranted.

This note is the CPU baseline only.  It will be compared against a GPU
measurement when GPU porting work begins.

---

## Check-log entry

See `docs/dev-log/check-log.d/2026-06-20-cpu-benchmark-baseline.md`.
