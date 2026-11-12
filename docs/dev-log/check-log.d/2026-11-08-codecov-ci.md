# 2026-11-08 Codecov CI (Ubuntu Julia 1 lcov, OIDC upload)

Goal: wire coverage collection and one Codecov OIDC upload onto the existing
four-leg CI matrix without changing tests or `src/`.

Commands and results:

- `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/CI.yml")); yaml.safe_load(open("codecov.yml")); print("YAML_OK")'`
  → `YAML_OK` (exit 0).
- `bash tools/preamble_cap.sh` → `CAP OK` (9303 B, 1 snapshot entry, exit 0).
- `git diff --check` → clean (exit 0).
- `command -v julia` → missing in this cloud image. No local `lcov.info`
  and no local coverage percentage.

Claim boundary: configured + YAML-checked. Coverage file / Codecov report
**not** measured here. Upload/report receipts follow the PR's `codecov` job.
Do not add a badge until that job's upload is accepted. No merge to `main`.
Julia 1 Windows red on current `main` (`42255350096`) is pre-existing and
out of this lane.
