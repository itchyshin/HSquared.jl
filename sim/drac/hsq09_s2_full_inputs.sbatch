#!/usr/bin/env bash
# Private S2 input-only materialization. This script never fits a model,
# computes an interval, or invokes S10/S11. Submit from the retained run root.
# The default is deliberately one task; widening the array requires a separate
# approval after the pre-run's output and `seff` receipt are inspected.
#SBATCH --job-name=hsq09-s2-input
#SBATCH --account=aip-snakagaw
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --array=1-1%1
#SBATCH --time=00:03:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=hsq09-s2-input-%A_%a.out
#SBATCH --error=hsq09-s2-input-%A_%a.err

set -euo pipefail

: "${HSQ09_REPO_ROOT:?set the pinned candidate checkout path}"
: "${HSQ09_TASK_MANIFEST:?set the sealed raw-task manifest path}"
: "${HSQ09_OUTPUT_ROOT:?set the retained output root}"
: "${SLURM_ARRAY_TASK_ID:?Slurm must provide the raw task index}"

export JULIA_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

module load StdEnv/2023 julia/1.10.0

exec julia --project="${HSQ09_REPO_ROOT}" \
  "${HSQ09_REPO_ROOT}/tools/materialize_hsq09_s2_full_inputs.jl" \
  --task-index "${SLURM_ARRAY_TASK_ID}" \
  --task-manifest "${HSQ09_TASK_MANIFEST}" \
  --output-root "${HSQ09_OUTPUT_ROOT}"
