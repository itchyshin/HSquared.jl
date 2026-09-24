#!/usr/bin/env bash
# #366 S5 — Totoro, N=2000, sparse interior only.
# PAUSED until owner answers Totoro/DRAC + N on issue #366.
# Requires: K366_S5_GO=1
#
# Usage (on Totoro, repo already rsynced e.g. ~/hsq_work/HSquared-coverage-366):
#   K366_S5_GO=1 bash sim/k366_totoro_n2000.sh
set -euo pipefail

if [[ "${K366_S5_GO:-}" != "1" ]]; then
  echo "PAUSED: owner has not authorized S5. Set K366_S5_GO=1 after Totoro/DRAC + N answer." >&2
  exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

JULIA_BIN="${JULIA_BIN:-$(command -v julia)}"
OUT="docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n2000-replicates.tsv"
SUM="docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n2000-summary.tsv"
LOG="docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n2000.log"

mkdir -p "$(dirname "$OUT")"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1

{
  echo "HOST=totoro N=2000 START=$(date -Iseconds)"
  "$JULIA_BIN" --project=. sim/phase3_k_effect_coverage.jl \
    --mode=main --host=Totoro --reps=2000 --cell=interior --resume=true \
    --out="$OUT" --summary="$SUM"
  echo "END=$(date -Iseconds)"
} 2>&1 | tee -a "$LOG"

echo "Wrote $OUT / $SUM (log $LOG)"
