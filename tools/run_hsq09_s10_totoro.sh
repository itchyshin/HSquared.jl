#!/usr/bin/env bash
# One-task S10 launcher.  It is safe-by-default: an exact arming token is
# required, output is staged privately then atomically published, and the
# driver’s result is validated before publication.  It runs no array and makes
# no scientific or release claim.
set -euo pipefail

readonly S10_EXPECTED_GIT_SHA="${HSQ09_S10_EXPECTED_GIT_SHA:?set by the immutable local S10 manifest}"
readonly S10_EXPECTED_MANIFEST_SHA256="${HSQ09_S10_EXPECTED_MANIFEST_SHA256:?set by the immutable local S10 manifest}"
readonly S10_TIMEOUT_SECONDS=1470
readonly S10_CORE_CAP=1

[[ "${HSQ09_S10_ARMED:-}" == "1" ]] || { echo "REFUSING: S10 is not armed" >&2; exit 78; }
[[ "$(git rev-parse HEAD)" == "$S10_EXPECTED_GIT_SHA" ]] || { echo "REFUSING: wrong candidate" >&2; exit 79; }
[[ -f Manifest.toml ]] || { echo "REFUSING: missing Manifest.toml" >&2; exit 80; }
[[ "$(sha256sum Manifest.toml | awk '{print $1}')" == "$S10_EXPECTED_MANIFEST_SHA256" ]] || {
  echo "REFUSING: Manifest.toml digest mismatch" >&2; exit 81;
}
command -v timeout >/dev/null || { echo "REFUSING: GNU timeout is required" >&2; exit 82; }
command -v /usr/bin/time >/dev/null || { echo "REFUSING: /usr/bin/time is required" >&2; exit 83; }
[[ "${JULIA_NUM_THREADS:-1}" == "1" && "${OPENBLAS_NUM_THREADS:-1}" == "1" ]] || {
  echo "REFUSING: pin JULIA_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1" >&2; exit 84;
}

readonly RUN_ID="${HSQ09_S10_RUN_ID:-}"
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "REFUSING: invalid HSQ09_S10_RUN_ID" >&2; exit 85; }
readonly RESULTS_ROOT="${HSQ09_S10_RESULTS_ROOT:-$HOME/hsq_work/results}"
mkdir -p "$RESULTS_ROOT"
readonly FINAL_DIR="$RESULTS_ROOT/hsq09-s10-$RUN_ID"
[[ ! -e "$FINAL_DIR" ]] || { echo "REFUSING: final directory already exists" >&2; exit 86; }
readonly STAGE_DIR="$(mktemp -d "$RESULTS_ROOT/.hsq09-s10-$RUN_ID.stage.XXXXXX")"
cleanup() { rm -rf "$STAGE_DIR"; }
trap cleanup EXIT

echo "S10_START candidate=$S10_EXPECTED_GIT_SHA run_id=$RUN_ID timeout_seconds=$S10_TIMEOUT_SECONDS"
set +e
timeout --foreground "$S10_TIMEOUT_SECONDS" /usr/bin/time -v -o "$STAGE_DIR/resource.txt" \
  julia --project=. sim/phase1_interval_coverage_ext.jl \
  --mode=smoke --reps=1 --seed=20260903 --levels=0.95 --resume=false \
  --output="$STAGE_DIR/summary.tsv" --detail-out="$STAGE_DIR/detail.tsv" \
  >"$STAGE_DIR/driver.log" 2>&1
readonly RUN_RC=$?
set -e
[[ "$RUN_RC" -eq 0 ]] || { echo "S10_FAILED exit=$RUN_RC" >&2; exit "$RUN_RC"; }
julia --project=. tools/validate_hsq09_s10_smoke.jl --validate "$STAGE_DIR/detail.tsv" "$STAGE_DIR/summary.tsv" \
  >"$STAGE_DIR/validator.log" 2>&1
sha256sum "$STAGE_DIR/detail.tsv" "$STAGE_DIR/summary.tsv" "$STAGE_DIR/resource.txt" \
  >"$STAGE_DIR/SHA256SUMS"
printf '%s\n' "$S10_EXPECTED_GIT_SHA" >"$STAGE_DIR/candidate.sha"
mv "$STAGE_DIR" "$FINAL_DIR"
trap - EXIT
echo "S10_PUBLISHED dir=$FINAL_DIR"
