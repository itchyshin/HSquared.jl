#!/usr/bin/env bash
set -euo pipefail

ROOT=${ROOT:-$HOME/hsq_work/HSquared-boundary-holdout}
OUT_DIR=${OUT_DIR:-$HOME/hsq_results/v07_genomic_boundary_holdout}
DISCOVERY_DIR=${DISCOVERY_DIR:-$HOME/hsq_results/v07_genomic_optimizer_localization}
R_REPO=${R_REPO:-$HOME/hsq_work/hsquared-boundary-holdout}
R_ORACLE=${R_ORACLE:-$R_REPO/tools/v07_genomic_boundary_oracle.R}
JULIA_BIN=${JULIA_BIN:-$HOME/hsq_work/julia-1.10.10/bin/julia}
WORKERS=${WORKERS:-16}
DRIVER=sim/phase2_v07_genomic_boundary_holdout.jl

[[ "$WORKERS" =~ ^[0-9]+$ ]] && (( WORKERS >= 1 && WORKERS <= 96 )) || {
  echo "WORKERS must be an integer in [1,96]" >&2
  exit 2
}

export JULIA_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1

cd "$ROOT"

run_manifest() {
  tail -n +2 "$OUT_DIR/holdout_manifest.tsv" |
    awk -F '\t' '{print $1 "\t" $2}' |
    xargs -P "$WORKERS" -n 2 bash -c '
      "$0" --project=. "$1" --mode=run --out-dir="$2" --cell="$3" --seed="$4"
    ' "$JULIA_BIN" "$DRIVER" "$OUT_DIR"
}

run_oracles() {
  find "$OUT_DIR/packets" -mindepth 2 -maxdepth 2 -type d -print0 |
    sort -z |
    xargs -0 -P "$WORKERS" -n 1 bash -c '
      packet=$1
      cell=$(basename "$(dirname "$packet")")
      seed=$(basename "$packet")
      output="$2/oracle/$cell/$seed.tsv"
      mkdir -p "$(dirname "$output")"
      if [[ -f "$output" && -f "$output.sha256" ]]; then
        Rscript "$3" holdout-verify --dataset "$packet" --output "$output"
      else
        Rscript "$3" holdout-oracle --dataset "$packet" --output "$output"
        Rscript "$3" holdout-verify --dataset "$packet" --output "$output"
      fi
    ' _ {} "$OUT_DIR" "$R_ORACLE"
}

action=${1:-selftest}
case "$action" in
  selftest)
    "$JULIA_BIN" --project=. "$DRIVER" --mode=selftest
    ;;
  seal)
    "$JULIA_BIN" --project=. "$DRIVER" --mode=seal --out-dir="$OUT_DIR" \
      --discovery-dir="$DISCOVERY_DIR" --r-repo="$R_REPO" --r-oracle="$R_ORACLE"
    ;;
  manifest)
    "$JULIA_BIN" --project=. "$DRIVER" --mode=manifest --out-dir="$OUT_DIR"
    ;;
  run)
    run_manifest
    ;;
  oracle)
    run_oracles
    ;;
  summarize)
    "$JULIA_BIN" --project=. "$DRIVER" --mode=summarize --out-dir="$OUT_DIR"
    ;;
  *)
    echo "usage: $0 {selftest|seal|manifest|run|oracle|summarize}" >&2
    exit 2
    ;;
esac
