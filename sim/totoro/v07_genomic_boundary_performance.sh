#!/usr/bin/env bash
set -euo pipefail

# Doc-47 discovery-only launcher. Each dataset/repeat is one orchestration unit;
# its three implementations run sequentially in the preregistered Latin order,
# while independent units may run in parallel.

ACTION=${1:-selftest}
DISCOVERY_DIR=${DISCOVERY_DIR:-/home/snakagaw/hsq_work/v07_localization_20260712/results/discovery-5d14acd1023d}
OUT_DIR=${OUT_DIR:-$HOME/hsq_work/v07_boundary_performance_20260713/results/discovery}
DRIVER_ROOT=${DRIVER_ROOT:-$HOME/hsq_work/HSquared-v07-performance}
REFERENCE_ROOT=${REFERENCE_ROOT:-$HOME/hsq_work/HSquared-v07-reference}
CANDIDATE_ROOT=${CANDIDATE_ROOT:-$HOME/hsq_work/HSquared-v07-performance}
JULIA_BIN=${JULIA_BIN:-$HOME/hsq_work/julia-1.10.10/bin/julia}
WORKERS=${WORKERS:-16}
DRIVER=$DRIVER_ROOT/sim/phase2_v07_genomic_boundary_performance.jl
REFERENCE_COMMIT=ecc058f380be71058c9cfde373c345ab7a2f6aba

[[ "$WORKERS" =~ ^[0-9]+$ ]] && (( WORKERS >= 1 && WORKERS <= 96 )) || {
  echo "WORKERS must be an integer in [1,96]" >&2
  exit 2
}
[[ "$OUT_DIR" = /* && "$DISCOVERY_DIR" = /* ]] || {
  echo "OUT_DIR and DISCOVERY_DIR must be absolute" >&2
  exit 2
}

export JULIA_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1

assert_driver_binding() {
  [[ -e "$DRIVER_ROOT/.git" && -e "$CANDIDATE_ROOT/.git" ]] || {
    echo "driver and candidate checkouts must exist" >&2
    exit 2
  }
  [[ "$(cd "$DRIVER_ROOT" && pwd -P)" == "$(cd "$CANDIDATE_ROOT" && pwd -P)" ]] || {
    echo "DRIVER_ROOT must be the exact CANDIDATE_ROOT checkout" >&2
    exit 2
  }
  [[ "$DRIVER" == "$CANDIDATE_ROOT/sim/phase2_v07_genomic_boundary_performance.jl" ]] || {
    echo "driver path is not bound to candidate checkout" >&2
    exit 2
  }
}

assert_study_environment() {
  [[ "$(hostname)" == totoro ]] || { echo "doc47 profiling must run on totoro" >&2; exit 2; }
  [[ "$($JULIA_BIN --version)" == "julia version 1.10.10" ]] || {
    echo "doc47 profiling requires Julia 1.10.10" >&2
    exit 2
  }
}

assert_checkout() {
  local root=$1 expected=${2:-}
  [[ -e "$root/.git" ]] || { echo "missing checkout: $root" >&2; exit 2; }
  [[ -z "$(git -C "$root" status --porcelain --untracked-files=all)" ]] || {
    echo "checkout is dirty: $root" >&2
    exit 2
  }
  if [[ -n "$expected" && "$(git -C "$root" rev-parse HEAD)" != "$expected" ]]; then
    echo "checkout commit mismatch: $root" >&2
    exit 2
  fi
}

run_units() {
  local admission=$OUT_DIR/admission/discovery_admission.tsv
  [[ -f "$admission" ]] || { echo "run admission first" >&2; exit 2; }
  assert_checkout "$REFERENCE_ROOT" "$REFERENCE_COMMIT"
  assert_checkout "$CANDIDATE_ROOT"
  local candidate_commit
  candidate_commit=$(git -C "$CANDIDATE_ROOT" rev-parse HEAD)
  export OUT_DIR DISCOVERY_DIR DRIVER JULIA_BIN REFERENCE_ROOT CANDIDATE_ROOT REFERENCE_COMMIT candidate_commit
  tail -n +2 "$admission" | cut -f2,3,4 | while IFS=$'\t' read -r cell seed role; do
    for repeat in 1 2 3 4 5; do
      printf '%s\t%s\t%s\t%s\n' "$cell" "$seed" "$role" "$repeat"
    done
  done | xargs -P "$WORKERS" -n 4 bash -c '
    set -euo pipefail
    cell=$1; seed=$2; role=$3; repeat=$4
    cycle=$(( (seed + repeat) % 3 ))
    case "$cycle" in
      0) order=(default_ai reference_boundary candidate_boundary) ;;
      1) order=(reference_boundary candidate_boundary default_ai) ;;
      2) order=(candidate_boundary default_ai reference_boundary) ;;
    esac
    timed_order=$(IFS=">"; echo "${order[*]}")
    index=0
    for implementation in "${order[@]}"; do
      index=$((index+1))
      if [[ "$implementation" == candidate_boundary ]]; then
        root=$CANDIDATE_ROOT; expected=$candidate_commit
      else
        root=$REFERENCE_ROOT; expected=$REFERENCE_COMMIT
      fi
      "$JULIA_BIN" --project="$root" "$DRIVER" --mode=run \
        --out-dir="$OUT_DIR" --discovery-dir="$DISCOVERY_DIR" \
        --cell="$cell" --seed="$seed" --role="$role" --repeat="$repeat" \
        --cycle="$cycle" --order-index="$index" --timed-order="$timed_order" \
        --implementation="$implementation" --expected-commit="$expected"
    done
  ' _
}

argument_selftest() {
  local observed
  observed=$(printf 'cell\t123\tcontrol\t4\n' | xargs -n 4 bash -c 'printf "%s|%s|%s|%s" "$1" "$2" "$3" "$4"' _)
  [[ "$observed" == "cell|123|control|4" ]] || {
    echo "xargs orchestration argument wiring failed" >&2
    exit 1
  }
  local order seed=123 repeat=4 cycle
  cycle=$(( (seed + repeat) % 3 ))
  case "$cycle" in
    0) order="default_ai>reference_boundary>candidate_boundary" ;;
    1) order="reference_boundary>candidate_boundary>default_ai" ;;
    2) order="candidate_boundary>default_ai>reference_boundary" ;;
  esac
  [[ "$cycle" == 1 && "$order" == "reference_boundary>candidate_boundary>default_ai" ]] || {
    echo "Latin-order launcher selftest failed" >&2
    exit 1
  }
  observed=$(printf 'cell\t123\tcontrol\t4\n' | xargs -n 4 bash -c '
    set -euo pipefail
    seed=$2; repeat=$4; cycle=$(( (seed + repeat) % 3 ))
    case "$cycle" in
      0) order=(default_ai reference_boundary candidate_boundary) ;;
      1) order=(reference_boundary candidate_boundary default_ai) ;;
      2) order=(candidate_boundary default_ai reference_boundary) ;;
    esac
    timed_order=$(IFS=">"; echo "${order[*]}")
    printf "%s|%s|%s" "$1" "$cycle" "$timed_order"
  ' _)
  [[ "$observed" == "cell|1|reference_boundary>candidate_boundary>default_ai" ]] || {
    echo "nested worker-script selftest failed" >&2
    exit 1
  }
}

case "$ACTION" in
  selftest)
    assert_driver_binding
    argument_selftest
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=selftest
    ;;
  admit)
    assert_driver_binding
    assert_study_environment
    assert_checkout "$CANDIDATE_ROOT"
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=admit \
      --out-dir="$OUT_DIR" --discovery-dir="$DISCOVERY_DIR"
    ;;
  run)
    assert_driver_binding
    assert_study_environment
    run_units
    ;;
  summarize)
    assert_driver_binding
    assert_study_environment
    assert_checkout "$CANDIDATE_ROOT"
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=summarize \
      --out-dir="$OUT_DIR" --discovery-dir="$DISCOVERY_DIR"
    ;;
  validate)
    assert_driver_binding
    assert_study_environment
    assert_checkout "$CANDIDATE_ROOT"
    "$JULIA_BIN" --project="$CANDIDATE_ROOT" "$DRIVER" --mode=validate \
      --out-dir="$OUT_DIR" --discovery-dir="$DISCOVERY_DIR"
    ;;
  *)
    echo "usage: $0 {selftest|admit|run|summarize|validate}" >&2
    exit 2
    ;;
esac
