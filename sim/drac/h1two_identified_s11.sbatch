#!/usr/bin/env bash
# Authorized retained H1-two S11 campaign.  One task is exactly one seed.
# The staging directory, source commit, runtime Manifest.toml, and this file
# are checked against the sealed S11 manifest before `sbatch` is called.
# Target cluster: narval
#SBATCH --account=def-snakagaw_cpu
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --job-name=hsq09-h1t-s11
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=1-2000%100
#SBATCH --output=/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691/logs/%x_%A_%a.out
#SBATCH --error=/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691/logs/%x_%A_%a.err

set -euo pipefail

readonly H1T_S11_ROOT=/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691
readonly H1T_S11_SEED_START=202609100001
readonly H1T_S11_SEED_STOP=202609102000
readonly source="${H1T_S11_ROOT}/source"
readonly receipts="${H1T_S11_ROOT}/receipts"

task_id="${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID is required}"
[[ "${task_id}" =~ ^[0-9]+$ ]] || { echo "invalid array task id: ${task_id}" >&2; exit 64; }
[[ "${task_id}" -ge 1 && "${task_id}" -le 2000 ]] || { echo "task id out of range: ${task_id}" >&2; exit 64; }
seed=$((H1T_S11_SEED_START + task_id - 1))
[[ "${seed}" -le "${H1T_S11_SEED_STOP}" ]] || { echo "seed out of range: ${seed}" >&2; exit 64; }

module load julia/1.10.10
export JULIA_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1
export JULIA_DEPOT_PATH="${H1T_S11_ROOT}/julia-depot:${JULIA_DEPOT_PATH:-}"

mkdir -p "${receipts}"
receipt="${receipts}/rep-${seed}.tsv"
[[ ! -e "${receipt}" ]] || { echo "refusing to overwrite retained receipt: ${receipt}" >&2; exit 66; }

julia --project="${source}" "${source}/sim/h1two_identified_campaign.jl" \
  --seed="${seed}" --out="${receipt}"
sha256sum "${receipt}" > "${receipt}.sha256"
echo "H1T_S11_TASK_OK task=${task_id} seed=${seed} receipt=${receipt}"
