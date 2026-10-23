# Check-log: B SelectedInversion bake-off start (oracle only)

Date: 2026-09-24  
Lane: `cursor:HSquared-selinv-B` @ `~/local-scratch/lanes/HSquared.jl-selinv-bakeoff-B-20260924`  
Tip: `d1eb566b` · kernel pin `#363` `c9eac468…`

## Commands

```sh
LANE_ID=cursor:HSquared-selinv-B ~/shinichi-brain/tools/lane_lease.sh --claim HSquared.jl \
  --paths 'bench/,sim/,docs/dev-log/plans/,docs/dev-log/after-task/,docs/dev-log/check-log.d/'
git worktree add -b cursor/selinv-bakeoff-B-20260924 \
  ~/local-scratch/lanes/HSquared.jl-selinv-bakeoff-B-20260924 origin/main
# Ported prior S2b bench/ (SelectedInversion only in bench/Project.toml)
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=bench -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
# Kernel SHA guard: ENV override pattern from origin/bench/selinv-arms-postkernel
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=bench bench/selinv_arms.jl --gate agree
```

## Outcomes so far (superseded by closeout)

See `2026-09-24-selinv-bakeoff-B.md` for the closed receipt.

- Agree gate: **PASS** (`GATE G2b.2 PASS`).
- Mac 1-thread fill≈474 wall: `S_c_trace=4.59` → **KEEP-OURS** (under D-271 10x).
- Totoro re-run left optional (#364); not required for the KEEP-OURS call.
- Did **not** wire production or weakdeps.
