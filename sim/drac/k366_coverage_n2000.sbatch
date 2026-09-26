#!/bin/bash
# #366 S5 — DRAC, N=2000, sparse interior only (single serial task).
# Owner go 2026-09-25: N=2000 on DRAC. Requires K366_S5_GO=1.
#
# Dedicated campaign tree (do not overwrite older HSquared.jl checkouts):
#   rsync → $HOME/projects/def-snakagaw/HSquared.jl-coverage-366-n2000
#   K366_S5_GO=1 K366_REPO_ROOT=$HOME/projects/def-snakagaw/HSquared.jl-coverage-366-n2000 \
#     sbatch --export=ALL,K366_S5_GO=1,K366_REPO_ROOT sim/drac/k366_coverage_n2000.sbatch
#
# Measured Totoro N=500 interior = 61 s. AGENT-INFERRED N=2000 ≈ 4–20 min.
# --time=1:00:00 is generous; right-size with seff after first run.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=k366_n2000_int
#SBATCH --time=1:00:00
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

OUT="docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-drac-n2000-interior-replicates.tsv"
SUM="docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-drac-n2000-interior-summary.tsv"

echo "HOST=DRAC N=2000 cell=interior job=${SLURM_JOB_ID:-na} START=$(date -Iseconds)"
julia --project=. sim/phase3_k_effect_coverage.jl \
  --mode=main --host=DRAC --reps=2000 --cell=interior --resume=true \
  --out="$OUT" --summary="$SUM"
echo "END=$(date -Iseconds) Wrote $OUT / $SUM"
