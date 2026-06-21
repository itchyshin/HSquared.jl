# After-Task Report: CPU Fit Benchmark Baseline

Date: 2026-06-20  
Branch: `julia/cpu-benchmark-baseline`  
Session: autonomous slice

---

## 1. Slice identity

Opt-in CPU benchmark harness for the sparse AI-REML fit path — a MEASUREMENT
baseline, not a performance claim.  The harness records single-threaded wall-clock
timings at four pedigree sizes (q ≈ 100, 500, 2000, 8000) as the CPU baseline for
a future GPU port (Apple Metal / Compute Canada CUDA).

---

## 2. Files changed

| File | Change |
| ---- | ------ |
| `sim/cpu_fit_benchmark.jl` | new opt-in harness (outside `test/`) |
| `docs/dev-log/2026-06-20-cpu-fit-benchmark-baseline.md` | recorded timings + framing note |
| `docs/dev-log/check-log.d/2026-06-20-cpu-benchmark-baseline.md` | check-log entry |
| `docs/design/capability-status.md` | one clause added to Sparse production fitting row |

---

## 3. Implementation notes

The harness follows the `sim/phase6_*_recovery.jl` opt-in pattern:

- No RNG in the committed test suite; all randomness (none here) stays in `sim/`.
- The half-sib pedigree generator is a direct port from `phase6_poisson_recovery.jl`.
- Response `y` is a deterministic structured function of index — no seed needed.
- JIT warm-up run before each size; median of 3 timed runs reported.
- Dense PEV guarded at q > 500 (O(q³) explicit comment in source).

The capability-status clause is the minimal honest update: one sentence,
explicitly "measurement, not a performance claim, not a CI gate."
No `validation_status()` row was added.

---

## 4. Recorded timings (2026-06-20, developer laptop, single-threaded)

| Label  |    q | nnz(Ainv) | fit_ai_reml (s) | selinv-PEV (s) | dense-PEV (s) |
| ------ | ---: | --------: | --------------: | -------------: | ------------: |
| q≈100  |  100 |       460 |          0.0072 |         0.0000 |        0.0002 |
| q≈500  |  500 |      2340 |          0.0230 |         0.0002 |        0.0125 |
| q≈2000 | 2000 |      9360 |          0.0840 |         0.0007 |     (skipped) |
| q≈8000 | 8000 |     37440 |          0.3340 |         0.0027 |     (skipped) |

These numbers are a raw measurement on one machine.  No claim is made about
relative performance vs other software or about production-scale suitability.

---

## 5. Checks

| Check | Result |
| ----- | ------ |
| `Pkg.test()` | PASS — suite unaffected (harness in `sim/`, not `test/`) |
| `docs/make.jl` | PASS — build complete in 4.43 s |
| `validation_status()` rows | 41 (unchanged) |
| Benchmark run (opt-in) | Completed; table recorded above |

---

## 6. Rose audit (claim-vs-evidence gate)

**No new fitted-capability claim, no performance claim, no competitive claim.**

The harness and dev-log note state plainly:

- Numbers are machine-dependent.
- Not a comparison to any other package.
- Not a CI gate.
- Not a performance-optimisation claim.
- CPU baseline only; GPU work is parked and not started.

The capability-status update adds one sentence, explicitly framed as
"measurement, not a performance claim."  No `validation_status()` row.
No `experimental→covered` promotion.

**Rose: framing is correct.  No unsupported claim.**

---

## 7. DoD checklist

| Item | Status |
| ---- | ------ |
| Implementation (`sim/cpu_fit_benchmark.jl`) | done |
| Tests (suite unaffected; harness opt-in only) | done |
| Documentation (dev-log note + check-log) | done |
| Capability-status row update (minimal honest clause) | done |
| Validation-debt row (NOT applicable — no new fitted capability) | N/A |
| After-task report | this document |
| Rose audit | done (section 6) |
| Clean local checks (`Pkg.test()` + `docs/make.jl`) | done |
| No `validation_status()` rows added | confirmed (41) |

---

## 8. What is NOT claimed

- "The engine is fast."
- "HSquared.jl is faster than [ASReml / BLUPF90 / WOMBAT / sommer / ...]."
- "q = 8000 animals is production-scale."
- "These timings will hold on other hardware."
- "Single-threaded performance is the production default."

None of these appear anywhere in the committed files.

---

## 9. Cross-lane impact

None.  This slice is Julia-only, no R-lane contract change.

---

## 10. Next actions

- GPU work (Apple Metal / Compute Canada CUDA) remains parked.
- When GPU porting begins, `docs/dev-log/2026-06-20-cpu-fit-benchmark-baseline.md`
  is the CPU reference to compare against.
- The harness can be re-run on any machine with
  `env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 ~/.juliaup/bin/julia --project=. sim/cpu_fit_benchmark.jl`.

---

## 11. Phase snapshot (updated pointer)

**As of 2026-06-20 (this slice):** CPU benchmark baseline harness committed.
`validation_status()` = 41 rows unchanged.  No capability status promoted.
GPU work parked.  Sparse AI-REML CPU timing baseline now recorded in
`docs/dev-log/2026-06-20-cpu-fit-benchmark-baseline.md`.
