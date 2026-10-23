#!/usr/bin/env bash
# #366 S5 — Totoro, N=2000, main_rest (low_pe, near_pe, near_va).
# Owner go 2026-09-25: N=2000 (DRAC primary; Totoro is the no-queue bank).
# Requires: K366_S5_GO=1
#
# Usage (on Totoro after rsync → ~/hsq_work/HSquared-coverage-366-n2000):
#   K366_S5_GO=1 bash sim/k366_totoro_n2000_nearbound.sh
set -euo pipefail

if [[ "${K366_S5_GO:-}" != "1" ]]; then
  echo "PAUSED: owner has not authorized S5. Set K366_S5_GO=1 after Totoro/DRAC + N answer." >&2
  exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

JULIA_BIN="${JULIA_BIN:-$(command -v julia)}"
CELL_SPEC="${K366_CELL:-main_rest}"
OUT="docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-totoro-n2000-nearbound-replicates.tsv"
SUM="docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-totoro-n2000-nearbound-summary.tsv"
LOG="docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-totoro-n2000-nearbound.log"

mkdir -p "$(dirname "$OUT")"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1

{
  echo "HOST=totoro N=2000 cells=${CELL_SPEC} START=$(date -Iseconds)"
  if command -v taskset >/dev/null 2>&1; then
    echo "AFFINITY=taskset -c 0-3"
    taskset -c 0-3 "$JULIA_BIN" --project=. sim/phase3_k_effect_coverage.jl \
      --mode=main --host=Totoro --reps=2000 --cell="${CELL_SPEC}" --resume=true \
      --out="$OUT" --summary="$SUM"
  else
    echo "AFFINITY=none (taskset missing); thread caps only"
    "$JULIA_BIN" --project=. sim/phase3_k_effect_coverage.jl \
      --mode=main --host=Totoro --reps=2000 --cell="${CELL_SPEC}" --resume=true \
      --out="$OUT" --summary="$SUM"
  fi
  echo "END=$(date -Iseconds)"
} 2>&1 | tee -a "$LOG"

echo "Wrote $OUT / $SUM (log $LOG)"
