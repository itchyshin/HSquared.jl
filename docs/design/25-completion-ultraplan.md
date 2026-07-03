# doc-25 — Ultra-plan: completely finishing the v0.7 + v0.8 arc

**Authored:** 2026-07-02 (Claude, autonomous session). **Method:** ultra-plan (decompose →
dispatch → verify → consolidate). **Status:** PLAN for the next sessions. **Context:** this
session delivered the v0.7/v0.8 *first wave* (G-A device-resident GBLUP; S1 METIS banked-negative;
S2 matrix-free multi-effect PCG + the matrix-free Monte-Carlo REML FIT: Slices A/B/C + the `:auto`
usability layer). This doc is the honest map of what remains to take BOTH versions to their
covered gates, and the strategic fork underneath.

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
| **V8.4** external comparator at scale | blupf90/sommer same-estimand through the sparse/matrix-free path on a large fixture (the S3 comparator leg) | fleet | partly (needs blupf90) | med |
| **V8.5 ✅ DONE (2026-07-03)** APY genomic scaling | `apy_genomic_relationship_inverse(G, core)` — inverts only the core×core block + a diagonal conditional-variance correction for non-core (`O(ncore³)` not `O(n³)`). Exact-reduction gate: core=all == full `inv(G+ridge·I)` (diff 0.0); the approximation converges to the full-inverse GEBV as core grows (corr 0.986→1.0). Validation-scale, supplied-`G`, caller supplies `core`; a sparse/on-device representation + a core-selection algorithm + a scale benchmark remain owed. | local | done | — |
| **V8.6 ✅ DONE (2026-07-03)** R multi-term `(1\|g)` bridge | R twin REOPENED. `fit_payload_v2(...; scale_method=:auto)` + R `engine_control scale_method="auto"` route the existing `target="multi_effect"` surface through `fit_multi_effect(:auto)` — validation-scale = sparse-exact (reduces to the covered dense result, live-bridge verified 2.7e-5), large-scale = experimental matrix-free. Default `:dense` byte-identical (frozen contract). NO covered-count change (opt-in). Paired PRs (engine #251 / hsquared #122). | — | done | — |

### Stream V7 — v0.7 GPU to covered

| Slice | What | Compute | Parallel-safe? | Risk |
|---|---|---|---|---|
| **V7.1** G-B Float32 | mixed-precision device path + accuracy characterization vs Float64 (honest accuracy-vs-speed fence) | DRAC GPU | yes | low-med |
| **V7.2** G-A cross-device replicate | agreement gate on a 2nd/3rd GPU architecture (Narval A100, Killarney/Vulcan H100) | DRAC GPU | yes | low |
| **V7.3** G-C real marker panel | real (or realistic large) genotype panel benchmark + memory profile | DRAC GPU | yes | low |
| **V7.4** G-D backend dispatcher | `control`/`AutoBackend` → `:cuda` routing (the GPU analogue of the `:auto` solver dispatch just built) | local | yes | low |
| **V7.5** G-E close-out | Rose + status flip of `V2-GRM-GPU` evidence (no public move) | local | Rose-gated | low |

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
