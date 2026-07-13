#!/usr/bin/env bash
set -euo pipefail

# Totoro launcher for docs 45/45a/45b.  The driver itself never forks; this
# wrapper gives each dataset/arm a fresh Julia process and never exceeds the
# preregistered 16-worker discovery ceiling.

ACTION=${1:-}
OUT_DIR=${2:-}
WORKERS=${WORKERS:-16}
JULIA_BIN=${JULIA_BIN:-julia}
REPO_ROOT=${REPO_ROOT:-$HOME/hsq_work/HSquared.jl}
DRIVER="$REPO_ROOT/sim/phase2_v07_genomic_optimizer_localization.jl"
R_ORACLE=${R_ORACLE:-$HOME/hsq_work/hsquared/tools/v07_genomic_boundary_oracle.R}

[[ -n "$ACTION" ]] || { echo "usage: $0 ACTION OUT_DIR" >&2; exit 2; }
[[ -n "$OUT_DIR" ]] || { echo "OUT_DIR is required" >&2; exit 2; }
[[ "$OUT_DIR" = /* ]] || { echo "OUT_DIR must be absolute" >&2; exit 2; }
[[ "$WORKERS" =~ ^[0-9]+$ ]] && (( WORKERS >= 1 && WORKERS <= 16 )) || {
  echo "WORKERS must be an integer in 1:16" >&2
  exit 2
}

export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1
export JULIA_NUM_THREADS=1

run_manifest_arms() {
  local phase=$1 manifest="$OUT_DIR/${1}_manifest.tsv"
  [[ -f "$manifest" ]] || { echo "missing $manifest" >&2; exit 2; }
  tail -n +2 "$manifest" | cut -f2,3,5 | \
    xargs -P "$WORKERS" -n 3 bash -c '
      cell=$1; seed=$2; arm=$3
      "$JULIA_BIN" --project="$REPO_ROOT" "$DRIVER" --mode=run \
        --phase="'$phase'" --cell="$cell" --seed="$seed" --arm="$arm" \
        --out-dir="$OUT_DIR" --resume=true
    ' bash
}

seal_datasets() {
  local phase=$1 manifest="$OUT_DIR/${1}_manifest.tsv"
  tail -n +2 "$manifest" | cut -f2,3 | sort -u | \
    xargs -P "$WORKERS" -n 2 bash -c '
      "$JULIA_BIN" --project="$REPO_ROOT" "$DRIVER" --mode=dataset \
        --phase="'$phase'" --cell="$1" --seed="$2" --out-dir="$OUT_DIR"
    ' bash
}

run_oracles() {
  local phase=$1 manifest="$OUT_DIR/${1}_manifest.tsv"
  [[ -f "$manifest" ]] || { echo "missing $manifest" >&2; exit 2; }
  [[ -f "$R_ORACLE" ]] || { echo "missing R oracle: $R_ORACLE" >&2; exit 2; }
  tail -n +2 "$manifest" | cut -f2,3 | sort -u | \
    xargs -P "$WORKERS" -n 2 bash -c '
      cell=$1; seed=$2
      packet="$OUT_DIR/datasets/'"$phase"'/$cell/$seed"
      output="$OUT_DIR/oracle/'"$phase"'/$cell/$seed.tsv"
      mkdir -p "$(dirname "$output")"
      Rscript "$R_ORACLE" oracle --dataset "$packet" --output "$output"
      Rscript "$R_ORACLE" verify --dataset "$packet" --output "$output"
      "$JULIA_BIN" --project="$REPO_ROOT" "$DRIVER" --mode=verify \
        --phase="'"$phase"'" --cell="$cell" --seed="$seed" --out-dir="$OUT_DIR"
    ' bash
}

export JULIA_BIN REPO_ROOT DRIVER R_ORACLE OUT_DIR
cd "$REPO_ROOT"

case "$ACTION" in
  selftest)
    "$JULIA_BIN" --project=. "$DRIVER" --mode=selftest
    ;;
  discovery-manifest)
    [[ -n "${PILOT_DIR:-}" ]] || { echo "PILOT_DIR is required" >&2; exit 2; }
    "$JULIA_BIN" --project=. "$DRIVER" --mode=manifest --phase=discovery \
      --pilot-dir="$PILOT_DIR" --out-dir="$OUT_DIR"
    ;;
  discovery-run)
    run_manifest_arms discovery
    ;;
  discovery-datasets)
    seal_datasets discovery
    ;;
  discovery-oracle)
    run_oracles discovery
    ;;
  discovery-summarize)
    "$JULIA_BIN" --project=. "$DRIVER" --mode=summarize --phase=discovery --out-dir="$OUT_DIR"
    ;;
  holdout-manifest)
    "$JULIA_BIN" --project=. "$DRIVER" --mode=manifest --phase=holdout --out-dir="$OUT_DIR"
    ;;
  holdout-run)
    run_manifest_arms holdout
    ;;
  holdout-datasets)
    seal_datasets holdout
    ;;
  holdout-oracle)
    run_oracles holdout
    ;;
  holdout-summarize)
    "$JULIA_BIN" --project=. "$DRIVER" --mode=summarize --phase=holdout --out-dir="$OUT_DIR"
    ;;
  *)
    echo "unknown ACTION: $ACTION" >&2
    exit 2
    ;;
esac
