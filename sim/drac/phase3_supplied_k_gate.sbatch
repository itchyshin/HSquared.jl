#!/bin/bash
# ============================================================================
# Supplied-K / Q escape-hatch — 48-seed recovery SCREEN (one array task per cell).
#
# Governing pre-registration: docs/design/34-interval-recovery-pre-registration.md
# (R repo, §5 recovery leg / §10 supplied-K campaign / §11 screening tier). This is the
# operational grid/seeds/sbatch that §10 delegates to the twin — it cites the doc.
#
# NEW driver sim/phase3_supplied_k_recovery_gate.jl + NEW per-cell TSVs under
# sim/drac/results/supplied_k/. Mutates NO committed harness and NO committed TSV.
#
# GATE ≠ EXIT CODE (programme gotcha: SLURM COMPLETED ≠ Julia succeeded). The gate
# PASS/FAIL is DATA (GATE line + GATE_JSON + TSV). The Julia EXIT CODE means real
# success/failure. This script captures the REAL Julia RC via PIPESTATUS (it pipes stdout
# through tee), then asserts non-empty outputs (TSV row count + RUN_COMPLETE sentinel) and
# exits with the real RC — no `|| true`.
#
# SCREENING ONLY (§11): 48 seeds set DIRECTION, not magnitude. A clean screen SCHEDULES a
# 2000-rep confirm; it CANNOT set a claim level, move public_covered_count, or promote. A
# public move needs the confirm tier + a real Rose audit + the maintainer's G10.
#
# CLUSTER-AGNOSTIC: no cluster name, partition, or cluster path is hardcoded. Submit on
# whichever DRAC by-core general-purpose cluster you are on (fir / nibi / rorqual / narval),
# e.g. `sbatch -M nibi sim/drac/phase3_supplied_k_gate.sbatch` or plain `sbatch …` while
# SSH'd in. `def-snakagaw_cpu`, `module load julia/1.10.10`, and the
# ~/projects/def-snakagaw layout are uniform across the fleet. AVOID Trillium: it is
# whole-node, so a 1-core array task allocates a full node per task — use a by-core cluster
# for this 1-core-per-seed workload.
#
# SAME-ESTIMAND COMPARATOR (R lane, run SEPARATELY): sommer
# mmer(y ~ 1, random = ~ vsr(id, Gu = K)) on the supplied K, compared at the same variance
# components / ratio. NOT part of this Julia gate.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=supplied_k_gate
#SBATCH --array=1-3
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/slurm_%x_%A_%a.out
set -uo pipefail
# NOTE: deliberately NO `set -e` — Julia's exit code is captured manually below.

export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot   # depot on /project, never /scratch
# One fit per seed, single-threaded and deterministic: pin every BLAS/thread knob to 1.
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl

# ---- pre-declared cell table (NEW; touches no committed TSV) ----
# fields: cell  kind  scope  q  records  sk  se  mu  factors  ridge  kseed  nsire ndam noff
#   1 arbK     : genuine arbitrary well-conditioned PD K.        scope=new    (fail → banked-negative)
#   2 identity : C=I → reduces to the iid variance-component recovery. scope=inside (fail → R9 STOP-and-ask)
#   3 pedA     : C=A_pedigree → reduces to / must match the pedigree animal model. scope=inside (R9)
# All three share the DGP (q=500, r=2, n=1000, truth σ²k=0.6 σ²e=0.4 h²k=0.6); only K changes.
# pedA sizes 25+50+425 = 500 = q. factors/ridge/kseed apply only to arbK; nsire/ndam/noff only to pedA.
CELLS=(
  "arbK     arbitrary new    500 2 0.6 0.4 2.0 1000 0.10 20260701 25 50 425"
  "identity identity  inside 500 2 0.6 0.4 2.0 1000 0.10 20260701 25 50 425"
  "pedA     pedigree  inside 500 2 0.6 0.4 2.0 1000 0.10 20260701 25 50 425"
)

IDX=$((SLURM_ARRAY_TASK_ID - 1))
if (( IDX < 0 || IDX >= ${#CELLS[@]} )); then
  echo "ERROR: SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID out of range 1..${#CELLS[@]}" >&2
  exit 3
fi
read -r CELL KIND SCOPE Q RECORDS SK SE MU FACTORS RIDGE KSEED NSIRE NDAM NOFF <<< "${CELLS[$IDX]}"

# 48 pre-declared cold-start seeds (§11 screening tier). Block 20266000..20266047 is DISJOINT
# from EVERY committed sim/ seed block: two-effect 20260700.., neffect/genomic 20260800..847,
# QTL threshold 20260900..919, QTL add-one 20260920..939, QTL design-sweep 20260940..969,
# rr-k2 / QTL production 20261000..099, reuse-vs-rebuild 20262000.., rebuild-prod 20263000..,
# direct-maternal 20264000.., repeatability 20265000..047, C8 re-seed 20270001..500. (The prior
# 20260900 base COLLIDED with the QTL phase-5 gates at …900..969; bumped 2026-07-10.) Overridable
# for the smoke.
NSEEDS="${SK_NSEEDS:-48}"
SEED0="${SK_SEED0:-20266000}"
SEEDS=$(seq -s, "$SEED0" "$((SEED0 + NSEEDS - 1))")

# SK_TAG (e.g. "smoke") routes to a SEPARATE output dir so a smoke never pollutes the real run.
TAG="${SK_TAG:-}"
OUTDIR="sim/drac/results/supplied_k${TAG:+_$TAG}"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/gate_${CELL}.tsv"
LOG="$OUTDIR/log_${CELL}.out"

echo "cell=$CELL kind=$KIND scope=$SCOPE q=$Q records=$RECORDS truth(sk,se,mu)=($SK,$SE,$MU) nseeds=$NSEEDS seed0=$SEED0 out=$OUT"

# ---- run: capture Julia's REAL exit code via PIPESTATUS (stdout also tee'd to $LOG). ----
julia --project=. sim/phase3_supplied_k_recovery_gate.jl \
  --cell="$CELL" --kind="$KIND" --scope="$SCOPE" \
  --q="$Q" --records="$RECORDS" --sk="$SK" --se="$SE" --mu="$MU" \
  --factors="$FACTORS" --ridge="$RIDGE" --kseed="$KSEED" \
  --nsire="$NSIRE" --ndam="$NDAM" --noffspring="$NOFF" \
  --seeds="$SEEDS" --out="$OUT" --resume=true 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}

# REAL check #1 — Julia exit code. A gate FAIL and a thrown-then-banked seed do NOT set
# RC!=0 (gate is data; a throwing seed is caught inside the driver), so RC!=0 is a genuine
# crash / OOM / timeout.
if [[ $RC -ne 0 ]]; then
  echo "FAILED cell=$CELL rc=$RC (genuine Julia error/timeout — NOT a gate fail). Tail of $LOG:" >&2
  tail -n 25 "$LOG" >&2
  exit "$RC"
fi

# REAL check #2 — the artifact must be non-empty: the TSV must hold at least NSEEDS data
# rows for THIS cell (thrown seeds are banked as rows, so this reaches NSEEDS even if some
# fits fail).
if [[ ! -s "$OUT" ]]; then
  echo "EMPTY_OUTPUT cell=$CELL — $OUT missing or empty; see $LOG" >&2
  exit 2
fi
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
grep -E '^(GATE|CONVERGENCE|INTERPRETATION|GATE_JSON|RUN_COMPLETE)' "$LOG" || true
exit "$RC"

# ------------------------------------------------------------------------------------
# SMOKE (the arbitrary-K cell = array index 1, the genuine new-scope path; 4 seeds; a
# SEPARATE tag/dir so it never pollutes the real run):
#
#   sbatch --array=1 --time=0:30:00 \
#     --export=ALL,SK_NSEEDS=4,SK_TAG=smoke sim/drac/phase3_supplied_k_gate.sbatch
#
# Verify: sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ExitCode  (State=COMPLETED,
# ExitCode=0:0); tail results/slurm_supplied_k_gate_<jobid>_1.out (want "=== OK cell=arbK
# rows=4 ===" + GATE/CONVERGENCE/INTERPRETATION lines); wc -l
# sim/drac/results/supplied_k_smoke/gate_arbK.tsv (want 5 = 4 data + header). Re-run the
# SAME smoke to confirm resume: log shows "resume: 4 of 4 declared seeds already present".
# Right-size --time / --mem from `seff <jobid>` (Elapsed for 4 seeds → ×12 for 48, + Julia
# precompile, + margin) BEFORE launching the full 3-cell array:
#   sbatch sim/drac/phase3_supplied_k_gate.sbatch
# ------------------------------------------------------------------------------------
