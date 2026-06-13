# Genomics QTL GPU HPC Roadmap

Date: 2026-06-13

Active lenses: Ada, Shannon, Jason, Hopper, Karpinski, Grace, Rose, Darwin,
Falconer, Kirkpatrick.

Spawned subagents: none.

## Scope

Convert the extended planning direction into Julia-side repository memory and a
public Documenter page.

The plan covers:

- R/Julia package architecture;
- formula parity and Julia experimental lanes;
- phenotype, pedigree, genotype, marker, expression, annotation, and
  environment data integration;
- animal-model and inheritance modules;
- genomic prediction;
- QTL/GWAS/eQTL;
- multivariate G matrices;
- GLLVM-style latent-variable integration;
- CPU/GPU backends;
- Mac/Metal, CUDA, AMDGPU, oneAPI, and CPU strategy;
- backend benchmarking;
- HPC workflows;
- validation against Mrode, ASReml, JWAS, XSim, GLLVM, and related tools;
- extractors;
- docs/vignettes;
- roadmap, risks, and minimal implementation path.

## Files

Added:

- `docs/src/genomics-qtl-gpu-hpc.md`;
- `docs/design/08-genomics-qtl-gpu-hpc-plan.md`.

Updated:

- `docs/make.jl`;
- `docs/src/index.md`;
- `docs/src/changelog.md`;
- `docs/dev-log/check-log.md`.

## Source Anchors

Checked current GPU ecosystem sources before writing the backend plan:

- CUDA.jl array and backend docs;
- AMDGPU.jl quick-start docs;
- Metal.jl docs and `MtlArray` docs;
- oneAPI.jl repository;
- KernelAbstractions.jl docs.

## Rose Audit

Verdict: clean with limitations.

The page is allowed because it is explicitly marked as roadmap. It does not
claim that genomic models, QTL/eQTL, GPU, or HPC support is implemented.

Blocked wording remains:

- `HSquared.jl` beats ASReml;
- GPU acceleration works;
- QTL/eQTL/GWAS is implemented;
- GLLVM-style animal models fit;
- HPC workflows are production ready.

Those claims require implementation, validation, benchmarks, and status-table
updates.
