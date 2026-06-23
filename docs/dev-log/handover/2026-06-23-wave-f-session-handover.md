# Handover — Wave F kickoff on DRAC compute (2026-06-23)

**Lane:** one owner, both repos. **Julia `main` at `d5d2b9b1`** (#180 merged). This session
stood up DRAC HPC, opened **Wave F** (production sparse foundation + genomic GPU, two
co-equal tracks per `docs/design/17-wave-F-foundation-and-genomic-gpu.md`), and landed the
first two engine slices by **measure-first** on real q=10⁵–10⁶ pedigrees.

## What landed (both full-DoD, real Rose audit, CI-green, self-merged)

- **F1 (#179) — Meuwissen–Luo O(n) inbreeding.** `src/pedigree.jl` `_meuwissen_luo_inbreeding`
  (T-row accumulation over ancestors via an inline max-heap) replaces the dense O(n²)
  inbreeding that gated `pedigree_inverse` (it built the full n×n `A` just to read its
  diagonal; capped at q=10⁴, ~80 GB at 10⁵). Exact vs the dense oracle (maxdiff 0.0). **DRAC:
  Ainv build at q=300k = 0.337 s** (was impossible past 10⁴). Rose caught a vacuous test
  fixture (a modular rule collapsed to constant parents → 0 inbreeding) — verified + fixed
  (multiplicative-hash mating → genuine bounded inbreeding + anti-vacuous guard).
- **F3 (#180) — scale-invariant AI-REML convergence.** The F1 after-curve flagged
  `fit_ai_reml` as the q=300k wall (35.6 s, non-converged). The plan + the citation-backed
  scout research said "factorization ordering → METIS". **An experiment on the real MME
  overturned that**: the sparse Cholesky is **0.15 s** at q=300k and METIS reduces fill by
  ~1% (the half-sib MME barely fills in) — **METIS not implemented** (no dependency added).
  The real bug: `hypot(score) < tol` is the *absolute* REML score, which scales with n and
  is unreachable at large q — the fit ran to its 100-iter cap with σ̂² already at truth (a
  false-negative `converged`). Fix: also stop on the *relative* VC change.
  **DRAC: q=300k 35.6 s/non-converged → 2.3 s/converged (15.5×), q=100k 2.8 → 0.88 s.**

> **The session's clearest "best algorithm & speed" win was a NEGATIVE result obtained by
> measuring:** the research correctly described what BLUPF90/WOMBAT/YAMS do, but the measured
> bottleneck in this engine was convergence, not ordering. Do not add METIS until a **deep
> multi-generation pedigree** (real fill-in) re-measures as factorization-bound. (The benchmark
> so far is a SHALLOW half-sib pedigree — minimal fill; deep is the honest stress case, and
> also stresses the inbreeding path depth.)

## Track B (GPU, priority trio) — G0 verified

The GPU path WORKS: on **tamia** a whole-node job got **4× NVIDIA H100 80GB** and CUDA.jl
reports **`functional=true` + a real H100 matmul**. The DRAC CUDA dance (the gotcha that cost
two iterations) is now in the runbook: `Pkg.add("CUDA")` → `set_runtime_version!(local_toolkit)`
→ **re-precompile on the login node** (compute nodes have no internet) → GPU job loads the
cache. The genomic-GPU slices (G1 VanRaden `G`/`Ginv`, G2 GBLUP, G3 marker scan, G4 low-rank,
each CPU↔GPU agreement + benchmark) are unblocked. Env on tamia: `/project/aip-snakagaw/gpu_env`
(CUDA.jl bound, local_toolkit). Account `aip-snakagaw`, whole-node `h100:4`/`h200:8`, 24 h cap.

## DRAC compute — how to use it (verified this session)

- **Connect:** `ssh fir` / `ssh tamia` reuse live ControlMaster sockets (12 h, no Duo prompt).
  User `snakagaw`. Accounts: **fir `def-snakagaw_cpu` / `def-snakagaw_gpu`; tamia `aip-snakagaw`.**
- **Repos on cluster:** `~/projects/def-snakagaw/HSquared.jl` (fir, = `/project/6098264/…`),
  `/project/aip-snakagaw/HSquared.jl` (tamia). Julia depot on `/project` (NOT scratch).
  `module load julia/1.10.10`; thread-cap `OPENBLAS_NUM_THREADS=2 JULIA_NUM_THREADS=1`.
- **The harness (committed):** `sim/drac/f0_scale_benchmark.jl` (per-step timing + peak RSS,
  gene-dropping O(q) DGP), `f0_fir.sbatch` / `f0_fir_scale.sbatch` (q arg),
  `f2_ordering_experiment.jl` (AMD-vs-METIS). Results → `sim/drac/results/` (committed for
  provenance). Pattern: edit on Mac → `scp` the changed `src/*.jl` to the cluster → `sbatch` →
  watch `squeue` → ingest the `.tsv`. **Workflow: I author + the heavy live runs execute on the
  cluster; no number reported without a committed script + artifact.**
- **Full runbook (cross-project):** `shinichi-brain/tools/drac-setup.md` (SLURM, GPU, Julia/R,
  per-cluster specs, the verified CUDA fix).

## What's next (recommended order)

1. **Re-measure after F3** — the next wall is no longer obvious (factorization is 0.15 s, the
   fit is 2.3 s at 300k). Run F0 at q=10⁶ on a Fir 6 TB `cpularge` node; profile selinv vs the
   per-iteration solves. **Likely a deep-pedigree benchmark is the higher-value next measure**
   (re-opens the METIS question honestly + stresses inbreeding depth).
2. **Track B genomic GPU (G1–G5)** on the priority trio — the dense ops are GPU-ready now.
3. **Cross-lane non-Gaussian R bridges** (the six engine families H2/H3/H7/C2/C6 have no R
   surface) — CPU/logic, doesn't need DRAC.
4. **Colleau (2002) `A·v`** and the **`phylogenetic_inverse`** (Hadfield–Nakagawa sparse
   phantom-parent tree inverse) are scoped candidates in the scout doc — gate on a consumer.

## Open items / pending decisions (the maintainer's)

- **J1 haplodiploid kernel** — still GATED on maintainer ratification of `A = 2θ` / drone-2 +
  the construction-only fence (`docs/dev-log/decisions/2026-06-22-haplodiploid-…`). Unchanged.
- **Stale `HSquared.jl/CLAUDE.md` §13** ("Julia engine lane only / don't edit R") still
  contradicts the one-owner model — a doctrine wording fix worth a maintainer nod (NOT done).
- **Two untracked files** in the tree are not mine and pre-date this session
  (`docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`,
  `sim/phase6_nongaussian_interval_coverage.tsv`) — decide commit / gitignore / discard.
- **R repo (`hsquared`) not rehydrated** this session (Track A was engine-only). Per the prior
  handover, run `devtools::check()` early before any R work (the last PR-branch R-CMD-check
  had failed).

## Discipline lessons (this session, for the next)

- **Measure before optimizing** overturned the research-recommended METIS and saved a useless
  dependency. The F0/F1/F3 chain is the template: each slice's after-curve names the next wall.
- **Verify Rose's factual claims** — Rose audited the GUARDED F3 and claimed "green suite," but
  the guarded code actually FAILED CI (a flat-surface test). CI + a verify caught it.
- **My two F3 mis-steps** (a preemptive boundary guard, then an `iterations < 50` assertion)
  both broke CI and were removed. The core convergence fix was correct throughout; the lesson
  is to run the FULL suite on the exact committed state before pushing, and to not pin
  assertions on a flat-surface fixture's iteration count.
- **Nothing promoted to `covered`** — public default is still v0.1 univariate Gaussian.

## Smallest safe next action

Rehydrate (`git log --oneline -8`, `gh pr list`), read this handover + the scout doc + doc 17.
Then either (a) drive Track B G1 (genomic GPU, the trio is idle and verified), or (b) build the
deep-pedigree benchmark and re-measure Track A's next wall. Both use DRAC; the env is stood up.
