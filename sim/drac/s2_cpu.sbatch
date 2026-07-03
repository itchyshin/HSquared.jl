#!/bin/bash
# v0.8 / Track A — S2 matrix-free-PCG vs direct-Cholesky multi-effect SOLVE benchmark on a
# DRAC general CPU node (def- account). OPT-IN measurement, NOT CI. Single-process, BLAS
# pinned to 1 thread. Predeclaration:
#   docs/dev-log/recovery-checkpoints/2026-07-02-v08-s2-matfree-pcg-predeclaration.md
#
# FLEET USE: the harness is byte-identical across clusters. Each CPU cluster (Fir, Nibi,
# Rorqual, Trillium, + Totoro outside SLURM) runs the WHOLE grid up to its RAM limit; the
# largest-memory nodes reach the q=1e6 matrix-free-only cells (direct is nnz(L)-capped and
# skipped there). Within a cluster the matrix-free-vs-direct comparison is fair (same box);
# cross-cluster we aggregate only the feasibility frontier + the internal speedup ratios,
# NOT absolute times across machines.
#
# ONE-TIME SETUP (login node): checkout HSquared.jl to the pinned commit under /project and
# instantiate against the /project julia_depot (NEVER /scratch):
#   export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
#   module load julia/1.10.10
#   cd $HOME/projects/def-snakagaw/HSquared.jl && julia --project=. -e 'using Pkg; Pkg.instantiate()'
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=v08_s2_matfree
#SBATCH --time=6:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=249G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
set -e
export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
export HSQUARED_RUN_S2_BENCH=1
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl
mkdir -p sim/drac/results
echo "node=$(hostname) start=$(date) cpus=$SLURM_CPUS_PER_TASK mem=${SLURM_MEM_PER_NODE}M"
# The PRE-DECLARED default grid (overlap 2k..50k both paths; matrix-free-only 100k..1M) is
# baked into the harness; override via S2_BENCH_* only to trim to a node's RAM (recorded).
julia --project=. sim/v08_s2_matfree_pcg_benchmark.jl \
      sim/drac/results/s2_$(hostname -s)_${SLURM_JOB_ID}.tsv
echo "end=$(date)"
