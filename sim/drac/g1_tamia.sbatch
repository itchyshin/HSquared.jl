#!/bin/bash
# Wave F / Track B — G1 genomic GPU agreement + benchmark on tamia (priority aip- GPU).
# OPT-IN CPU↔GPU agreement + benchmark, NOT CI. tamia is WHOLE-NODE only (h100:4) with a
# 24 h cap; G1 uses a single GPU but the node is allocated whole. Heavy live run — author
# on the Mac, run here, then ingest the .tsv into a committed checkpoint doc (doc 17 model).
#SBATCH --account=aip-snakagaw
#SBATCH --job-name=wf_g1_gpu
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=h100:4
#SBATCH --cpus-per-task=12
#SBATCH --mem=128G
#SBATCH --output=/project/aip-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
set -e
# The CUDA.jl-bound depot from G0 (local_toolkit). CUDA must be resolvable from the active
# project — G0 added it to this depot's shared @v1.10 env (so `using CUDA` works under
# `--project=.` via the LOAD_PATH fallback). Adjust if your G0 binding used a different env.
export JULIA_DEPOT_PATH=/project/aip-snakagaw/gpu_env
export OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 JULIA_NUM_THREADS=1
module load cuda/12.6 julia/1.10.10
cd /project/aip-snakagaw/HSquared.jl
mkdir -p sim/drac/results
echo "node=$(hostname) start=$(date) gpus=${SLURM_GPUS_PER_NODE} mem=${SLURM_MEM_PER_NODE}M"
# Fail fast with a clear message if the CUDA binding is not live on this node.
julia --project=. -e 'using CUDA; @assert CUDA.functional() "CUDA not functional"; @show CUDA.name(CUDA.device())'
julia --project=. sim/drac/g1_gpu_genomic.jl \
      sim/drac/results/g1_gpu_${SLURM_JOB_ID}.tsv \
      2000,5000,10000,20000,40000 4000
echo "end=$(date)"
