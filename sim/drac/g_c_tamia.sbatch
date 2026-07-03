#!/bin/bash
# v0.7 / Track B — G-C large / realistic-panel genomic-G benchmark + device-memory profile on tamia H100.
# OPT-IN, NOT CI. tamia requires a whole-node GPU allocation (h100:4); the harness uses a single GPU.
# Reuses the aip- gpu_env. Predeclaration:
#   docs/dev-log/recovery-checkpoints/2026-07-03-v07-gc-realpanel-predeclaration.md
#SBATCH --account=aip-snakagaw
#SBATCH --job-name=v07_gc_panel
#SBATCH --time=0:50:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=h100:4
#SBATCH --cpus-per-task=12
#SBATCH --mem=120G
#SBATCH --output=/project/aip-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
export JULIA_DEPOT_PATH=/project/aip-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=8 JULIA_NUM_THREADS=1
module load julia/1.10.10 cuda/12.6
cd /project/aip-snakagaw/gpu_env
mkdir -p /project/aip-snakagaw/HSquared.jl/sim/drac/results
echo "node=$(hostname) start=$(date)"; nvidia-smi -L 2>&1 | head -2
julia --project=. -e 'using CUDA; @assert CUDA.functional() "CUDA not functional"; println("GPU=", CUDA.name(CUDA.device()))'
julia --project=. /project/aip-snakagaw/HSquared.jl/sim/drac/g_c_realpanel.jl \
      /project/aip-snakagaw/HSquared.jl/sim/drac/results/g_c_realpanel_${SLURM_JOB_ID}.tsv
echo "end=$(date)"
