#!/bin/bash
# W1 Campaign 1 — interval COVERAGE characterization of the existing delta/profile/bootstrap
# methods (V1-HERIT-CI). Characterization only; t/Satterthwaite df stays BLOCKED (V1-HERIT-TCAL planned).
# Seed-block split: each array task uses a distinct master seed -> independent rep stream;
# union over 20 tasks x 50 reps = 1000 reps/cell (95% MCSE ~= 0.7pp at full interval_success).
# RE-SIZED 2026-06-29 for bootstrap-arm feasibility: tiny+small only (the genuine small-sample
# regime; medium q=240 and n_boot>=199 deferred — the bootstrap arm there was many h/task, R4).
# Coverage is computed on interval_success per cell at ingest (denominator != reps); flag any
# cell with interval_success < 0.9*reps as non-interpretable. Resumable (--resume per task file).
# Predeclaration: docs/dev-log/recovery-checkpoints/2026-06-29-w1-drac-ademp-predeclaration.md
# Right-size --time/--mem and NBOOT with `seff` after the 1-task smoke before the full array.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=w1_interval_coverage
#SBATCH --array=1-20
#SBATCH --time=8:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/w1_interval/%x_%A_%a.out
set -euo pipefail
export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=2
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl
mkdir -p sim/drac/results/w1_interval

TASK=$SLURM_ARRAY_TASK_ID
SEED=$((20260629 + TASK))   # distinct master seed per task -> independent rep stream
REPS=50                     # 20 tasks x 50 = 1000 reps/cell (95% MCSE ~0.7pp)
NBOOT=99                    # re-sized bootstrap arm (tiny+small only) for feasibility

echo "task=$TASK seed=$SEED reps=$REPS nboot=$NBOOT"
julia --project=. sim/phase1_small_sample_interval_calibration.jl \
  --seed=$SEED --reps=$REPS --nboot=$NBOOT \
  --designs=tiny:4:8:24,small:8:16:96 \
  --h2=0.1,0.3,0.5,0.7 --levels=0.9,0.95 \
  --out=sim/drac/results/w1_interval/c1_summary_task${TASK}.tsv \
  --detail-out=sim/drac/results/w1_interval/c1_detail_task${TASK}.tsv \
  --resume=true
echo "done task=$TASK"
