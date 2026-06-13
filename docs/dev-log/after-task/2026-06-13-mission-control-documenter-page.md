# Mission-Control Documenter Page

Active lenses: Ada, Shannon, Hopper, Emmy, Karpinski, Grace, Rose, Pat.
Spawned subagents: none.

## Goal

Add a dashboard-style page for the Julia lane that mirrors the
`hsquared` / `HSquared.jl` operating system: one R language, one Julia engine,
and one evidence gate.

## Files Changed

- `README.md`
- `docs/make.jl`
- `docs/src/index.md`
- `docs/src/mission-control.md`
- `docs/src/roadmap.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-13-mission-control-documenter-page.md`

## Implementation

The page is a static Documenter page with embedded HTML/CSS. It reports:

- current Julia lane status;
- R twin boundary;
- phase board from ecosystem learning through HPC scaling;
- current evidence rows;
- blocked claims;
- active review lenses.

The page is intentionally not a runtime dashboard and does not query GitHub,
CI, or local state.

## Checks

- `julia --project=docs docs/make.jl`: passed. Local deployment was skipped as
  expected outside CI; Vitepress dependency installation reported the existing
  generated/transient npm advisory noise.

## Public Claim Audit

Allowed wording:

- the Julia docs include a mission-control dashboard;
- the dashboard summarizes implemented, experimental, and planned status.

Blocked wording:

- production fitting is available;
- production sparse reliability or PEV is available;
- GPU execution, backend benchmarking, or CPU/GPU agreement is available;
- genomic prediction, QTL/eQTL, GLLVM, or non-standard inheritance fitting is
  available.

## Coordination Notes

The R repo had a recent sparse REML validation commit with CI still running
when this Julia page was added. R-side dashboard edits should wait for a clean
R checkpoint and then mirror the same status separation in pkgdown.

## Next Actions

1. Add the matching R pkgdown article once the R lane is clean and current CI
   is settled.
2. Record remote Documenter/Pages evidence after this page is pushed.
