#!/usr/bin/env bash
# One-task H3 S10 launcher. It is safe-by-default: it accepts only the sealed
# H3 source basis, runs one single-thread path-only smoke, validates before
# atomic publication, and retains every partial or failed result directory.
set -euo pipefail

readonly S10_ENGINE_SHA="82f836f368e37cf75609f721f7a03bde3113e10b"
readonly S10_EXPECTED_DRIVER_SHA256="6c1b74cc207247241e395bd78143c07f01b0091682d3049e57bfdbb1a8d0401d"
readonly S10_EXPECTED_MANIFEST_SHA256="a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221"
readonly S10_TIMEOUT_SECONDS=1470
readonly S10_JULIA_BIN="${HSQ09_H3_S10_JULIA_BIN:-${JULIA_BIN:-julia}}"

[[ "${HSQ09_H3_S10_ARMED:-}" == "1" ]] || { echo "REFUSING: H3 S10 is not armed" >&2; exit 78; }
git rev-parse --verify --quiet "${S10_ENGINE_SHA}^{commit}" >/dev/null || {
  echo "REFUSING: H3 engine commit is absent" >&2; exit 79;
}
git merge-base --is-ancestor "$S10_ENGINE_SHA" HEAD || {
  echo "REFUSING: checkout does not descend from sealed H3 candidate" >&2; exit 80;
}
git diff --quiet "$S10_ENGINE_SHA" -- src || {
  echo "REFUSING: source tree differs from sealed H3 candidate" >&2; exit 81;
}
[[ -f sim/phase1_interval_coverage_ext.jl ]] || { echo "REFUSING: H3 driver missing" >&2; exit 82; }
[[ "$(sha256sum sim/phase1_interval_coverage_ext.jl | awk '{print $1}')" == "$S10_EXPECTED_DRIVER_SHA256" ]] || {
  echo "REFUSING: H3 driver digest mismatch" >&2; exit 83;
}
[[ -f Manifest.toml ]] || { echo "REFUSING: Manifest.toml missing" >&2; exit 84; }
[[ "$(sha256sum Manifest.toml | awk '{print $1}')" == "$S10_EXPECTED_MANIFEST_SHA256" ]] || {
  echo "REFUSING: Manifest.toml digest mismatch" >&2; exit 85;
}
command -v timeout >/dev/null || { echo "REFUSING: GNU timeout is required" >&2; exit 86; }
command -v /usr/bin/time >/dev/null || { echo "REFUSING: /usr/bin/time is required" >&2; exit 87; }
command -v "$S10_JULIA_BIN" >/dev/null || { echo "REFUSING: Julia executable is unavailable: $S10_JULIA_BIN" >&2; exit 92; }
[[ "${JULIA_NUM_THREADS:-1}" == "1" && "${OPENBLAS_NUM_THREADS:-1}" == "1" ]] || {
  echo "REFUSING: pin JULIA_NUM_THREADS=1 and OPENBLAS_NUM_THREADS=1" >&2; exit 88;
}

readonly RUN_ID="${HSQ09_H3_S10_RUN_ID:-}"
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "REFUSING: invalid HSQ09_H3_S10_RUN_ID" >&2; exit 89; }
readonly RESULTS_ROOT="${HSQ09_H3_S10_RESULTS_ROOT:-$HOME/hsq_work/results}"
mkdir -p "$RESULTS_ROOT"
readonly FINAL_DIR="$RESULTS_ROOT/hsq09-h3-s10-$RUN_ID"
readonly FAILED_DIR="$FINAL_DIR.failed"
[[ ! -e "$FINAL_DIR" ]] || { echo "REFUSING: final directory already exists" >&2; exit 90; }
[[ ! -e "$FAILED_DIR" ]] || { echo "REFUSING: failed directory already exists" >&2; exit 91; }
readonly STAGE_DIR="$(mktemp -d "$RESULTS_ROOT/.hsq09-h3-s10-$RUN_ID.stage.XXXXXX")"

publish_failure() {
  local rc="$1"
  printf 'S10_FAILED exit=%s\n' "$rc" >"$STAGE_DIR/launcher_failure.txt"
  find "$STAGE_DIR" -maxdepth 1 -type f ! -name SHA256SUMS -print0 | sort -z |
    xargs -0 sha256sum >"$STAGE_DIR/SHA256SUMS" || true
  mv "$STAGE_DIR" "$FAILED_DIR"
  trap - EXIT
  echo "S10_FAILURE_RETAINED dir=$FAILED_DIR exit=$rc" >&2
  exit "$rc"
}
trap 'rc=$?; if [[ -d "$STAGE_DIR" ]]; then publish_failure "$rc"; fi' EXIT

echo "H3_S10_START candidate=$S10_ENGINE_SHA run_id=$RUN_ID timeout_seconds=$S10_TIMEOUT_SECONDS"
set +e
timeout --foreground "$S10_TIMEOUT_SECONDS" /usr/bin/time -v -o "$STAGE_DIR/resource.txt" \
  "$S10_JULIA_BIN" --project=. sim/phase1_interval_coverage_ext.jl \
  --mode=smoke --campaigns=h3_rg,h3_ram --reps=1 --seed=20260903 --levels=0.95 --resume=false \
  --out="$STAGE_DIR/summary.tsv" --detail-out="$STAGE_DIR/detail.tsv" \
  >"$STAGE_DIR/driver.log" 2>&1
readonly RUN_RC=$?
set -e
[[ "$RUN_RC" -eq 0 ]] || { echo "H3_S10_DRIVER_FAILED exit=$RUN_RC" >&2; exit "$RUN_RC"; }

set +e
"$S10_JULIA_BIN" --project=. tools/validate_hsq09_h3_s10_smoke.jl --validate "$STAGE_DIR/detail.tsv" "$STAGE_DIR/summary.tsv" \
  >"$STAGE_DIR/validator.log" 2>&1
readonly VALIDATOR_RC=$?
set -e
[[ "$VALIDATOR_RC" -eq 0 ]] || { echo "H3_S10_VALIDATOR_FAILED exit=$VALIDATOR_RC" >&2; exit "$VALIDATOR_RC"; }

sha256sum "$STAGE_DIR/detail.tsv" "$STAGE_DIR/summary.tsv" "$STAGE_DIR/resource.txt" \
  "$STAGE_DIR/driver.log" "$STAGE_DIR/validator.log" >"$STAGE_DIR/SHA256SUMS"
printf '%s\n' "$S10_ENGINE_SHA" >"$STAGE_DIR/candidate.sha"
git diff --name-only "$S10_ENGINE_SHA" -- src >"$STAGE_DIR/source_diff.txt"
mv "$STAGE_DIR" "$FINAL_DIR"
trap - EXIT
echo "H3_S10_PUBLISHED dir=$FINAL_DIR"
