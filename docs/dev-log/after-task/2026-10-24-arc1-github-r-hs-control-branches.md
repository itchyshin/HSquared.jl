# Arc 1 R-source branch-head hash check

## 1. Goal

Extend the read-only source recovery check to the current branch heads in the public hsquared repository, testing the exact expected `R/hs_control.R` SHA-256.

## 2. Implemented

Listed all 106 branch heads across two GitHub API pages. Retrieved and hashed `R/hs_control.R` from 105 heads; it is absent from the `gh-pages` head. None of the 105 retrieved files matches the source-map hash. Read-only same-name searches found three copies under `/private/tmp` and two under Codex worktrees; all five hashes differ. Per-head commits and content hashes are retained in the JSON artifact.

## 3a. Decisions and Rejected Alternatives

Treat this as a branch-tip search only. It does not search every commit reachable from every non-main branch, deleted branches, private/local history, working-tree copies, or backups. Do not replace the expected bytes with a near match.

## 4. Files Touched

- Added `docs/dev-log/after-task/2026-10-24-arc1-github-r-hs-control-branches.json`.
- Added `docs/dev-log/after-task/2026-10-24-arc1-r-hs-control-tmp-search.json`.
- Added `docs/dev-log/after-task/2026-10-24-arc1-r-hs-control-worktree-search.json`.
- Added this report.

No source checkout, recovery tree, isolated R tree, protected record, or external repository was edited. No fit or package check was started.

## 5. Checks Run

- Branch inventory: 106 heads listed.
- File versions retrieved and SHA-256 checked: 105.
- Expected SHA-256: `0951333cb8541a1c6615ba0131db5c98f8b5a59bccc24ab3358d4a47d85146f4`.
- Exact matches: 0.
- `R/hs_control.R` is absent from `gh-pages`; the other 105 heads were hashed.
- The same expected hash was absent from all 59 versions in the public `main` path history, as recorded in the preceding audit artifact.
- A filename-only walk under `/private/tmp` found these copies: `/private/tmp/hsquared-pr345-fix/R/hs_control.R` (SHA-256 `71cd526145ddccf269695cf2af6523f861713ee483912922da047a16fad9e7b2`), `/private/tmp/arc1-r-test-package-8f1d9f1/R/hs_control.R` (SHA-256 `36433c28c4c72f2b684a124a96d215f89e926f3ee4ca5974da5b714a7c350221`), and a Claude scratch copy (SHA-256 `86e7d9d76fd037d5e861fa7e9802d5f88cc78d84e1105f2e15b57a1b4d716109`). None matches the expected hash.
- A filename-only walk under the Codex worktrees found `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl/LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g7-current-source-pkg-test-v29/r-check-replay-v1/hsquared.Rcheck/00_pkg_src/hsquared/R/hs_control.R` and the same file under `/Users/z3437171/.codex/worktrees/arc1-g2-lineage/HSquared.jl/...`; both have SHA-256 `91c2505822c8ac6b6b705a80c0c72987138d442ee996397c5afef4ced9c885aa`. Neither matches.

## 6. Tests of the Tests

No package test suite was applicable. Every retrieved file version was hashed as UTF-8; the JSON artifact retains its branch-head commit and content hash. The hash computations are verified; source-map correctness remains untested.

## 7a. Issue Ledger

The expected `R/hs_control.R` bytes remain unrecovered from the compared R trees, local reachable Git history, public `main` history, current public branch tips, and the located same-file copies under `/private/tmp` and Codex worktrees. No external issue was posted.

## 8. Consistency Audit

This audit changes no gate, denominator, or capability status. G2-G5 and G8 remain open; the exact G6/G7 evidence remains unresolved. `public_covered_count=7`; v7 remains HOLD.

## 9. What Did Not Go Smoothly

The expected file version was not found at any current public branch tip or in public `main` history. The source map therefore appears to refer to a version outside the checked public Git states.

## 10. Known Residuals

This does not establish that the bytes are absent from every non-main branch commit, private/local source store, or deleted backup. The complete R source snapshot and exact G6/G7 source identity remain open. The next step is to continue Arc 1 on an independent Julia engineering or evidence task while retaining this R source gap as an issue.

## 11. Team Learning

Search branch tips and branch history as separate scopes. A complete tip inventory is useful but cannot stand in for historical commit enumeration or local working-tree provenance.

Memory receipt: the repository LOAD-FIRST route is unavailable for this worktree; retained source-map evidence and the supplied operating contract governed the check. Golden Set: not run; no implementation or tests changed.

## 12. Cross-Product Coverage

Covers read-only hash matching for one R source file across 105 public branch tips and located copies in temporary storage and Codex worktrees. It does NOT reconstruct a complete R package, establish full Git history absence, pass G6 or G7, or validate Julia/R parity or Arc 1 statistical gates.

