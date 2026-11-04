# 2026-10-30 Arc 1 N80/null bootstrap refusal (#478)

Goal: record the owner-authorized `insufficient_usable_bootstrap` refusal for
the N80/null FA bootstrap as the Arc 1 feasibility finding, then close the
#478 diagnostic. G4 stays open.

Commands:

- `git diff --check`: passed on the note and receipts.
- `bash tools/preamble_cap.sh`: green (AGENTS.md unchanged).
- `bash tools/build_check_log.sh --check`: run after this shard lands.
- No Julia `Pkg.test()`, Documenter build, fit, seed, or bootstrap rerun.
- `GATES.md` not edited. Coordination board not edited.

Claim boundary: formation refusal only. Outer 2 is capped at 196 usable
draws; outer 14 reached 184/199. Both are below the frozen 198. No
calibration, no G2-G8 credit, no capability or covered-count change.
Related #476 decision (no K1 start jitter) is recorded in the same note.
