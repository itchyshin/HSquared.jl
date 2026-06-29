#!/bin/bash
# W1 Campaign 2 — broader-DGP V4-MV-REML recovery (doc-33 path-b gate).
# One SLURM array task per pre-declared DGP cell (sim/drac/phase4_v4_cells.tsv).
# Each cell runs 50 cold-start seeds; the AUTHORITATIVE gate is the printed AGGREGATE
# bias/MCSE block (machine-readable GATE line), NOT the per-seed Frobenius exit.
# Predeclaration: docs/dev-log/recovery-checkpoints/2026-06-29-w1-drac-ademp-predeclaration.md
# Right-size --time/--mem with `seff` after the 1-task smoke before launching the full array.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=w1_v4_recovery
#SBATCH --array=1-8
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/w1_v4/%x_%A_%a.out
set -uo pipefail
export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=2
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl
mkdir -p sim/drac/results/w1_v4

CELLS=sim/drac/phase4_v4_cells.tsv
# line 1 is the header; cell N is on line N+1
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$CELLS")
IFS=$'\t' read -r CELL G11 G12 G22 R11 R12 R22 NSIRE NDAM NOFF RECORDS SCOPE <<< "$LINE"
SEEDS=$(seq -s, 20260629 20260678)   # 50 pre-declared seeds
OUT=sim/drac/results/w1_v4/c2_${CELL}.out

echo "cell=$CELL scope=$SCOPE seeds=50 G0=[$G11 $G12; $G12 $G22] R0=[$R11 $R12; $R12 $R22] design=$NSIRE/$NDAM/$NOFF rec=$RECORDS"
# `|| true`: a gate FAIL is data (exit 1), not a job error — we still want the GATE line.
julia --project=. sim/phase4_multivariate_reml_recovery.jl \
  --seeds=$SEEDS --g11=$G11 --g12=$G12 --g22=$G22 --r11=$R11 --r12=$R12 --r22=$R22 \
  --nsire=$NSIRE --ndam=$NDAM --noffspring=$NOFF --records=$RECORDS \
  --cold-start=true --gate=aggregate --cell=$CELL > "$OUT" 2>&1 || true
echo "=== GATE / AGGREGATE for $CELL (scope=$SCOPE) ==="
grep -E '^(GATE|AGGREGATE|  G\[|  R\[|  EBV|  converged)' "$OUT" || echo "no gate output (check $OUT)"
