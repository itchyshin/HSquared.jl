# SelectedInversion bake-off (arc B, 2026-09-24)

Oracle-only. SelectedInversion.jl lives in **this** `bench/Project.toml`, never in the package `Project.toml`.

```sh
cd "$(git rev-parse --show-toplevel)"
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=bench -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=bench bench/selinv_arms.jl --gate agree
# Full Mac grid (slow) or Totoro fill~471:
#   julia --project=bench bench/selinv_arms.jl
#   julia --project=bench bench/selinv_arms.jl --totoro-arm
```

D-271: optional-extension bar is ≥10× kernel win at one BLAS thread. Under bar → KEEP ours; do not wire.
