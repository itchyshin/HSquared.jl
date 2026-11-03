# Arc 1 history scope reconciliation

## 1. Goal

Reconcile the current Arc 1 evidence inventory and paired R source lineage without starting fits or modifying recovery trees.

## 2. Implemented

Recounted the current retained evidence directory and hashed its files against the expected historical audit payload. Compared retained v8, v10, and v11 R source-map entries with the exact isolated R root and a read-only Dropbox R comparator, and saved every per-path result in a local JSON evidence file. Updated the local pilot-admission issue draft with the live evidence and test results.

## 3a. Decisions and Rejected Alternatives

Treat filesystem observations from this turn as current scope evidence; do not treat the retained 15,914-path inventory as a current count. Keep the R tree and both broken `.git` directories untouched. Do not infer complete seed history from the 22 reconstructed diagnostic identities or from passing admission tests.

Assumptions made without asking: the source maps' `source_roots.r` value identifies the intended R root for comparison. If that mapping is wrong, the comparison must be rerun against the correct root before any lineage conclusion is used.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-24-arc1-pilot-history-admission-issue-draft.md`
- `docs/dev-log/after-task/2026-10-24-arc1-history-scope-reconciliation.md`
- `docs/dev-log/after-task/2026-10-24-arc1-r-lineage-comparison.json`

No recovery-tree or isolated R-tree files were written. The `closeout.py new` helper resolved its root to the Dropbox brain checkout and its write was denied; no Dropbox file changed. The report was created directly in this worktree.

## 5. Checks Run

- Current recovery evidence traversal: 1,348 regular files, 19,768,244 bytes, zero symlinks, zero stat errors. `recovery-20261019` contains 1,209 files and 16,717,195 bytes, versus 15,800 in the retained inventory.
- SHA-256 scan of all 1,348 current evidence files: expected historical audit digest `02a8eaec2b84dc2b332f516c1ce9521c6550fc31ec5cd54f5e835a9a36a7f44b` not found.
- R map comparison against the pinned R root: v8 has 4 matches, 2 changed paths, and 283 missing of 289; v10 and v11 each have 4 matches, 2 changed, and 268 missing of 274. `DESCRIPTION`, `.Rbuildignore`, and `NAMESPACE` are absent at that root.
- Supplemental read-only comparison against the Dropbox R working tree: v8 has 111 matches, 85 changed paths, and 93 missing of 289; v10/v11 each have 111 matches, 85 changed, and 78 missing of 274. Package metadata exists there, but these maps do not identify that checkout exactly. Its pre-existing modifications and untracked paths mean these are working-tree counts, not committed-HEAD counts.
- Per-path comparisons against both R roots saved in `2026-10-24-arc1-r-lineage-comparison.json`; SHA-256 `36343cf14eb63d1f505b950c7e3d20d11b3f23c94abdc2985032a3bdea215c00`.
- A read-only name search across both retained trees found no `DESCRIPTION`, `.Rbuildignore`, or `NAMESPACE`; only `R/arc1-uncertainty.R` was found among the checked Arc 1 R implementation filenames. `.git` directories were excluded from this search.
- Dropbox lane preflight for the R checkout completed and showed a recent Codex-owned branch. Read-only Git status showed pre-existing modifications and untracked files; mapped files were read only for hashes, and no Dropbox files were written or changed. The Julia Dropbox preflight showed a Claude-named branch and a 73-worktree census; after more than three minutes without a new result, its read-only process was interrupted. No Julia Dropbox source files were read or changed.
- `python3 -m unittest discover -s test -p 'test_arc1_diagnostic_*.py' -v`: 28 tests passed.
- `python3 -m unittest discover -s test -p 'test_arc1_rank_pilot_amendment.py' -v`: 8 tests passed.
- `python3 -m unittest discover -s test -p 'test_arc1_pilot_cells.py' -v`: 33 tests passed.
- `slop_check.py` on the updated issue draft: zero findings. No fitting job or SSH session was started.
- Memory receipt: `route.py` returned no repo LOAD-FIRST manifest; the targeted Brain search returned no matching note. Applied the supplied AGENTS.md boundaries and the recovery handoff. Golden Set: not run; no code defect was changed in this evidence-only slice.

## 6. Tests of the Tests

The diagnostic-history tests exercise missing and unparsed history, source-map drift, seed collisions, and symlink escapes. Pilot-admission tests reject incomplete root listings, missing consumed-attempt history, source-pin mismatch, and unauthorized execution. These are guardrail tests, not evidence that the actual retained roots are complete.

## 7a. Issue Ledger

The pilot history-admission issue remains a local draft at `docs/dev-log/after-task/2026-10-24-arc1-pilot-history-admission-issue-draft.md`. GitHub issue creation was rejected by automatic review because the payload contained detailed internal project history and hashes for a destination it considered unverified. No retry or alternate posting route was used.

## 8. Consistency Audit

G0 and G1 remain recorded as met; G2 through G8 remain open. `public_covered_count` remains 7 and v7 remains HOLD. The eight-fit diagnostic pre-run remains diagnostic-only. No scientific gate or capability status changed.

## 9. What Did Not Go Smoothly

The retained evidence inventory's file count does not match the current filesystem traversal. The historical payload digest is absent from the complete current evidence directory. The isolated R tree is missing most source-map paths, and the dirty Dropbox R working tree also differs from most pinned paths. The Julia Dropbox lane census ran long and was interrupted before completion, so those source files were not inspected. The standard closeout generator is rooted in the Dropbox brain checkout, so its attempted new-file write was denied; this report was written in the authorized worktree instead.

## 10. Known Residuals

The complete retained-attempt root inventory and exact historical audit payload remain unresolved. The current R tree does not establish source identity for the retained v8/v10/v11 maps. No pilot admission or full Arc 1 gate passes from this work. The broader non-GPU HSquared Julia/R objective remains active.

## 11. Team Learning

Validate every source map against the exact root it names before relying on its hashes. A successful finite seed comparison or a test of fail-closed admission logic does not prove that all historical roots were enumerated.

## 12. Cross-Product Coverage

Covers read-only Julia/R source-lineage and retained-history inspection for the Arc 1 pilot-admission question. This does NOT cover a complete seed-history admission, automatic rank-selection reliability, interval calibration, repeatability inference, live Julia/R parity, package-wide checks, releases, or GPU work.
