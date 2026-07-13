#!/usr/bin/env bash
set -euo pipefail

DRIVER_ROOT=${DRIVER_ROOT:-$HOME/hsq_work/HSquared-v07-holdout-v2-driver}
CANDIDATE_ROOT=${CANDIDATE_ROOT:-$HOME/hsq_work/HSquared-v07-performance-candidate}
REFERENCE_ROOT=${REFERENCE_ROOT:-$HOME/hsq_work/HSquared-v07-reference}
OUT_DIR=${OUT_DIR:-$HOME/hsq_work/v07_boundary_performance_20260713/results/fresh-holdout-v2}
DISCOVERY_DIR=${DISCOVERY_DIR:-$HOME/hsq_work/v07_boundary_performance_20260713/results/discovery-v4}
DISCOVERY_CORPUS=${DISCOVERY_CORPUS:-$HOME/hsq_work/v07_localization_20260712/results/discovery-5d14acd1023d}
R_REPO=${R_REPO:-$HOME/hsq_work/hsquared-v07-holdout-v2}
R_ORACLE=${R_ORACLE:-$R_REPO/tools/v07_genomic_boundary_oracle.R}
JULIA_BIN=${JULIA_BIN:-$HOME/hsq_work/julia-1.10.10/bin/julia}
WORKERS=${WORKERS:-16}
DRIVER=$DRIVER_ROOT/sim/phase2_v07_genomic_boundary_holdout_v2.jl
CANDIDATE_COMMIT=fc9d39df650b20aa09d769d9f9528eed1b606f1e
REFERENCE_COMMIT=ecc058f380be71058c9cfde373c345ab7a2f6aba
R_COMMIT=05ba8aed1c19a7971eeaaf3199fd1afe7d899561

[[ "$WORKERS" =~ ^[0-9]+$ ]] && (( WORKERS >= 1 && WORKERS <= 96 )) || {
  echo "WORKERS must be an integer in [1,96]" >&2
  exit 2
}

export JULIA_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1

assert_environment() {
  [[ "$(hostname)" == totoro ]] || { echo "fresh holdout must run on totoro" >&2; exit 2; }
  [[ "$($JULIA_BIN --version)" == "julia version 1.10.10" ]] || {
    echo "fresh holdout requires Julia 1.10.10" >&2
    exit 2
  }
  [[ "$(cd "$DRIVER_ROOT" && pwd -P)" != "$(cd "$CANDIDATE_ROOT" && pwd -P)" ]] || {
    echo "driver and selected-candidate checkouts must be separate" >&2
    exit 2
  }
  [[ -z "$(git -C "$DRIVER_ROOT" status --porcelain --untracked-files=all)" ]] || {
    echo "driver checkout is dirty" >&2
    exit 2
  }
  [[ -z "$(git -C "$CANDIDATE_ROOT" status --porcelain --untracked-files=all)" ]] || {
    echo "candidate checkout is dirty" >&2
    exit 2
  }
  [[ "$(git -C "$CANDIDATE_ROOT" rev-parse HEAD)" == "$CANDIDATE_COMMIT" ]] || {
    echo "selected candidate commit drift" >&2
    exit 2
  }
  [[ -z "$(git -C "$REFERENCE_ROOT" status --porcelain --untracked-files=all)" &&
     "$(git -C "$REFERENCE_ROOT" rev-parse HEAD)" == "$REFERENCE_COMMIT" ]] || {
    echo "reference checkout is dirty or at the wrong commit" >&2
    exit 2
  }
  [[ -z "$(git -C "$R_REPO" status --porcelain --untracked-files=all)" &&
     "$(git -C "$R_REPO" rev-parse HEAD)" == "$R_COMMIT" ]] || {
    echo "R checkout is dirty or at the wrong commit" >&2
    exit 2
  }
}

run_manifest() {
  export OUT_DIR DRIVER JULIA_BIN CANDIDATE_ROOT
  tail -n +2 "$OUT_DIR/holdout_manifest.tsv" |
    awk -F '\t' '{print $1 "\t" $2}' |
    xargs -P "$WORKERS" -n 2 bash -c '
      "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=run \
        --out-dir="$OUT_DIR" --cell="$1" --seed="$2"
    ' _
}

run_oracles() {
  find "$OUT_DIR/packets" -mindepth 2 -maxdepth 2 -type d -print0 |
    sort -z |
    xargs -0 -P "$WORKERS" -n 1 bash -c '
      out_dir=$1
      r_oracle=$2
      r_repo=$3
      packet=$4
      cell=$(basename "$(dirname "$packet")")
      seed=$(basename "$packet")
      output="$out_dir/oracle/$cell/$seed.tsv"
      mkdir -p "$(dirname "$output")"
      if [[ -f "$output" && -f "$output.sha256" ]]; then
        Rscript "$r_oracle" holdout-verify --dataset "$packet" --output "$output" \
          --seal "$out_dir/candidate_seal.tsv" --r-repo "$r_repo"
      else
        Rscript "$r_oracle" holdout-oracle --dataset "$packet" --output "$output" \
          --seal "$out_dir/candidate_seal.tsv" --r-repo "$r_repo"
        Rscript "$r_oracle" holdout-verify --dataset "$packet" --output "$output" \
          --seal "$out_dir/candidate_seal.tsv" --r-repo "$r_repo"
      fi
    ' _ "$OUT_DIR" "$R_ORACLE" "$R_REPO"
}

oracle_argument_selftest() {
  observed=$(printf '/tmp/sealed-packet\0' |
    xargs -0 -n 1 bash -c 'printf "%s|%s|%s|%s" "$1" "$2" "$3" "$4"' \
      _ "$OUT_DIR" "$R_ORACLE" "$R_REPO")
  expected="$OUT_DIR|$R_ORACLE|$R_REPO|/tmp/sealed-packet"
  [[ "$observed" == "$expected" ]] || {
    echo "oracle xargs argument wiring failed" >&2
    exit 1
  }
}

run_argument_selftest() {
  observed=$(printf 'cell\t123\n' | xargs -n 2 bash -c 'printf "%s|%s" "$1" "$2"' _)
  [[ "$observed" == "cell|123" ]] || { echo "holdout xargs argument wiring failed" >&2; exit 1; }
}

action=${1:-selftest}
case "$action" in
  selftest)
    assert_environment
    oracle_argument_selftest
    run_argument_selftest
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=selftest
    ;;
  seal)
    assert_environment
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" \
      "$CANDIDATE_ROOT/sim/phase2_v07_genomic_boundary_performance.jl" --mode=validate \
      --out-dir="$DISCOVERY_DIR" --discovery-dir="$DISCOVERY_CORPUS"
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=seal --out-dir="$OUT_DIR" \
      --discovery-dir="$DISCOVERY_DIR" --reference-root="$REFERENCE_ROOT" \
      --r-repo="$R_REPO" --r-oracle="$R_ORACLE"
    ;;
  manifest)
    assert_environment
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=manifest --out-dir="$OUT_DIR"
    ;;
  run)
    assert_environment
    run_manifest
    ;;
  oracle)
    assert_environment
    run_oracles
    ;;
  summarize)
    assert_environment
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=summarize --out-dir="$OUT_DIR"
    ;;
  *)
    echo "usage: $0 {selftest|seal|manifest|run|oracle|summarize}" >&2
    exit 2
    ;;
esac
