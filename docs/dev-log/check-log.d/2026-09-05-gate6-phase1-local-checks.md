# 2026-09-05 — Gate-6 Phase-1 local checks (honesty stack @ `f8abd105`; scratch receipt)

**Lane:** scratch Path FULL (independent `origin/main` clone; Dropbox Julia
checkout was FOREIGN). **Not** a Rose audit. **Not** Gate-6 CLEAN. **Not**
0.9.0. Version **0.8.0**. `public_covered_count` **7**.

`check-log.md` is frozen (2026-06-19); this shard is the correct landing, not a
prepend to the historical file.

## Goal

Record Phase-1 local checks run off Dropbox so Gate-6 later has a dated receipt.
Does **not** authorize a Rose spawn, a covered flip, or `authorize 0.9.0`.

## Tree

`~/local-scratch/worktrees/HSquared.jl-phase1-checks-2026-09-05`  
HEAD **`f8abd105dca3ec1353d53b9beb0ff7502192fcd4`** (merge of #308; stack
#305–#308 on tip). `Pkg.instantiate()` created a local `Manifest.toml` (repo
ships without one) — **not committed**, **not copied to Dropbox**.

## Commands and outcomes

| Command | Exit | Result |
| --- | ---: | --- |
| `bash tools/preamble_cap.sh` | 0 | PASS — `CAP OK` (12186 B / 1 snapshot entry) |
| `julia --project=. -e 'using Pkg; Pkg.test()'` | 0 | PASS — `Testing HSquared tests passed` (345.25 s; 148 Test Summary blocks; HSquared v0.8.0) |
| `julia --project=docs docs/make.jl` | 0 | PASS — local Documenter/vitepress build, no deploy (57.52 s) |

Documenter warnings (not failures): 42 unused docstrings; missing
logo/favicon/`package.json`; skipped GitHub Pages deploy (expected off CI).
Docs build left a timestamp-only dirty line in `docs/src/validation-status.md`
(`regenerated:` comment) — **not committed**.

## Claim boundary

Does **not** pay: Gate-6 Rose spawn / CLEAN; Layer B owner accept; ratify;
H1/H3 science; G10 S1/S2/S3; after-task Dropbox commit; Dropbox `git pull`
onto `main`; covered flip; 0.9.0.

Full scratch receipt:
`~/local-scratch/h2-09-finish-JULIA-PHASE1-CHECKS-2026-09-05.md`.
After-task DRAFT still waiting:
`~/local-scratch/h2-09-finish-postmerge-packets/after-task-JL-stack-305-308-DRAFT.md`.
