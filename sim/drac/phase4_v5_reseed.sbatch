#!/bin/bash
# C8 multivariate-REML recovery RE-SEED — 500 seeds/cell, one array task per DGP cell.
# NEW driver sim/phase4_v5_mv_recovery_reseed.jl (does NOT mutate the committed harness
# sim/phase4_multivariate_reml_recovery.jl nor the committed sim/drac/phase4_v4_cells.tsv).
# Writes a per-(cell,seed) TSV under sim/drac/results/w1_v5/ and RESUMES on restart.
#
# GATE vs EXIT CODE: the gate PASS/FAIL is DATA (GATE line + TSV). The Julia EXIT CODE
# means real success/failure. So this script does a REAL exit-code check plus a TSV
# row-count check and a sentinel check — the committed v4 sbatch used `|| true`, which
# the programme gotcha warns hides crashes (SLURM COMPLETED != Julia succeeded).
#
# CLUSTER-AGNOSTIC: no cluster name, partition, or cluster-specific path is hardcoded.
# The same file submits to whichever DRAC by-core general-purpose cluster you are on —
# pick it at SUBMIT time, e.g.  `sbatch -M nibi sim/drac/phase4_v5_reseed.sbatch`  (or
# just `sbatch ...` while SSH'd into fir/nibi/rorqual/narval). `def-snakagaw_cpu`,
# `module load julia/1.10.10`, and the ~/projects/def-snakagaw layout are uniform across
# the fleet. (Trillium is whole-node; a 1-core array there allocates a full node per
# task — submit it packed, or prefer a by-core cluster for this 1-core-per-seed workload.)
#
# CELLS: all 16 are 2-trait HALF-SIB (size_med is a LARGER half-sib design, 16/32/112 —
# not a different design type). cold-start. gate = aggregate CONDITIONAL ON CONVERGENCE.
#
# --time CALIBRATION: this budget is a conservative upper bound for the SLOW-CONVERGENCE
# boundary cells (rg_095 / rg_095_rec1), NOT the base cell. Right-size it from the rg_095
# smoke: `seff <jobid>` Elapsed for 5 seeds -> x100 for 500 seeds, +~3 min Julia precompile,
# +30% margin. Do that BEFORE launching the full array. --mem: `seff` MaxRSS after the smoke.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=c8_v5_reseed
#SBATCH --array=1-16
#SBATCH --time=6:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/slurm_%x_%A_%a.out
set -uo pipefail
# NOTE: deliberately NO `set -e` — we capture Julia's exit code manually below.

export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
# One fit per seed, single-threaded and deterministic: pin every BLAS/thread knob to 1.
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl

# ---- pre-declared cell table (NEW; does NOT touch the committed phase4_v4_cells.tsv) ----
# fields: cell  g11 g12 g22  r11 r12 r22  nsire ndam noff  records  design  npair noppp  scope
#   rows 1-8  : the 8 committed C8 cells, re-declared verbatim.
#   row    9  : NULL cell  (g12=0 => r_g=0).
#   rows 10-12: records ladder at EXTREME r_g=0.70 (rec 2/4/6). With rg_high_rec1 (rec1,
#               row 8) and rg_high (rec3, row 3) this is the full rec {1,2,3,4,6} ladder AT
#               THE r_g WHERE THE #268 DOWNWARD GENETIC-COVARIANCE BIAS LIVES — the base-r_g
#               (0.42) ladder of the draft traced bias where there is little bias to trace.
#   rows 13-14: |r_g| boundary cells 0.90 (g12=0.7530) and 0.95 (g12=0.7948), rec3.
#   rows 15-16: the WORST #268 corner — rec1 companions of the 0.90/0.95 boundary, where the
#               downward genetic-covariance bias should be maximal (single record x extreme r_g).
# r_g = g12 / sqrt(g11*g22);  sqrt(1.0*0.7)=0.83666  => 0.5857->0.70, 0.7530->0.90, 0.7948->0.95.
CELLS=(
  "base_inside 1.0 0.35 0.7 0.8 0.2 0.55 8 16 56 3 halfsib 20 2 interior"
  "rg_low 1.0 0.0837 0.7 0.8 0.2 0.55 8 16 56 3 halfsib 20 2 interior"
  "rg_high 1.0 0.5857 0.7 0.8 0.2 0.55 8 16 56 3 halfsib 20 2 interior_ladder_rec3"
  "h2_asym 1.2 0.2078 0.4 0.4 0.15 1.0 8 16 56 3 halfsib 20 2 interior"
  "records_1 1.0 0.35 0.7 0.8 0.2 0.55 8 16 56 1 halfsib 20 2 interior"
  "size_med 1.0 0.35 0.7 0.8 0.2 0.55 16 32 112 3 halfsib 20 2 interior"
  "rg_low_rec1 1.0 0.0837 0.7 0.8 0.2 0.55 8 16 56 1 halfsib 20 2 interior"
  "rg_high_rec1 1.0 0.5857 0.7 0.8 0.2 0.55 8 16 56 1 halfsib 20 2 interior_ladder_rec1"
  "rg_null 1.0 0.0 0.7 0.8 0.2 0.55 8 16 56 3 halfsib 20 2 null"
  "rg_high_rec2 1.0 0.5857 0.7 0.8 0.2 0.55 8 16 56 2 halfsib 20 2 ladder_rg070_rec2"
  "rg_high_rec4 1.0 0.5857 0.7 0.8 0.2 0.55 8 16 56 4 halfsib 20 2 ladder_rg070_rec4"
  "rg_high_rec6 1.0 0.5857 0.7 0.8 0.2 0.55 8 16 56 6 halfsib 20 2 ladder_rg070_rec6"
  "rg_090 1.0 0.7530 0.7 0.8 0.2 0.55 8 16 56 3 halfsib 20 2 boundary"
  "rg_095 1.0 0.7948 0.7 0.8 0.2 0.55 8 16 56 3 halfsib 20 2 boundary"
  "rg_090_rec1 1.0 0.7530 0.7 0.8 0.2 0.55 8 16 56 1 halfsib 20 2 boundary_worst"
  "rg_095_rec1 1.0 0.7948 0.7 0.8 0.2 0.55 8 16 56 1 halfsib 20 2 boundary_worst"
)

IDX=$((SLURM_ARRAY_TASK_ID - 1))
if (( IDX < 0 || IDX >= ${#CELLS[@]} )); then
  echo "ERROR: SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID out of range 1..${#CELLS[@]}" >&2
  exit 3
fi
read -r CELL G11 G12 G22 R11 R12 R22 NSIRE NDAM NOFF RECORDS DESIGN NPAIR NOPPP SCOPE <<< "${CELLS[$IDX]}"

# 500 pre-declared seeds, DISJOINT from the 50-seed triage block (20260629..20260678),
# so this re-seed is independent evidence, not a superset. Overridable for the smoke.
NSEEDS="${RESEED_NSEEDS:-500}"
SEED0="${RESEED_SEED0:-20270001}"
SEEDS=$(seq -s, "$SEED0" "$((SEED0 + NSEEDS - 1))")

# RESEED_TAG (e.g. "smoke") routes to a SEPARATE output dir so a smoke never pollutes
# or invalidates the real w1_v5 resume.
TAG="${RESEED_TAG:-}"
OUTDIR="sim/drac/results/w1_v5${TAG:+_$TAG}"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/reseed_${CELL}.tsv"
LOG="$OUTDIR/log_${CELL}.out"

echo "cell=$CELL scope=$SCOPE nseeds=$NSEEDS seed0=$SEED0 G0=[$G11 $G12; $G12 $G22] R0=[$R11 $R12; $R12 $R22] design=$DESIGN $NSIRE/$NDAM/$NOFF rec=$RECORDS out=$OUT"

# ---- run: NO `|| true`; capture Julia's real exit code. ----
julia --project=. sim/phase4_v5_mv_recovery_reseed.jl \
  --seeds="$SEEDS" \
  --g11="$G11" --g12="$G12" --g22="$G22" --r11="$R11" --r12="$R12" --r22="$R22" \
  --nsire="$NSIRE" --ndam="$NDAM" --noffspring="$NOFF" --records="$RECORDS" \
  --design="$DESIGN" --npair="$NPAIR" --noffspring-per-pair="$NOPPP" \
  --cold-start=true --gate=aggregate --cell="$CELL" \
  --out="$OUT" --resume=true > "$LOG" 2>&1
RC=$?

# REAL check #1 — Julia exit code. A gate FAIL (or a boundary cell that under-recovers)
# does NOT set RC!=0 in the new driver (gate is data), so RC!=0 is a genuine crash/OOM/
# timeout. A single throwing SEED is caught inside the driver and banked, so it does not
# set RC!=0 either.
if [[ $RC -ne 0 ]]; then
  echo "FAILED cell=$CELL rc=$RC (genuine Julia error/timeout — NOT a gate fail). Tail of $LOG:" >&2
  tail -n 25 "$LOG" >&2
  exit "$RC"
fi

# REAL check #2 — the artifact. SLURM COMPLETED != work done: the TSV must hold at least
# NSEEDS data rows for THIS cell (thrown seeds are banked as rows, so this reaches NSEEDS
# even at the boundary).
ROWS=$(awk -F'\t' -v c="$CELL" 'NR>1 && $1==c {n++} END{print n+0}' "$OUT")
if [[ "$ROWS" -lt "$NSEEDS" ]]; then
  echo "INCOMPLETE cell=$CELL rows=$ROWS expected>=$NSEEDS — resume with the same command; see $LOG" >&2
  exit 2
fi

# REAL check #3 — the driver's own completion sentinel must be present.
if ! grep -q "^RUN_COMPLETE cell=$CELL " "$LOG"; then
  echo "NO_SENTINEL cell=$CELL — driver did not print RUN_COMPLETE; see $LOG" >&2
  exit 4
fi

echo "=== OK cell=$CELL rows=$ROWS ==="
grep -E '^(GATE|CONVERGENCE|CONV-AGGREGATE|AGGREGATE|RUN_COMPLETE|  G\[|  R\[|  EBV)' "$LOG" || true

# ------------------------------------------------------------------------------------
# SMOKE (fix 5: smoke the EXTREME cold-start cell rg_095 = array index 14, the regime
# most likely to hit slow/failed convergence at cond(G)~40 — NOT base_inside):
#
#   sbatch --array=14 --time=0:30:00 \
#     --export=ALL,RESEED_NSEEDS=5,RESEED_TAG=smoke sim/drac/phase4_v5_reseed.sbatch
#
# Verify: sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ExitCode  (State=COMPLETED,
# ExitCode=0:0); tail results/slurm_c8_v5_reseed_<jobid>_14.out (want "=== OK cell=rg_095
# rows=5 ===" + a GATE + CONVERGENCE line); wc -l sim/drac/results/w1_v5_smoke/reseed_rg_095.tsv
# (want 6 = 5 data + header). Re-run the SAME smoke to confirm resume: log shows
# "resume: 5 of 5 declared seeds already present" and "new_fits=0", still ExitCode 0:0.
# Optional worst-corner timing bound: --array=16 (rg_095_rec1) with the same overrides.
# Only after a clean rg_095 smoke, and after seff-right-sizing --time, launch the full
# array:  sbatch sim/drac/phase4_v5_reseed.sbatch
# ------------------------------------------------------------------------------------
