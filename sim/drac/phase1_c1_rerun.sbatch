#!/bin/bash
# C1 univariate interval-coverage RE-RUN (bootstrap arm ON, n_boot=199).
# Repo path: sim/drac/phase1_c1_rerun.sbatch
# Driver:    sim/phase1_c1_rerun_interval_coverage.jl (FROZEN grid; does NOT mutate the harness).
# Output:    NEW dir sim/drac/results/c1_rerun_boot199/  (NO committed TSV touched).
# Predeclaration: docs/dev-log/recovery-checkpoints/2026-06-29-w1-drac-ademp-predeclaration.md
#   (the FULL pre-registered C1 spec the 2026-06-29 launch had to RE-SIZE away from:
#    n_boot=199 x 2000 reps/cell, tiny+small small-sample regime).
#
# 20 array tasks x 100 reps = 2000 reps/cell target.
#   Coverage denominator is interval_success, NOT reps (pooled downstream):
#     coverage = sum(covered)/sum(interval_success),  MC-SE = sqrt(c(1-c)/sum(interval_success)).
#   95% coverage MC-SE ~ sqrt(0.95*0.05/2000) ~ 0.0049 at full interval_success.
#
# SEED-SPACING FIX (must-fix 3). The harness rep seed = master + 1_000_003*di + 10_007*hi + rep.
# Tasks whose master seeds are spaced <= --reps overlap their WITHIN-cell rep streams; the prior
# array used base+task (spacing 1) -> ~119 distinct datasets/cell, MC-SE understated ~4x. But a
# stride that ALIASES the offset constants shares the SAME rep_seed across DIFFERENT cells: at
# stride=1000, 10_007 = 10*1000+7, so task t and task t-10 in the adjacent h2 cell share 93/100
# datasets (verified: 5580 shared seeds, only 10420/16000 distinct across the grid). STRIDE=40_009
# is coprime to both 10_007 and 1_000_003, keeps every h2 offset (<=30_021) below one stride and
# every design offset (~1e6) beyond 19 strides -> 0 cross-cell sharing, 16000/16000 distinct,
# a true 2000 DISTINCT rep_seeds per cell. STRIDE MUST match C1_RERUN_SEED_STRIDE in the driver.
# The 0.90 level rides along as DESCRIPTIVE-ONLY (doc 34); the summary keeps its `level` column.
#
# EXIT + GATE DISCIPLINE (must-fix 2). SLURM COMPLETED != Julia OK, and a row-count check alone is
# FAILURE-INVARIANT (an all-fit-fail run still writes rows and exits 0). This script therefore
# captures Julia's real exit code (PIPESTATUS, not the tee), and gates on:
#   (a) config ECHO from main() -> confirms n_boot=199 / h2={0.1,0.3,0.5,0.7} / levels={0.9,0.95} /
#       bootstrap=true actually reached main() (guards the harness's silent unknown-flag fallback
#       to n_boot=10 / reps=5);
#   (b) total interval_success > 0  (an all-fit-fail run has 0 -> hard fail);
#   (c) an interior SANITY cell (h2 / h2_delta_z / design=small q=120 / level=0.95): interval_success
#       > 0 and coverage above a gross-wiring FLOOR always; the tight ~[0.85,1.0] band is enforced
#       HARD only under SMOKE=1 with enough successes (see COVERAGE_TIGHT_LO / MIN_N_TIGHT), and is
#       WARN-only on the production array so a genuine coverage finding is never discarded.
#
# CLUSTER-AGNOSTIC. No cluster-specific paths or partitions. Choose the cluster at SUBMIT time
# (SSH to fir/nibi/rorqual/trillium/narval and `sbatch` there, or `sbatch -M <cluster>` on a
# federated login). SUBMIT FROM THE REPO ROOT so the relative --output resolves, and pre-create
# the output dir first:
#     cd $HOME/projects/def-snakagaw/HSquared.jl   # or wherever the repo is on THIS cluster
#     mkdir -p sim/drac/results/c1_rerun_boot199
#     sbatch sim/drac/phase1_c1_rerun.sbatch
# Override HSQ_REPO / JULIA_DEPOT_PATH if the checkout or depot lives elsewhere on a given cluster.
#
# RIGHT-SIZE --time/--mem with `seff` after the 1-task SMOKE, BEFORE the full array. --time/--mem
# below are deliberately generous placeholders; drop them once the smoke reports MaxRSS/Elapsed.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=c1r_boot199
#SBATCH --array=1-20
#SBATCH --time=6:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=sim/drac/results/c1_rerun_boot199/%x_%A_%a.out

set -euo pipefail

# ---- Cluster-agnostic environment -------------------------------------------
HSQ_REPO=${HSQ_REPO:-$HOME/projects/def-snakagaw/HSquared.jl}
export JULIA_DEPOT_PATH=${JULIA_DEPOT_PATH:-$HOME/projects/def-snakagaw/julia_depot}
# Single-threaded BLAS/Julia (programme rule; deterministic per-task cost).
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
module load julia/1.10.10
cd "$HSQ_REPO"

# ---- Per-task knobs ----------------------------------------------------------
# RESULTS_DIR is overridable so a smoke can isolate its output (also pass a matching
# --output=<dir>/%x_%A_%a.out to sbatch, since #SBATCH --output is fixed at submit time).
RESULTS_DIR=${RESULTS_DIR:-sim/drac/results/c1_rerun_boot199}
mkdir -p "$RESULTS_DIR"

DRIVER=sim/phase1_c1_rerun_interval_coverage.jl
TASK=$SLURM_ARRAY_TASK_ID
BASE=90000000                       # fresh high seed block; disjoint from prior C1 (2026xxxx/2027xxxx)
STRIDE=40009                        # coprime to 10_007 & 1_000_003 -> 0 cross-cell sharing (MUST match driver)
SEED=$((BASE + TASK * STRIDE))      # task 1..20 -> 90040009..90800180
REPS=${REPS:-100}                   # smoke overrides via --export=ALL,REPS=50
SMOKE=${SMOKE:-0}                   # SMOKE=1 -> enforce the tight interior-coverage band HARD

SUMMARY=$RESULTS_DIR/c1r_summary_task${TASK}.tsv
DETAIL=$RESULTS_DIR/c1r_detail_task${TASK}.tsv
LOG=$RESULTS_DIR/c1r_run_task${TASK}.log     # controlled copy of THIS run's stdout (gate reads it)

# ---- Gate tunables -----------------------------------------------------------
COVERAGE_FLOOR=0.50     # gross-wiring floor for the interior cell (ALWAYS hard; ~0 false positives)
COVERAGE_TIGHT_LO=0.85  # tight interior band lower edge (SMOKE hard / array WARN)
MIN_N_TIGHT=40          # min interior interval_success for the tight band to be a non-flaky hard gate

echo "task=$TASK seed=$SEED reps=$REPS nboot=199 bootstrap=on stride=$STRIDE smoke=$SMOKE"
echo "repo=$HSQ_REPO depot=$JULIA_DEPOT_PATH"
echo "summary=$SUMMARY"
echo "detail=$DETAIL"
echo "log=$LOG"

# ---- Run Julia; capture its REAL exit code (not the tee's) -------------------
: > "$LOG"
set +e
julia --project=. "$DRIVER" \
  --seed="$SEED" --reps="$REPS" \
  --out="$SUMMARY" --detail-out="$DETAIL" --resume=true 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
set -e

echo "julia_exit=$rc task=$TASK"
if [ "$rc" -ne 0 ]; then
  echo "FAIL task=$TASK: julia exited $rc" >&2
  exit "$rc"
fi

# ---- Structural assertions ---------------------------------------------------
if [ ! -s "$DETAIL" ] || [ "$(wc -l < "$DETAIL")" -lt 2 ]; then
  echo "FAIL task=$TASK: no data rows in $DETAIL" >&2
  exit 21
fi
if [ ! -s "$SUMMARY" ] || [ "$(wc -l < "$SUMMARY")" -lt 2 ]; then
  echo "FAIL task=$TASK: no summary rows in $SUMMARY" >&2
  exit 22
fi

# ---- (a) Config echo from main() (guards the silent unknown-flag fallback) ----
if ! grep -Eq '^bootstrap=true n_boot=199 resume=' "$LOG"; then
  echo "FAIL task=$TASK: main() did not echo bootstrap=true / n_boot=199 (silent fallback?)" >&2
  exit 23
fi
if ! grep -Eq '^reps=[0-9]+ h2=0\.1,0\.3,0\.5,0\.7 levels=0\.9,0\.95$' "$LOG"; then
  echo "FAIL task=$TASK: main() did not echo the frozen h2={0.1,0.3,0.5,0.7} / levels={0.9,0.95} grid" >&2
  exit 24
fi

# ---- Pull the driver's greppable diag + probe lines --------------------------
# helper: extract space-separated key=value token from a single line
kv() { printf '%s\n' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -n1; }
# helper: a >= b for finite decimals (NaN handled by the caller)
fge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a+0 >= b+0)}'; }

DIAG_LINE=$(grep -m1 '^C1-RERUN diag:' "$LOG" || true)
PROBE_LINE=$(grep -m1 '^C1-RERUN probe:' "$LOG" || true)

# ---- (b) total interval_success > 0 (all-fit-fail run has 0) ------------------
if [ -z "$DIAG_LINE" ]; then
  echo "FAIL task=$TASK: driver emitted no 'C1-RERUN diag:' line" >&2
  exit 25
fi
TOTAL_ISUCC=$(kv "$DIAG_LINE" total_interval_success)
if [ -z "$TOTAL_ISUCC" ] || [ "$TOTAL_ISUCC" -le 0 ]; then
  echo "FAIL task=$TASK: total_interval_success=$TOTAL_ISUCC (0 => all replicates failed to yield an interval)" >&2
  exit 25
fi

# ---- (c) interior sanity cell ------------------------------------------------
if [ -z "$PROBE_LINE" ]; then
  echo "FAIL task=$TASK: driver emitted no 'C1-RERUN probe:' line" >&2
  exit 26
fi
P_FOUND=$(kv "$PROBE_LINE" found)
P_ISUCC=$(kv "$PROBE_LINE" interval_success)
P_COV=$(kv "$PROBE_LINE" coverage)
if [ "$P_FOUND" != "1" ]; then
  echo "FAIL task=$TASK: interior probe cell (h2/h2_delta_z/small/h2=0.5/level=0.95) not found in summary" >&2
  exit 26
fi
if [ -z "$P_ISUCC" ] || [ "$P_ISUCC" -le 0 ]; then
  echo "FAIL task=$TASK: interior probe interval_success=$P_ISUCC (0 => wiring/fit failure at the best-case cell)" >&2
  exit 27
fi
if [ "$P_COV" = "NaN" ] || ! fge "$P_COV" "$COVERAGE_FLOOR"; then
  echo "FAIL task=$TASK: interior probe coverage=$P_COV below gross-wiring floor $COVERAGE_FLOOR" >&2
  exit 28
fi

# Tight interior band: HARD under SMOKE with enough successes; WARN otherwise
# (never discard a genuine coverage finding on the production array).
if fge "$P_COV" "$COVERAGE_TIGHT_LO"; then
  echo "OK probe: interior coverage=$P_COV in tight band [$COVERAGE_TIGHT_LO,1.0] (interval_success=$P_ISUCC)"
else
  if [ "$SMOKE" = "1" ] && [ "$P_ISUCC" -ge "$MIN_N_TIGHT" ]; then
    echo "FAIL task=$TASK: SMOKE interior coverage=$P_COV < tight band $COVERAGE_TIGHT_LO at n=$P_ISUCC (wiring/regression?)" >&2
    exit 29
  elif [ "$SMOKE" = "1" ]; then
    echo "WARN task=$TASK: SMOKE interior coverage=$P_COV < $COVERAGE_TIGHT_LO but interval_success=$P_ISUCC < $MIN_N_TIGHT; re-run smoke with REPS>=50 for a hard tight-band gate" >&2
  else
    echo "WARN task=$TASK: interior coverage=$P_COV < tight band $COVERAGE_TIGHT_LO (advisory on the production array; adjudicate at pooled scale)" >&2
  fi
fi

echo "OK task=$TASK detail_rows=$(($(wc -l < "$DETAIL") - 1)) summary_cells=$(($(wc -l < "$SUMMARY") - 1)) total_interval_success=$TOTAL_ISUCC probe_coverage=$P_COV"
exit 0
