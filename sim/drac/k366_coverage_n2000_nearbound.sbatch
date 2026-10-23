#!/bin/bash
# #366 S5 — DRAC, N=2000, main_rest (low_pe, near_pe, near_va).
# Owner go 2026-09-25: N=2000 on DRAC. Requires K366_S5_GO=1.
#
# Measured Totoro N=500 main_rest = 126 s. AGENT-INFERRED N=2000 ≈ 10–40 min.
# --time=2:00:00 is generous; right-size with seff after first run.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=k366_n2000_nb
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl-coverage-366-n2000/sim/drac/results/slurm_%x_%j.out
set -euo pipefail

if [[ "${K366_S5_GO:-}" != "1" ]]; then
  echo "PAUSED: owner has not authorized S5. Re-submit with K366_S5_GO=1." >&2
  exit 2
fi

export JULIA_DEPOT_PATH="${JULIA_DEPOT_PATH:-$HOME/projects/def-snakagaw/julia_depot}"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1

module load julia/1.10.10

ROOT="${K366_REPO_ROOT:-$HOME/projects/def-snakagaw/HSquared.jl-coverage-366-n2000}"
cd "$ROOT"
mkdir -p sim/drac/results docs/dev-log/recovery-checkpoints

CELL_SPEC="${K366_CELL:-main_rest}"
OUT="docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-drac-n2000-nearbound-replicates.tsv"
SUM="docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-drac-n2000-nearbound-summary.tsv"

echo "HOST=DRAC N=2000 cells=${CELL_SPEC} job=${SLURM_JOB_ID:-na} START=$(date -Iseconds)"
julia --project=. sim/phase3_k_effect_coverage.jl \
  --mode=main --host=DRAC --reps=2000 --cell="${CELL_SPEC}" --resume=true \
  --out="$OUT" --summary="$SUM"
echo "END=$(date -Iseconds) Wrote $OUT / $SUM"
