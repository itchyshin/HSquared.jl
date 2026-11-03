# Arc 1 R-source public history hash check

## 1. Goal

Test whether the expected `R/hs_control.R` bytes from retained Arc 1 source maps can be recovered from the public hsquared repository's default-branch history, without editing a package tree or starting fits.

## 2. Implemented

Fetched the current `main` version and all 59 commits returned by GitHub's path-filtered history endpoint for `R/hs_control.R`. Hashed the file contents at each commit against the source-map SHA-256. None matched. The current `main` file also differs.

## 3a. Decisions and Rejected Alternatives

Treat this as a bounded negative result about the default branch's returned path history only. It does not prove the expected bytes are absent from other branches, local uncommitted work, backups, or other source stores. Do not reconstruct by substituting a nearby version.

## 4. Files Touched

- Added `docs/dev-log/after-task/2026-10-24-arc1-github-r-hs-control-history.json`, containing the expected hash, current-main hash, all 59 commit identifiers and dates, and the computed hash at each commit.
- Added this report.

No source, R tree, recovery tree, Dropbox checkout, protected freeze, checkpoint, gate ledger, or coordination board was edited. No commits or external writes were made.

## 5. Checks Run

- GitHub repository metadata confirmed `itchyshin/hsquared` is public and its default branch is `main`.
- The path-history endpoint returned 59 commits for `R/hs_control.R`; all 59 file versions were fetched and hashed successfully.
- Expected source-map SHA-256: `0951333cb8541a1c6615ba0131db5c98f8b5a59bccc24ab3358d4a47d85146f4`.
- Current `main` SHA-256: `f1c8c17ba5646da8b208cd716e21967c981476c76e9ca8ac422cb54a25393ffb`.
- Exact matches among the 59 default-branch history versions: 0.
- Detailed per-commit results are in the JSON artifact.

## 6. Tests of the Tests

No test suite was applicable. The check used the expected SHA-256 already recorded in the retained source-map comparison and hashed the UTF-8 file content returned for each commit. This validates only the per-version hash comparison, not source-map correctness or history completeness beyond the endpoint's returned default-branch history.

## 7a. Issue Ledger

The exact `R/hs_control.R` source version remains unrecovered from the isolated R tree, the compared Dropbox working tree, local reachable Git history, and the public `main` path history checked here. The broader complete R source lineage remains unresolved. No external issue was opened.

## 8. Consistency Audit

This read-only result does not change the recorded Arc 1 gate status, study denominators, `public_covered_count=7`, or v7 HOLD. G2-G5 and G8 remain open. R source identity and the exact G6/G7 evidence requirements remain open.

## 9. What Did Not Go Smoothly

The expected hash is absent from every checked default-branch version, so the public main history does not restore this file. Other branches and non-GitHub stores were outside this check.

## 10. Known Residuals

A complete R source snapshot and exact source identity are still required before using the retained live test as G6 evidence or relying on a G7 package freeze. The previous recovery report found the isolated R directory is only a seven-file delta, while the source maps list 274 R paths. No R package tests or fits were run.

## 11. Team Learning

For a missing source path, verify the expected content against every relevant version returned by the path-history API and record the branch scope. A nearby committed version is not a substitute for the pinned bytes.

Memory receipt: the routed Brain lookup found no repository LOAD-FIRST manifest for this worktree. Repo instructions and retained source-map evidence governed this audit. Golden Set: not run; no implementation or tests changed.

## 12. Cross-Product Coverage

Covers a read-only exact-hash search for one R source file in the public repository's default-branch history. It does NOT reconstruct the complete R package, qualify G6 or G7, establish Julia/R parity, validate FA selection or intervals, or close the non-GPU project.

