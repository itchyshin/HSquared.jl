#!/bin/bash
# ============================================================================
# Repeatability (permanent-environment) 48-seed recovery SCREEN — one SLURM array
# task per DGP cell. NEW driver sim/phase3_repeatability_recovery_gate.jl (does NOT
# mutate any committed harness or TSV).
#
# GOVERNING PRE-REGISTRATION: R-repo docs/design/34-interval-recovery-pre-registration.md
# (§5 recovery gate, §10 repeatability campaign, §11 screening tier, §12 run discipline).
#
# WHAT IS GATED: ONLY the identifiable repeatability t = (sigma_a2+sigma_pe2)/total, via
# |bias(t)| <= 2*MC-SE over CONVERGED seeds. The sigma_a2/sigma_pe2 SPLIT and h2 are
# CHARACTERIZED-ONLY (experimental-only; reported, never gated) — the honesty stance
# pre-committed in doc-34 §10.
#
# SCREENING TIER: 48 seeds establish DIRECTION only. A clean screen schedules a ~2000-rep
# CONFIRM tier; it can NEVER set a claim or move public_covered_count on its own (needs the
# confirm tier + a real Rose audit + the maintainer's per-move G10).
#
# GATE vs EXIT CODE: the gate PASS/FAIL is DATA (the GATE line + the TSV). The Julia EXIT
# CODE means real success/failure. This script captures Julia's REAL exit code via
# PIPESTATUS (the run is piped through `tee`), plus a TSV row-count check and a completion-
# sentinel check — SLURM COMPLETED != Julia succeeded, and a `|| true` would hide a crash.
#
# CLUSTER-AGNOSTIC: no cluster name/partition/path is hardcoded. Submit to whichever DRAC
# BY-CORE general-purpose cluster you are on (fir/nibi/rorqual/narval), e.g.
#   sbatch -M nibi sim/drac/phase3_repeatability_gate.sbatch
# or just `sbatch sim/drac/phase3_repeatability_gate.sbatch` while SSH'd into one.
# AVOID Trillium for this workload: it is WHOLE-NODE, so a 1-core array task allocates a
# full node per cell (wasteful); prefer a by-core cluster for 1-core-per-seed fits.
# `def-snakagaw_cpu`, `module load julia/1.10.10`, and the ~/projects/def-snakagaw layout
# are uniform across the by-core fleet.
#
# --time CALIBRATION: the budget below is a CONSERVATIVE placeholder sized for the largest
# cell (the well-powered n=3200 dense fit). RIGHT-SIZE IT from the smoke before the full
# array: run the well-powered cell at a reduced seed count, `seff <jobid>` its Elapsed for
# k seeds -> x(48/k) for 48 seeds, + ~2 min Julia precompile, + ~30% margin. The dense
# REML forms an n x n covariance (n = noffspring * records), so cost scales ~ n^3 per
# likelihood eval; the well-powered / null cells (n=3200) dominate, the records=1 rung
# (n=800) is cheapest.
# ============================================================================
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=rr_repeat_gate
#SBATCH --array=1-6
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/slurm_%x_%A_%a.out
set -uo pipefail
# NOTE: deliberately NO `set -e` — we capture Julia's exit code manually via PIPESTATUS.

export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
# One fit per seed, single-threaded and deterministic: pin EVERY BLAS/thread knob to 1
# (doc-34 §12; the dense REML is BLAS-bound and multi-thread BLAS would non-determinize it).
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl

# ---- pre-declared cell table (NEW; touches no committed TSV) ----
# fields: cell  scope  nsire ndam noffspring records  sigma_a2 sigma_pe2 sigma_e2  mu
#   row 1 : WELL-POWERED interior gated cell (half-sib q=860 pedigree matching the passed
#           two-effect design; 800 offspring x 4 records = n=3200). SMOKE target + largest n.
#   rows 2-4 : records-per-individual IDENTIFIABILITY LADDER at the same design.
#           rec1 is scope=boundary_rec1 — pe (and therefore t) is NOT point-identified at
#           1 record/ind, so its "fail" is the expected identifiability FLOOR (characterization,
#           never promotion); rec2/rec3 are ladder rungs where t becomes recoverable while the
#           a/pe split stays weak. With the well-powered rec4 this is a full rec {1,2,3,4} ladder.
#   row 5 : reduced-n_ind rung (200 offspring x 4 records) — fewer pedigree contrasts, so the
#           a/pe SPLIT degrades further while t still recovers.
#   row 6 : sigma_pe2 = 0 NULL cell — t reduces to h2 = 0.4; checks the estimator does not
#           spuriously inflate pe at the boundary.
# Truth (1.0, 0.6, 1.5) is the documented repeatability validation triple (t=0.5161, h2=0.3226);
# the null cell uses (1.0, 0.0, 1.5) (t=h2=0.4).
CELLS=(
  "wellpowered   interior      20 40 800 4 1.0 0.6 1.5 2.0"
  "ladder_rec1   boundary_rec1 20 40 800 1 1.0 0.6 1.5 2.0"
  "ladder_rec2   ladder        20 40 800 2 1.0 0.6 1.5 2.0"
  "ladder_rec3   ladder        20 40 800 3 1.0 0.6 1.5 2.0"
  "split_small_n ladder        20 40 200 4 1.0 0.6 1.5 2.0"
  "null_pe0      null          20 40 800 4 1.0 0.0 1.5 2.0"
)

IDX=$((SLURM_ARRAY_TASK_ID - 1))
if (( IDX < 0 || IDX >= ${#CELLS[@]} )); then
  echo "ERROR: SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID out of range 1..${#CELLS[@]}" >&2
  exit 3
fi
read -r CELL SCOPE NSIRE NDAM NOFF RECORDS SA SPE SEE MU <<< "${CELLS[$IDX]}"

# 48 pre-declared seeds, DISJOINT from every prior committed block (two-effect 20260700..,
# neffect 20260800.., QTL 20260920.., rr-k2 20261000.., reuse-vs-rebuild 20262000..,
# rebuild-prod 20263000.., direct-maternal 20264000.., C8 re-seed 20270001..). Overridable
# for the smoke.
NSEEDS="${RR_NSEEDS:-48}"
SEED0="${RR_SEED0:-20265000}"
SEEDS=$(seq -s, "$SEED0" "$((SEED0 + NSEEDS - 1))")

# RR_TAG (e.g. "smoke") routes to a SEPARATE output dir so a smoke never pollutes or
# invalidates the real resume.
TAG="${RR_TAG:-}"
OUTDIR="sim/drac/results/rr_repeat${TAG:+_$TAG}"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/rr_${CELL}.tsv"
LOG="$OUTDIR/log_${CELL}.out"

echo "cell=$CELL scope=$SCOPE design=$NSIRE/$NDAM/$NOFF records=$RECORDS n=$((NOFF * RECORDS)) truth=($SA,$SPE,$SEE) mu=$MU nseeds=$NSEEDS seed0=$SEED0 out=$OUT"

# ---- run: piped through tee; capture Julia's REAL exit code via PIPESTATUS ----
julia --project=. sim/phase3_repeatability_recovery_gate.jl \
  --cell="$CELL" --scope="$SCOPE" \
  --nsire="$NSIRE" --ndam="$NDAM" --noffspring="$NOFF" --records="$RECORDS" \
  --sigma-a2="$SA" --sigma-pe2="$SPE" --sigma-e2="$SEE" --mu="$MU" \
  --seeds="$SEEDS" --out="$OUT" --resume=true 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}

# REAL check #1 — Julia exit code. A gate FAIL (or a boundary cell that under-recovers)
# does NOT set RC!=0 (gate is DATA), and a single throwing SEED is caught inside the driver
# and banked, so RC!=0 is a GENUINE crash/OOM/timeout.
if [[ $RC -ne 0 ]]; then
  echo "FAILED cell=$CELL rc=$RC (genuine Julia error/timeout — NOT a gate fail). Tail of $LOG:" >&2
  tail -n 25 "$LOG" >&2
  exit "$RC"
fi

# REAL check #2 — the artifact. SLURM COMPLETED != work done: the TSV must hold at least
# NSEEDS data rows for THIS cell (thrown seeds are banked as rows, so this reaches NSEEDS
# even at the identifiability boundary).
if [[ ! -s "$OUT" ]]; then
  echo "EMPTY_OUTPUT cell=$CELL — expected TSV $OUT is missing or empty; see $LOG" >&2
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
grep -E '^(CONVERGENCE|NON-INTERPRETABLE|GATE|GATE_JSON|RUN_COMPLETE|  t |  sigma_|  h2 )' "$LOG" || true

# ----------------------------------------------------------------------------
# SMOKE FIRST (doc-34 §12) — run THREE cells so the smoke actually exercises the STRESSED
# regime, not only the easy one: array index 1 = WELL-POWERED (the largest dense fit, n=3200,
# so it also sets the conservative --time bound) PLUS the two cells most likely to throw or
# fail to converge under the engine's log-variance parametrization at sigma_pe2 -> 0:
# index 2 = ladder_rec1 (boundary_rec1, the records=1 identifiability edge) and
# index 6 = null_pe0 (sigma_pe2 = 0). A REDUCED seed count in a SEPARATE tagged dir so the
# smoke never pollutes the real resume:
#
#   sbatch --array=1,2,6 --time=1:30:00 \
#     --export=ALL,RR_NSEEDS=3,RR_TAG=smoke sim/drac/phase3_repeatability_gate.sbatch
#
# Verify (per array task): sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ExitCode
# — EVERY task must be State=COMPLETED, ExitCode=0:0. A stressed cell that throws or falls
# below the interpretability floor is NOT a smoke failure: the driver banks throws as rows,
# still prints RUN_COMPLETE, and exits 0 (the gate / interpretability verdict is DATA, not
# the exit code). tail each results/slurm_rr_repeat_gate_<jobid>_{1,2,6}.out for
# "=== OK cell=<cell> rows=3 ===" + a CONVERGENCE line: wellpowered should reach a GATE line
# (gate_pass=... screening_only=true), while ladder_rec1 / null_pe0 may legitimately print
# NON-INTERPRETABLE (conv_rate < 0.90) OR a GATE line — either is a clean smoke as long as
# ExitCode=0:0 and RUN_COMPLETE is present. wc -l each of
# sim/drac/results/rr_repeat_smoke/rr_{wellpowered,ladder_rec1,null_pe0}.tsv (want 4 = 3 data
# + header). Re-run the SAME smoke to confirm resume: each log shows "resume: 3 of 3 declared
# seeds already present" and "new_fits=0", still ExitCode 0:0.
#
# Then `seff <jobid>` -> right-size --time (Elapsed for 3 seeds x 16 for 48, + precompile +
# 30% margin) and --mem (MaxRSS), and ONLY then launch the full array:
#   sbatch sim/drac/phase3_repeatability_gate.sbatch
# ----------------------------------------------------------------------------
