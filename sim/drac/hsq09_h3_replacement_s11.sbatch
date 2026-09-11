#!/usr/bin/env bash
# Retained H3 S11 launcher. Submit separately with CELL=rg and CELL=ram.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --job-name=hsq09-h3-s11
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --array=1-2000%100
#SBATCH --output=/project/6098264/snakagaw/hsq09-h3-replacement-s11-20260910/logs/%x_%A_%a.out
#SBATCH --error=/project/6098264/snakagaw/hsq09-h3-replacement-s11-20260910/logs/%x_%A_%a.err

set -euo pipefail
: "${CELL:?set CELL=rg or CELL=ram}"
[[ "$CELL" == rg || "$CELL" == ram ]] || { echo "invalid CELL" >&2; exit 64; }
readonly ROOT=/project/6098264/snakagaw/hsq09-h3-replacement-s11-20260910
readonly SOURCE="$ROOT/source"; readonly RECEIPTS="$ROOT/receipts/$CELL"
readonly H1_DEPOT=/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691/julia-depot
readonly START=$([[ "$CELL" == rg ]] && echo 202609110001 || echo 202609120001)
task=${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID}; [[ "$task" =~ ^[0-9]+$ && "$task" -ge 1 && "$task" -le 2000 ]] || exit 64
seed=$((START + task - 1)); receipt="$RECEIPTS/rep-$seed.tsv"; [[ ! -e "$receipt" ]] || { echo "refusing overwrite" >&2; exit 66; }
module load julia/1.10.10
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
export JULIA_DEPOT_PATH="$ROOT/julia-depot:$H1_DEPOT"
export JULIA_PKG_OFFLINE=true
mkdir -p "$RECEIPTS"
julia --project="$SOURCE" "$SOURCE/sim/hsq09_h3_replacement_s11.jl" --cell="$CELL" --seed="$seed" --out="$receipt"
sha256sum "$receipt" > "$receipt.sha256"
echo "H3_REPLACEMENT_S11_TASK_OK cell=$CELL task=$task seed=$seed receipt=$receipt"
