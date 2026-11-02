# 2026-10-30 permutation threshold canon (#48)

Goal: record the 25 Oct 2026 owner decision that
`genome_wide_threshold_from_null` is the accepted genome-wide calibration
canon, instead of waiting for PLINK / GEMMA / GCTA.

Commands:

- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: green (AGENTS.md unchanged).
- `bash tools/build_check_log.sh --check`: run after this shard lands.
- No Julia tests, no calibration run, no marker-scan output change.

Claim boundary: decision record only. #48 stays open. No capability,
validation-debt, or `public_covered_count` change. No public significance
wording.
