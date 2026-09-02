# Unlazy acceptance ledger — h2-twin-0.5.0 (Block 1)

Armed: 2026-09-01 post-G0. Bind approval before running checks.

| Group | CHECK | EXPECT |
|-------|-------|--------|
| **G1 Lane hygiene** | Worktrees at `~/local-scratch/lanes/{hsquared,HSquared.jl}-h2-twin-20260901`; branch `claude/lane-h2-twin-20260901`; base SHA recorded; no file overlaps PR137/PR274 | 2 worktrees, 1 branch, 0 foreign-path collisions |
| **G2 Claim↔evidence** | Every `covered` row in Julia capability-status has committed evidence; every R public claim maps to `validation_status()` row | 0 unbacked claims; 0 R-only claims |
| **G3 Covered count** | `public_covered_count` equals enumerated-and-proven rows | Asserted count == proven count (currently asserted 5) |
| **G4 Comparators** | Comparator runner executes all 7 targets; BLUPF90 runs or has dated unavailability note | 7/7 accounted; 0 silent skips |
| **G5 Bridge parity** | Round-trip fixtures pass both directions; one Mrode example agrees R↔Julia within declared tolerance; parity test in CI | 0 schema drift; parity green on both matrix legs |
| **G6 Test suites** | R `devtools::test()` and Julia `Pkg.test()` green locally; `test_that` count ≥ 632 without silent reduction | 0 failures; count non-decreasing without recorded reason |
| **G7 Real-data tier** | 3-tier manifest in both repos; each tier states claim boundary; gryphon tier has Darwin sign-off | 3/3 tiers present; 0 tiers overclaiming |
| **G8 Docs excellence** | Both navbars job-shaped; status pages generated not hand-prose; CI fails on broken doctest/cross-ref | 0 flat-dump navbars; 0 `warnonly` suppression |
| **G9 Twin registration** | Julia General registry **before** R CRAN submission; one shared DOI recorded | Order matches ROADMAP Release Model |
| **G10 CRAN gate** | `R CMD check --as-cran` + extrachecks on hsquared 0.5.0; all five D-41 channels present | 0 ERROR, 0 WARNING; every NOTE explained; 5/5 channels |
| **G11 Records** | check-log with exact commands; after-task; capability-status + validation-debt rows; coordination board; Rose audit; `tools/preamble_cap.sh` green | All Definition-of-Done items present |

Verifier (when re-verifying): `node ~/.codex/skills/unlazy/scripts/gate-check.mjs` from Julia worktree with `--approve` after reading every CHECK.
