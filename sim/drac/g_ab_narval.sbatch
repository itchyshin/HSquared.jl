#!/bin/bash
# v0.7 / Track B — G-A + G-B CROSS-DEVICE agreement replicate on Narval (A100).
# OPT-IN, NOT CI. Re-runs the SAME committed harnesses that ran on tamia H100
# (g_a_device_gblup.jl, g_b_float32.jl) on a DIFFERENT GPU architecture (NVIDIA A100)
# to confirm the CPU<->GPU agreement + the Float64 gate hold across architectures
# (portability), and to characterize Float32 on A100's tensor cores.
# Predeclaration: docs/dev-log/recovery-checkpoints/2026-07-03-v07-g72-crossdevice-predeclaration.md
#
# ONE-TIME SETUP (login node, internet) — gpu_env under the def-snakagaw allocation:
#   export JULIA_DEPOT_PATH=/project/def-snakagaw/julia_depot
#   module load julia/1.10.10 cuda/12.6
#   cd /project/def-snakagaw/gpu_env
#   julia --project=. -e 'using Pkg; Pkg.develop(path="/project/def-snakagaw/HSquared.jl"); Pkg.precompile()'
#SBATCH --account=def-snakagaw
#SBATCH --job-name=v07_g72_narval
#SBATCH --time=0:50:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=a100:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --output=/project/def-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
export JULIA_DEPOT_PATH=/project/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=4 JULIA_NUM_THREADS=1
module load julia/1.10.10 cuda/12.6
cd /project/def-snakagaw/gpu_env
mkdir -p /project/def-snakagaw/HSquared.jl/sim/drac/results
echo "node=$(hostname) start=$(date)"; nvidia-smi -L 2>&1 | head -2
julia --project=. -e 'using CUDA; @assert CUDA.functional() "CUDA not functional"; println("GPU=", CUDA.name(CUDA.device()))'
# G-A device-resident GBLUP agreement + benchmark (dense O(q^3); A100 40/80GB -> q<=16000)
julia --project=. /project/def-snakagaw/HSquared.jl/sim/drac/g_a_device_gblup.jl \
      /project/def-snakagaw/HSquared.jl/sim/drac/results/g_a_narval_${SLURM_JOB_ID}.tsv \
      2000,4000,8000,16000 5000
# G-B Float32 accuracy + speedup on A100
julia --project=. /project/def-snakagaw/HSquared.jl/sim/drac/g_b_float32.jl \
      /project/def-snakagaw/HSquared.jl/sim/drac/results/g_b_narval_${SLURM_JOB_ID}.tsv \
      2000,5000,10000,20000,40000,80000 2000
echo "end=$(date)"
