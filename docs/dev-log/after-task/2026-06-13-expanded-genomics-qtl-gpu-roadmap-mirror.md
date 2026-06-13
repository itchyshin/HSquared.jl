# Expanded Genomics QTL GPU Roadmap Mirror

Date: 2026-06-13

Active lenses: Ada, Shannon, Jason, Karpinski, Hopper, Rose, Pat, Grace.

Spawned subagents: none.

## Goal

Mirror the R twin's expanded genomics/QTL/GLLVM/GPU/HPC plan into Julia
Documenter and design memory while keeping every new item as roadmap/status
only.

## R Handoff

R commits:

- `f806a96 Expand genomics QTL GPU plan`;
- `2c18b30 Record expanded plan CI evidence`.

Reported R evidence for the evidence commit:

- R-CMD-check `27459454821`: success;
- pkgdown `27459454815`: success;
- Pages `27459486904`: success.

R boundary:

- no genomic fitting claim;
- no QTL/eQTL scan claim;
- no GLLVM animal-model claim;
- no GPU execution claim;
- no APY, Takahashi selected inverse, AI-REML, HPC, or performance claim.

## Julia Action

Added:

- `docs/src/backend-algorithm-roadmap.md`;
- `docs/design/09-backend-algorithm-roadmap.md`.

Updated:

- `docs/make.jl`;
- `docs/src/index.md`;
- `docs/src/genomics-qtl-gpu-hpc.md`;
- `docs/src/roadmap.md`;
- `docs/src/changelog.md`;
- `ROADMAP.md`;
- `docs/design/00-ecosystem-lessons.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/08-genomics-qtl-gpu-hpc-plan.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`.

The new Documenter page records:

- backend vocabulary for CPU, threads, CUDA, AMDGPU, Metal, oneAPI, and auto;
- optional extension policy;
- CPU-first, GPU-friendly, and hybrid work placement;
- algorithm leads for sparse MME, sparse REML/ML, AI-REML, warm starts,
  Newton/trust-region refinement, PCG, Takahashi selected inversion,
  Woodbury/determinant-lemma paths, and APY;
- numerical policy and claim gates.

The public R grammar example now uses `precision(1 | id, Q = Q)`. The Julia
qualification `HSquared.precision()` is documented separately for direct Julia
calls.

## Checks

- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; generated Vitepress dependencies reported npm
  advisories in temporary build artifacts.
- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals sum to
  294 checks.
- `git diff --check`: passed.
- Edited-file ASCII scan: no matches.
- Claim scan: clean with limitations. Hits were status, audit, planned, or
  blocked-wording rows, not unsupported claims.

Remote checks: pending.

## Public Claim Audit

Allowed wording:

- backend and algorithm roadmap is documented;
- backend names are status/control metadata;
- CPU is the trusted baseline;
- GPU, APY, AI-REML, Takahashi selected inversion, GLLVM acceleration, QTL/eQTL,
  and HPC workflows are roadmap targets.

Blocked wording:

- GPU execution works;
- CPU and GPU agree;
- backend auto-selection works;
- APY, AI-REML, or Takahashi selected inversion is implemented;
- genomic, QTL/eQTL, or GLLVM models fit;
- `HSquared.jl` is faster than ASReml, JWAS, GLLVM.jl, or another comparator.

Rose verdict: clean with limitations.

## Tests Of The Tests

This was a documentation/status slice. Existing Julia tests still passed after
navigation and design files changed. Documenter built the new page and
cross-links locally.

## Coordination Notes

- Julia lane only. No R repo edits were made.
- R syntax remains the public authority.
- `result_payload()` and engine APIs were not changed.
- The next bridge-impacting changes still need R/Julia lockstep coordination.

## What Did Not Go Smoothly

- None beyond expected care around wording. The main risk was avoiding a
  roadmap page that reads like an implementation page.

## Known Limitations

- The new page is roadmap and design memory only.
- No backend dispatch, GPU execution, CPU/GPU agreement test, genomic fitting,
  QTL/eQTL scan, GLLVM animal model, APY, AI-REML, Takahashi selected inverse,
  or HPC checkpointing was implemented.
- The phase order changed in the broad roadmap, but existing formula-status
  rows remain conservative until a lockstep R/J syntax update is required.

## Next Actions

1. Push and watch CI/Documenter/Pages for this documentation slice.
2. Add remote evidence once checks complete.
3. Continue Phase 1 validation work before promoting any later-phase roadmap
   item.
