# Pre-declaration — Phase 5 sparse-vs-dense AI-REML performance benchmark

**Date:** 2026-07-02 · **Lane:** Julia engine (`HSquared.jl`) · **Author:** Claude (solo).
**Status when written:** working tree on `main` (HEAD `c2b093b1`); `validation_status()`
rows=53, covered=13, `public_covered_count`=5. This document, the rewritten harness
`sim/phase5_sparse_aireml_benchmark.jl`, and the additive `src/likelihood.jl` edit (§9) are
all committed together in **one commit BEFORE the timing run** — call it the
**pre-declaration commit** (`PREDECL`). **Freeze baseline:** the byte-identity proof is
against the harness blob **in `PREDECL`**, NOT against `c2b093b1` (whose blob is the old
scaffold — the harness is a full rewrite that is uncommitted as this is written). After the
run I will prove `git show PREDECL:sim/phase5_sparse_aireml_benchmark.jl` is identical to the
harness that ran (no post-`PREDECL` harness edit; the run checks out `PREDECL` on Totoro).

## 0. Why this exists (and what it is NOT)

The sparse K-component AI-REML estimator `fit_sparse_multi_effect_aireml` (P5.1, row
`V3-NEFFECT-SPARSE`, `partial`) is the production-shaped scale path behind the dense
`fit_multi_effect_reml` oracle. Its **correctness** is already discharged in-suite
(`test/runtests.jl`): exact reduction to the dense optimum (K=2/K=3, loglik ~1e-8, VC rtol
~2e-4) and to `fit_ai_reml` (K=1, ~1e-14). What is **owed** — and what this benchmark
supplies — is a **measured** sparse-vs-dense timing/scaling characterization. The package
currently makes **no performance claim**; this is "measure-first, bank it."

**This is a measurement, not a promotion.** No covered flip. `V3-NEFFECT-SPARSE` stays
`partial`; row count stays 53; `public_covered_count` stays 5. The estimand is already
covered via `V3-NEFFECT-REML`. This run only adds *performance evidence* to a partial row.

## 1. The confound, stated up front (this bounds the claim)

The two paths differ in **two** ways at once:

| | sparse `fit_sparse_multi_effect_aireml` | dense `fit_multi_effect_reml` |
|---|---|---|
| linear algebra | sparse Cholesky of the Henderson MME `C` + one Takahashi selected inverse per iter, `O(nnz(L))` | forms an `n×n` `V`, dense Cholesky each objective eval, `O(n³)` |
| optimizer | AI/Newton (analytic score + AI matrix), few iterations | derivative-free `Optim.NelderMead` over K+1 log-variances, many evals |

A wall-clock comparison is therefore **estimator-vs-estimator, end-to-end** — NOT an
isolated linear-algebra comparison. To keep this honest the harness records **iteration and
function-eval counts for both paths** so the write-up can decompose any speed difference
into "fewer iterations" (AI-Newton vs NelderMead) vs "cheaper per iteration" (sparse vs
dense LA). The claim (§5) is scoped to exactly what is measured.

## 2. Fixed experimental design (frozen)

- **Harness:** `sim/phase5_sparse_aireml_benchmark.jl` (opt-in, env-gated, OUT of CI),
  frozen byte-identical by the pre-declaration commit `PREDECL` (see §0).
- **Model / data:** K-component INDEPENDENT random-effect Gaussian model. Effect 1 =
  additive (half-sib pedigree via `normalize_pedigree`; precision = `pedigree_inverse`,
  all animals phenotyped, `Z₁ = I`); effects 2..K = i.i.d. environmental groupings assigned
  INDEPENDENTLY of the pedigree. Phenotypes by **O(q) gene-dropping** (no dense q×q matrix
  is ever formed — the harness is scalable to q=50000). Deterministic; `base_seed = 20260702`.
- **Size grid (locked):**
  - overlap (both paths): `q ∈ {200, 500, 800, 1000}` (dense feasible; `dense_cap = 4_000_000`).
  - sparse-only scaling: `q ∈ {2000, 5000, 10000, 20000, 50000}` (dense skipped — infeasible/capped).
- **K passes:** **K=3** (headline, multi-effect) and **K=1** (pure additive animal-model
  reference), same grid, two separate invocations / two TSVs.
- **Replication:** sparse `trials = 5`, `nseeds = 5`; dense `dense_trials = 3`,
  `dense_seeds = 2` (dense is `O(n³)`/fit and far more expensive; its timing is stable
  relative to its magnitude, so it takes fewer replicates — dense runs on the first
  `dense_seeds` datasets, a paired subset of the sparse seeds).

## 3. Timing protocol (frozen)

- Single core: `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1` passed at launch.
- **Warm-up excluded twice:** a global JIT warm-up at q=200 (discarded) + a per-cell
  full-size warm-up fit (discarded) before the measured trials, so size-dependent
  compilation is out of the timed region for both paths.
- **GC suppressed during each timed call** (`GC.gc()` then `GC.enable(false)` around the
  `@elapsed`, re-enabled after) so per-iteration allocations don't inject GC pauses into
  measured times.
- **Summary stat:** **min over trials** (robust to co-tenant noise on the shared box) and
  **median over seeds** (dataset generality). Raw per-`(q,K,path,seed,trial)` rows are
  written so any statistic is reproducible from the committed TSV.
- **Symmetric cold start:** sparse uses `em_warmup = 0` to match the dense cold NelderMead
  start (the estimator optimum is `em_warmup`-invariant on identified data, so this is a
  fairness choice, not an accuracy one).

## 4. Machine/version manifest (recorded in the TSV; filled post-run)

Host, `VERSION`, `BLAS.get_config()`, thread counts, free/total memory, `loadavg1` at start
and end, and per-row `loadavg1`. Compute target: **Totoro** (`julia-1.10.10`, matching the
DRAC F0 benchmark manifest), 1 core (≪ the ≤100-core lab rule), over the existing
ControlMaster socket. Repo staged to the pre-declaration commit `PREDECL` on `main`.

## 5. Pre-declared claim + decision rule (measurement-shaped)

After the run, I may make **at most** the following claims, each only if its condition holds.
The sparse path is timed at **every** grid size (overlap + sparse-only), so a sparse
log-log fit spans the full range {200,…,50000}; the dense path is timed only on the overlap
grid {200,500,800,1000}. Slopes on the two paths are therefore estimated on **different q
ranges** and are reported as such — no extrapolation is assumed.

- **C1 (sparse scaling — descriptive, not a gate):** report the sparse wall-clock log-log
  OLS slope (with its R² and the fitted range) over the full sparse grid {200,…,50000}.
  State it descriptively, e.g. "the sparse estimator's wall-clock scales with an empirical
  exponent ≈ s (R² = r) over q∈[200,50000] on <host>." **No single slope value is a
  pass/fail gate** (5–9 points cannot distinguish s=1.9 from s=2.1). The prior is only that
  a sparse `O(nnz)`-dominated path should land well below the dense `O(n³)` exponent of ~3.
  The dense slope, if reported, is explicitly tagged "estimated on q∈[200,1000] only."
  The dense oracle is **not run above q=1000** and is **cap-excluded** (`n²>max_dense_cells`)
  by policy for q>2000 — this is a design consequence of the chosen cap, **not a measured
  wall**; do not phrase it as "hits the wall at q≈2000."
- **C2 (crossover + sparse feasibility):** licensed **iff**, on the overlap grid, sparse
  min-time ≤ dense min-time at some grid value **X and at all larger overlap sizes**
  (monotone dominance above X), with the sparse-faster sign **stable across all dense
  seeds** (so co-tenant noise cannot manufacture the win); X is then reported as that actual
  grid value. If sparse does not dominate monotonically over the overlap grid, C2 is **not
  licensed** → banked negative (§7). The feasibility half: "the sparse path remains feasible
  (bounded wall-clock, `converged=true`) at q up to 50000, where the dense oracle is
  **cap-excluded (`n²>max_dense_cells`) and not attempted**." The run demonstrates sparse
  feasibility to q=50000; it does **not** measure dense infeasibility (no dense fit is
  attempted above q=1000) — do not claim it does.
- **C3 (confound decomposition — mandatory framing, descriptive not arithmetic):** the
  speed difference MUST be reported alongside the recorded counts, with the units stated
  explicitly: **sparse "iterations" = AI/Newton steps** (each = one sparse Cholesky + one
  Takahashi selected inverse + one score/AI-matrix eval, `O(nnz(L))`); **dense "f_calls" =
  NelderMead objective evaluations** (each = one `O(n³)` dense-V Cholesky), with dense
  "iterations" = NelderMead simplex steps. These are **different units** — the sparse path
  records `iterations` (its `f_calls` column is `-1`, not recorded); the dense path records
  both. The decomposition is **descriptive**: `total_sparse/total_dense =
  (sparse_iters·cost_per_sparse_iter)/(dense_fcalls·cost_per_dense_eval)`, and the per-unit
  costs are **not independently observed** — only totals and counts are. State this; do not
  present a per-iteration cost ratio as a measured quantity.

**Forbidden regardless of results:** any isolated-linear-algebra speedup number; any
"faster than package/software Y" comparison; any GPU/accelerator claim; any
production-hardening claim; any accuracy/recovery claim (timing ≠ correctness — that is the
separately-owed recovery gate). Every claim is tagged **machine-specific measurement on
<host>**, never a portable/absolute performance guarantee.

## 6. Same-optimum verification (so the timing is meaningful)

A fast estimator that stops early is not "faster." Cross-path same-optimum is verified on
the **variance components** — the TSV records `sigma_a`, `sigma_e`, and `sigmas_all` (all K
components) per row. **Hard gate (parallel to the `converged` exclusion):** an overlap cell
is declared *same-optimum* iff the max absolute difference across all K+1 components between
the sparse and dense σ-vectors is **≤ 0.01**. This is magnitude-calibrated: the DGP fixes
all variances at `O(1)` (`σ_a²=1`, `σ_e²=1`, `σ_env=0.5`), so ≤0.01 is ≤~1% of every
component (local smoke agrees ~1e-5). **Any cell exceeding 0.01, or where either path reports
`converged=false`, is flagged not-same-optimum and EXCLUDED from the crossover claim C2**
(its timing is not comparable). **loglik note:** the two paths' `loglik` columns differ by
the known additive constant — specifically `sparse.loglik == dense.loglik − 0.5(n−p)log(2π)`
(dense `_multi_effect_dense` omits the `2π` term; the sparse loglik includes it — the
objective-identity relation gated in-suite). So `loglik` is a *within-path* optimum-stability
check across seeds/trials, **never** a direct cross-path comparison.

## 7. Bank-a-negative clause

If the results are noisy (high trial variance not resolved by min-over-trials), show no
crossover, or show sparse *not* winning at the tested sizes, the outcome is a **BANKED
NEGATIVE**: the checkpoint records the table + the honest read, and `V3-NEFFECT-SPARSE`
keeps its "no performance claim" wording (only gaining "benchmark run; no scaling advantage
demonstrated at tested sizes" evidence). No result is discarded or re-run to get a better
number; the harness is not modified post-hoc (byte-identity proof in §0). If a large-q cell
OOMs or aborts (the timed region runs with GC disabled), that cell is recorded as a banked
negative for that size — it is **NOT** retried with GC re-enabled or with the harness
altered, which would break the frozen protocol.

## 8. Exact run commands (Totoro)

```sh
cd ~/hsq_work/HSquared.jl        # checked out to PREDECL on main, instantiated (julia-1.10.10)
JL=~/hsq_work/julia-1.10.10/bin/julia
# K=3 headline:
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 SPARSE_BENCH_K=3 \
  SPARSE_BENCH_TRIALS=5 SPARSE_BENCH_SEEDS=5 SPARSE_BENCH_DENSE_TRIALS=3 SPARSE_BENCH_DENSE_SEEDS=2 \
  HSQUARED_RUN_SPARSE_BENCH=1 nohup $JL --project=. \
  sim/phase5_sparse_aireml_benchmark.jl phase5_sparse_benchmark_K3.tsv > r3_K3.log 2>&1 &
# K=1 reference (same grid):
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 SPARSE_BENCH_K=1 \
  SPARSE_BENCH_TRIALS=5 SPARSE_BENCH_SEEDS=5 SPARSE_BENCH_DENSE_TRIALS=3 SPARSE_BENCH_DENSE_SEEDS=2 \
  HSQUARED_RUN_SPARSE_BENCH=1 nohup $JL --project=. \
  sim/phase5_sparse_aireml_benchmark.jl phase5_sparse_benchmark_K1.tsv > r3_K1.log 2>&1 &
```
Both TSVs are `scp`'d back and committed. Estimated wall-clock ~10–20 min total.

## 9. Pre-run review (recorded before freeze)

Four review-lens subagents examined the harness + this pre-declaration before freeze:
- **Karpinski (timing methodology):** SOUND-WITH-FIXES → (1) GC suppression during the timed
  region, (2) live dense-`converged` visibility. Both applied to the harness.
- **Gauss (same-optimum):** SOUND-WITH-FIXES → (1) record `loglik`, (2) record all K σ's, so
  same-optimum is post-hoc verifiable per cell. Both applied to the harness.
- **Fisher (claim/decision-rule):** SOUND-WITH-FIXES → C1 slope descriptive not a gate (+R²);
  acknowledge non-overlapping grids; pre-commit the C2 crossover rule; C3 decomposition
  descriptive with explicit iteration-unit definitions; magnitude-calibrate the same-optimum
  threshold. All applied to §5/§6.
- **Rose (claim-vs-evidence):** APPROVE-WITH-CHANGES → (R1) fix the freeze baseline to the
  pre-declaration commit `PREDECL` (not `c2b093b1` — the harness is a rewrite, uncommitted
  when written); (R2) drop the un-measured "wall at q≈2000"; (R3) bound C2's X + swap
  "infeasible"→"cap-excluded, not attempted"; plus S1/S2/S3/S4 strengthenings. All applied
  to §0/§2/§4/§5/§6/§7/§8/§10.
- Additive, payload-safe edit to `fit_multi_effect_reml` (exposes `iterations`/`f_calls`;
  `result_payload_v2` field-selects, so the frozen payload shape is unchanged) — this is a
  source change, not a harness change; the byte-identity freeze (§0) is on the harness file.

## 10. GO / NO-GO

- **GO** to run once: (a) this pre-declaration + rewritten harness + src edit are committed
  as `PREDECL`; (b) `Pkg.test()` is green with the additive `fit_multi_effect_reml` edit
  (**confirmed green 2026-07-02, count 53**); (c) Totoro is checked out to `PREDECL` and
  instantiated.
- After the run: prove harness byte-identity; write the post-run checkpoint
  (`2026-07-02-phase5-sparse-benchmark.md`) with the manifest, the min/median table, the
  iteration-decomposition, the same-optimum σ-check, and the GO/negative decision per §5/§7;
  then a real Rose audit before any status-surface edit.
