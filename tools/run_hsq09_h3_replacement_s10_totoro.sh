#!/usr/bin/env bash
# Execute exactly one sealed H3 replacement S10 cell in an already isolated
# Totoro checkout.  This launcher is not a scheduler and never starts S11.
set -euo pipefail

readonly BASE_COMMIT="46232fbc"
readonly FIXTURE_SHA256="8c3ccaf70e005d9b0b7b5e96cf4b3cbaf7b489522b30a37c31dfaf12e1e0c82a"
readonly S2_MANIFEST_SHA256="d1183b3a6f13373f293ab333d94ecbdfdc18af7b519a7b56943318d6a7ff1510"
readonly RUNNER_SHA256="983816a3a5a426fccc260c27c479a0fdcced9e53ed4fd359b42caefb0b66dfb3"
readonly LOCK_SHA256="a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221"
readonly TIMEOUT_SECONDS=1800
readonly JULIA_BIN="${HSQ09_H3_REPLACEMENT_S10_JULIA_BIN:-${JULIA_BIN:-julia}}"

usage() { echo "usage: --dry-run --cell rg|ram | --run --cell rg|ram" >&2; exit 64; }
[[ $# -eq 3 ]] || usage
MODE="$1"; [[ "$2" == "--cell" ]] || usage; CELL="$3"
[[ "$MODE" == "--dry-run" || "$MODE" == "--run" ]] || usage
[[ "$CELL" == "rg" || "$CELL" == "ram" ]] || usage

require_hash() {
  local path="$1" expected="$2" label="$3"
  [[ -f "$path" ]] || { echo "REFUSING: missing $label" >&2; exit 70; }
  [[ "$(sha256sum "$path" | awk '{print $1}')" == "$expected" ]] || {
    echo "REFUSING: $label digest mismatch" >&2; exit 71;
  }
}

git rev-parse --verify --quiet "${BASE_COMMIT}^{commit}" >/dev/null || { echo "REFUSING: materialization base absent" >&2; exit 72; }
git merge-base --is-ancestor "$BASE_COMMIT" HEAD || { echo "REFUSING: checkout does not descend from materialization base" >&2; exit 73; }
git diff --quiet "$BASE_COMMIT" -- src || { echo "REFUSING: source differs from the sealed base" >&2; exit 74; }
if [[ -n "$(git status --porcelain | grep -v '^?? Manifest.toml$')" ]]; then
  echo "REFUSING: checkout has unsealed changes" >&2
  exit 75
fi
require_hash test/fixtures/h3_replacement_interval/fixture.toml "$FIXTURE_SHA256" fixture
require_hash docs/dev-log/evidence/2026-09-09-h3-replacement-s2-manifest.toml "$S2_MANIFEST_SHA256" materialization-manifest
require_hash sim/hsq09_h3_replacement_s10.jl "$RUNNER_SHA256" runner
require_hash Manifest.toml "$LOCK_SHA256" Manifest.toml
command -v "$JULIA_BIN" >/dev/null || { echo "REFUSING: Julia unavailable: $JULIA_BIN" >&2; exit 76; }
[[ "${JULIA_NUM_THREADS:-}" == "1" && "${OPENBLAS_NUM_THREADS:-}" == "1" ]] || { echo "REFUSING: pin JULIA_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1" >&2; exit 77; }

if [[ "$MODE" == "--dry-run" ]]; then
  "$JULIA_BIN" --project=. sim/hsq09_h3_replacement_s10.jl --dry-run "--cell=$CELL"
  exit 0
fi

[[ "${HSQ09_H3_REPLACEMENT_S10_ARMED:-}" == "1" ]] || { echo "REFUSING: explicit S10 arming missing" >&2; exit 78; }
readonly RESULTS_ROOT="${HSQ09_H3_REPLACEMENT_S10_RESULTS_ROOT:?REFUSING: results root required}"
readonly RUN_ID="${HSQ09_H3_REPLACEMENT_S10_RUN_ID:?REFUSING: run id required}"
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "REFUSING: invalid run id" >&2; exit 79; }
mkdir -p "$RESULTS_ROOT"
readonly FINAL_DIR="$RESULTS_ROOT/hsq09-h3-replacement-s10-${CELL}-${RUN_ID}"
readonly FAILED_DIR="${FINAL_DIR}.failed"
[[ ! -e "$FINAL_DIR" && ! -e "$FAILED_DIR" ]] || { echo "REFUSING: receipt identity exists" >&2; exit 80; }
readonly STAGE_DIR="$(mktemp -d "$RESULTS_ROOT/.hsq09-h3-replacement-s10-${CELL}-${RUN_ID}.stage.XXXXXX")"
publish_failure() {
  local rc="$1"
  printf 'S10_FAILURE_RETAINED cell=%s exit=%s\n' "$CELL" "$rc" >"$STAGE_DIR/launcher_failure.txt"
  (cd "$STAGE_DIR" && find . -maxdepth 1 -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS) || true
  mv "$STAGE_DIR" "$FAILED_DIR"; trap - EXIT
  echo "H3_REPLACEMENT_S10_FAILURE_RETAINED cell=$CELL dir=$FAILED_DIR exit=$rc" >&2
  exit "$rc"
}
trap 'rc=$?; [[ -d "$STAGE_DIR" ]] && publish_failure "$rc"' EXIT

printf 'cell=%s\nthreads=1\npath_only=true\nbase_commit=%s\n' "$CELL" "$BASE_COMMIT" >"$STAGE_DIR/config.txt"
git rev-parse HEAD >"$STAGE_DIR/candidate.sha"
git diff --name-only "$BASE_COMMIT" -- src >"$STAGE_DIR/source_diff.txt"
set +e
timeout --foreground "$TIMEOUT_SECONDS" /usr/bin/time -v -o "$STAGE_DIR/resource.txt" \
  "$JULIA_BIN" --project=. sim/hsq09_h3_replacement_s10.jl "--cell=$CELL" --out="$STAGE_DIR/receipt.toml" \
  >"$STAGE_DIR/driver.log" 2>&1
DRIVER_RC=$?
set -e
[[ "$DRIVER_RC" -eq 0 ]] || publish_failure "$DRIVER_RC"
set +e
"$JULIA_BIN" --project=. tools/validate_hsq09_h3_replacement_s10.jl --validate-receipt "$CELL" "$STAGE_DIR/receipt.toml" >"$STAGE_DIR/validator.log" 2>&1
VALIDATOR_RC=$?
set -e
[[ "$VALIDATOR_RC" -eq 0 ]] || publish_failure "$VALIDATOR_RC"
(cd "$STAGE_DIR" && find . -maxdepth 1 -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
mv "$STAGE_DIR" "$FINAL_DIR"; trap - EXIT
echo "H3_REPLACEMENT_S10_PUBLISHED cell=$CELL dir=$FINAL_DIR"
