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
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
OUTDIR="$(cd "$OUTDIR" && pwd -P)"
export OUTDIR
case "$OUTDIR/" in
  "$REPO_ROOT/"*) echo "OUTDIR must be outside the git checkout: $OUTDIR" >&2; exit 2 ;;
esac

if [[ "$MODE" == pilot ]]; then
  MANIFEST="$OUTDIR/pilot_manifest.tsv"
  if [[ ! -e "$MANIFEST" && ! -e "$OUTDIR/environment_manifest.txt" ]]; then
    "$JULIA" --project=. "$DRIVER" --mode=manifest --tier=pilot --out-dir="$OUTDIR"
  else
    [[ -s "$MANIFEST" && -s "$OUTDIR/environment_manifest.txt" ]] || {
      echo "Incomplete immutable pilot state in $OUTDIR; use a fresh OUTDIR" >&2; exit 2;
    }
    echo "reusing immutable pilot manifest $MANIFEST"
  fi
else
  MANIFEST="$OUTDIR/confirmation_manifest.tsv"
  [[ -s "$MANIFEST" ]] || { echo "Run pilot summarization first: missing $MANIFEST" >&2; exit 2; }
fi

PEAK_MB=""
if [[ -d "$OUTDIR/raw/pilot" ]]; then
  PEAK_MB="$(find "$OUTDIR/raw/pilot" -name '*.tsv' -type f -exec awk -F '\t' 'NR==2 {print $18}' {} + | sort -nr | head -1)"
fi
AVAIL_MB="$(awk '/MemAvailable:/ {print int($2/1024)}' /proc/meminfo)"
[[ -n "$AVAIL_MB" ]] || { echo "Could not derive available RAM" >&2; exit 2; }
SAFE_WORKERS=""
if [[ -n "$PEAK_MB" ]]; then
  SAFE_WORKERS="$(awk -v ram="$AVAIL_MB" -v rss="$PEAK_MB" 'BEGIN {n=int(0.7*ram/rss); if(n<1)n=1; if(n>96)n=96; print n}')"
fi

if [[ "$NWORKERS" == auto ]]; then
  [[ -n "$SAFE_WORKERS" ]] || { echo "NWORKERS=auto requires completed pilot rows" >&2; exit 2; }
  NWORKERS="$SAFE_WORKERS"
  echo "auto-sized NWORKERS=$NWORKERS from available_ram_mb=$AVAIL_MB pilot_peak_rss_mb=$PEAK_MB"
fi
(( NWORKERS >= 1 && NWORKERS <= 96 )) || { echo "NWORKERS must be in 1..96 or auto" >&2; exit 2; }
if [[ -n "$SAFE_WORKERS" ]]; then
  (( NWORKERS <= SAFE_WORKERS )) || {
    echo "NWORKERS=$NWORKERS exceeds RAM-safe cap $SAFE_WORKERS (available_ram_mb=$AVAIL_MB pilot_peak_rss_mb=$PEAK_MB)" >&2
    exit 2
  }
elif (( NWORKERS > 16 )); then
  echo "NWORKERS above 16 requires pilot peak RSS for RAM sizing" >&2
  exit 2
fi

tail -n +2 "$MANIFEST" | cut -f1-3 | \
  xargs -r -P "$NWORKERS" -n 3 sh -c '
    tier="$1"; cell="$2"; seed="$3"
    "$JULIA" --project=. "$DRIVER" --mode=run --tier="$tier" --cell="$cell" \
      --seed="$seed" --out-dir="$OUTDIR" --resume=true
  ' sh

"$JULIA" --project=. "$DRIVER" --mode=summarize --tier="$MODE" --out-dir="$OUTDIR"
