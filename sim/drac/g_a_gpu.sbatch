#!/bin/bash
# v0.7 / Track B — G-A device-resident GBLUP agreement + benchmark on a DRAC GPU node.
# OPT-IN CPU<->GPU agreement + benchmark, NOT CI. Default target: tamia (aip- H200-141GB,
# whole-node h100:4-style alloc). Reuses the G0/G1 CUDA env (gpu_env, CUDA bound via
# LocalPreferences). Predeclaration:
#   docs/dev-log/recovery-checkpoints/2026-07-02-v07-ga-device-gblup-predeclaration.md
#
# ONE-TIME SETUP (login node, internet) — same as the G1 setup; the HSquaredCUDAExt
# extension must resolve + precompile against the pinned commit:
#   export JULIA_DEPOT_PATH=/project/aip-snakagaw/julia_depot
#   module load julia/1.10.10 cuda/12.6
#   cd /project/aip-snakagaw/gpu_env
#   julia --project=. -e 'using Pkg; Pkg.develop(path="/project/aip-snakagaw/HSquared.jl"); Pkg.precompile()'
#SBATCH --account=aip-snakagaw
#SBATCH --job-name=v07_ga_gpu
#SBATCH --time=1:00:00
#SBATCH --nodes=1
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
# q = genotyped population sizes; m = markers. End-to-end GBLUP is dense O(q³); size q to GPU memory.
julia --project=. /project/aip-snakagaw/HSquared.jl/sim/drac/g_a_device_gblup.jl \
      /project/aip-snakagaw/HSquared.jl/sim/drac/results/g_a_gblup_${SLURM_JOB_ID}.tsv \
      2000,4000,8000,16000,32000 5000
echo "end=$(date)"
