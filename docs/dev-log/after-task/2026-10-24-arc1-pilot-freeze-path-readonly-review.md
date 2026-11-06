# Arc 1 G6/G7 freeze path review

## 1. Goal

Review the eight previously reported undeclared Julia paths against the current Arc 1 recovery source and inventory policy. This was a read-only source review; no fits, seed use, freeze edits, or gate changes were authorized or performed.

## 2. Implemented

No implementation change. The eight named files were checked for presence and current SHA-256 in `/private/tmp/HSquared.jl-arc1-recovery-20261015`. The current package-check inventory rules were read to determine whether each path is included or excluded.

## 3a. Decisions and Rejected Alternatives

No path was excluded and no freeze was regenerated. The current checker recursively includes `comparator`, `docs/design`, and `test`, and its listed exclusions do not match these eight paths. Removing paths from the freeze or adding an exclusion would require a separate reviewed policy decision.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-24-arc1-pilot-freeze-path-readonly-review.md` (this report only)

The recovery checkout, isolated R tree, Dropbox checkouts, freeze candidates, gate files, checkpoint, and coordination board were not edited.

## 5. Checks Run

- Exact-path read-only check of all eight files under the recovery source: all eight are present as regular files. Their current sizes and SHA-256 values are recorded below.
- Read `tools/arc1_package_checks.py` inventory declarations and `tree_files()` behavior. `comparator`, `docs/design`, and `test` are recursively inventoried. The exclusion rules cover cache directories, Python bytecode, and `.DS_Store`; none match the eight paths.
- Imported the package-check module with `PYTHONDONTWRITEBYTECODE=1 python3.13 -B` and called only its read-only `build_file_map(root, r_root)` function. It refused because the required Julia `ext/` directory is absent. No package-check CLI or gate verifier was run. The configured R subdirectories `data`, `demo`, `exec`, `po`, `renv`, and `src` are absent; the current function skips R tree names whose directories do not exist, so no R failure is inferred from that observation.
- The recovery worktree's recorded HEAD, `20409e97689655342d30ec642fa1b935c9773bab`, is present in the attached repository's local object store. `git ls-tree` identifies the two `ext/` files at that commit. `git diff --exit-code 20409e97689655342d30ec642fa1b935c9773bab e1df4c6e4972edf1c9ecc7c691d4c147e1e32017 -- ext` returned 0, and the attached checkout reports no working-tree changes under `ext/`. This proves those files match the saved commit and attached HEAD; it does not prove they match the missing freeze hashes or the lost recovery working-tree bytes.
- The same commit comparison shows the eight reviewed paths are absent from the recorded HEAD tree, and the recovery `tools/arc1_package_checks.py` bytes differ from that commit. The commit is therefore a narrow anchor for the two extension files, not a reproducible snapshot of the full recovery source.
- Read the retained 2026-10-20 and 2026-10-21 undeclared-path reports and the 2026-10-23 local inventory comparison draft.
- Exact `find` in the recovery tree did not locate `g6-reviewed-freeze.json`, `g7-reviewed-freeze.json`, or `g7-current-candidate.json`. The expected v5, v6, and v7-unreviewed evidence directories are empty. The named v6 and v7 freeze files are also absent at their expected Dropbox paths.
- No package-check CLI, gate verifier, Julia command, R command, fit, SSH command, seed, or Git repair was run in the recovery or R trees.
- Follow-up candidate discovery: the recovery evidence tree contains `recovery-20261022/g6-current-source-freeze-candidate-v8-20261023.json` and its referenced `current-source-map-candidate-v7.json`. The candidate's `source_map.sha256` (`cbf8f959634d629d3fb7029fb0a00c194dec2adbea43c399deb2163aa67bdca3`) matches the referenced map file's raw SHA-256. The candidate states `pending` independent review, `gate_credit=false`, and `execution_authorized=false`; its limitations say it is a current-source inventory candidate, not a G6/G7 freeze or pass receipt.
- A read-only comparison of that map with its recorded roots found 450/451 Julia paths matching, one changed Julia file (`tools/arc1_manifest.py`), and no missing Julia paths. For the isolated R root, 3/289 paths match, one path is changed (`tests/testthat/test-arc1-uncertainty-live.R`), and 285 are missing. No files were copied or restored.
- A read-only comparison of the same 289 R map entries against `/Users/z3437171/Dropbox/Github Local/hsquared` found 111 exact matches, 85 changed files, and 93 absent files. That checkout therefore is not an exact substitute for the candidate's isolated R source root; it was not edited.
- A read-only comparison against `/private/tmp/hsquared-pr345-fix` found 199 exact matches, 62 changed files, and 28 absent files. Git identifies that directory as branch `claude/cloud-299-rr-scale-warning`, with only three visible commits and a grafted base; its temporary directory name does not identify its branch. It cannot replace the source-map root and was not edited.
- A bounded inventory of direct and one-level-deep managed worktree package roots found 25 `DESCRIPTION` files, none in an `hsquared` package root. No archive was found in the retained Arc 1 evidence directory. This does not establish that no other source copy exists outside the inspected roots.
- Read-only GitHub checks found no open pull requests in either `itchyshin/hsquared` or `itchyshin/HSquared.jl`. At hsquared commit `c63e89598991e9d94554aae409bd7f8652e28625` (the merge of PR #345), GitHub returns 404 for `R/arc1-uncertainty.R`, `R/fa-rank-selection.R`, and `tests/testthat/test-arc1-uncertainty-live.R`. These Arc 1 files in the candidate map are not available from that remote commit. No branch or issue was created.

Current path hashes:

| Path | Bytes | SHA-256 |
| --- | ---: | --- |
| `comparator/blupf90_multitrait/animal_id_map.csv` | 128 | `497122f472b256a8421c760557a3225124222e583f761ef4e1a7985916056f32` |
| `comparator/blupf90_multitrait/blupf90_multitrait.dat` | 3425 | `573c05f7598fcfb369128d746dbdf979c4d418c5146733389827e4b98e7f92b5` |
| `comparator/blupf90_multitrait/blupf90_multitrait.ped` | 137 | `192ff2bf6cbae800377585751d0cc8db2657c1cec03d4f42f9645251fe1195d9` |
| `comparator/blupf90_multitrait/hsquared_targets.csv` | 313 | `d22cdab9061f8d140f1fa24f39728a4f0a82bc5c7c2e9bb8d1cc99580f8a4298` |
| `comparator/blupf90_multitrait/renumf90.par` | 402 | `121c11e14bf10b2e732f5a34b6bc671a94044cb26504128ffbe67274d26856b2` |
| `docs/design/arc1-profile-v4-development-admission.md` | 1962 | `b49a185357c06303b1db1424b670c806a0d08acf90a4f72dcb4e912d79b5d270` |
| `test/arc1_profiles_v4.jl` | 50557 | `8d868194e0632dbb0743b283c32e3243d2515001881ea4fd088c224f470af0ba` |
| `test/arc1_v4_no_fit_artifact_fixture.jl` | 8687 | `02f79dc2123a5d0dd663c7a90fc20a72626d302ffa1b0515349d3a4683d60a86` |

The matching local commit has `ext/HSquaredCUDAExt.jl` (10,258 bytes, SHA-256 `97233440c63389aad5b000a1472421887048dd34351fd4e180e7a1e36d82caa2`) and `ext/HSquaredMakieExt.jl` (20,020 bytes, SHA-256 `1b293d1232953d346d406ae0e9ec5f7f7a334bc7cb30b6e0c16ce7af86a7fe7e`). They are source anchors only; they were not copied into the recovery tree. The recorded commit does not contain the eight reviewed paths and does not match the current recovery package-check script, so it cannot replace the full source lineage.

## 6. Tests of the Tests

Not applicable. This review did not change checker or test code. No current freeze was available to exercise the checker against these live hashes.

## 7a. Issue Ledger

- Confirmed: the five BLUPF90 comparator files are within the current recursive `comparator` inventory policy.
- Confirmed: the profile-v4 admission document and two test files are within the current `docs/design` and `test` inventory policy.
- Unresolved: the exact reviewed G6/G7 freeze artifacts are missing from the expected recovery and Dropbox paths, and the required Julia source root `ext/` is absent. A saved commit provides candidate contents for the two files, but no freeze hash is available to establish that they are the intended recovery bytes. The checker cannot build its current inventory, so this review cannot establish exact freeze membership or gate status.
- Clarification: an unreviewed G6 source-inventory candidate exists, but it expressly grants no gate credit and its source map does not match current roots (one changed Julia path; 285 missing R paths and one changed R path). The exact reviewed G6/G7 freeze files remain unlocated.
- Confirmed: the available Dropbox R checkout also differs from the candidate's 289-path R map (111 exact matches, 85 changed, 93 absent), so its contents cannot be substituted without an owner-approved lineage decision.
- Confirmed: the available local PR #299 worktree is incomplete against the candidate map (199 exact matches, 62 changed, 28 absent); no exact local paired source was found in the checked copies.
- Scope limit: the managed-worktree inventory was bounded to direct and one-level-deep package roots, and the archive search was limited to retained Arc 1 evidence. It cannot rule out source copies elsewhere.
- Scope limit: the GitHub lookup checked the named hsquared commit only for the three Arc 1 files, and searched open pull requests in the two package repositories. It did not audit every remote branch or closed pull request.
- Unresolved: the later v9 comparison draft reports three profile-v4 paths matched and five comparator paths missing, plus nine other Julia inventory omissions and hundreds of absent frozen paths. Those figures could not be revalidated because the cited candidate freeze is absent.

## 8. Consistency Audit

The eight-path list is not a complete description of current source-freeze drift. The later v9 draft describes a different inventory state and additional missing, absent, and changed paths. A correction limited to these eight paths would not prove a current G6 or G7 pass. The latest readable Arc 1 notes retain G2 through G8 as open; the N80/null 25-of-30 count meets the amended count clause only, while the expanded-reference comparisons for outers 2 and 14 remain unresolved.

## 9. What Did Not Go Smoothly

The exact reviewed freeze files named by the retained reports are absent from the recovery evidence tree and their expected Dropbox locations. A different, unreviewed G6 source-inventory candidate is present, but current-root comparison finds source drift and substantial R-tree omissions; the available Dropbox and local PR #299 R copies also differ from the candidate map. The recovery Julia root also lacks `ext/`, which is required by the current inventory function. The saved commit is a candidate source anchor, not proof of the missing freeze hashes. These conditions prevent a direct live-to-reviewed-freeze hash comparison.

## 10. Known Residuals

This source-path review earns no G6/G7 credit. `public_covered_count` remains 7 and v7 remains HOLD. The checker’s path inclusion rule is established from source, but the pending candidate review, source-map mismatches, missing R files, divergent Dropbox and local PR #299 R copies, absent `ext/` directory, and incomplete commit snapshot prevent verification of the current paired inventory and reviewed hashes. The no-Git recovery checkout was left untouched, and no source files were restored from the local commit.

## 11. Team Learning

A path report must be tied to a specific freeze hash and source root. When the referenced freeze is unavailable, preserve the path classification as a finding and keep the gate unverified; do not promote a historical candidate comparison to current evidence.

## 12. Cross-Product Coverage

This read-only review does NOT cover the R package, Julia package checks, current G6/G7 retained-receipt verification, any scientific fit, or Arc 1 gate completion. It covers only the eight Julia paths and their inclusion under the current recovery tree’s package-check inventory policy.

## Next Actions

1. Identify the owner-approved exact Julia/R source lineage; the current R tree and Dropbox R checkout both differ materially from the candidate map.
2. Obtain an independent review of a refreshed complete Julia/R source map and exact G6/G7 freeze artifacts.
3. Run G6/G7 retained verification only after the paired freeze is exact and independently reviewed.

No commit, push, or gate update was made. Other dirty work in this worktree remains preserved.
