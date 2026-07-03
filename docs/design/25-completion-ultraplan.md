# doc-25 — Ultra-plan: completely finishing the v0.7 + v0.8 arc

**Authored:** 2026-07-02 (Claude, autonomous session). **Method:** ultra-plan (decompose →
dispatch → verify → consolidate). **Status (2026-07-03 — ARC COMPLETE):** ALL NUMBERED SLICES DONE + BOTH OWED HARDENING LEGS DONE.
The **V8 stream (V8.1–V8.6)** and the **V7 GPU stream (V7.1–V7.5)** are COMPLETE, each slice
pre-declared + Rose-audited + merged. The two explicitly-OWED hardening legs are now discharged:
**V8.4's at-scale comparator** (blupf90 vs exact-sparse vs matrix-free at q=4060; PR #260) and
**coverage-calibrated intervals** (empirical coverage of the shipped `:delta`/`:profile` h²/σ²a
intervals measured on DRAC fir — conservative over-coverage at small n, converging to nominal,
`:profile` > `:delta`; `docs/dev-log/recovery-checkpoints/2026-07-03-interval-coverage.md`). Neither
is a covered-flip — `public_covered_count` stayed **5** throughout the entire arc. **Context:** the
first wave delivered G-A device-resident GBLUP; S1 METIS banked-negative; S2 matrix-free multi-effect
PCG + the matrix-free Monte-Carlo REML FIT (Slices A/B/C + the `:auto` usability layer). This doc is
the honest map of what remained; **the numbered map AND the owed legs are now cleared — doc-25 is
fully closed.**

## Where we are

- **v0.8 engine:** matrix-free SOLVE (q→10⁶) + matrix-free FIT (`fit_multi_effect_mc_reml`,
  recovers exact AI-REML within MC error) + `:auto` exact/matrix-free dispatch. The scale wall is
  broken; the estimator is validated at small scale + (Slice C) a recovery/scale gate.
- **v0.7 engine:** device-resident GBLUP agreement (~1e-15) + benchmark (5.2×→23×) on H100.
- **The honest gap (unchanged):** engine capability keeps outrunning *user reachability* — the
  public covered surface is still the same 5 R-reachable models. (The R twin has since REOPENED —
  V8.6 below connects the matrix-free scale path to the R multi_effect surface as an opt-in, with
  no covered-count change.)

## The remaining work, decomposed

### Stream V8 — v0.8 production-sparse to covered

| Slice | What | Compute | Parallel-safe? | Risk |
|---|---|---|---|---|
| **V8.1 ✅ DONE (2026-07-03)** matrix-free REML loglik | `matrix_free_reml_loglik` — `log\|C\|` by stochastic Lanczos quadrature (matrix-free) + the other REML terms exact; matches the exact `sparse_multi_reml_loglik` within the SLQ MC band (~0.5–1.5 abs at q=300–1000). Stochastic. Enables LRTs / interval machinery. | local | done | — |
| **V8.2 ✅ DONE (2026-07-03)** trace variance reduction | `shared_probes = true` — one full-random probe/solve → all K block traces (`nprobe` solves/iter, not `nprobe·K`), unbiased, tighter-at-equal-budget. | local | done | — |
| **V8.3 ✅ DONE (2026-07-03)** matrix-free intervals | `matrix_free_reml_information` — the AI (average-information) matrix built matrix-free and EXACTLY (working-variate P-projections, no stochastic trace — only the score needs the trace), reproducing the exact Cholesky-factor AI; `matrix_free_ratio_intervals` gives the same delta-method ratio/`h²` intervals as the exact path. Asymptotic (not coverage-calibrated). | local | done | — |
| **V8.4 ⚑ ESTIMAND LEG DONE (2026-07-03)** external comparator | `comparator/matfree_blupf90_neffect.jl` runs `blupf90+` 2.60 AIREMLF90 live on the shared K=3 fixture (q=860); the matrix-free `fit_multi_effect_mc_reml` across-seed mean reaches blupf90's optimum to **≤0.15%** within MC error (nprobe 128 → 0.05%, 512 → 0.15%; blupf90 within ≤0.5 across-seed SD per component; exact-vs-blupf90 3.8e-5). Validates the matrix-free ESTIMAND against an external tool at validation scale (checkpoint `docs/dev-log/recovery-checkpoints/2026-07-03-v84-matfree-blupf90-comparator.md`). **AT-SCALE leg DONE (2026-07-03):** `comparator/matfree_blupf90_atscale.jl` re-runs the 3-way comparison at a ~5× larger q=4060 — exact sparse engine == blupf90 to 4.7e-6, matrix-free reaches the external optimum to ≤1% (nprobe 128→0.95%, 256→0.71%; checkpoint `docs/dev-log/recovery-checkpoints/2026-07-03-v84-atscale-comparator.md`). The exact-infeasible regime (q≫50k) has NO external oracle BY CONSTRUCTION (blupf90 forms the MME too) → validated by the internal exact-agreement + recovery gate, not an oracle. V8.4 is now DONE — externally corroborated at q=860 and q=4060; the exact-infeasible regime is beyond any direct solver (external or exact) by construction. | local | done | med |
| **V8.5 ✅ DONE (2026-07-03)** APY genomic scaling | `apy_genomic_relationship_inverse(G, core)` — inverts only the core×core block + a diagonal conditional-variance correction for non-core (`O(ncore³)` not `O(n³)`). Exact-reduction gate: core=all == full `inv(G+ridge·I)` (matrix diff ~1e-15; GEBV diff 0.0); the approximation converges to the full-inverse GEBV as core grows (corr 0.986→1.0). Validation-scale, supplied-`G`, caller supplies `core`; a sparse/on-device representation + a core-selection algorithm + a scale benchmark remain owed. | local | done | — |
| **V8.6 ✅ DONE (2026-07-03)** R multi-term `(1\|g)` bridge | R twin REOPENED. `fit_payload_v2(...; scale_method=:auto)` + R `engine_control scale_method="auto"` route the existing `target="multi_effect"` surface through `fit_multi_effect(:auto)` — validation-scale = sparse-exact (reduces to the covered dense result, live-bridge verified 2.7e-5), large-scale = experimental matrix-free. Default `:dense` byte-identical (frozen contract). NO covered-count change (opt-in). Paired PRs (engine #251 / hsquared #122). | — | done | — |

### Stream V7 — v0.7 GPU to covered

| Slice | What | Compute | Parallel-safe? | Risk |
|---|---|---|---|---|
| **V7.1 ✅ DONE (2026-07-03)** G-B Float32 | `gpu_genomic_relationship_matrix(...; precision = Float32)` — opt-in mixed-precision `G` GEMM (return always Float64; centering unchanged → same estimand). RUN on tamia H100 (job 360780): Float64 gate held (7.3e-15); Float32 `G` differs by ~1–5e-6 absolute with NEGLIGIBLE GEBV impact (~1e-6) — numerically safe for prediction; but the speedup is MODEST (~1.1–1.4×) and TF32 tensor cores were not engaged (default==pedantic, FP32-level). Honest: Float32 safe but only ~1.2× on this H100; Float64 stays default. `V2-GRM-GPU` stays partial, no covered flip. (checkpoint `docs/dev-log/recovery-checkpoints/2026-07-03-v07-gb-float32-result.md`) | DRAC GPU (done) | — | low-med |
| **V7.2 ✅ DONE (2026-07-03)** G-A cross-device replicate | SAME committed G-A + G-B harnesses re-run on NVIDIA A100 (Narval job 64637092): device-resident GBLUP CPU↔GPU agreement HELD (β/GEBV ~1e-15) + Float64 gate HELD (3.0e-15) → GPU numerical AGREEMENT is architecture-portable (H100 → A100); Float32 same story (FP32-level, TF32 not engaged, modest speedup); A100 device-resident GBLUP benchmark 5.9×→46.7×. Machine-specific, not a competitive A100-vs-H100 claim. (checkpoint `docs/dev-log/recovery-checkpoints/2026-07-03-v07-g72-crossdevice-result.md`) | DRAC GPU (done) | — | low |
| **V7.3 ✅ DONE (2026-07-03)** G-C real marker panel | `sim/drac/g_c_realpanel.jl` benchmarks `gpu_genomic_relationship_matrix` at realistic panel dimensions (LARGE SIMULATED, not a real dataset) + a device-memory profile. RUN on tamia H100 (job 360812): agreement gate 1.35e-14; the GPU HANDLES **n=20k × m=300k** on one H100 (largest cell ~24 GB = 29% of 80 GB; the n×m marker matrix `W` dominates memory, up to 22 GB, not the n×n `G`). Float32 speedup MODEST even at scale (0.96×–1.38×; transfer-bound — the 6–41 s times are dominated by CPU centering + H2D of the huge `W`, not the sub-second GEMM). A feasibility + memory-envelope record, NOT a speed headline. (checkpoint `docs/dev-log/recovery-checkpoints/2026-07-03-v07-gc-realpanel-result.md`) | DRAC GPU (done) | — | low |
| **V7.4 ✅ DONE (2026-07-03)** G-D backend dispatcher | opt-in `backend = :cuda` kwarg on `genomic_relationship_matrix` / `genomic_relationship_inverse` routes to their GPU twins (the GPU analogue of the `:auto` solver dispatch) — the two construction ops whose CPU/GPU signatures match. `backend = :cpu` (default) byte-identical; `:cuda` → `MethodError` without CUDA; invalid backend → `ArgumentError`. NOT the general backend dispatcher (`backend_info()` `:cuda` stays `:planned`); the device-resident GBLUP (`gpu_fit_gblup`, different from-markers signature) stays its own entry point. CI-tested (7 assertions). | local | done | low |
| **V7.5 ✅ DONE (2026-07-03)** G-E close-out | Consolidated the V7 GPU stream: `status_cache.json` pointer refreshed (→ current HEAD, 55/13/5); the whole `V2-GRM-GPU` evidence chain (G-A device-resident GBLUP + G-B Float32 + G-7.2 cross-device A100 + G-C large-panel + G-D dispatcher) verified coherent by a final Rose consolidation. NO status flip — `V2-GRM-GPU` stays `partial` (no covered move; the honest summary is: GPU acceleration is numerically-exact + architecture-portable + handles realistic panels, but Float32 is only a minor win and there is no R-public surface). The **v0.7 GPU stream (V7.1–V7.5) is COMPLETE**. | local | done | low |

### Cross-cutting

- **Covered-flip discipline:** each covered claim needs a pre-declared gate + external comparator
  + real Rose. Engine-covered ≠ public-covered; `public_covered_count` stays 5 regardless (these
  are engine perf/scale/agreement, not new R-public models).

## Dispatch plan (how to run it economically)

Two **independent hardware streams**, as in the first wave — V7 on DRAC GPU, V8 on DRAC CPU +
local — so they run concurrently with zero contention. Within a session:

1. **V8.1 + V8.2 together** (loglik + variance reduction) — both touch the matrix-free trace
   machinery; do them as one coherent Julia slice, local-gated, then a small fleet timing.
2. **V8.3** (intervals) after V8.1 (needs the log-det for the information).
3. **V7.1 + V7.2 + V7.3** fan out across GPU clusters in one campaign (like the G-A fleet run) —
   each a pre-declared agreement+benchmark; dispatch to one sub-agent per cluster if parallelizing.
4. **V8.4** (comparator) + **V8.5** (APY) are the two biggest remaining engine pieces; sequence
   after V8.1-3.
5. **V7.4 + V7.5** and the V8 close-outs consolidate at the end.

Each slice: implementation + local correctness gate + (if perf/scale) a pre-declared fleet
benchmark + Rose + status + after-task. Verify by independent reproduction (Rose re-runs numbers).
Consolidate per stream with a paired PR.

## Honest completion estimate

At the first-wave cadence (~1 focused session/day, DRAC queues behaving):

- **v0.7 to covered** (V7.1–V7.5): ~**3–4 sessions** — G-B is the only real build; the rest are
  fleet replicates + dispatcher + close-out. Lower risk.
- **v0.8 to covered** (V8.1–V8.5; V8.6 R connection DONE 2026-07-03): ~**5–8 sessions** — the loglik +
  intervals + APY are genuine new machinery, and a covered flip needs the comparator + gate to
  actually pass (science risk).
- **Both, end-to-end:** realistically **2–3 weeks** of focused sessions, gated by (a) DRAC queue
  time, (b) whether the recovery/comparator gates pass first try. (The R lane has reopened; V8.6 is
  DONE. Further *public covered* surfacing of the matrix-free path would still need its own R gate —
  the current V8.6 connection is an opt-in experimental route, not a covered-count move.)

**The honest ceiling:** without reopening the R twin, this arc can reach *engine*-covered for both
versions in ~2–3 weeks, but the capability stays unreachable by R users. The single highest-impact
decision is not on this list — it is whether/when to **reopen the R lane** and convert ~6 months of
engine work into user-facing capability. That is a maintainer decision, flagged here as the real
gate to impact.

## Recommended next session

**V8.1 + V8.2** (matrix-free loglik + variance reduction) — highest-leverage: it completes the
matrix-free fit into a *full* REML fit (loglik → LRTs → intervals) and makes it cheaper at scale,
all Julia-lane-solo-safe. Then the V7 GPU fan-out (G-B + cross-device) as an independent parallel
campaign.
