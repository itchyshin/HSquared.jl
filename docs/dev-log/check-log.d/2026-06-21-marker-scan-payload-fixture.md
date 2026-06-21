# 2026-06-21 Marker-Scan Payload Fixture

- Goal: finish the Julia-owned #45 bridge payload slice after the R lane
  synced hsquared issue #23 in PR #75 (`e9633c0`): export a stable
  post-fit marker-scan payload shape and serialize a deterministic mixed-model
  target fixture that the R lane can consume without live Julia.
- Active lenses: Ada, Shannon, Hopper, Boole, Emmy, Fisher, Curie, Grace,
  Rose.
- Starting point: `main` at `7466b2d` after the PEV/reliability payload
  ledger closeout. No R files were touched from this branch. While this slice
  was in progress, the R lane also merged hsquared PR #76 (`9e94137`) to sync
  the multivariate validation issue body; that is coordination context only,
  not evidence for this marker-scan slice.
- Implementation evidence:
  - Exported `marker_scan_result_payload(scan)` from `HSquared`.
  - The payload returns the row-aligned bridge fields for `single_marker_scan`,
    `mixed_model_marker_scan`, and `loco_mixed_model_marker_scan`: engine,
    target, marker IDs, effects, SEs, Wald statistics, nominal p-values,
    Bonferroni/BH values, LOD-equivalent scores, denominators, allele
    frequencies, VanRaden scale, optional variance components, and optional
    LOCO group metadata.
  - Added `test/fixtures/marker_scan_parity/` with pedigree, phenotype,
    marker, expected payload, metadata, README, and `generate.jl` files.
  - The fixture uses a six-animal supplied-variance mixed scan, not calibrated
    GWAS validation and not external comparator evidence.
- Tests and status updates:
  - Added payload-shape/value tests to the existing post-fit marker-scan
    testset.
  - Added a fixture-parity testset that rebuilds the model from CSV files,
    recomputes the payload, compares all serialized numeric fields, and
    includes a corrupted-effect negative check.
  - Updated `V5-MARKER-MIXED` validation-status assertions so stale wording
    cannot drop the payload/fixture evidence or claim map-annotated table
    activation.
  - Updated the engine contract, bridge matrix, public-claims register,
    capability status, validation debt register, Documenter API/roadmap/genomic
    pages, roadmap, and coordination board.
- Commands run:
  - `julia --project=. test/fixtures/marker_scan_parity/generate.jl` —
    passed and regenerated the checked-in fixture files.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
  - `julia --project=docs docs/make.jl` — passed with existing local
    Documenter warnings for skipped deployment detection, substituted
    Vitepress defaults, missing logo/favicon, and npm audit output.
  - `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-marker-scan-payload-fixture.md`
    — passed.
  - `git diff --check` — passed.
- Rose verdict: clean with limitations. This banks the bridge payload and
  deterministic parity target only. It does not activate calibrated
  genome-wide thresholds (#48), map-annotated `gwas_table()` / `qtl_table()` /
  `eqtl_table()` / `lod_scores()` workflows, R formula `marker_scan()`,
  sparse production scanning, comparator evidence, or covered status.
