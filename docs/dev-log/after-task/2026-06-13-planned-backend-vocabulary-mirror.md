# Planned Backend Vocabulary Mirror

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose.

Spawned subagents: none.

## Goal

Mirror the R twin's planned backend and accelerator vocabulary in Julia
controls, marker types, and public status documentation.

## R Handoff

Verified read-only from the sibling R repo:

- `hsquared` `5feac1f Expand planned backend controls`;
- R-CMD-check `27457948686`: success;
- pkgdown `27457948693`: success;
- Pages `27457985141`: success.

R vocabulary:

- backend: `auto`, `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, `oneapi`;
- accelerator: `auto`, `none`, `gpu`, `cuda`, `amdgpu`, `metal`, `oneapi`.

## Julia Action

Added marker types:

- `ThreadsBackend`;
- `AMDGPUBackend`;
- `MetalBackend`;
- `OneAPIBackend`.

Updated `HSControl()` validation to accept the shared planned backend and
accelerator names.

Updated documentation and repo memory:

- README;
- ROADMAP;
- API docs;
- genomics/QTL/GPU/HPC docs;
- engine contract;
- public claims register;
- capability status;
- validation debt;
- coordination board;
- check-log.

## Public Claim Audit

Allowed wording:

- Julia and R now share planned backend and accelerator vocabulary;
- backend marker types exist;
- `HSControl()` validates backend/accelerator metadata;
- CPU is the trusted always-available path;
- CUDA, AMDGPU, Metal, and oneAPI are future optional-extension markers.

Blocked wording:

- GPU execution works;
- Metal, CUDA, AMDGPU, or oneAPI backends execute model code;
- backend availability diagnostics exist;
- backend benchmarking exists;
- CPU/GPU numerical agreement has been tested.

## Checks

- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed with 197 checks.
- `julia --project=docs docs/make.jl`: passed. Local deployment skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- Claim scan: clean with limitations. Hits were blocked/audit wording or
  historical check-log notes, not public execution or speed claims.
- GitHub CI after push: pending.

Rose verdict: clean with limitations.
