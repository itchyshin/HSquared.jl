#!/bin/bash
# Wave F / Track A — F0 scale run (post-F1) on fir. OPT-IN measurement, NOT CI.
# Arg $1 = comma-separated q list (default 30000,100000,300000).
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=wf_f0_scale2
#SBATCH --time=3:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
set -e
export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=4 OMP_NUM_THREADS=4 JULIA_NUM_THREADS=1
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl
mkdir -p sim/drac/results
echo "node=$(hostname) start=$(date)"
julia --project=. sim/drac/f0_scale_benchmark.jl "${1:-30000,100000,300000}" \
      sim/drac/results/f0_scale2_${SLURM_JOB_ID}.tsv
echo "end=$(date)"
