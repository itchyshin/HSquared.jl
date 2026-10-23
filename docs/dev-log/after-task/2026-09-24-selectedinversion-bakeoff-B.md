# After-task: SelectedInversion.jl bake-off B (KEEP-OURS)

Date: 2026-09-24  
Lane: `cursor:HSquared-selinv-B`  
Worktree: `~/local-scratch/lanes/HSquared.jl-selinv-bakeoff-B-20260924`  
Base tip: `origin/main` @ `d1eb566b`  
Kernel under test: `src/takahashi_selinv.jl` @ `c9eac468` (#363 SIMD on #361 scatter)  
Plan: `docs/dev-log/plans/2026-09-24-ultra-plan-B-C-selinv.md`  
Deps audit (declare only; no wire): `docs/dev-log/plans/2026-09-24-selectedinversion-deps-audit.md`

Active lenses: Shannon, Ada, Rose (perspectives). Spawned subagents: none.

## Verdict

KEEP-OURS. SelectedInversion.jl is faster on this cell but fails D-271's one-BLAS-thread 10x bar for an optional extension. Production stays on our SIMD Takahashi. No package `Project.toml` / `ext/` / weakdeps change in this arc.

## Measured (1 BLAS thread, identity + wall)

Host: Apple M1 Ultra (Mac Studio). Julia 1.10.0.  
`OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`.  
Fixture: f0adv q=20,000, `nfounder_frac=0.005` (banked #361 / D-271 fill≈471 family).  
`is_super=true`, fill=**473.937**, nnz(L)=9,479,216.

| arm | median wall |
| --- | --- |
| ours (a) trace | 7.456 s |
| ours (a) diag | 8.153 s |
| SelectedInversion 0.2.1 (c) trace | 1.623 s |
| SelectedInversion 0.2.1 (c) diag | 1.570 s |
| factorise (reuse) | 0.660 s |

| quantity | value | D-271 gate |
| --- | --- | --- |
| `S_c_trace` (ours / package) | **4.59x** | need >= 10x for weakdeps |
| `S_c_diag` | **5.19x** | same |
| `R_c_trace` (package / fact) | 2.46 | report only |
| `err_c` (max rel) | **1.657e-14** | PASS (<= 1e-10) |
| `--gate agree` | **PASS** | G2b.2 |

Package lead ≈4.6x matches the deps-audit Mac figure after #361/#363. Under the bar. Not a flip.

## What landed in this worktree

- Scratch `bench/` harness only (`SelectedInversion = "=0.2.1"` in `bench/Project.toml`; package deps untouched).
- Plans copied: ultra-plan B-C, deps audit, sort-out pointer.
- Receipt TSV: `bench/results/selinv_arms_c9eac468_mac_q20000_fill474_t1.tsv`  
  (same bytes as sibling lane measurement; Mac host in filename; header `cpu=Apple M1 Ultra`).
- Package `Project.toml`: no SelectedInversion (`rg` empty).

## Explicitly not done

- No production default flip to SelectedInversion.
- No DRM / GLLVM Takahashi port (C is a later G0; this lane stops at B).
- No GLLVModels #463 work.
- Totoro one-thread re-run remains optional (#364); Mac 1-thread already decides KEEP-OURS under D-271.

## Rose fence

Kernel-arm bake-off only. Not a multi-iter `fit_ai_reml` speedup claim (#378 projected fence still stands). `S_c` means the package is faster than ours on one selinv pass.

## Next (outside this slice)

C = share **our** SIMD Takahashi one-cell into DRM or GLLVM if owner opens that G0. Do not force SelectedInversion into the three.
