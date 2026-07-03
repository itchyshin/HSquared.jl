# Pre-declaration — v0.8-S2 matrix-free-PCG vs direct-Cholesky multi-effect SOLVE benchmark

**Date:** 2026-07-02 · **Lane:** Julia engine (`HSquared.jl`) · **Author:** Claude (solo).
**Predecessor:** the Phase 5 sparse-vs-dense AI-REML benchmark (PR #247) — found the DIRECT
multi-effect Cholesky is fill-limited for K≥2 (K=3 ~quadratic) and v0.8-S1 (this session)
banked METIS as NOT a robust fix. This benchmark measures the alternative the S1 negative
points to: a **matrix-free iterative solve** that never forms/factors `C`.

## 0. What this is (and is NOT)

`solve_multi_effect_pcg(y, X, effects, sigmas, σ²e; matrix_free = true)` (NEW this session,
`src/iterative_solve.jl`) solves the `K`-INDEPENDENT-effect MME by Jacobi-preconditioned CG,
applying `C·v` from the per-block sparse `X`/`Zᵢ`/`Aᵢ⁻¹` matvecs — `C` is **never assembled**.
Its **correctness** is discharged in-suite (`test/runtests.jl`, testset "Multi-effect
matrix-free PCG"): matrix-free β + per-block BLUPs equal an INDEPENDENT dense-Cholesky solve
of `C` (~1e-8); matrix-free == assembled; operator `C·eᵢ == C[:,i]` (≤1e-12); K=1 reduces to
`solve_animal_model_pcg`. What is **owed** — and what this benchmark supplies — is a **measured**
matrix-free-vs-direct SOLVE timing/feasibility characterization. **This is a measurement, not a
promotion.** No covered flip. Row `V1-PCG` (extended to cover the multi-effect generalization)
stays `partial`; `validation_status()` count **53 UNCHANGED**; `public_covered_count` **5**.

**This times a single SUPPLIED-VARIANCE SOLVE, not a full REML fit.** The AI-REML score needs a
Takahashi selected inverse (a factor); the production route to a matrix-free FIT is a
stochastic-trace / EM scheme — out of scope here. The claim is bounded to the solve.

## 1. The confound, stated up front

| | matrix-free PCG | direct Cholesky |
|---|---|---|
| method | Jacobi-preconditioned CG, iterative (tol-dependent iteration count) | exact sparse factorization + triangular solves |
| memory | O(Σnnz) matvecs; `C`/`L` NEVER formed | forms `C`, factorizes → `nnz(L)` fill |

Both solve the SAME SPD system. The harness records **PCG iterations + relative residual** and
verifies **same-solution per overlap cell**, so the iterative-vs-direct difference is disclosed.
The risk this measures: PCG's Jacobi conditioning could make the iteration count blow up at
large q (then matrix-free would NOT be the enabler — a banked negative). *Local preliminary
signal (Mac, q≤20k): iterations FLAT ~40 as q grows — but that is not the pre-declared result.*

## 2. Fixed experimental design (frozen)

- **Harness:** `sim/v08_s2_matfree_pcg_benchmark.jl`, opt-in (`HSQUARED_RUN_S2_BENCH=1`), OUT of
  CI, frozen byte-identical by the pre-declaration commit `PREDECL` (proven post-run:
  `git show PREDECL:sim/v08_s2_matfree_pcg_benchmark.jl` == the harness that ran).
- **Model / data:** identical DGP to the Phase 5 harness — effect 1 additive (half-sib pedigree,
  all phenotyped, `Z₁=I`); effects 2..K i.i.d. environmental groupings independent of the
  pedigree; O(q) gene-dropping (scalable to q=10⁶). Deterministic; `base_seed = 20260702`.
  Supplied variances = truth (`σ²_a=1`, `σ_env=0.5`, `σ²e=1`).
- **Size grid (locked):**
  - overlap (both paths): `q ∈ {2000, 5000, 10000, 20000, 50000}` (direct feasible; `nnz(L)`-capped).
  - matrix-free-only: `q ∈ {100000, 200000, 500000, 1000000}` (direct `nnz(L)`-capped, skipped).
- **K passes:** **K=3** (headline, the fill-limited multi-effect case) and **K=1** (reference).
- **Replication:** matrix-free `trials=5`, `nseeds=5`; direct `direct_trials=3`, `direct_seeds=2`.
- **PCG:** `tol=1e-8`, `maxiter=5000`, `preconditioner=:jacobi`, `matrix_free=true`.
- **Direct cap:** skip the direct path when `nnz(L) > 60_000_000` (a memory guard, recorded).

## 3. Timing protocol (frozen)

Single core (`OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1`); global JIT warm-up + per-cell
per-path warm-up (discarded); GC suppressed during each timed call; **min over trials**, **median
over seeds**; raw per-`(q,K,path,seed,trial)` rows written. Each path's peak Julia allocation
(`Base.gc_num().allocd`) is recorded as the memory proxy.

## 4. Machine/version manifest

Recorded in the TSV: host, `VERSION`, `BLAS.get_config()`, thread counts, free/total memory,
`loadavg1`. Compute: the **FLEET** — the byte-identical harness runs on multiple CPU clusters
(see doc-24). `julia-1.10.10` (matching the DRAC manifest).

## 5. Pre-declared claims + decision rule (measurement-shaped)

- **C1 (matrix-free scaling — descriptive):** report the matrix-free solve wall-clock log-log OLS
  slope (with R² and fitted range) over the full feasible grid. State descriptively (e.g. "the
  matrix-free multi-effect solve scales with empirical exponent ≈ s over q∈[…] on <host>"). No
  single slope is a pass/fail gate. Prior: a matrix-free O(Σnnz)-per-iteration path with bounded
  iteration count should land well below the direct-Cholesky exponent (Phase 5 K=3 ~2.25).
- **C2 (feasibility frontier — the headline):** licensed iff the matrix-free path reaches
  `converged=true` at q values where the direct path is **`nnz(L)`-cap-excluded and not attempted**.
  Report the largest q that completes on each machine. Phrase as "matrix-free remains feasible
  (bounded wall-clock, `converged=true`, relres ≤ tol) to q=<X> on <host>, where the direct
  Cholesky is cap-excluded (`nnz(L) > cap`) and not attempted." The run demonstrates matrix-free
  feasibility; it does NOT measure direct infeasibility (no direct fit attempted above the cap).
- **C3 (within-cluster crossover — descriptive):** on the overlap grid where BOTH run on the same
  machine, report matrix-free-min vs direct-min per q, with the **same-solution** check and the
  **PCG iteration count** alongside — so any speed difference is disclosed as
  iterative-vs-direct, not attributed to linear algebra alone. Report per machine; do NOT compare
  absolute times across machines.
- **C4 (iteration-count behaviour — mandatory framing):** report the median PCG iteration count vs
  q. If it grows materially with q (Jacobi conditioning degrading), state that explicitly — the
  matrix-free advantage is contingent on bounded iterations.

**Forbidden regardless of results:** any full-REML-fit performance claim (this is a SOLVE); any
GPU/accelerator claim; any "faster than package Y"; any accuracy/recovery claim; any
cross-machine absolute-time comparison; any portable/absolute performance guarantee. Every claim
tagged **machine-specific measurement on <host>**.

## 6. Same-solution verification

An overlap cell is **same-optimum** iff `max|[β;u]_matfree − [β;u]_direct| ≤ 1e-4` (magnitude-
calibrated: all effects are O(1); at PCG `tol=1e-8` the solution matches the exact factorization
to ~1e-6 locally). Any cell exceeding this, or where the matrix-free path reports
`converged=false`, is flagged not-same-solution and EXCLUDED from C3. Recorded per row.

## 7. Bank-a-negative clause

If matrix-free PCG (a) fails to converge in `maxiter` at any tested q (iteration blow-up), (b)
shows no feasibility advantage (does not reach beyond the direct cap), or (c) is slower than
direct on the overlap grid with no compensating scaling benefit, the outcome is a **BANKED
NEGATIVE**: the checkpoint records the table + the honest read, `V1-PCG` keeps its "no
performance claim / correctness primitive" wording (gaining only "matrix-free multi-effect
benchmark run; no scaling advantage demonstrated at tested sizes"). No result discarded or
re-run for a better number; the harness is not modified post-hoc (byte-identity, §2). A large-q
cell that OOMs/aborts is recorded as a banked negative for that size, NOT retried.

## 8. GO / NO-GO

- **GO** to run once: (a) this pre-declaration + harness + the `solve_multi_effect_pcg` source +
  test are committed as `PREDECL`; (b) `Pkg.test()` green (count 53) with the new code
  (**confirmed green 2026-07-02**); (c) each fleet node is checked out to `PREDECL` and
  instantiated on `/project` (never `/scratch`).
- After the run: prove harness byte-identity; write the post-run checkpoint with the manifest,
  the feasibility frontier per machine, the within-cluster crossover + same-solution + iteration
  table, and the GO/negative decision per §5/§7; then a real Rose audit before any status edit.
