#!/bin/bash
# v0.7 / Track B — G-B Float32 (mixed-precision) genomic accuracy + speedup on a DRAC GPU node.
# OPT-IN Float64-gate + Float32 accuracy-fence + speedup benchmark, NOT CI. Default target: tamia
# (aip- H100). Reuses the G0/G1/G-A CUDA env (gpu_env, CUDA bound via LocalPreferences).
# Predeclaration:
#   docs/dev-log/recovery-checkpoints/2026-07-03-v07-gb-float32-predeclaration.md
#
# ONE-TIME SETUP (login node, internet) — same as G-A; the HSquaredCUDAExt extension must resolve
# + precompile against the pinned commit:
#   export JULIA_DEPOT_PATH=/project/aip-snakagaw/julia_depot
#   module load julia/1.10.10 cuda/12.6
#   cd /project/aip-snakagaw/gpu_env
#   julia --project=. -e 'using Pkg; Pkg.develop(path="/project/aip-snakagaw/HSquared.jl"); Pkg.precompile()'
#SBATCH --account=aip-snakagaw
#SBATCH --job-name=v07_gb_f32
#SBATCH --time=0:45:00
#SBATCH --nodes=1
# tamia requires a whole-node GPU allocation (h100:4); the harness uses a single GPU
# (CUDA.device() = the first), the other three sit idle — the scheduler's constraint, not a need.
#SBATCH --gpus-per-node=h100:4
#SBATCH --cpus-per-task=12
#SBATCH --mem=64G
#SBATCH --output=/project/aip-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
export JULIA_DEPOT_PATH=/project/aip-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=4 JULIA_NUM_THREADS=1
module load julia/1.10.10 cuda/12.6
cd /project/aip-snakagaw/gpu_env
mkdir -p /project/aip-snakagaw/HSquared.jl/sim/drac/results
echo "node=$(hostname) start=$(date)"; nvidia-smi -L 2>&1 | head -4
# Fail fast if the CUDA binding is not live on this node.
julia --project=. -e 'using CUDA; @assert CUDA.functional() "CUDA not functional"; println("GPU=", CUDA.name(CUDA.device()))'
# m = marker counts (the O(n^2*m) GEMM cost); n = individuals (G is n x n; size to GPU memory).
julia --project=. /project/aip-snakagaw/HSquared.jl/sim/drac/g_b_float32.jl \
      /project/aip-snakagaw/HSquared.jl/sim/drac/results/g_b_float32_${SLURM_JOB_ID}.tsv \
      2000,5000,10000,20000,40000,80000 2000
echo "end=$(date)"
