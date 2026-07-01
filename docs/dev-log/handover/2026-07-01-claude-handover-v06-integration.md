# Handover → next Claude — v0.6 integration VERIFIED + 3 spawned lanes (2026-07-01)

Meta: 2026-07-01 · from Claude (autonomous + maintainer-engaged) · TARGET = claude ·
AUTHOR = claude. Companion to the session-close handover
`docs/dev-log/handover/2026-07-01-session-close-handover.md` (read that first for the
9-PR anatomy + h² ledger). This doc adds: the VERIFIED full-9-PR integration + recipe,
and the state of three spawned work-lanes.

## Critical Context (get this or go wrong)

1. **`main` @ `94d20319` is UNCHANGED** — count **50**, public-covered FITTING **1**,
   covered 8 / covered_external 3 / partial 38 / planned 1. Nothing was merged to `main`,
   nothing flipped to covered. Every honesty pin HOLDS.
2. **The 9 v0.6 PRs (#215–#223) are VERIFIED to integrate green.** I ran the full
   4-tip trial-merge in a throwaway branch (`trial/v06-full-integration`), resolved
   every conflict, and `Pkg.test()` passed with count==50 and pins intact. The exact,
   mechanical recipe is `docs/dev-log/recovery-checkpoints/2026-07-01-full-v06-merge-recipe.md`.
3. **The merge is ADDITIVE/experimental — it is NOT the G10 covered flip.** Merging the
   9 PRs does not move public-covered. Flipping ordinal+gamma to covered (public-covered
   1→3) is a SEPARATE, non-delegable maintainer decision.
4. **A real Rose audit of the integration was IN-FLIGHT when this doc was written.** Its
   verdict + any required fixes go into the recipe's `ROSE-FINDINGS` placeholder before
   the recipe PR is finalized. If you are resuming and the recipe still shows the
   placeholder, check the Rose result / re-run Rose.

## What Was Accomplished (this session)

- **Created the session-close handover** (`2026-07-01-session-close-handover.md`) — the
  definitive 9-PR / h²-ledger / merge-recipe reference.
- **Spawned three launch-ready work-lane chips** (see "Spawned lanes" below).
- **Executed the full 9-PR integration verification MYSELF** (superseding the merge-prep
  chip): 4-tip trial-merge, all conflicts resolved, suite GREEN, pins intact, recipe written.
- **Launched a real `rose-systems-auditor`** on the integrated tree (in-flight at write time).

## Current Working State

- **Working:** `main` (green, count 50). The integration verification (trial branch,
  suite green). The recipe doc + this handover (untracked in the working tree at write
  time — MUST be committed onto a branch, see Next Steps).
- **In progress:** the Rose audit of the integration (background subagent); the recipe's
  ROSE-FINDINGS section (placeholder until Rose returns); the recipe/handover COMMIT +
  PR (deferred until Rose finishes to avoid disturbing its working tree).
- **Blocked (maintainer-only):** merging the 9 PRs to `main`; the G10 covered flip.

## Spawned lanes — the three chips (answer to "all be OK?")

All three are **safe by construction**: each brief carries the honesty pins (count 50,
public-covered 1, nothing to covered), forbids autonomous push to `main`, and ends with
a Rose audit + PR that STOPS for maintainer G10. None can flip a covered claim.

| Lane | Chip | State | Note |
| --- | --- | --- | --- |
| 1 | Verify full 9-PR merge + recipe | **STARTED by maintainer** (running as its own session) | REDUNDANT with the in-session verification I already did — benign; it will independently reach the same green + recipe (a useful cross-check). Safe: throwaway branch, no push to main. |
| 2 | MCMCglmm h² comparator | launch-ready chip | The last owed h² comparator (QGglmm already done). Bayesian-agreement framing, stays `partial`. |
| 3 | Execute v0.4 broader-DGP MV recovery arc | launch-ready chip | Runs the written plan `~/.claude/plans/plan-the-arc-concurrent-mccarthy.md` (full-sib + 3-trait Totoro gates); covered status UNCHANGED. |

If lane 1's spawned session and this session's recipe disagree on any resolution, TRUST
whichever has a green `Pkg.test()` + count 50 and re-derive — they should match.

## Key Decisions & Rationale

- **Did the merge verification in-session rather than only via the chip** — highest-value
  safe autonomous work; de-risks the maintainer's merge to a mechanical recipe.
- **Deferred the recipe/handover commit until Rose finishes** — switching branches while a
  subagent audits the trial working tree would corrupt its read. Write-now / commit-after.
- **The NS-H2 merge is a genuine COMBINE, not pick-one** — #221/#223 (threshold/ordinal)
  and #222 (Gamma) both edit the same h² surfaces; the merged row/code must carry BOTH.
- **Found a pre-existing staleness** (not merge-introduced): `validation_status.jl`'s
  V6-NS-H2 third tuple field ("claim boundary" string) still says "NO external-comparator
  (QGglmm/MCMCglmm) evidence" — now contradicted by the same row. The real comparator PRs
  should fix it; flagged to Rose.

## Files Created / Modified (this session, durable)

- `docs/dev-log/handover/2026-07-01-session-close-handover.md` (committed `6881108c`).
- `docs/dev-log/recovery-checkpoints/2026-07-01-full-v06-merge-recipe.md` (NEW, untracked → commit).
- `docs/dev-log/handover/2026-07-01-claude-handover-v06-integration.md` (THIS doc, untracked → commit).
- `AGENTS.md` — snapshot pointer to be prepended at commit (Step 4).
- (throwaway, not durable) `trial/v06-full-integration` merge commits — delete after the recipe lands.

## Next Immediate Steps (ordered)

1. **When Rose returns:** read its verdict; apply any REQUIRED fix (likely wording); fill
   the recipe's `ROSE-FINDINGS` section.
2. **Cut the handover/docs branch off main** (do NOT disturb the trial tree until Rose is
   done): `git checkout -b handover/2026-07-01-claude-v06 origin/main` (untracked recipe +
   this doc carry over).
3. **Prepend the AGENTS.md snapshot bullet** (Step 4).
4. **Commit** the recipe + this handover + AGENTS.md (explicit paths; never the 3 foreign
   never-commit files); **push; open a PR; do NOT merge.**
5. **Delete** `trial/v06-full-integration` (throwaway).
6. **Maintainer-gated:** merge the 9 PRs (recipe) + the G10 covered flip.

## Blockers / Open Questions

- Merge to `main` + G10 covered flip — maintainer-only.
- MCMCglmm + Fisher/Falconer sign-off on the h² decomposition — still owed (lane 2 + human).

## Gotchas & Failed Approaches

- **Never stage the 3 foreign untracked files** (`docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`, `sim/.v2gate_run.log.txt`, `sim/phase6_nongaussian_interval_coverage.tsv`).
- **Don't `git checkout` while a subagent audits the working tree** — it corrupts the read.
- **The V6-NS-H2 doc conflicts are SEMANTIC, not textual** — each merge kept the *updated*
  version of each row (not a naive union, which re-introduces stale rows).
- **Remote-session spawning (`list_environments`) returns 404 in this local context** — use
  `spawn_task` chips (user-clicks-to-launch) for "start sessions," not remote env.

## How to Resume

1. Run the `hsquared-rehydrate` skill (live git/CI + ROADMAP, coordination board, check-log,
   newest after-task, capability-status, validation-debt-register).
2. Read this doc + `2026-07-01-session-close-handover.md` + the merge recipe.
3. Confirm pins on `main`: `grep public_covered_count tools/status_cache.json` → 1; count
   guard `test/runtests.jl` `== 50`.
4. Spawn a real `rose-systems-auditor` before ANY covered claim.

### One-command resume (paste in your authenticated terminal, from the repo root)

```
claude "Rehydrate from docs/dev-log/handover/2026-07-01-claude-handover-v06-integration.md + the AGENTS.md snapshot. The 9 v0.6 PRs are verified to integrate green (recipe in docs/dev-log/recovery-checkpoints/2026-07-01-full-v06-merge-recipe.md); main is unchanged (count 50, public-covered 1). Continue with the Next Immediate Steps — finalize the recipe PR after Rose, then it's maintainer-gated. Do NOT flip covered without maintainer G10."
```

## Mission-control

| Field | State |
| --- | --- |
| `main` | `94d20319` — count 50, public-covered fitting 1, UNCHANGED |
| Open PRs | 9 (#215–#223), Rose-clean, CI-green; VERIFIED to integrate green together |
| This session | 9-PR integration verified + recipe; 3 lanes spawned; Rose auditing |
| Recipe | `docs/dev-log/recovery-checkpoints/2026-07-01-full-v06-merge-recipe.md` |
| Maintainer-gated | merge the 9 PRs; G10 covered flip (public-covered 1→3) |
| Next (Claude) | finalize recipe PR after Rose → then hand to maintainer |
| Next (human) | merge PRs (recipe) + G10; optionally launch lanes 2/3 |

## Goals / mission

Programme `/goal`: *finish — Fast & Accurate Algorithms for Mixed & Latent-Variable Model
Fitting (HSquared · DRM · GLLVM)* (long-horizon). This session completed the v0.6 h²
surface's **integration verification** slice. Covered = v0.1 Gaussian only; engine-covered
≠ R-public-covered; no covered flip without maintainer G10.

## Plans / roadmap (beyond next steps)

- Merge the 9 PRs (recipe) → G10 covered flip (ordinal + gamma) → public-covered 1→3.
- h²: MCMCglmm comparator (lane 2) + Fisher/Falconer sign-off; intervals/SEs; R-bridge.
- v0.4 broader-DGP MV recovery (lane 3); V5 GCTA 2nd comparator; v0.7+.
