# Backend And Algorithm Roadmap

Canonical public page: `docs/src/backend-algorithm-roadmap.md`.

Status: roadmap. This design note records execution strategy only. It does not
claim backend dispatch, GPU execution, CPU/GPU agreement, APY, AI-REML,
Takahashi selected inversion, GLLVM acceleration, or production HPC support.

## Backend Names

Shared R/Julia vocabulary:

- CPU: `CPUBackend()` / `backend = "cpu"`;
- threaded CPU: `ThreadsBackend()` / `backend = "threads"`;
- NVIDIA: `CUDABackend()` / `backend = "cuda"`;
- AMD/ROCm: `AMDGPUBackend()` / `backend = "amdgpu"`;
- Apple/macOS: `MetalBackend()` / `backend = "metal"`;
- Intel: `OneAPIBackend()` / `backend = "oneapi"`;
- automatic metadata: `AutoBackend()` / `backend = "auto"`.

Current implementation:

- marker types exist;
- `HSControl` accepts the vocabulary;
- `backend_info()` reports rows as selectable and execution unavailable.

Current non-implementation:

- no device probing;
- no backend dispatch;
- no GPU kernels;
- no benchmark or agreement evidence.

## Algorithm Leads

Phase 1 production fitting should proceed through sparse mixed-model equations
and a sparse REML/ML optimizer before broadening to accelerators.

Development leads:

- sparse Henderson MME for EBVs/BLUPs;
- sparse REML/ML objective and later AI-REML;
- EM or PX-EM starts where variance components are fragile;
- Newton or trust-region refinement after stable starts;
- PCG and block preconditioners for very large systems;
- Takahashi selected inversion for selected PEV/reliability entries after
  sparse factorization exists;
- Woodbury and determinant lemma for factor-analytic G matrices and
  GLLVM-style likelihoods;
- APY approximation for genomic and single-step phases only.

Local references:

- `DRM.jl/src/takahashi_selinv.jl`: selected inverse algorithm lead;
- `GLLVM.jl/src/fit.jl`: profiled low-rank likelihood and hot-path design lead;
- `GLLVM.jl/src/structured_schur.jl`: structured precision and Woodbury-style
  design lead.

These references are not implementation imports. Code reuse requires license,
provenance, tests, and explicit review.

## Backend Placement Rule

CPU-first:

- pedigree validation;
- ID recoding;
- sparse `Ainv`;
- symbolic sparse factorization;
- small animal models.

GPU-friendly later:

- dense genomic matrix operations;
- marker matrix products;
- large response matrices;
- factor-analytic and GLLVM likelihood blocks;
- simulation, bootstrap, and prediction batches.

Hybrid later:

- sparse iterative solvers;
- GPU matrix-vector products plus CPU preconditioners;
- CPU sparse factorization plus GPU dense updates;
- single-step models with sparse `A` and dense `G`.

## Promotion Gate

Before any algorithm or backend moves from roadmap to public capability, update:

- implementation;
- tests;
- Documenter;
- capability status;
- validation debt;
- public claims register;
- check-log evidence;
- after-task report;
- R bridge contract where user-facing syntax or results change.
