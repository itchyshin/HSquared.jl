#!/bin/bash
# W1 Campaign 1 follow-up — interval COVERAGE at the MEDIUM design (q=240), deferred from the
# tiny+small run for feasibility (which turned out fast: refits are ms-scale). Same config as the
# tiny+small run (20 tasks x 50 reps = 1000 reps/cell, n_boot=99, h2 in {0.1,0.3,0.5,0.7}, levels
# {0.9,0.95}) so coverage is directly comparable across designs -> tests whether the small-sample
# sigma_a2 under-coverage IMPROVES with n. Characterization only; t/Satterthwaite df stays BLOCKED.
# Coverage on interval_success at ingest (denominator != reps). Resumable per task file.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=w1_interval_medium
#SBATCH --array=1-20
#SBATCH --time=8:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/w1_interval_medium/%x_%A_%a.out
set -euo pipefail
export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=2
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl
mkdir -p sim/drac/results/w1_interval_medium

TASK=$SLURM_ARRAY_TASK_ID
SEED=$((20270629 + TASK))   # distinct master seed per task (offset from the tiny+small run)
REPS=50                     # 20 tasks x 50 = 1000 reps/cell
NBOOT=99

echo "task=$TASK seed=$SEED reps=$REPS nboot=$NBOOT design=medium"
julia --project=. sim/phase1_small_sample_interval_calibration.jl \
  --seed=$SEED --reps=$REPS --nboot=$NBOOT \
  --designs=medium:16:32:192 \
  --h2=0.1,0.3,0.5,0.7 --levels=0.9,0.95 \
  --out=sim/drac/results/w1_interval_medium/c1m_summary_task${TASK}.tsv \
  --detail-out=sim/drac/results/w1_interval_medium/c1m_detail_task${TASK}.tsv \
  --resume=true
echo "done task=$TASK"
