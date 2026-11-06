# Arc 1 G5 pedigree container compatibility, 2026-10-10

## 1. Goal

Allow the bounded Arc 1 artifact container to validate and round-trip both the
current Julia pedigree layout and the retained legacy fake-engine layout.
Retain a full Julia package test result and an independent source review without
claiming scientific G5 completion.

## 2. Implemented

The container allowlist now accepts only the two exact `HSquared.Pedigree`
field layouts `ids, sire, dam, order` and `ids, sire, dam, original_order`.
The type and value validation paths recurse through the approved fields. A
regression exercises the current engine pedigree through validation, write,
read, and `original_order` equality; the existing fake-engine fixture continues
to use `order`.

The final Julia package test log ends with `Testing HSquared tests passed`.
Independent review passed for the exact source and test hashes listed below.
The review did not independently rerun Julia.

## 3a. Decisions and Rejected Alternatives

Keeping only `order` rejects the current engine type. Replacing it with only
`original_order` breaks the embedded legacy fake engine. The chosen closed list
preserves both without accepting arbitrary structs or field combinations.
Serialized structs remain tied to their matching engine definition; no
cross-layout migration was added.

Assumptions made without asking: none.

## 4. Files Touched

- `sim/arc1/artifact_container.jl`
- `test/arc1_simulation_executor.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g7-source-freeze-20261010-v27/package-freeze-candidate-v27.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g7-source-freeze-20261010-v27/source-diff-v27.json`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-pedigree-type-fix-v1/julia-pkg-test-final.log`
- `docs/dev-log/source-review/2026-10-10-g5-pedigree-layout-review.md`
- `docs/dev-log/after-task/2026-10-10-g5-pedigree-container-repair.md`
- `docs/dev-log/check-log.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint-archive-20261010-before-g5-pedigree-layout.md`

## 5. Checks Run

- Full Julia `Pkg.test()` with a lane-local depot: passed. The retained log is
  `LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g5-pedigree-type-fix-v1/julia-pkg-test-final.log`,
  SHA-256 `1e95ff7f8bd60226b2e7d038b025897d9e7d1193da1ed8907e6cc0d77afc2ea5`.
  File creation and final modification timestamps indicate about 30 minutes
  elapsed; the command did not retain a precise wall-clock duration.
- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: passed, 9,224 bytes under the 14,000-byte cap.
- After-task structural checker: passed.
- Naturalness check: passed, 0 findings in 717 words.
- Full closeout compiler: correctly withheld completion because the Arc 1,
  automatic-rank, and parent non-GPU ledgers still have unmet gates. The report
  is a progress record, not an Arc 1 completion claim.
- Independent exact-source review: PASS for the three pinned paths; record at
  `docs/dev-log/source-review/2026-10-10-g5-pedigree-layout-review.md`.
- G7's v26 full package check remains verified only for its exact freeze. The
  current 776-file Julia and 275-file R inventory has no path additions or
  removals, but four Julia hashes differ: `sim/arc1/artifact_container.jl`,
  `sim/arc1/manifest-revisions.md`,
  `sim/arc1/manifests/arc1_seed_manifest.json`, and
  `test/arc1_simulation_executor.jl`. A fresh current-source G7 freeze and
  review are required. Candidate v27 was generated from a current inventory
  preflight and is awaiting exact-source review. Its SHA-256 is
  `0d90a27149c07e8be3c3c3b59d5db51d4d49ec199104f473d50d3c1306ab04eb`; the
  source diff SHA-256 is
  `4a58321f24fdb37e2313f52dc9e8e9623a74ff31b2deff88f16d028946300323`.

## 6. Tests of the Tests

The regression operates on the imported current engine `Pedigree`, then checks
both the validator and a serialized round trip. The fake-engine integration
fixture retains its separate `order` layout and is exercised by the full
package test suite. A prior run exposed failures when only one layout was
allowed, which demonstrated that the legacy fixture detects that compatibility
regression. No model fit or study attempt was part of these tests.

## 7a. Issue Ledger

- Fixed: current `Pedigree{String}` was rejected because it uses
  `original_order`.
- Fixed: supporting only `original_order` broke the fake engine's `order`
  layout; both layouts are now accepted with exact field-name checks.
- Open: current-source G7 needs a fresh reviewed freeze and full paired package
  check.
- Open: G2, G3, G4, G5 scientific calibration, and G8 remain unmet.

## 8. Consistency Audit

Checked both validation paths, the real-engine round-trip regression, the
legacy fake-engine fixture, and container framing tests. The independent review
found no widening beyond the two approved field tuples. G7 v26's exact source
pins were compared with all current paths; the four changed files prevent that
receipt from certifying this source revision.

## 9. What Did Not Go Smoothly

The repository lane-preflight script was absent, and the route helper found no
LOAD-FIRST manifest for this worktree. The first package test invocation
stopped at shared-depot permission denial, so the final run used the retained
lane-local depot. An earlier intermediate allowlist fixed the current layout
but exposed the legacy fake-engine layout. The brain's `closeout.py new`
command resolved its output under the separate brain repository, where this
workspace cannot write; this report was therefore created in the permitted
project tree and validated with the available report checker.

## 10. Known Residuals

This is container engineering evidence only. It does not establish repeatability
interval formation, all-attempt coverage, G5, or any scientific gate. G7's v26
receipt applies to its frozen inputs only; current-source candidate v27 awaits
independent review before a paired package run. The owner-approved G2
one-attempt request is also still pending.

## 11. Team Learning

Keep narrowly typed container support synchronized with actual engine record
layouts and test both current and fixture layouts. A passing `Pkg.test()` is
not the paired G7 receipt when its source inventory differs.

Memory receipt: repository ground truth was used. The lane-preflight command was
missing and `route.py` returned no manifest; no brain note was used. Golden Set:
not in scope for this serializer compatibility fix.

## 12. Cross-Product Coverage

Covers: Julia Arc 1 container type validation and serialization round trips for
the two listed pedigree layouts.

Does NOT cover: R implementation or bridge behavior, public formula grammar,
model-fitting reliability, interval calibration, G5 scientific acceptance,
campaign performance, GPU, or release readiness.
