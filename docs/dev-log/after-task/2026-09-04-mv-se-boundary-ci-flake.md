# After-task — n=8 mv covariance SE CI flake

Date: 2026-09-04. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/mv-se-flake-20260904`. Type: pre-existing CI flake (not #303).

```
PLATFORM: cursor | LANE: cursor/mv-se-flake-20260904
OTHER LANES: Codex #274 genomic · cursor #303 DRAFT LLM disclosure (do not merge)
Active lenses: Ada / Shannon fence · Gauss / Curie (perspectives)
Spawned subagents: none
Current lane: scratch WT — Dropbox FOREIGN
```

## Goal

Harden the Phase 4 n=8 single-record unstructured SE throw so Julia 1.10
CI cannot go red when the FD Hessian looks PD at `|r_g|≈1`. Seen on
DRAFT #303 (docs-only); rerun of the same SHA passed. Separate slice;
do not merge #303; do not touch LLM disclosure.

## What landed

- Helper rejects `|r| ≥ 1−1e-6` before the Hessian (documented boundary
  contract; same 10-line pin as genomic `609c8bb3`).
- Test keeps `@test_throws` and adds a `|r_g|≈1` fixture assert plus a
  synthetic `|r_g|=1` contract lock. Check not deleted.
- Count stays **7**. Experimental **0.8.0**. No 1.0.

## Public-claim audit

**Allowed:** flake hardening of an experimental SE helper.

**Blocked:** count 7→8 · experimental lift · tag / General / CRAN / 1.0
· merge #303 · LLM disclosure edits.

## Twin

R unchanged. Engine-only test/helper pin.
