## 1. Goal

Review the eight Arc 1 paths previously reported as missing from the G6/G7 source freezes. Keep the review read-only, preserve the recovery and Dropbox trees, and do not start fits.

## 2. Implemented

Completed a path-by-path comparison against the retained recovery tree and the v9 reviewed-freeze candidate. The freeze is SHA-256 `8a879ad40c05584309bc56f5e28f6eeffdbcc12720b21429d2eca459133ab9eb` and declares 773 Julia paths.

| Path | On disk | In v9 freeze | SHA-256 |
|---|---:|---:|---|
| `comparator/blupf90_multitrait/animal_id_map.csv` | yes | no | `497122f472b256a8421c760557a3225124222e583f761ef4e1a7985916056f32` |
| `comparator/blupf90_multitrait/blupf90_multitrait.dat` | yes | no | `573c05f7598fcfb369128d746dbdf979c4d418c5146733389827e4b98e7f92b5` |
| `comparator/blupf90_multitrait/blupf90_multitrait.ped` | yes | no | `192ff2bf6cbae800377585751d0cc8db2657c1cec03d4f42f9645251fe1195d9` |
| `comparator/blupf90_multitrait/hsquared_targets.csv` | yes | no | `d22cdab9061f8d140f1fa24f39728a4f0a82bc5c7c2e9bb8d1cc99580f8a4298` |
| `comparator/blupf90_multitrait/renumf90.par` | yes | no | `121c11e14bf10b2e732f5a34b6bc671a94044cb26504128ffbe67274d26856b2` |
| `docs/design/arc1-profile-v4-development-admission.md` | yes | yes, matching | `b49a185357c06303b1db1424b670c806a0d08acf90a4f72dcb4e912d79b5d270` |
| `test/arc1_profiles_v4.jl` | yes | yes, matching | `8d868194e0632dbb0743b283c32e3243d2515001881ea4fd088c224f470af0ba` |
| `test/arc1_v4_no_fit_artifact_fixture.jl` | yes | yes, matching | `02f79dc2123a5d0dd663c7a90fc20a72626d302ffa1b0515349d3a4683d60a86` |

An independent read-only review confirmed these eight results. It also confirmed that the v9 freeze declares the comparator README and scripts, but not the five comparator data/configuration files. Its scoped review does not establish that these are the only inventory omissions across the source tree.

## 3a. Decisions and Rejected Alternatives

The eight-path list came from the earlier v5/v6 inventory review. The surviving v9 candidate has since added and hash-matched three profile-v4 paths; it still omits the five comparator paths. I did not treat v9 as an approved replacement for the missing freezes or change inclusion policy. Under the current checker, all regular files under `comparator/`, `docs/design/`, and `test/` are inventoried, and no exclusion rule applies to these paths.

Assumptions made without asking: none.

## 4. Files Touched

- Created `docs/dev-log/after-task/2026-10-23-g6-g7-freeze-path-review.md`.
- No recovery-tree, freeze, gate-ledger, checkpoint, coordination-board, AGENTS, source, or Dropbox file was edited.

## 5. Checks Run

- Read-only Python comparison of all eight recovery-tree file hashes and v9 freeze membership: passed for the stated entries.
- Independent read-only reviewer: confirmed all eight path classifications and the limited scope of the review.
- Checked the exact G6 run receipt and v5 freeze paths cited by the handoff: both are missing.
- Checked the exact G7 run receipt and v6 freeze paths cited by the handoff: the receipt exists with expected SHA-256 `732b4d29606c2082118213d4645f49a60898bb70a069aae84ceac9e39230a4e8`; the freeze file is missing.
- No retained verifier, package checker, fit, or simulation was run in this review.

## 6. Tests of the Tests

No code or checker was changed. The comparison independently calculated each on-disk SHA-256 and checked path membership in the parsed v9 `files.julia` map. The reviewer repeated the eight classifications read-only. This tests the report's inventory claims, not overall G6/G7 eligibility.

## 7a. Issue Ledger

- Five BLUPF90 comparator data/configuration files remain present in the recovery source but absent from the v9 Julia freeze.
- Three profile-v4 files are present and hash-matched in v9.
- The exact G6 v5 freeze and run receipt referenced by the handoff are missing.
- The exact G7 v6 freeze referenced by the handoff is missing. The referenced G7 run receipt remains present.
- The complete inventory still needs reconciliation. This scoped review cannot establish that the five files are the only omissions or settle whether they should be declared or intentionally excluded with evidence.

## 8. Consistency Audit

The eight paths are regular files under the recovery tree's declared Julia source root. The comparator files are grouped under the BLUPF90 multitrait comparator directory. The remaining three are the profile-v4 development admission document and its two tests. The current package inventory walks all three parent areas and defines no matching skip rule. The exact G6/G7 receipt verifier inputs cited by the handoff are not interchangeable with the v9 candidate freeze, so their missing-file refusal remains unresolved.

## 9. What Did Not Go Smoothly

The canonical closeout generator resolved its output path through a symlink into the protected Dropbox checkout and was denied. The lane-lease registry reported lock contention and did not return a claim result within the bounded observation, so no lease was recorded. The report was written only to the authorized managed worktree; protected source and evidence trees remain untouched.

## 10. Known Residuals

This review does not pass G6 or G7. The v9 freeze remains a candidate, and the five comparator paths still need an owner-approved inventory decision followed by a regenerated and independently reviewed freeze and exact-source verification. G6/G7 remain open; G0/G1 remain met; G2-G5 and G8 remain open; `public_covered_count` remains 7 and v7 remains HOLD. No fits were started.

## 11. Team Learning

Freeze reviews must distinguish an earlier rejected inventory from a later candidate. Keep exact path membership and hashes for each freeze version; do not transfer validation from a candidate to a gate receipt that names another source and freeze.

Memory receipt: `route.py` previously found no LOAD-FIRST manifest for this worktree. This review was limited to retained source and freeze evidence. Golden Set: not checked; the task changed no estimator behavior.

## 12. Cross-Product Coverage

This read-only inventory review covers source-file membership only. It does NOT cover G6/G7 package checks, R parity, automatic factor-rank selection, uncertainty calibration, confirmation studies, or any public capability status.
