# After-task — Wave F / Track B G1: GPU VanRaden G/Ginv (authored; GPU run pending) — 2026-06-23

## Task goal

Wave F, Track B (genomic GPU), slice **G1**: VanRaden `G` build + regularized `Ginv` on
GPU (GEMM + dense Cholesky inverse), gated by a CPU↔GPU numerical-agreement test + an honest
benchmark (doc 17). `[JL]` engine + infra. **No `covered` promotion** (Wave F honesty fence:
rows gain evidence; GPU = acceleration, not a new estimand).

Per the Wave F execution model, Claude **authors** the CUDA.jl code, the agreement test, the
benchmark, the sbatch, and the pure-logic CI test; the **heavy live GPU run** executes on the
priority trio (tamia). This report covers the AUTHORED half — the GPU agreement/benchmark run
is the explicit, pending handoff step.

## What landed

Mirrors the proven `HSquaredMakieExt` weak-dep pattern (GPU is OUT of CI, like Makie):

- `Project.toml`: `CUDA` `[weakdeps]` + `HSquaredCUDAExt` `[extensions]` + compat `CUDA = "5"`.
- `src/gpu_ext.jl` (NEW): EXPORTED method-less stubs `gpu_genomic_relationship_matrix` /
  `gpu_genomic_relationship_inverse` (throw `MethodError` until `using CUDA` activates the
  extension). `/src` stays GPU-dependency-free.
- `ext/HSquaredCUDAExt.jl` (NEW): the device methods. They REUSE the validated CPU
  `centered_markers` verbatim (same allele frequencies, VanRaden scale `k`, input guards), so
  the result is the SAME estimand: only the dense `W·Wᵀ/k` GEMM (+ `:vanraden2`/weighted) and
  the ridge `inv(G + ridge·I)` Cholesky inverse run on the device, copied back to a CPU
  `Matrix{Float64}` (a drop-in for the CPU twin). Non-PD regularized G rethrows the SAME
  `ArgumentError` as the CPU path. Float64 throughout (matches the CPU contract).
- `sim/drac/g1_gpu_genomic.jl` (NEW): opt-in agreement (HARD-FAIL on mismatch) across all G
  variants + the inverse (from CPU-built and GPU-built G) + a `(G+rI)·Ginv ≈ I` true-inverse
  check, then a CPU-vs-GPU benchmark over marker count m. Deterministic DGP; emits a TSV.
- `sim/drac/g1_tamia.sbatch` (NEW): the tamia GPU job (`aip-snakagaw`, whole-node `h100:4`,
  `cuda/12.6`, the G0-bound depot); fails fast if CUDA is not functional.
- Funnel: capability-status row, validation-debt `V2-GRM-GPU`, `validation_status()`
  `V2-GRM-GPU` (partial; 47→48), `api.md` `@docs` entries.

## Checks run and exact outcomes

- `using HSquared` (no CUDA): loads; stubs method-less; calls throw `MethodError` (verified).
- **Full `Pkg.test()` green** (julia 1.10.0, thread-capped, "Testing HSquared tests passed");
  the new GPU stub testset is 7/7; **CUDA never loaded** (not in the test env).
- **`docs/make.jl` green** (DocumenterVitepress build complete).
- **CI (PR #184) green**: all four checks pass (Julia 1, Julia 1.10, docs, documenter/deploy)
  — after fixing a stale row-count assertion (see "What did not go smoothly"). CUDA is OUT of
  CI, so the GPU agreement is deliberately NOT exercised by CI.
- CPU side of the agreement script verified locally (no monomorphic columns; all CPU G
  variants + the ridge inverse + the `(G+rI)·Ginv ≈ I` identity run/hold). The GPU path is
  the only untested variable — by design, it runs on the cluster.
- Real `rose-systems-auditor`: **CLEAN** (no changes required). Verified line-by-line that
  the GPU methods reproduce the CPU estimand by construction, that CUDA stays OUT of CI, and
  that there is **NO overclaim** — every artifact that could imply the GPU works is fenced
  with "no number until a run lands". Non-blocking flags: the sbatch depot path is an
  assumption (caveated, fails fast) and only the tamia launcher exists (script device-agnostic).

## Public claim audit (Rose) — the load-bearing honesty point

The dev Mac has no NVIDIA GPU, so the CUDA methods are **authored but not executed**. The
CPU↔GPU agreement and the benchmark **have NOT run** — there is NO agreement or performance
number yet. Every status row (capability-status, validation-debt `V2-GRM-GPU`,
`validation_status()`) states this explicitly: the evidence is OWED, pending a committed
tamia run + ingested `.tsv`. The slice is a numerical ACCELERATION (same estimand by
construction — it reuses the CPU centering), NOT a new statistical claim and NOT the general
backend dispatcher (`backend_info()` `:cuda` stays `:planned`). Nothing promoted to `covered`.

## What did not go smoothly

- `julia` was not on the non-interactive shell PATH (juliaup at `~/.juliaup/bin`); used the
  full path. An inline `-e` heredoc tripped a shell parse error on an anonymous function —
  switched the CPU-side sanity check to a temp `.jl` file.
- Two GPU-API faithfulness choices, resolved by mirroring the CPU contract exactly: (1) form
  `G + ridge·I` on the CPU before moving to the device (adding `ridge*I` to a `CuMatrix`
  would force disallowed scalar indexing on the diagonal); (2) use a broadcast column-scale
  for the weighted/`:vanraden2` variants (algebraically identical to `Diagonal`, device-safe).
  These are unverified on hardware until the tamia run.
- **A stale `validation_status()` row-count assertion broke CI on the first push.**
  `test/runtests.jl:174` pinned `length(validation) == 47`; the new `V2-GRM-GPU` row made it
  48. Root cause: I added that row AFTER the last full `Pkg.test()` and did not re-run before
  pushing — the exact "run the FULL suite on the committed state before pushing" discipline.
  A pre-edit grep also missed the assertion (it reads a local `validation` variable, not
  `validation_status` on that line). Fixed to `== 48`, re-ran the FULL suite green, amended +
  force-pushed → CI green. Lesson reinforced: re-run after the LAST edit, not the last code edit.

## Next actions

1. ✅ Real `rose-systems-auditor` — **CLEAN**, no changes required (verdict recorded above).
2. Commit on a branch; decide with the maintainer whether to push + open the PR (CI gates the
   CPU suite + stub + docs — green expected; it does NOT and cannot run the GPU agreement).
3. **The handoff:** run `sim/drac/g1_tamia.sbatch` on tamia (maintainer-driven SSH, or Codex),
   ingest the `.tsv` into a committed checkpoint doc, and FLIP the three rows to "CPU↔GPU
   agreed (tol) + benchmarked" — the close-out that banks G1's evidence. Then G2/G3/G4 (the
   independent GPU slices) and G5 (bank).
