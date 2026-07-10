#!/bin/bash
# ============================================================================
# repeatability t — 2000-rep CONFIRM tier (doc-34 §11) for the WELLPOWERED
# interior cell only (the t claim-setter). The n=3200 dense REML is ~112 s/seed,
# so 2000 seeds MUST parallelise: 40 array tasks x SEEDS_PER_TASK seeds, each to
# its OWN per-task TSV (no concurrent-append), pooled separately (see POOLING
# below). Reuses the ADEMP-verified, locally + cluster-smoked driver
# sim/phase3_repeatability_recovery_gate.jl read-only via its CLI (no new fit code).
# The per-task GATE line (over SEEDS_PER_TASK seeds) is NOISE — the real verdict is
# the pooled 2000-seed aggregate. Cluster-agnostic (fir/nibi/rorqual/narval by-core;
# NOT Trillium). def-snakagaw_cpu; module julia/1.10.10; threads pinned to 1.
#
# CONFIRM seed block 20280000..20281999 (2000) — DISJOINT from the 48-seed screen
# (20265000..047), the supplied-K confirm (20266000..20267999), C8 (20270001..500),
# and every committed block.
#
# LAUNCH: sbatch sim/drac/phase3_repeatability_confirm.sbatch
# SMOKE : sbatch --array=1-2 --time=0:40:00 --export=ALL,RR_SEEDS_PER_TASK=3,RR_TAG=confirm_smoke \
#           sim/drac/phase3_repeatability_confirm.sbatch    (2 tasks x 3 seeds, isolated dir)
#
# POOLING (after the array is COMPLETE — run once; the aggregate does ZERO fits):
#   D=sim/drac/results/rr_confirm
#   head -1 "$D/rr_wellpowered_task1.tsv" > "$D/rr_wellpowered_pooled.tsv"
#   for t in $(seq 1 40); do tail -n +2 "$D/rr_wellpowered_task${t}.tsv" >> "$D/rr_wellpowered_pooled.tsv"; done
#   sbatch --array=1 --time=0:20:00 --job-name=rr_confirm_pool \
#     --export=ALL,RR_POOL=1 sim/drac/phase3_repeatability_confirm.sbatch
#   # -> prints the GATE line over all 2000 seeds (resume: 0 new fits).
# ============================================================================
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=rr_confirm
#SBATCH --array=1-40
#SBATCH --time=1:30:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/slurm_%x_%A_%a.out
set -uo pipefail
# NOTE: deliberately NO `set -e` — Julia's exit code is captured manually via PIPESTATUS.

export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl

# Wellpowered interior cell (matches the 48-seed screen's row-1 DGP exactly).
CELL=wellpowered; SCOPE=interior
NSIRE=20; NDAM=40; NOFF=800; RECORDS=4
SA=1.0; SPE=0.6; SEE=1.5; MU=2.0
SEED0="${RR_SEED0:-20280000}"
SEEDS_PER_TASK="${RR_SEEDS_PER_TASK:-50}"
TAG="${RR_TAG:-confirm}"
OUTDIR="sim/drac/results/rr_${TAG}"
mkdir -p "$OUTDIR"

# ---- POOL mode: aggregate the concatenated 2000-seed TSV (0 new fits) ----
if [[ "${RR_POOL:-0}" == "1" ]]; then
  POOLED="$OUTDIR/rr_wellpowered_pooled.tsv"
  if [[ ! -s "$POOLED" ]]; then echo "POOL: missing $POOLED (concat the per-task TSVs first)"; exit 2; fi
  # Derive the seed list from the pooled file itself (col 2), robust to any count
  # (works for the 6-seed smoke and the 2000-seed full run). resume => 0 new fits.
  ALLSEEDS=$(awk -F'\t' 'NR>1 {print $2}' "$POOLED" | sort -un | paste -sd, -)
  NTOT=$(awk -F'\t' 'NR>1 {print $2}' "$POOLED" | sort -un | wc -l)
  echo "POOL aggregate over $NTOT distinct seeds from $POOLED"
  julia --project=. sim/phase3_repeatability_recovery_gate.jl \
    --cell="$CELL" --scope="$SCOPE" \
    --nsire="$NSIRE" --ndam="$NDAM" --noffspring="$NOFF" --records="$RECORDS" \
    --sigma-a2="$SA" --sigma-pe2="$SPE" --sigma-e2="$SEE" --mu="$MU" \
    --seeds="$ALLSEEDS" --out="$POOLED" --resume=true 2>&1 | tee "$OUTDIR/pool_aggregate.log"
  exit ${PIPESTATUS[0]}
fi

# ---- array mode: one 50-seed block per task ----
TASK=$SLURM_ARRAY_TASK_ID
BLOCK_START=$((SEED0 + (TASK - 1) * SEEDS_PER_TASK))
BLOCK_END=$((BLOCK_START + SEEDS_PER_TASK - 1))
SEEDS=$(seq -s, "$BLOCK_START" "$BLOCK_END")
OUT="$OUTDIR/rr_wellpowered_task${TASK}.tsv"
LOG="$OUTDIR/log_wellpowered_task${TASK}.out"

echo "CONFIRM task=$TASK cell=$CELL seeds=${BLOCK_START}..${BLOCK_END} n=$((NOFF * RECORDS)) out=$OUT"

julia --project=. sim/phase3_repeatability_recovery_gate.jl \
  --cell="$CELL" --scope="$SCOPE" \
  --nsire="$NSIRE" --ndam="$NDAM" --noffspring="$NOFF" --records="$RECORDS" \
  --sigma-a2="$SA" --sigma-pe2="$SPE" --sigma-e2="$SEE" --mu="$MU" \
  --seeds="$SEEDS" --out="$OUT" --resume=true 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}
if [[ $RC -ne 0 ]]; then
  echo "FAILED task=$TASK rc=$RC (genuine Julia error/timeout). Tail of $LOG:" >&2
  tail -n 25 "$LOG" >&2
  exit "$RC"
fi
if [[ ! -s "$OUT" ]]; then echo "EMPTY_OUTPUT task=$TASK ($OUT)"; exit 2; fi
ROWS=$(awk -F'\t' 'NR>1 {n++} END{print n+0}' "$OUT")
if [[ "$ROWS" -lt "$SEEDS_PER_TASK" ]]; then
  echo "INCOMPLETE task=$TASK rows=$ROWS expected>=$SEEDS_PER_TASK — resume same command" >&2
  exit 2
fi
echo "OK task=$TASK rows=$ROWS seeds=${BLOCK_START}..${BLOCK_END}"
