#!/usr/bin/env bash
# One bounded, retained H3 S11 pre-run. It prepares once and executes both cells.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --job-name=hsq09-h3-s11-prerun
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=/project/6098264/snakagaw/hsq09-h3-replacement-s11-20260910/logs/%x_%A.out
#SBATCH --error=/project/6098264/snakagaw/hsq09-h3-replacement-s11-20260910/logs/%x_%A.err

set -euo pipefail
readonly ROOT=/project/6098264/snakagaw/hsq09-h3-replacement-s11-20260910
readonly SOURCE="$ROOT/source"; readonly RECEIPTS="$ROOT/prerun/receipts"
module load julia/1.10.10
export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
export JULIA_DEPOT_PATH="$ROOT/julia-depot:${JULIA_DEPOT_PATH:-}"
mkdir -p "$RECEIPTS"
julia --project="$SOURCE" -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
for cell in rg ram; do
  seed=$([[ "$cell" == rg ]] && echo 202609110001 || echo 202609120001)
  receipt="$RECEIPTS/$cell-$seed.tsv"
  [[ ! -e "$receipt" ]] || { echo "refusing overwrite: $receipt" >&2; exit 66; }
  julia --project="$SOURCE" "$SOURCE/sim/hsq09_h3_replacement_s11.jl" --cell="$cell" --seed="$seed" --out="$receipt"
done
(cd "$RECEIPTS" && sha256sum *.tsv) > "$ROOT/prerun/SHA256SUMS"
echo "H3_REPLACEMENT_S11_PRERUN_OK cells=rg,ram claim_eligible=false"
