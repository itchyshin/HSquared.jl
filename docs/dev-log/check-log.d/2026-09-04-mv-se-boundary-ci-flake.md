# check-log — 2026-09-04 n=8 mv covariance SE CI flake

**Arc:** pre-existing Julia CI flake (Phase 4 multivariate covariance SEs + LRTs)  
**Lane:** `cursor/mv-se-flake-20260904` @ `~/local-scratch/lanes/HSquared.jl-mv-se-flake-20260904`  
**Base:** `origin/main` `a70106c2`  
**Fence:** flake class only. Not #303 (LLM disclosure). No covered flip.
`public_covered_count` stays **7**. Experimental **0.8.0**. No 1.0.

## Changes

- `src/multivariate.jl` — reject `|r| ≥ 1−1e-6` before the FD Hessian so
  the n=8 boundary throw is platform-independent (same pin as genomic
  `609c8bb3`).
- `test/runtests.jl` — keep `@test_throws`; add `|r_g|≈1` fixture assert
  and a synthetic `|r_g|=1` contract lock.
- Board + this file + after-task.

## Commands

```sh
cd ~/local-scratch/lanes/HSquared.jl-mv-se-flake-20260904
julia --project=. /Users/z3437171/local-scratch/probe-mv-se-n8.jl
julia --project=. /Users/z3437171/local-scratch/probe-mv-se-n8-post.jl
bash tools/preamble_cap.sh
bash tools/build_check_log.sh --check
```

## Results

| Check | Outcome |
|-------|---------|
| Local Julia | **1.10.0** (the flaky CI matrix) |
| n=8 pre-fix `|r_g|` | `1 − |r_g| = 9.2e-9` (boundary) |
| Focused post-fix probe | **9/9 pass** (n=8 throw, synthetic `|r_g|=1`, C2 throw, interior n=24 SEs, structured reject) |
| `preamble_cap.sh` | CAP OK |
| `build_check_log.sh --check` | **179** shards well-formed |
| `public_covered_count` | **7** |
| Experimental version | **0.8.0** |
