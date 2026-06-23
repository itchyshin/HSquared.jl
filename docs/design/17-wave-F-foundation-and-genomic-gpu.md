# Wave F — Production sparse foundation + genomic GPU (two co-equal tracks)

**Status:** design (brainstormed 2026-06-23, awaiting maintainer review). **Not yet
implemented.** Branch of record for planning: `claude/wave-f-foundation-gpu-plan`.

**Supersedes/extends:** the next "big set of slices" after
[`15-backlog-wave-execution-plan.md`](15-backlog-wave-execution-plan.md). Draws slices
from [`14-program-backlog.md`](14-program-backlog.md) waves **B** (Gaussian hardening →
production sparse), **K** (performance & scale), and the genomic half of **F/G**. Honesty
gates per [`16-promotion-gate-predicates.md`](16-promotion-gate-predicates.md). Genomic/GPU
context in [`08-genomics-qtl-gpu-hpc-plan.md`](08-genomics-qtl-gpu-hpc-plan.md). Compute
runbook: `shinichi-brain/tools/drac-setup.md`.

## Why this wave now

The Digital Research Alliance of Canada (DRAC) clusters became available this session —
general-purpose CPU clusters (`def-` access: Fir/Nibi/Rorqual/Trillium/Narval) **and**
priority `aip-` access on three GPU clusters (**tamia / vulcan / killarney**). This
unblocks two things the roadmap had deferred:

- the **K-wave**, explicitly *hardware-gated* (no GPU/benchmark before); and
- the expensive **scale/benchmark** evidence that could not run on a laptop.

## Decisions captured (this brainstorm)

1. **Direction = Foundation-first.** Build the production sparse path before promotions or
   speculative GPU-sparse work.
2. **Ambition = build → prove → bank.** Land + harden + scale-prove + honestly benchmark.
   **No `covered` promotion this cycle** — promotion (Rose + maintainer + same-estimand
   parity) is the explicit *next* wave, with evidence pre-banked.
3. **Two co-equal tracks** running in parallel (different code paths, no contention):
   **Track A** = production sparse REML (CPU); **Track B** = genomic GPU.
4. **Use the priority GPU trio for GPU work, not relocated CPU work.** The `aip-`
   allocation is for GPU/AI; pure-CPU REML benchmarking belongs on `def-` GP clusters.
   Running CPU-only jobs on whole-node GPU machines strands H100/H200/L40S.
5. **Routing:** Track A on **Fir `def-`** (192-core / 750 GB; 6 TB large-mem nodes for the
   10⁶ stretch); Track B on the **priority trio** — GPU work only; its whole-node GPU
   machines are reserved for genuine GPU compute (consistent with decision 4). tamIA's
   CPU-only partition (*if* it exists — verify) is a **fallback** for single-node Track-A
   benchmark points if Fir queues are slow, never the primary.
6. **Scale targets:** Track A q = 10⁴ → **10⁵ firm** → 10⁶ stretch. Track B large
   (n individuals, m markers), where dense GPU linear algebra wins.
7. **Comparators (Track A):** `sommer` + `pedigreemm` (both R, both REML, installable via
   `module load gcc r`); BLUPF90 opt-in.

## Goal & success criteria

A **production (non-experimental) sparse REML fit path that is the default**, proven
correct and honestly benchmarked at real-pedigree scale; plus a **GPU-accelerated genomic
path** validated by CPU↔GPU agreement and benchmarked at scale. "Done" =

1. hardened AI-REML is the **default** fit path (not NelderMead, not "experimental");
2. correct at **q ≥ 10⁵** (MME self-consistency at fitted VCs + `selinv == dense` on
   subsets + comparator agreement);
3. honest **wall-clock + peak-memory** at q = 10⁴→10⁵(→10⁶) *with* fill-reducing ordering;
4. same-estimand **agreement** with `sommer` + `pedigreemm` at matched sizes;
5. genomic ops (`G`/`Ginv`, GBLUP/GREML, marker scan, low-rank) run on GPU with a
   **CPU↔GPU numerical-agreement test** (match to tolerance) + an honest GPU benchmark;
6. **every number traces to a committed sbatch script + summary doc** (repo state is
   truth); each slice DoD-clean.

### Honesty fences (explicit non-goals this wave)

- **No `covered` promotion** — that is the next wave (Rose + maintainer + same-estimand
  parity certification). Validation rows stay `partial`/`experimental` and *gain* evidence.
- **GPU = acceleration, not a new statistical claim.** A GPU genomic op must be
  *numerically identical* (to tolerance) to its CPU twin; it does not change estimands.
- **GPU helps dense ≫ sparse.** Lead Track B with dense genomic ops (clear wins);
  GPU-accelerated PCG / sparse REML is a later stretch, after Track A lands.
- **Benchmarks are honest measurements**, reported with the Phase-7 packet (hardware, data
  size, #records/animals/traits/markers/nonzeros, memory, precision, comparator, versions)
  — never a competitive/marketing claim.
- **No production claim before scale evidence** is committed.

## Execution model (Claude ↔ Codex)

Per the hub doctrine: **Claude (planning lane)** authors the harness, the CUDA.jl code, the
CPU↔GPU agreement tests, the analysis/ingestion scripts, and pure-logic tests. **Heavy live
runs** (real large-pedigree fits, GPU benchmarks) execute where Julia runs on real
hardware — Codex, or Claude driving `sbatch` over SSH once the maintainer connects a
session (MFA-gated). **No reported timing/agreement number without an actual run + a
committed script.** Each slice still follows the per-slice recipe (derive → independent
oracle → implement → funnel → checks → real Rose audit → check-log + after-task → one PR).

## Shared · S0 — DRAC reproducibility harness  [JL/infra]

First slice; both tracks depend on it. Deliverables, all committed to the repo:

- `comparator/drac/` (or `sim/drac/`) with **parameterized sbatch templates**: one CPU
  template (Fir `def-`, big-mem, `--time`/`--mem` knobs, `module load StdEnv/2023 julia`)
  and one GPU template (trio, `--gpus-per-node=h100:N`, CUDA.jl).
- **Julia depot setup** documented + scripted to `/project` (not purged `/scratch`); on
  Narval/tamIA the `/project` depot is required.
- **CUDA.jl offline binding:** `CUDA.set_runtime_version!(...; local_toolkit=true)` against
  a `module load cuda`, with `Pkg.add` done on a login node (compute nodes have no
  internet).
- A **results-ingestion script** that reads raw timing/agreement output and writes a
  summary into `docs/dev-log/recovery-checkpoints/` (+ a benchmark report doc). Raw → committed
  summary; never chat-only.
- A tiny pure-logic test of the ingestion/summary code (runs in CI; no cluster needed).

## Track A — Production sparse foundation (CPU), Fir `def-`

| Slice | Backlog | What | Cluster | DoD target |
|---|---|---|---|---|
| **F0** | — | **Measure-first.** Extend `sim/cpu_fit_benchmark.jl` to q=10⁴/3×10⁴/10⁵; time + peak-RSS for Ainv build, MME assembly+factorization, `fit_ai_reml`, PCG solve, selinv. **Find the bottleneck**; confirm two facts: is inbreeding O(n) or O(q²)? is CHOLMOD already AMD-ordering the MME? | Fir big-mem | checkpoint doc; no capability claim |
| **F1** | B3 | **Meuwissen–Luo O(n) inbreeding** in the production Ainv path (only if F0 shows it isn't already O(n)). | Fir | new/updated row; tiny + scaling test |
| **F2** | B4 | **Fill-reducing ordering** for the MME factorization — verify/expose/tune CHOLMOD AMD; add METIS for very large q (the fill-in scaling lever). | Fir | benchmark shows reduced fill |
| **F3** | B5 | **AI-REML convergence hardening** — step control, restarts, PD guards; robust default. | Fir | hardening tests; boundary cases |
| **F4** | B1 | **Promote to the production path** — hardened AI-REML is the default `fit_animal_model` path with production diagnostics; flip V1-REML off "experimental". | — | V1-REML production row; status flip |
| **F5** | B2 | **Conditioning + deep-inbreeding stress at q ≥ 10⁵** (self-consistency; `selinv == dense` on subsets). | Fir big-mem | V1-DENSE-COND large-scale evidence |
| **F6** | K1 | **Matrix-free PCG benchmark** vs direct factorization at q=10⁴→10⁶ — where matrix-free wins on memory (the large-scale enabler). | Fir / 6 TB | V1-PCG benchmark (retires "no benchmark") |
| **F7** | K3 | **Threading + BLAS + allocation/type-stability pass** (Karpinski lens). | Fir | perf pass; allocation report |
| **F8** | K2 | **CPU benchmark vs `sommer` + `pedigreemm`** — same-estimand agreement (correctness) + honest timing/memory at matched sizes. BLUPF90 opt-in. | Fir | comparator-agreement evidence |
| **F9** | — | **Bank it** — benchmark report; V1-REML/V1-EBV gain "scales to 10⁵, benchmarked, comparator-agreed" (stay `partial`); capability-status + check-log + after-task. **Promotion (B8) deferred to next wave.** | — | evidence banked; no promotion |

## Track B — Genomic GPU, priority trio (tamia/vulcan/killarney)

The genomic engine (VanRaden `G`/`Ginv`, GBLUP/GREML, SNP-BLUP, marker/GWAS scan, LOCO,
low-rank/FA) is already built (experimental, dense, CPU) — these are the dense,
matrix-multiply-heavy ops where GPUs win. Each Gx = CUDA.jl port **+ CPU↔GPU agreement
gate + honest benchmark**.

| Slice | Backlog | What | DoD target |
|---|---|---|---|
| **G0** | — | **CPU baseline + CUDA.jl smoke.** Baseline the genomic ops at large (n,m) on a trio node; confirm CUDA.jl runs (depot + `local_toolkit`); pick GPU targets. | checkpoint; GPU "hello" |
| **G1** | K4(part) | **VanRaden `G` build + `Ginv` on GPU** (GEMM + dense Cholesky/inverse). | CPU↔GPU agreement (tol) + benchmark vs m |
| **G2** | F2/K4 | **GBLUP / GREML solve on GPU** (dense linear solve). | agreement + benchmark |
| **G3** | K4 | **Marker / GWAS scan on GPU** (batched GLS Wald). | agreement + benchmark vs (n,m) |
| **G4** | K4 | **Low-rank / FA genomic AI-REML on GPU.** | agreement + benchmark |
| **G5** | — | **Bank it** — GPU benchmark report with the **Phase-7 packet**; CPU↔GPU agreement evidence; capability/validation rows stay `experimental`/`partial` and gain "GPU-agreed + benchmarked"; check-log + after-task. **No covered promotion.** | evidence banked |

## Dependencies & ordering

```
S0  →  ┌─ Track A:  F0 → F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F9
        └─ Track B:  G0 → { G1 ∥ G2 ∥ G3 ∥ G4 } → G5
```

- **S0 first** (both tracks need the harness + depot + ingestion).
- **F0 / G0 are the measure-first openers** — run early to target the work and exercise DRAC.
- Track A is mostly sequential (path hardening). Track B's G1–G4 are largely independent.
- The two tracks run in parallel on different clusters; natural checkpoints at F4 (production
  path lands), F6 (scale proven), G1 (first GPU agreement), G5 (GPU banked).

## Out of scope (the *next* wave)

- Promotion of V1-REML / V1-EBV (and any genomic row) to **`covered`** — needs Rose +
  maintainer + same-estimand parity certification. Evidence is pre-banked here.
- **GPU-accelerated sparse REML / matrix-free PCG on GPU** (the harder, lower-certainty
  win) — a stretch after Track A lands and F6 shows the CPU PCG profile.
- R-side surfacing of production diagnostics (B7) and the genomic-GPU bridge — `[bridge]`
  follow-ons once the engine evidence is banked.

## Open items to resolve at kickoff

1. **Verify tamIA exposes a CPU-only partition** (`sinfo -o "%P %.5a %.11l %.6D %.5c %.9m %G"`;
   `sacctmgr show assoc user=$USER`) before routing any Track-A benchmark there; else Fir
   `def-` only.
2. **Confirm the `aip-` account name** for the trio and the `def-<pi>` account for Fir.
3. **F0 findings** decide whether F1 (inbreeding) and F2 (ordering) are real work or
   verify-and-benchmark.

## Risks

- **Scope:** ~16 slices across two tracks is large; each is independently DoD-clean and
  mergeable, so the wave degrades gracefully if paused at any checkpoint.
- **Benchmark honesty:** numbers depend on node/CPU/GPU model — always report the Phase-7
  packet; treat absolute timings as machine-specific, not universal.
- **GPU-sparse temptation:** resist claiming sparse-REML GPU wins; pedigree systems are
  irregular-sparse and may not beat CPU. Lead with dense genomic.
- **Live-run provenance:** the heavy runs happen off-CI on DRAC — discipline is the
  committed script + ingested summary, audited by Rose like any other evidence.
