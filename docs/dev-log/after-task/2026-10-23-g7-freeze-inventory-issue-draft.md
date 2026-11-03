# Issue draft: reconcile the Arc 1 G6/G7 source freeze

Local draft only; not posted. This revision supersedes the earlier eight-path-only inventory comparison.

## Problem

The available v9 candidate freeze does not describe the current source tree. Its Julia root points to `/private/tmp/HSquared.jl-arc1-recovery-20261015`; its R root points to `/private/tmp/hsquared-arc1-r-branch-20261015`. A read-only comparison used the package checker's own `build_file_map()` and `snapshot()` functions against that freeze. No package checks, fits, or gate verifiers were run.

| Source | Current files | Frozen files | Current files missing from freeze | Frozen files absent from tree | Changed common files |
| --- | ---: | ---: | ---: | ---: | ---: |
| Julia | 453 | 773 | 9 | 329 | 9 |
| R | 274 | 318 | 0 | 44 | 0 |

Candidate freeze SHA-256: `8a879ad40c05584309bc56f5e28f6eeffdbcc12720b21429d2eca459133ab9eb`.

The nine current Julia files missing from v9 are:

- `comparator/blupf90_multitrait/animal_id_map.csv`
- `comparator/blupf90_multitrait/blupf90_multitrait.dat`
- `comparator/blupf90_multitrait/blupf90_multitrait.ped`
- `comparator/blupf90_multitrait/hsquared_targets.csv`
- `comparator/blupf90_multitrait/renumf90.par`
- `sim/arc1/run_pilot_cells.py`
- `test/test_arc1_pilot_cells.py`
- `test/test_arc1_rank_pilot_amendment.py`
- `tools/arc1_rank_pilot_amendment.py`

The nine changed Julia files are `comparator/run_targets.jl`, `docs/Manifest.toml`, `docs/Project.toml`, `docs/make.jl`, `sim/arc1/execute_attempt.jl`, `test/arc1_simulation_executor.jl`, `test/test_arc1_package_checks.py`, `tools/arc1_manifest.py`, and `tools/arc1_package_checks.py`.

The 329 frozen Julia paths absent from the current tree are distributed across `comparator` (8), `docs` (307), `ext` (2), `test` (1), and `tools` (11). The 44 frozen R paths absent from the current tree are under `evidence/recovery-20261016` (29) and `evidence/recovery-20261018` (15). These are inventory differences, not automatic deletion recommendations. The intended source lineage and disposition of every path still need review.

## Earlier eight-path review retained

Five checked-in BLUPF90 comparator packet files are present in the current Julia root but absent from v9. The checker recursively inventories `comparator/`, so all five are included by its current policy. An owner must decide whether the packet belongs in the freeze or whether a specific exclusion is justified.

The other three paths named in the earlier review are present in v9 with matching hashes, so they are not omissions from this candidate:

- `docs/design/arc1-profile-v4-development-admission.md`
- `test/arc1_profiles_v4.jl`
- `test/arc1_v4_no_fit_artifact_fixture.jl`

The earlier v5/v6 freeze files and the cited G6 receipt are missing at their expected paths. This review does not establish that v9 is the intended source lineage or that these inventory differences are the complete set of G6/G7 blockers.

## Required follow-up

1. Decide whether the intended source is the current recovery tree or a restored earlier source lineage.
2. Record a disposition for all added, absent, and changed paths. Do not silently omit the 329 Julia or 44 R paths to make verification pass.
3. Create a complete freeze from the decided source, then obtain independent review.
4. Run the exact current-source G6/G7 checks and retain their receipts.

G6 and G7 remain open. The path and inventory reviews earn no gate credit. `public_covered_count` remains 7 and v7 remains HOLD. No fit, seed, package check, freeze edit, GATES.md edit, checkpoint edit, or gate update was made.

## Draft assessment

This issue draft covers the full source inventory and its concrete path lists. I rate its style 3/10 for AI-like patterns, with medium confidence. The inventory counts and changed-file lists were checked against the package checker's read-only inventory functions; the hash and path sources appear above. The factual gate passes for this v9 comparison. Scientific interpretation and external references do not apply. I checked this revision against the local writing-naturalness protocol on 2026-10-23; I had seen the prior draft and used no style controls.
