# 2026-09-02 — A29 follow-up: no-anchor disclosure + A26 parity language (Julia half)

**Arc:** A29 follow-up (agent-runnable prep after the Rose pre-flip **BLOCKED**
verdict, `~/local-scratch/h2-a29-rose-preflip-2026-09-02.md`).
**Lane:** Julia (`HSquared.jl`) — the R half is the twin commit on
`hsquared` `claude/lane-h2-twin-20260901`. Both moved together because a
**shared-contract fact** changed (`AGENTS.md` rule 2: do not change the public
R–Julia contract without updating both twins).
**Worktree:** `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Branch:** `claude/lane-h2-twin-20260901`. **Not pushed.**

## Why the Julia lane moved at all

Two reasons, both about the twins disagreeing rather than about the engine:

1. **A26 parity wording.** The R lane had discharged element-wise bridge parity,
   but `src/validation_status.jl`, `src/multivariate.jl`, and the **published
   Documenter page** all still said it was "still owed". The twins therefore
   disagreed on a shared-contract fact. All three understated, so nothing was
   inflated — but that is drift either way.
2. **Gate item 2 applies here too.** `V4-MV-REML` is `covered`, and its evidence
   list cites the R lane's Mrode Example 5.1 anchor. That anchor is
   supplied-`G0`/`R0` BLUP/MME and does not anchor the **estimated** covariances
   the row covers. The row now carries the explicit no-anchor disclosure, which
   the Standard-Tier gate requires as the alternative to a pinned textbook
   number.

## What changed

| File | Change |
|---|---|
| `src/validation_status.jl` | `V4-MV-REML` claim boundary: no-anchor disclosure + "parity discharged locally, NOT CI-backed" |
| `src/multivariate.jl` | `fit_multivariate_reml` docstring — the same two facts. **Seventh stale surface; it was not on A29's list of six** |
| `docs/design/capability-status.md` | MV-REML row: both facts |
| `docs/design/validation-debt-register.md` | `V4-MV-REML` row: both facts |
| `docs/design/06-public-claims-register.md` | multivariate engine-utilities row: both facts |
| `docs/src/validation-status.md` | **regenerated**, not hand-edited |

Agreed wording, identical on both lanes: parity is **implemented and locally
verified** at pre-declared tolerances, but **not CI-verified** — the R lane's CI
provisions no Julia, so the parity legs *skip* rather than run, and a push would
give a green check with them silently absent. Owner decision **DP-10**; not
delivered by DP-1 (push).

## Commands and outcomes

| Command | Result |
|---|---|
| `julia --project=. tools/write_validation_status_page.jl` | wrote 56 rows; `git diff` on the page is **exactly** the `V4-MV-REML` row + the regen timestamp (no other row moved) |
| `julia --project=. -e 'using Pkg; Pkg.test()'` | **tests passed** |
| live re-read of the ladder | `V4-MV-REML` = **covered** (unchanged); **13** covered rows / **56** total (unchanged) |

The generated page is `tools/write_validation_status_page.jl` output and carries
a do-not-hand-edit banner; it was regenerated from source, per that contract.

## Fence

- Engine status **untouched**: `V4-MV-REML` stays `covered`; no row promoted or
  demoted; no counts moved.
- R multivariate stays **partial**; `public_covered_count` stays **5**.
- No push; no Registrator; no version bump; no Documenter deploy; no
  Totoro/DRAC compute; no G10.
- This is a wording/honesty change only. No `src/` numerics were altered beyond
  a docstring.
