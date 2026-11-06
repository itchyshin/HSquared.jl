# HSquared Arc 1 handover to Szymek

Date: 2026-10-24

## What this handover covers

This hands over the current non-GPU HSquared project lane. The project is not complete. The bounded Arc 1 goal is reliable Gaussian automatic FA-rank selection and validated uncertainty for the declared models, exposed consistently through Julia and R. Current evidence does not establish that goal.

## Exact checkout state

- Worktree: `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl`
- HEAD: `e1df4c6e4972edf1c9ecc7c691d4c147e1e32017`, detached.
- Current `git status --porcelain`: 69 paths, comprising 17 modified and 52 untracked. This count includes the two handover documents created in this lane.
- 58 local commits are ahead of remotes on the detached HEAD. Other local branches also contain unpushed history; the handoff-gate snapshot reported 189 unpushed commits across other branches.
- Do not reset, clean, delete, or overwrite the dirty work. No commit or push was made for this handoff.

## Verified status and limits

- Current Arc 1 evidence records G0 and G1 as met; G2 through G8 remain open. The live-phase snapshot in `AGENTS.md` is stale for later evidence.
- The earlier eight-cell diagnostic pre-run produced eight results and sixteen rank-reference comparisons within the stated shortfall bound. These were diagnostic only and earn no pilot, confirmation, or original gate credit. Do not rerun those seeds.
- The eight-cell pilot candidate remains refused by the current launcher because reviewed, complete consumed-attempt history is missing. Its plan-only check produced no plan or result files.
- A Totoro archive scan found 115 direct `arc1*` roots and 90 archive-name paths under its filter, with 18 parse exceptions. An earlier scoped count was 114 roots. Reconcile the one-root scope difference and classify the archive exceptions before treating this inventory as complete.
- The scan found the candidate's 240 seed literals in a retained source snapshot's allocation manifest. That proves allocation-manifest presence only; it does not prove the attempts ran or were consumed.
- The paired R source lineage is unresolved. The retained R maps compare poorly with both the isolated R tree and the Dropbox working tree. Dropbox and the isolated R tree were not changed. Their broken `.git` directories were not repaired.
- Existing N80/null outer 2 and 14 still lack K1 reference maxima. Their available interval routes do not substitute for the missing reference maximum.
- `public_covered_count` remains 7 and v7 remains HOLD.

## Exact next work

1. Reconcile the 115-versus-114 root inventory and the 90 archive-name paths, including all 18 parse exceptions. Separate allocation manifests from actual run/start/result records. Preserve scope limitations and failed or unreadable inputs.
2. Have an independent reviewer check the declared root scope, source identities, parsed consumed-seed set, and candidate collision screen.
3. Only after that review, rebuild the consumed-history bundle and run the current pilot launcher in plan-only mode. A passing plan still does not authorize fits.
4. Keep the eight-cell pilot stopped until its separate execution authorization is confirmed. Do not rerun consumed seeds or the K1 reference grid.
5. Resume by reading this note, `docs/dev-log/coordination-board.md` Active Lane Split, `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`, `.unlazy/arc1-gaussian-reliability/GATES.md`, and the latest reports linked below. Then run lane preflight and inspect `git status` before editing.

Latest relevant reports:

- `docs/dev-log/after-task/2026-10-24-arc1-history-scope-reconciliation.md`
- `docs/dev-log/after-task/2026-10-24-arc1-pilot-history-admission-issue-draft.md`
- `docs/dev-log/after-task/2026-10-24-arc1-pilot-cross-source-plancheck.md`
- `docs/dev-log/after-task/2026-10-24-arc1-rebuilt-diagnostic-prerun.md`
- `docs/dev-log/decisions/2026-10-24-arc1-source-history-rebuild.md`

## Boundaries to preserve

- Do not edit Dropbox checkouts or the isolated R tree.
- Do not repair either broken `.git` directory.
- Do not edit the protected handover, `GATES.md`, freeze, checkpoint, coordination board, or `AGENTS.md`.
- Do not change `public_covered_count=7` or v7 HOLD.
- No fits, pilot, confirmation, push, tag, release, or commit are authorized by this handover.
- Leave the existing Totoro SSH ControlMaster alone. Do not kill it and do not open a fresh SSH login.
- The recovery tree under `/private/tmp` may be lost on reboot. Leave it in place and copy nothing over it.

## Latest continuation check before handoff

Work was stopped at the owner's request after checking the handoff state. No files other than this handover note were changed in that continuation, and no remote inventory command or fit was run.

- `bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD"` identified Codex on detached `HEAD`, one active lane in its 73-worktree census, no other branch active in the last 12 hours, and `origin/main` one commit ahead. It then failed at line 388 with an arithmetic error caused by an empty timestamp, before printing its final action. Treat the report as incomplete and rerun after that input issue is resolved.
- `python3 ~/shinichi-brain/tools/route.py "$PWD"` returned no LOAD-FIRST manifest for this exact worktree. The earlier route attempt that appeared to take a long time was interrupted before producing a result; the bounded retry produced the no-manifest result.
- `ssh -S ~/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22 -O check totoro.biology.ualberta.ca` confirmed the already-existing ControlMaster at PID 25356. No remote command was run. Leave this master alone; do not open a fresh login.
- The current detached HEAD remains `e1df4c6e4972edf1c9ecc7c691d4c147e1e32017`, with 58 local commits ahead of remotes and 69 dirty paths (17 modified, 52 untracked). No second active Szymek lane was visible in this preflight snapshot; confirm ownership with Szymek before editing.

## Resume command and carried state

```sh
cd /Users/z3437171/.codex/worktrees/b9ae/HSquared.jl
bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD"
git status --short --branch
```

CARRIED-OVER: the detached worktree at the exact HEAD above, all 69 dirty paths, and the unpushed local history. Preserve them until Szymek has inspected and reconciled the state. No commit was made. `FINDINGS-OF-RECORD: none`.
