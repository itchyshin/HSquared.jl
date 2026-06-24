#!/bin/bash
# Wave F / Track B — G1 genomic GPU agreement + benchmark on tamia (priority aip- GPU).
# OPT-IN CPU↔GPU agreement + benchmark, NOT CI. tamia is WHOLE-NODE only (h100:4) with a 24 h
# cap; G1 uses one GPU but the node is allocated whole. RAN 2026-06-23 as SLURM job 352612 →
# `docs/dev-log/recovery-checkpoints/2026-06-23-g1-gpu-agreement-benchmark.md`.
#
# ONE-TIME SETUP (login node, internet) — the CUDA env is the G0 project `gpu_env` (CUDA bound
# via LocalPreferences `CUDA_Runtime_jll local=true 12.6`); develop HSquared into it so the
# `HSquaredCUDAExt` extension resolves, then precompile:
#   export JULIA_DEPOT_PATH=/project/aip-snakagaw/julia_depot
#   module load julia/1.10.10 cuda/12.6
#   cd /project/aip-snakagaw/gpu_env
#   julia --project=. -e 'using Pkg; Pkg.develop(path="/project/aip-snakagaw/HSquared.jl"); Pkg.precompile()'
#SBATCH --account=aip-snakagaw
#SBATCH --job-name=wf_g1_gpu
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=h100:4
#SBATCH --cpus-per-task=12
#SBATCH --mem=64G
#SBATCH --output=/project/aip-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
# Depot = julia_depot (the G0 depot); project = gpu_env (CUDA bound + HSquared dev'd, see above).
# Module order matters on tamia: julia/1.10.10 (x86-64-v3/Core) BEFORE cuda/12.6, un-piped.
export JULIA_DEPOT_PATH=/project/aip-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=4 JULIA_NUM_THREADS=1
module load julia/1.10.10 cuda/12.6
cd /project/aip-snakagaw/gpu_env
mkdir -p /project/aip-snakagaw/HSquared.jl/sim/drac/results
echo "node=$(hostname) start=$(date)"; nvidia-smi -L 2>&1 | head -4
# Fail fast if the CUDA binding is not live on this node.
julia --project=. -e 'using CUDA; @assert CUDA.functional() "CUDA not functional"; println("GPU=", CUDA.name(CUDA.device()))'
julia --project=. /project/aip-snakagaw/HSquared.jl/sim/drac/g1_gpu_genomic.jl \
      /project/aip-snakagaw/HSquared.jl/sim/drac/results/g1_gpu_${SLURM_JOB_ID}.tsv \
      2000,5000,10000,20000,40000 4000
echo "end=$(date)"
