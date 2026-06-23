# Handover — AI-REML boundary fix in flight + Wave F plan (2026-06-23)

**Lane:** one owner, both repos (`hsquared` R + `HSquared.jl` Julia), one cross-repo DoD.
**Julia `main` at `997294af`** (#181 merged). **One slice is IN FLIGHT, not yet merged: PR
#182.** Read this top-to-bottom, then `docs/dev-log/handover/2026-06-23-wave-f-session-handover.md`
(the deeper Wave-F kickoff handover) + `docs/design/17-wave-F-foundation-and-genomic-gpu.md`
(the full two-track plan) + `docs/dev-log/scout/2026-06-23-production-sparse-algorithms.md`
(citation-backed algorithm scout; **METIS overturned by measurement**).

---

## 0. ALREADY DONE — PR #182 is MERGED (start at §3)

**PR [#182](https://github.com/itchyshin/HSquared.jl/pull/182) MERGED** to `main` as squash
commit `4b5e000e` (all four checks green: Julia 1, Julia 1.10, docs, documenter). This
section is kept for the record; **there is nothing to do here — begin at §3.** One loose
thread: a **real Rose audit** (`rose-systems-auditor`) was still running at merge time
(merge was on green CI + explicit maintainer authorization, this being a bugfix with no new
public claim); **check its verdict in the chat log / after-task and open a follow-up only if
it flagged something real.**

It fixed the flaky CI failure in the single-step fitting test (`fit_ai_reml could not keep
variance components positive`).

- **What the fix is:** the σ²a→0 boundary `throw` → graceful `break` (`converged=false`,
  finite positive σ) + an `isfinite(step)` guard. **Root cause** (systematic debugging): the
  single-step fixture has no genetic signal → REML optimum sits at the σ²a→0 boundary → the
  *finite* Newton step is large relative to a tiny σ²a → 60 step-halvings can't keep `a_new`
  positive → throw. Deterministic on Linux CI; on a Mac it grinds to the 100-iter cap instead
  → the flake. NOT a NaN step (first hypothesis, disproved); NOT caused by F1/F3.
- **Evidence:** new deterministic regression testset (`fit_ai_reml graceful σ²→0 boundary`,
  both fixtures threw pre-fix); full local `Pkg.test()` green (`JULIA_EXIT=0`); V1-REML
  capability-status + validation-debt boundary clauses updated to "always finite positive,
  `converged=false`, never throws". Funnel: `docs/dev-log/check-log.d/` +
  `docs/dev-log/after-task/2026-06-23-aireml-boundary-graceful.md`.
- **Status:** merged on green CI (squash `4b5e000e`); branch deleted; `main` synced. No
  action needed.
- **If Rose returned findings you haven't seen:** the audit asked it to check the key risk —
  *can the graceful `break` stop a HEALTHY (interior-optimum) fit prematurely?* The argument
  is no: 60-halving exhaustion only happens at tiny σ + large step (the boundary); a fit with
  σ = O(1) recovers in a few halvings. Confirm Rose agreed.

---

## 1. The bigger plan — Wave F (two co-equal tracks)

Full spec: `docs/design/17-wave-F-foundation-and-genomic-gpu.md`. **Direction = foundation-first;
ambition = build → prove → bank; NO `covered` promotion this wave** (promotion is the *next*
wave, with evidence pre-banked). Two tracks on different clusters, no contention:

### Goal & success criteria (doc 17 §"Goal")
A **production (non-experimental) sparse REML default fit path**, proven correct + honestly
benchmarked at real-pedigree scale, **plus** a GPU-accelerated genomic path validated by
CPU↔GPU agreement. "Done" =
1. hardened AI-REML is the **default** fit path (not NelderMead, not "experimental") — **F4**;
2. correct at **q ≥ 10⁵** (MME self-consistency at fitted VCs + `selinv == dense` on subsets +
   comparator agreement) — **F5**;
3. honest **wall-clock + peak-memory** at q = 10⁴→10⁵(→10⁶) *with* fill-reducing ordering —
   **F2/F6**;
4. same-estimand **agreement** with `sommer` + `pedigreemm` at matched sizes — **F8**;
5. genomic ops (`G`/`Ginv`, GBLUP, marker scan, low-rank) on GPU with a **CPU↔GPU agreement
   test** + honest benchmark — **G1–G4**;
6. **every number traces to a committed sbatch script + summary doc** (repo state is truth).

### Honesty fences (explicit non-goals this wave)
- **No `covered` promotion** — rows stay `partial`/`experimental` and *gain* evidence.
- **GPU = acceleration, not a new statistical claim** — must be numerically identical (to
  tolerance) to its CPU twin.
- **GPU helps dense ≫ sparse** — lead Track B with dense genomic ops; GPU-sparse REML is a
  later stretch, not this wave.
- **No production claim before committed scale evidence.**

---

## 2. Where Wave F stands (what's done vs open)

**Track A — production sparse foundation (CPU), Fir `def-snakagaw_cpu`:**
- **S0 harness** — `sim/drac/` committed (`f0_scale_benchmark.jl`, `f2_ordering_experiment.jl`,
  sbatch templates; results → `sim/drac/results/`). *Verify the formal ingestion-script + a
  pure-logic CI test exist; complete that S0 sub-item if not.*
- **F0 measure-first** ✅ — benchmark ran on DRAC; named the next wall each step.
- **F1 (#179)** ✅ — **Meuwissen–Luo O(n) inbreeding** replaces the dense O(n²) that capped
  `pedigree_inverse` at q=10⁴. Ainv build at q=300k = 0.337 s.
- **F2 ordering** — **RE-SCOPED by measurement.** The sparse Cholesky is 0.15 s at q=300k and
  METIS cuts fill ~1% on the **shallow half-sib** benchmark → **METIS NOT implemented, no dep
  added.** The honest next step is a **DEEP multi-generation pedigree** (real fill-in + deeper
  inbreeding path) to re-measure whether factorization ever becomes the wall. Do NOT add METIS
  until a deep benchmark re-opens it.
- **F3 (#180)** ✅ — **scale-invariant AI-REML convergence** (stop on *relative* VC change, not
  the absolute score that scales with n): q=300k 35.6 s→2.3 s (15.5×). **#182 (in flight) is
  further F3/B5 hardening** (graceful boundary).
- **F4–F9 OPEN** — F4 promote AI-REML to the **default** path (the headline milestone, gated on
  F5/F8 evidence); F5 conditioning + deep-inbreeding stress at q≥10⁵; F6 matrix-free PCG
  benchmark; F7 threading/BLAS/allocation pass; F8 comparator vs `sommer` + `pedigreemm`; F9
  bank the benchmark report. **None claims `covered`.**

**Track B — genomic GPU, priority trio (tamia/vulcan/killarney), `aip-snakagaw`:**
- **G0** ✅ — verified on **tamia**: 4× NVIDIA H100 80GB, CUDA.jl `functional=true`, real H100
  matmul. The CUDA.jl offline-binding dance is in the runbook (`Pkg.add` on login node →
  `set_runtime_version!(local_toolkit)` → **re-precompile on login node** → GPU job loads
  cache). Env: `/project/aip-snakagaw/gpu_env`.
- **G1–G5 OPEN, unblocked** — G1 VanRaden `G`/`Ginv` on GPU (GEMM + dense Cholesky); G2
  GBLUP/GREML solve; G3 marker/GWAS scan (batched GLS Wald); G4 low-rank/FA AI-REML; G5 bank.
  **Each = CUDA.jl port + CPU↔GPU agreement gate + honest benchmark.** G1–G4 are largely
  independent (parallelizable). The dense genomic engine already exists (experimental, CPU).

---

## 3. Recommended next moves (after #182 lands)

In rough priority — all DoD-clean, one PR per slice, real Rose audit each:

1. **Track B G1** — VanRaden `G`/`Ginv` on GPU. The trio is idle + verified; dense GEMM is the
   clearest GPU win; G1–G4 are independent so this is high-throughput. **CPU↔GPU agreement to
   tolerance + benchmark vs m markers** is the gate.
2. **Track A deep-pedigree re-measure (F2 honest re-open)** — build a deep multi-generation
   pedigree DGP, re-run F0 at q=10⁵→10⁶ on a Fir 6 TB `cpularge` node; profile selinv vs the
   per-iteration solves + the inbreeding path depth. This decides whether METIS / matrix-free
   PCG (F6) is real work. **Higher-value than more shallow-pedigree runs.**
3. **F8 comparator agreement** (`sommer` + `pedigreemm`, both `module load gcc r`) — the
   same-estimand correctness evidence that F4 promotion will need. Cross-lane (R), no GPU.
4. **Cross-lane non-Gaussian R bridges** — the six engine families merged last session
   (H2 beta-binomial, H3 probit, H7 `nongaussian_heritability`, C2 `genetic_correlation_interval`,
   C6 `bootstrap_variance_component_interval`) have **no R surface**. CPU/logic, no DRAC. Good
   filler when cluster jobs are queued.
5. **Colleau (2002) `A·v`** and **`phylogenetic_inverse`** (Hadfield–Nakagawa sparse
   phantom-parent tree inverse) — scoped in the scout doc; gate on a real consumer.

---

## 4. DRAC compute — how to run the heavy jobs

- **Connect:** `ssh fir` / `ssh tamia` reuse live ControlMaster sockets (12 h, no Duo
  re-prompt). User `snakagaw`. **Accounts:** Fir `def-snakagaw_cpu` / `def-snakagaw_gpu`;
  tamia `aip-snakagaw`. **NEVER run compute on a login node** (`sbatch`/`salloc` only).
- **Repos on cluster:** `~/projects/def-snakagaw/HSquared.jl` (Fir), `/project/aip-snakagaw/HSquared.jl`
  (tamia). **Julia depot on `/project`, NOT purged `/scratch`.** `module load julia/1.10.10`;
  thread-cap `OPENBLAS_NUM_THREADS=2 JULIA_NUM_THREADS=1`.
- **Workflow:** edit `src/*.jl` on the Mac → `scp` changed files to the cluster → `sbatch` →
  watch `squeue` → ingest the `.tsv` into a committed checkpoint doc. **No number reported
  without a committed script + artifact.** Heavy live runs execute on the cluster (or via
  Codex); Claude authors the harness, CUDA code, agreement tests, and logic tests.
- **Full cross-project runbook:** `shinichi-brain/tools/drac-setup.md` (SLURM, GPU, Julia/R,
  per-cluster specs, the verified CUDA-binding fix). The trio (tamia/vulcan/killarney) is
  **priority `aip-` GPU access — use it for GPU work, not relocated CPU work.**

---

## 5. Open items / pending maintainer decisions (NOT mine to decide)

- **J1 haplodiploid kernel** — GATED on maintainer ratification of `A = 2θ` / haploid-drone
  self = 2 + the construction-only fence (`docs/dev-log/decisions/2026-06-22-haplodiploid-relationship-convention.md`).
  The design spec's anchor set is provably IMPOSSIBLE (non-PSD); NO kernel shipped, NO
  capability row. Unchanged this session.
- **Stale `HSquared.jl/CLAUDE.md` §"Lane"** ("Julia engine lane only / do not edit the R repo")
  still contradicts the one-owner model — a doctrine wording fix worth a maintainer nod.
- **Two untracked files are NOT mine** and pre-date these sessions — leave them alone (never
  `git add`): `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`,
  `sim/phase6_nongaussian_interval_coverage.tsv`. Decide commit / gitignore / discard.
- **R repo (`hsquared`) not rehydrated** recently (engine-only sessions). Before any R work,
  run `devtools::check()` early — the last PR-branch R-CMD-check had failed.
- **tamIA CPU partition** — verify whether it exposes a CPU-only partition before routing any
  Track-A benchmark there (`sinfo`); else Fir `def-` only.

---

## 6. Discipline reminders (earned this session)

- **Measure before optimizing** overturned the research-recommended METIS and saved a useless
  dependency. The F0/F1/F3 chain is the template: each slice's after-curve names the next wall.
- **Verify Rose's factual claims** — last session Rose claimed "green suite" on a guarded F3
  variant that actually FAILED CI; CI + a verify caught it. Rose is a lens, not an oracle.
- **Run the FULL suite on the exact committed state before pushing** — two F3 mis-steps (a
  preemptive boundary guard, an `iterations<50` assertion) broke CI and were removed; the core
  fix was correct throughout. Don't pin assertions on a flat-surface fixture's iteration count.
- **Honest status:** nothing is `covered` beyond v0.1 univariate Gaussian. No fitting /
  performance / GPU / genomics claim without the full evidence chain. **Repository state — not
  chat — is the source of truth.**

## Smallest safe next action
Rehydrate (`git log --oneline -8`, `gh pr list`); confirm `main` is at `4b5e000e`+ (#182
merged). Then pick move #1 (Track B G1, trio idle + verified) or #2 (deep-pedigree re-measure)
from §3 — both use DRAC, the env is stood up. Confirm the Rose verdict on #182 was clean (or
open a follow-up) before treating the boundary fix as fully banked.
