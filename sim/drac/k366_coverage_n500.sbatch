#!/bin/bash
# #366 S5 — DRAC, N=500, sparse interior only (single serial task).
# PAUSED until owner answers Totoro/DRAC + N on issue #366.
# Requires: K366_S5_GO=1 in the job environment.
#
# Sync PR branch to $HOME/projects/def-snakagaw/HSquared.jl first, then:
#   K366_S5_GO=1 sbatch --export=ALL,K366_S5_GO=1 sim/drac/k366_coverage_n500.sbatch
#
# AGENT-INFERRED wall from Totoro smoke (~0.84 s/rep serial): ~7–15 min compute
# + queue. --time=1:00:00 is generous; right-size with seff after first run.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=k366_n500
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/slurm_%x_%j.out
set -euo pipefail

if [[ "${K366_S5_GO:-}" != "1" ]]; then
  echo "PAUSED: owner has not authorized S5. Re-submit with K366_S5_GO=1." >&2
  exit 2
fi

export JULIA_DEPOT_PATH="${JULIA_DEPOT_PATH:-$HOME/projects/def-snakagaw/julia_depot}"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1

module load julia/1.10.10

ROOT="${K366_REPO_ROOT:-$HOME/projects/def-snakagaw/HSquared.jl}"
cd "$ROOT"
mkdir -p sim/drac/results docs/dev-log/recovery-checkpoints

OUT="docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-drac-n500-replicates.tsv"
SUM="docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-drac-n500-summary.tsv"

echo "HOST=DRAC N=500 job=${SLURM_JOB_ID:-na} START=$(date -Iseconds)"
julia --project=. sim/phase3_k_effect_coverage.jl \
  --mode=main --host=DRAC --reps=500 --cell=interior --resume=true \
  --out="$OUT" --summary="$SUM"
echo "END=$(date -Iseconds) Wrote $OUT / $SUM"
