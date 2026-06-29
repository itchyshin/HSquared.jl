# After-task — PR #192 review + Rose audit + merge close-out — 2026-06-29

## Task goal

Pick up the Codex handover branch `codex/small-sample-interval-calibration`, review
the small-sample interval-calibration scaffold for merge-readiness without changing
interval behavior, gate it on CI + a real Rose claim-vs-evidence audit, merge on
maintainer go-ahead (no auto-merge), and bank the close-out so `main`'s status
surfaces stay truthful.

## Active lenses and spawned agents

Active lenses: Rose, Fisher, Curie, Grace.

Spawned agents: one — `rose-systems-auditor` (Rose), run as a real subagent for the
claim-vs-evidence audit of PR #192.

## Live phase snapshot

HSquared.jl `main` is at `5e37cb53` (#192 squash-merged) after this work; this
docs/metadata close-out is a separate follow-up branch off that commit. The R twin
`hsquared` was checked clean on `main` at `8c5c886`/#112 during rehydrate. Public-default
covered surface remains the v0.1 univariate Gaussian model only. Nothing was promoted to
covered; `validation_status()` is unchanged (48 rows, planned=1, covered=5).

## Files changed

This close-out branch (`docs/2026-06-29-pr192-closeout`):

- `AGENTS.md` (Live Phase Snapshot refresh: new review/merge bullet + corrected the
  now-merged #192 pointer)
- `docs/dev-log/after-task/2026-06-29-pr192-review-merge-closeout.md` (this report)
- `docs/dev-log/check-log.d/2026-06-29-pr192-review-merge-closeout.md`

The substantive scaffold itself landed in #192 and is recorded in Codex's two 2026-06-27
after-task reports and check-log entries; this close-out does not re-bank that content.

## What changed

No engine, harness, or status behavior changed in this close-out. It is documentation and
session-record only:

- Refreshed the AGENTS.md Live Phase Snapshot with a bullet recording the Claude
  rehydrate → CI verification → Rose audit → merge sequence, and corrected the prior
  2026-06-29 bullet's stale "PR pending/opened from branch" wording to "merged via #192
  (`5e37cb53`)".
- Added this after-task report and a check-log entry for the review/audit/merge step.

The review/merge work itself, summarized:

- Confirmed the scaffold PR was already pushed and opened as #192 (DRAFT) — the handover
  doc's "still needs to be pushed/opened" was stale.
- Verified all four PR checks green (Julia 1.10, Julia latest, docs, documenter/deploy).
- Ran a real Rose subagent audit: it independently re-verified that the diff touches no
  `src/` and no `R/`, that `validation_status()` is unchanged (48/planned=1/covered=5),
  that `V1-HERIT-TCAL` stays `planned` (and is correctly a docs-register row, not a
  `validation_status()` data row), that the harness is a pure `using HSquared` consumer
  with locally-defined probes surfaced only as `_probe`-suffixed labels, that the
  `df_eff < 2 → return nothing` guard prevents the SW probe from manufacturing a false
  "win", that the triage TSVs/df values/line counts reconcile, and that the two foreign
  files are unstaged. Verdict: clean-with-limitations, no required changes.
- On maintainer go-ahead, squash-merged #192 into `main` (`5e37cb53`) and deleted the
  branch (local + remote). Did not auto-merge.

## Checks run and exact outcomes

Review/merge session (live-toolchain outputs verified via GitHub, not re-run locally):

- `gh pr checks 192` → all four pass: Julia 1 (run `28366637652`), Julia 1.10 (same run),
  docs (run `28366637686`), documenter/deploy (PR192 preview built).
- `git diff --name-only main...HEAD` (pre-merge) → 21 files, all `AGENTS.md` / `docs/**` /
  `sim/phase1_small_sample_interval_calibration.jl`; no `src/`, no `R/`.
- `git ls-files --error-unmatch` on both foreign paths → not tracked; `git status` shows
  both as `??` untracked.
- Harness leakage grep (`import`/`function HSquared.`/`@eval`/`Base.`/`export`) → none; the
  t-probe (`_student_t_quantile_approx`, line 255) and the Satterthwaite chi-square probe
  (line 384) are script-local; surfaced only as output labels (lines 445–453).
- Rose `rose-systems-auditor` subagent → verdict clean-with-limitations, no required
  changes; one optional non-blocking nit (now-fixed stale snapshot wording).
- `gh pr ready 192` → marked ready for review.
- `gh pr merge 192 --squash --delete-branch` → merged; `main` fast-forwarded to
  `5e37cb53`; branch deleted local + remote.
- `gh pr view 192` → `state = MERGED`, `mergeCommit = 5e37cb534a5cd5e9fc6be14223983b236e0c2a94`,
  `mergedBy = itchyshin`.

This close-out branch:

- `git diff --check` → passed.
- `git diff --name-only main...HEAD` → only `AGENTS.md` and the two `docs/dev-log/**`
  files; no `src/`, no `R/`, no `sim/`, no Documenter-rendered `docs/src/` page.

## Public claim audit

Clean. This close-out makes no new capability claim. It records a review/audit/merge of an
already-fenced validation scaffold and refreshes the snapshot to match repository state. No
interval method exists or was implied; no default changed; `validation_status()` is
unchanged; `V1-HERIT-TCAL` remains `planned`; no R-facing wording was added; public-default
covered surface is still v0.1 Gaussian.

## Tests of the tests

The close-out is docs/metadata-only and touches no `src/`, no `sim/`, and no rendered
Documenter page, so engine behavior and `validation_status()` are unchanged by
construction; the PR's CI run is the authoritative gate. The merge gates themselves were
double-checked: CI status read directly from GitHub (not assumed), and the Rose audit was a
real independent subagent rather than a self-review.

## Coordination notes

No R files changed. The R twin `hsquared` stays the public-language owner and must not gain
t/Satterthwaite interval wording until the Julia engine ships an implementation plus tests,
docs, status/debt rows, and Fisher/Curie/Rose evidence. The shared `V1-HERIT-TCAL` debt
remains the durable cross-repo pointer.

## What did not go smoothly

Nothing material. One regex false-positive during fence verification (a loose pattern
matched the pre-existing tracked `sim/phase6_nongaussian_interval_coverage.jl` while the
foreign file is the `.tsv`) was caught and resolved by checking exact paths; no foreign
file was ever staged.

## Known limitations

The underlying debt is unchanged by this merge: the animal-model effective-degrees-of-
freedom / scaled-reference target is still unresolved, no DRAC-scale coverage run has been
executed, and the SW scaled-chi-square probe remains diagnostic-only and unstable in
low-h² small designs. The merged scaffold is reviewability/resumability infrastructure, not
coverage evidence.

## Next actions

1. For real coverage evidence: stage the harness on DRAC `/project` and submit a
   predeclared, resumable SLURM-array grid (no login-node compute).
2. Only after stronger evidence — and a documented effective-df / scaled-reference target —
   consider a prototype interval method behind an explicit label, gated by Fisher + Curie +
   Rose.
3. Larger independent lanes remain available: the V4 external REML comparator and GPU
   Track B G2–G5.
