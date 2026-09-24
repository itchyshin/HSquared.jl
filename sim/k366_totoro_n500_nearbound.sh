#!/usr/bin/env bash
# #366 S5 — Totoro, N=500, near-boundary (+ low_pe) main-rest cells.
# Cells: low_pe, near_pe, near_va (interior already banked separately).
# Requires: K366_S5_GO=1
# Cores: prefer taskset -c 0-3 (Linux/Totoro); thread caps always.
#
# Usage (on Totoro, repo already rsynced e.g. ~/hsq_work/HSquared-coverage-366):
#   K366_S5_GO=1 bash sim/k366_totoro_n500_nearbound.sh
set -euo pipefail

if [[ "${K366_S5_GO:-}" != "1" ]]; then
  echo "PAUSED: owner has not authorized S5. Set K366_S5_GO=1 after Totoro/DRAC + N answer." >&2
  exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

JULIA_BIN="${JULIA_BIN:-$(command -v julia)}"
OUT="docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n500-nearbound-replicates.tsv"
SUM="docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n500-nearbound-summary.tsv"
LOG="docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n500-nearbound.log"

mkdir -p "$(dirname "$OUT")"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1

# main_rest = low_pe,near_pe,near_va (G2 near-boundary + remaining main cell)
CELL_SPEC="${K366_CELL:-main_rest}"

{
  echo "HOST=totoro N=500 cells=${CELL_SPEC} START=$(date -Iseconds)"
  if command -v taskset >/dev/null 2>&1; then
    echo "AFFINITY=taskset -c 0-3"
    taskset -c 0-3 "$JULIA_BIN" --project=. sim/phase3_k_effect_coverage.jl \
      --mode=main --host=Totoro --reps=500 --cell="${CELL_SPEC}" --resume=true \
      --out="$OUT" --summary="$SUM"
  else
    echo "AFFINITY=none (taskset missing); thread caps only"
    "$JULIA_BIN" --project=. sim/phase3_k_effect_coverage.jl \
      --mode=main --host=Totoro --reps=500 --cell="${CELL_SPEC}" --resume=true \
      --out="$OUT" --summary="$SUM"
  fi
  echo "END=$(date -Iseconds)"
} 2>&1 | tee -a "$LOG"

echo "Wrote $OUT / $SUM (log $LOG)"
