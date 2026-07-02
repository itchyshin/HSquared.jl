# doc-23 — Programme plan: v0.7 (GPU) + v0.8 (HPC / production-sparse)

**Authored:** 2026-07-02 (Claude/Fable, planning session; ultra-plan method). **Status:**
PLAN — for maintainer review, then execution in a FRESH session (this plan is the start-point).
**Predecessor:** the Phase 5 sparse-vs-dense benchmark (merged PR #247) — its headline finding
(K=1 sparse near-linear to q=50k, K=3 ~quadratic from environmental-group Cholesky fill-in →
**METIS fill-reducing ordering is the concrete scale enabler**) is the load-bearing input to v0.8.

## Goal (one sentence)

Take v0.7 (GPU acceleration) and v0.8 (HPC / production-sparse) from their current `partial`
state toward coherent ENGINE performance/scale gates — every perf/scale claim under the
measure-first + pre-declaration discipline proven in Phase 5 — WITHOUT any public-covered flip.

## Honesty guardrails (carried verbatim from Phase 5 — non-negotiable)

1. **These are engine performance/scale versions, NOT new estimands.** "v0.7 covered" /
   "v0.8 covered" assert *acceleration / scale of an already-validated computation*, verified
   CPU-identical (GPU) or exact-reduction (sparse) + benchmarked. They do **NOT** flip
   `public_covered_count` (stays 5) and do **NOT** change the public default fit path.
2. **Measure-first + pre-declaration for EVERY perf/scale claim:** predeclaration committed
   BEFORE the run; harness byte-identical pre/post; machine-specific measurement; a pre-declared
   falsifiable claim + decision rule; a bank-a-negative clause; a real Rose audit before any
   status edit. (Template: `docs/dev-log/recovery-checkpoints/2026-07-02-phase5-sparse-benchmark-predeclaration.md`.)
3. **No overclaim:** no "faster than package Y"; disclose confounds; no isolated-component
   speedup without the decomposition; correctness (agreement/reduction) is a SEPARATE gate from
   timing.
4. **Engine-covered ≠ R-public-covered.** No R-repo edits (R twin frozen); coordinate at the
   shared contract only.
5. **Compute golden rules** (`~/shinichi-brain/tools/{drac,totoro}-setup.md`): never a login-node
   run; `/project` not `/scratch`; name the GPU model + set `--time`/`--account`; pin
   `OPENBLAS_NUM_THREADS=1`; ≤100 cores on Totoro.

---

## v0.7 — GPU acceleration

**Current state (`partial`, row `V2-GRM-GPU`):** GPU VanRaden `G`/`Ginv` via `HSquaredCUDAExt`
(`ext/HSquaredCUDAExt.jl`, stubs in `src/gpu_ext.jl`), reusing the validated CPU
`centered_markers` (same estimand by construction). **RUN on tamia** (4× H100, SLURM job 352612):
CPU↔GPU agreement ~1e-14; benchmark `G` GEMM 1.3×→~5× (m 2k→40k), ridge `Ginv` ~2.7–2.9×. CUDA
is out of CI (stub-gated). The general backend dispatcher (`backend_info` `:cuda`) stays
`:planned`.

**What "v0.7 covered" asserts:** the genomic pipeline (`G` → `Ginv` → GBLUP solve) runs on GPU,
**numerically identical** to the CPU twin, with an honest end-to-end benchmark on a real marker
panel — a machine-specific acceleration gate.

**Slices (toward v0.7):**
- **G-A — device-resident GBLUP solve (headline).** Extend the GPU path from `G`/`Ginv` to the
  GBLUP GEBV solve *keeping `G` on-device across `G→Ginv→solve`* (avoid host round-trips). CPU↔GPU
  agreement gate + pre-declared benchmark. Compute: DRAC GPU. Size L.
- **G-B — Float32 / mixed-precision path.** A `Float32` device path (larger speedups) WITH an
  accuracy characterization vs `Float64` (how much precision is lost; is it acceptable for GBLUP
  GEBV ranking?). Honest fence: accuracy-vs-speed trade documented, not hidden. Size M.
- **G-C — real-marker-panel benchmark.** Replace the synthetic benchmark with a real (or
  realistic large) genotype panel for the honest end-to-end speedup + memory profile. Size M.
- **G-D (optional) — backend dispatcher.** Wire `control`/`AutoBackend` → `:cuda` so a fit can
  route to GPU when available (keeps `:planned` honest until it actually dispatches). Size M.
- **G-E — Rose + status close-out** (flip `V2-GRM-GPU` evidence, no public move).

**Compute:** DRAC GPU ONLY — **Totoro has NO GPU, so every v0.7 slice runs on DRAC** — tamia
(H200-141GB, already configured; biggest GPU memory), Killarney/Vulcan (H100), Narval (A100,
single-GPU dev-friendly). PAICE clusters (Killarney/Vulcan/tamia) need an `aip-` allocation
(tamia set up); Narval uses ordinary `def-` access.

---

## v0.8 — HPC / production-sparse

**Current state (`partial`):** Wave-F **F1** (Meuwissen–Luo O(n) inbreeding, `_meuwissen_luo_inbreeding`
— Ainv build feasible to q=300k) + **F3** (scale-invariant AI-REML convergence: q=300k 35.6s→2.3s).
PCG MME solver (`solve_animal_model_pcg` + `preconditioner=:ichol`). Takahashi selected-inverse
PEV/reliability. `fit_sparse_multi_effect_aireml` (Phase 5). **Phase 5 benchmark finding
(load-bearing):** K=1 sparse near-linear (slope 1.01) to q=50k, but K=3 ~quadratic (slope 2.25)
from environmental-group-column Cholesky fill-in — **a fill-reducing ordering (METIS) is the
concrete next enabler**; METIS is currently NOT implemented (noted in Wave-F).

**What "v0.8 covered" asserts:** production-sparse fitting at q=10^5–10^6 with verified
correctness (exact reduction to the dense oracle at small scale) + **measured near-linear
scaling** for the multi-effect path (post fill-reducing ordering) — a machine-specific scale gate.

**Slices (toward v0.8):**
- **S1 — fill-reducing ordering (METIS/AMD) [HEADLINE, do first].** Apply a fill-reducing
  permutation to the sparse multi-effect Cholesky (`fit_sparse_multi_effect_aireml`) so K≥2
  scaling recovers toward near-linear. Verify exact-optimum invariance (permutation must not
  change the answer), then **re-run the frozen Phase 5 benchmark harness** (pre-declared) to
  confirm the K=3 slope drops from ~2.25 toward ~1. This is the direct, highest-leverage
  follow-up to Phase 5. Compute: Totoro. Size L.
- **S2 — matrix-free PCG operator.** A matrix-free MME operator (apply `C·x` without forming `C`)
  for the PCG solver — the actual large-scale enabler beyond direct Cholesky at q→10^6. Size L.
- **S3 — sparse-path recovery gate + comparator at scale.** A PRE-DECLARED bias/MCSE recovery
  gate run THROUGH the sparse estimator (not just the dense oracle) + a same-estimand external
  comparator (blupf90/sommer) at production scale. Compute: Totoro/DRAC. Size L.
- **S4 — APY genomic scaling.** Algorithm for Proven & Young (APY) sparse inverse of the genomic
  relationship for large genotyped populations. Size L.
- **S5 — production large-q fixtures + the R multi-term `(1|g)` bridge.** Committed large-q
  fixtures + wiring the sparse estimator to the R `(1|g)` multi-term surface (cross-lane —
  coordinate; R twin frozen, so this may defer). Size M.

**Compute:** Totoro (384-core, no queue — default for quick big-CPU) + DRAC Fir (`def-snakagaw_cpu`,
queued campaigns).

---

## Sequencing recommendation

v0.7 (GPU) and v0.8 (sparse) are **largely independent parallel streams** (GPU vs CPU; different
code paths; no shared blocker). But within the whole, **v0.8-S1 (METIS) is the single
highest-leverage next step** — it directly cashes in the fresh Phase 5 finding and is the biggest
scale win. Recommended order:

1. **v0.8-S1 (METIS) first** — highest leverage, builds on Phase 5 momentum, Totoro (fast, no
   queue).
2. Then run the two streams **in parallel**: v0.7 GPU (G-A → G-B → G-C) on DRAC GPU, and v0.8
   (S2 → S3 → S4) on Totoro/Fir. They don't contend (different clusters).
3. S5 / G-D last (cross-lane / dispatcher polish).

**Alternative:** if GPU compute (DRAC allocation) is readier than a METIS integration, start G-A
in parallel from day 1 — the streams are independent.

---

## Definition of Done (per slice) + verification

Each slice: implementation + tests (exact-reduction / CPU-identical correctness gate) + a
PRE-DECLARED benchmark (committed before the run, harness byte-identical, machine-specific,
bank-a-negative) + capability-status + validation-debt rows + check-log + after-task + a real
`rose-systems-auditor` audit + clean local `Pkg.test()` + `docs/make.jl` (+ clean CI if pushed).
No public-covered flip; honesty pins held (rows/covered/`public_covered_count` unchanged unless a
genuine engine-covered gate is cleared, and even then `public_covered_count` stays 5).

## Resolved decisions (maintainer, 2026-07-02)

1. **Scope: FULL** — both v0.7-covered and v0.8-covered (multi-session programme), not a single
   first milestone.
2. **Compute:** v0.7 GPU → **DRAC only** (tamia + Killarney/Vulcan/Narval) — **Totoro has NO
   GPU**. v0.8 sparse → **Totoro** (CPU, no queue) + DRAC Fir for queued campaigns. Every perf
   claim pre-declared + machine-specific.
3. **Run both streams in PARALLEL** — v0.7 on DRAC GPU, v0.8 on Totoro/Fir (different clusters,
   no contention). Still lead with v0.8-S1 (METIS) as the highest-leverage first slice, but do
   NOT gate the GPU stream on it.
4. **R bridge (S5):** deferred while the R twin is frozen (cross-lane); revisit when the R lane
   reopens. All other slices are Julia-lane-solo-safe.

## Fresh-session kickoff

1. `hsquared-rehydrate` (live git/CI + ROADMAP + coordination-board + check-log + newest
   after-task + this doc-23).
2. Confirm `main` includes PR #247 (Phase 5 benchmark); `public_covered_count` 5, rows 53.
3. Start with the maintainer-chosen first slice (recommended: **v0.8-S1 METIS**), following the
   pre-declaration discipline (predeclare → checkpoint for approval → run → ingest → Rose →
   status).
