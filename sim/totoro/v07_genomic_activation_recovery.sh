#!/usr/bin/env bash
set -euo pipefail

# Totoro launcher for the preregistered v0.7 genomic activation recovery.
# Run from the HSquared.jl checkout. Raw results stay outside git by default.
#
# Pilot:
#   MODE=pilot OUTDIR="$HOME/hsq_work/results/v07_genomic_activation" \
#     bash sim/totoro/v07_genomic_activation_recovery.sh
# After pilot summarization generates confirmation_manifest.tsv:
#   MODE=confirm OUTDIR="$HOME/hsq_work/results/v07_genomic_activation" \
#     bash sim/totoro/v07_genomic_activation_recovery.sh
#
# NWORKERS defaults to 16 for smoke/resource sizing. Raise only after inspecting
# pilot peak_rss_mb; never exceed min(96, floor(0.7*available_RAM/peak_RSS)).

MODE="${MODE:-pilot}"
OUTDIR="${OUTDIR:-$HOME/hsq_work/results/v07_genomic_activation}"
NWORKERS="${NWORKERS:-16}"
JULIA="${JULIA:-$HOME/hsq_work/julia-1.10.10/bin/julia}"
DRIVER="sim/phase2_v07_genomic_activation_recovery.jl"

case "$MODE" in pilot|confirm) ;; *) echo "MODE must be pilot or confirm" >&2; exit 2;; esac
[[ -x "$JULIA" ]] || { echo "Julia not executable: $JULIA" >&2; exit 2; }

export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 JULIA_NUM_THREADS=1
export JULIA DRIVER OUTDIR
mkdir -p "$OUTDIR"

if [[ "$MODE" == pilot ]]; then
  "$JULIA" --project=. "$DRIVER" --mode=manifest --tier=pilot --out-dir="$OUTDIR"
  MANIFEST="$OUTDIR/pilot_manifest.tsv"
else
  MANIFEST="$OUTDIR/confirmation_manifest.tsv"
  [[ -s "$MANIFEST" ]] || { echo "Run pilot summarization first: missing $MANIFEST" >&2; exit 2; }
fi

if [[ "$NWORKERS" == auto ]]; then
  [[ "$MODE" == confirm ]] || { echo "NWORKERS=auto requires completed pilot rows" >&2; exit 2; }
  PEAK_MB="$(find "$OUTDIR/raw/pilot" -name '*.tsv' -type f -exec awk -F '\t' 'NR==2 {print $17}' {} + | sort -nr | head -1)"
  AVAIL_MB="$(awk '/MemAvailable:/ {print int($2/1024)}' /proc/meminfo)"
  [[ -n "$PEAK_MB" && -n "$AVAIL_MB" ]] || { echo "Could not derive pilot RSS or available RAM" >&2; exit 2; }
  NWORKERS="$(awk -v ram="$AVAIL_MB" -v rss="$PEAK_MB" 'BEGIN {n=int(0.7*ram/rss); if(n<1)n=1; if(n>96)n=96; print n}')"
  echo "auto-sized NWORKERS=$NWORKERS from available_ram_mb=$AVAIL_MB pilot_peak_rss_mb=$PEAK_MB"
fi
(( NWORKERS >= 1 && NWORKERS <= 96 )) || { echo "NWORKERS must be in 1..96 or auto" >&2; exit 2; }

tail -n +2 "$MANIFEST" | cut -f1-3 | \
  xargs -P "$NWORKERS" -n 3 sh -c '
    tier="$1"; cell="$2"; seed="$3"
    "$JULIA" --project=. "$DRIVER" --mode=run --tier="$tier" --cell="$cell" \
      --seed="$seed" --out-dir="$OUTDIR" --resume=true
  ' sh

"$JULIA" --project=. "$DRIVER" --mode=summarize --tier="$MODE" --out-dir="$OUTDIR"
