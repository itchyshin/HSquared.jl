#!/bin/bash
# Wave F / Track A — F0 measure-first scale benchmark on fir (def- CPU).
# OPT-IN measurement, NOT CI. Single-process; locates the bottleneck at scale.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=wf_f0_scale
#SBATCH --time=3:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=96G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
set -e
export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 JULIA_NUM_THREADS=1
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl
mkdir -p sim/drac/results
echo "node=$(hostname) start=$(date) cpus=$SLURM_CPUS_PER_TASK mem=${SLURM_MEM_PER_NODE}M"
julia --project=. sim/drac/f0_scale_benchmark.jl 10000,30000,100000 \
      sim/drac/results/f0_fir_${SLURM_JOB_ID}.tsv
echo "end=$(date)"
