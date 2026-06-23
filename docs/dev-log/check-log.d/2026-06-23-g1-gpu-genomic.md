# Check log — Wave F / Track B G1: GPU VanRaden G/Ginv (authored; CPU↔GPU run pending)

**2026-06-23 · Wave F, Track B (genomic GPU), slice G1.** `[JL]` engine + infra; no
`covered` promotion; no R edit.

## What landed

The GPU twins of the CPU VanRaden genomic ops, as a `CUDA` weak-dep package extension —
the SAME architecture as `HSquaredMakieExt` (GPU deliberately OUT of CI, cost discipline):

- `Project.toml`: `CUDA` in `[weakdeps]` + `HSquaredCUDAExt` in `[extensions]` + compat
  `CUDA = "5"`.
- `src/gpu_ext.jl` (NEW): EXPORTED method-less STUBS `gpu_genomic_relationship_matrix` /
  `gpu_genomic_relationship_inverse` (+ docstrings); no GPU work in `/src`.
- `ext/HSquaredCUDAExt.jl` (NEW): the GPU methods. They REUSE the validated CPU
  `centered_markers` verbatim (identical allele frequencies, VanRaden scale `k`, input
  guards → the SAME estimand), run only the dense `W·Wᵀ/k` GEMM (+ `:vanraden2`/weighted)
  and the ridge `inv(G + ridge·I)` Cholesky inverse (CUSOLVER, with the same non-PD →
  `ArgumentError` contract as the CPU twin) on-device, and copy back to a CPU
  `Matrix{Float64}` (a drop-in for the CPU result → CPU↔GPU check is a direct `≈`). Float64.
- `sim/drac/g1_gpu_genomic.jl` (NEW): opt-in CPU↔GPU agreement (HARD-FAILS on mismatch,
  covers `:vanraden1`/`:vanraden2`/weighted G + the ridge inverse from both CPU- and
  GPU-built G + the `(G+rI)·Ginv ≈ I` true-inverse check) + a CPU-vs-GPU benchmark sweeping
  marker count m (G build) and recording the Ginv solve. Writes a TSV; deterministic DGP.
- `sim/drac/g1_tamia.sbatch` (NEW): tamia GPU job (`aip-snakagaw`, whole-node `h100:4`,
  `cuda/12.6 julia/1.10.10`, the bound depot from G0); fails fast on a non-functional CUDA.
- Funnel: capability-status (new GPU row), validation-debt (`V2-GRM-GPU`), `validation_status()`
  (`V2-GRM-GPU`, partial; 47→48), `docs/src/api.md` `@docs` entries.

## Checks run and exact outcomes

- **Package loads without CUDA** (`julia --project=. -e 'using HSquared'`): OK; both stubs
  are method-less `Function`s; calling them throws `MethodError` (verified directly).
- **Full `Pkg.test()` green** (thread-capped, julia 1.10.0, "Testing HSquared tests passed");
  the NEW `@testset "gpu genomic relationship stubs (HSquaredCUDAExt weak-dep, Wave F G1)"`
  is 7/7. **CUDA never loaded in CI** (not in the test env — same as Makie).
- **`docs/make.jl` green** (DocumenterVitepress build complete; the two new exports are in
  `api.md`).
- CPU-side of the agreement script verified locally (the data generator yields no
  monomorphic columns; CPU `:vanraden1`/`:vanraden2`/weighted G + the ridge inverse +
  `(G+rI)·Ginv ≈ I` all run/hold) — only the GPU path is the untested variable.
- Real `rose-systems-auditor`: **CLEAN**. Verified the GPU methods reproduce the CPU
  estimand by construction (reuse `centered_markers`; `:vanraden1`/`:vanraden2`/weighted +
  the ridge inverse + the non-PD `ArgumentError` are algebraically identical to the CPU
  twins, line-by-line), confirmed CUDA stays OUT of CI (weak-dep, not in `[targets].test`;
  stub test valid), and confirmed **NO overclaim** — every artifact that could imply the GPU
  works is fenced with "no number until a run lands". Two non-blocking flags: the sbatch
  `JULIA_DEPOT_PATH` is an assumption (caveated inline; the job fails fast on non-functional
  CUDA), and only the tamia launcher exists (the script is device-agnostic). No changes
  required.

## Honesty / boundary (the load-bearing point)

The CUDA code cannot run on the dev Mac (no NVIDIA GPU). So this slice lands the AUTHORED
G1: code + agreement test + benchmark + sbatch, locally verified at the stub/CPU/docs level.
**The CPU↔GPU agreement and the GPU benchmark have NOT been executed on a GPU** — NO
agreement or performance number exists yet. All three status rows say exactly this; the
evidence is OWED, pending a committed tamia run + its ingested `.tsv` (doc 17 execution
model: "no reported timing/agreement number without an actual run + a committed script").
GPU = acceleration, not a new estimand; nothing promoted to `covered`.
