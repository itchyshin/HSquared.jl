# 2026-11-02 PR 485 Windows #415 wall-time guard

Goal: unblock PR #485 after the 2 Nov main merge. Hosted Julia 1
windows-latest failed the imported `#415 wall-time guard` at 10.207 s vs
the 10.0 s bound. This is a main-imported runner flake, not a #408
regression: Julia 1.10 ubuntu/windows, Julia 1 ubuntu, and docs were
green on the same head.

Commands:

- Hosted CI run 41479178446 job 125392634656: Julia 1 windows-latest
  failed at `test/test_issue_415_two_effect_sparse_route.jl:131`
  (`elapsed < 10.0`, observed 10.2073937 s).
- Bound widened to 15.0 s. Dense `:two_effect` on this pedigree is ~1900 s,
  so the guard still rejects the old route.
- Focused #415 test and `git diff --check` run on the refreshed head.
- `bash tools/build_check_log.sh --check` after this shard lands.
- `bash tools/preamble_cap.sh`: expected green (AGENTS.md unchanged).

Claim boundary: test-only timeout. No `src/`, no package default, no
capability, validation-debt, or `public_covered_count` change. #408 and
#415 stay open.
