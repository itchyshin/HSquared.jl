# check-log — 2026-09-01 h2-twin A11 comparator harness (beyond skeleton)

**Arc:** A11 (B3) — completes the skeleton at `cf069956`
**Lane:** `claude/lane-h2-twin-20260901` @ `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Goal:** Turn the 7-target harness from a file-presence index into a fixture-integrity and evidence index, with a committed test. Validate-only; fixture-driven; no external runs.

## What the skeleton did vs what it does now

| Axis | Skeleton `cf069956` | Now |
|---|---|---|
| Fixture check | `isfile` per required file | non-empty, CSV header + ≥1 data row, constant column count, **no non-finite numeric cell** |
| Provenance | none | SHA-256 per file + rollup digest over sorted `(file, digest)` pairs |
| Cross-lane | `isdir` on one hard-coded worktree path | compares Julia fixture digests against the R lane's frozen `comparator_fixture_shas.csv`; reports `agree`/`drift`/`absent`/`uncheckable`; **drift forces `gap`** |
| R lane resolution | hard-coded `../hsquared-h2-twin-20260901` | `HSQUARED_R_ROOT`, else sibling `hsquared`, else a sibling `hsquared-*` worktree |
| Evidence metadata | dropped on the floor | `capability_rows`, `evidence_type`, `required_comparator`, `boundary` carried into the manifest, plus a derived `external_comparator` tier |
| `--run` | set `mode: "run"` and ran nothing external | **refused** with a message naming the per-model opt-in runners |
| JSON | hand-spliced trailing keys | ordered emitter that drops absent fields instead of writing `null` |
| Test | none | `Unified comparator harness (A11 validate-only)` — **37 assertions** |

## Commands

```sh
cd ~/local-scratch/lanes/HSquared.jl-h2-twin-20260901

julia comparator/run_targets.jl
python3 -c "import json;m=json.load(open('comparator/results/manifest.json'));print(m['summary'])"
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Results

| Check | Outcome |
|-------|---------|
| `julia comparator/run_targets.jl` | exit 0 — 7/7 targets accounted, 0 silent skips |
| Manifest JSON parses (`python3 -m json.tool`) | **PASS** — schema 2 |
| Status summary | `validated=4`, `gap=1` (sire: not mirrored by the R lane), `blocked=1` (marker scan, hsquared PR #83), `unavailable=1` (BLUPF90 executables absent) |
| External-comparator summary | `complete=0`, `one_leg=1`, `none=6` |
| Cross-lane fixture bytes | **`agree=6`, `drift=0`, `absent=1`, `uncheckable=0`** |
| `Pkg.test()` full suite | **PASS** — 141 testsets, 0 fail / 0 error; new harness testset 37/37 |

### First run failed; recorded rather than quietly fixed

The first `Pkg.test()` aborted with
`ArgumentError: Package Dates not found in current path`: the harness uses
`Dates` for its manifest timestamp, and `Dates` was in neither `[deps]` nor the
test target. Fixed by adding `Dates` to `[extras]` and `targets.test` — a
test-only stdlib addition, with a comment saying the engine does not depend on
it. `SHA` needed nothing; it is already an engine dep.

## Findings

1. **`sire_model_fitted_target` is the one fixture the R twin has never
   mirrored.** The skeleton already reported this as a gap; the digest check
   confirms it is a genuine absence, not a path miss (the other 6 resolve and
   agree byte-for-byte). Closing it means either mirroring the fixture into
   `hsquared/tests/testthat/fixtures/` and freezing its bytes, or recording a
   decision that the sire target stays Julia-only.
2. **Cross-lane byte parity is now verified, and it holds.** 6/6 mirrored
   fixtures are byte-identical to the R lane freeze. Before this slice, nothing
   checked that — the two lanes' parity tests could have been comparing different
   data and agreeing about it.

## Claim boundary

- **Validate-only. No external comparator was run.** No Totoro campaign, no
  `experimental → covered` flip, no `public_covered_count` change, no
  validation-status row touched.
- `comparator/results/manifest.json` is gitignored generated output; the manifest
  self-describes as "NOT comparator evidence".
- The `external_comparator` tier admits a `complete` value that **no target
  reaches**. A committed test asserts that no `evidence_type` maps to `complete`,
  so promoting one is a deliberate covered-flip decision, not a harness edit.
- `phase4_multitrait_parity` still carries only the single disclosed `sommer`
  leg; the second independent same-estimand comparator remains open, and BLUPF90
  remains unavailable (R-lane note
  `docs/dev-log/comparator-runs/2026-09-01-blupf90-tool-unavailability.md`).
