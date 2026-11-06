# Current Julia automatic FA-rank focused acceptance replay

Date: 2026-10-04. Scope: current working-tree Julia automatic-rank engine contract only.

## Result

**PASS.** The current `test/auto_fa_rank_acceptance.jl` run exited 0 with marker `AUTO_FA_ENGINE_ACCEPTANCE_PASS`: 13 testsets, 249 assertions passed, no failures or errors. The environment used `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, and `JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia`.

Command:

```sh
JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/auto_fa_rank_acceptance.jl
```

## Source identity

- Worktree HEAD: `0e4e5d742000f66bdb2127e43ca3756b432a5f10` on dirty branch `codex/arc1-gaussian-reliability-20261002`.
- Ordered path-and-byte digest of all 30 files under `src/`: `44ab3941838b4be62c63136de37945f0bf06c791602ae1a3c642b4c1a52fb7ef`.
- Test file: `test/auto_fa_rank_acceptance.jl`, SHA-256 `c7a031c323dc5dceeefcdf9fe64902a2d8204498d80b041de75b031d2bb16d0f`.
- `Project.toml`: `93422d9228f3e2d6c5170e2b6055bf8bccf6bef59f4189edfa9f68adbe32af5d`.
- `Manifest.toml`: `c5940f2be0347f7ff987468aed67f17070f556a0aa99e0e5ec5317898cfa0fad`.

This pins the on-disk source tree consumed by the focused run. It is not a clean commit or an independent runtime dependency-closure audit.

## Limits

This is focused Julia engineering evidence. It does not establish R parity, current R package acceptance, automatic-rank selection rates or covariance recovery, Arc 1 G0-G8 completion, or the wider H2 non-GPU gates. Public covered count remains seven.
