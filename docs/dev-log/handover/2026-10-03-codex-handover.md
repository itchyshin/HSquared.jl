# H2 handover to Codex, 2026-10-03

This handover is for the next Codex lane. The immediate request is to run a fresh Ultra Plan for the remaining HSquared work, excluding GPU work, after reconciling the Arc 1 state below. Do not resume implementation or launch studies until that planning lane has established scope, owners, gates, and the user's approval boundary.

## Goals and plans

The project goal is to finish the non-GPU HSquared project across `HSquared.jl` and its R twin, `hsquared`, while keeping public claims tied to tested, documented, and recorded capabilities. The Oct 1 bounded automatic FA-rank design contract and validation plan are complete. The larger Gaussian reliability Arc 1 is incomplete. The next lane should inventory the project roadmap and current capability/debt ledgers, separate finished work from open work, and produce a fresh, bounded Ultra Plan. It should use the current Arc 1 checkpoint as evidence, not assume that the older Arc 1 plan still describes the best next sequence.

GPU, release, tag, registration, publication, covered-status changes, and public grammar activation are outside this planning handoff. No new implementation or simulation is authorized by this note. The established Arc 1 gate for campaigns projected above three hours still requires measured pre-run results and the necessary approval if a later approved plan reaches that stage.

## Critical context

The paper topic that appeared in the prior conversation was unrelated context bleed. This is HSquared package work. The Oct 1 design-only FA-rank deliverable is complete; the full H2 project and the later Gaussian reliability Arc 1 are not.

## What changed in the stopped Arc 1 continuation

The continuation session stopped at the user's request for a fresh planning lane. Its exact checkpoint is `.unlazy/arc1-gaussian-reliability/evidence/fork-stop-checkpoint-20261003/checkpoint.md`, with source hashes, Git status, worker state, and retained outputs in the same directory. No acceptance gate closed.

- Astra's independent profile-v4 review is **HOLD**. It found a skipped continuation branch, missing producer identity for a direct-intersection winner, omitted v4 rows in Julia/R evidence sinks, and loss of tail-proof/refusal evidence in R reduction. The pinned review is `.unlazy/arc1-gaussian-reliability/evidence/fork-profile-v4-astra-20261003/review.md`.
- Canonical G7 attempt `20261003T223934Z-53559ce793` exited 1 before the package suite started. The checker expects an obsolete `ARC1_PROFILE_V3_ONLY == "1"` guard while the current broad profile suite uses `!= "1"`. The package suite never ran. The independent freeze matched all 768 Julia and 273 R pins before the one new profile-v4 test edit.
- The profile-v4 controls initially passed 104 assertions. A new negative regression then failed as intended: 87 passed and two failed because continuation was not called and the corner diagnostic was absent. Preserve this failing test as a blocker. No production source changed in that review/control work.
- FA-v2 fixed-matrix controls passed 157 assertions. The retained review still lists untested high-precision retained-input, bootstrap reproducibility, and receipt-corruption obligations.
- Three engineering development allocations have been consumed. One failed before data generation; two returned eligible K0 selections after a source repair. Keep source versions separate. No pilot or confirmation study has run.
- The workers finished and the parent process check found no matching test or package-check process. The lane lease was released. PID/PGID history was not retained for the profile controls.

## Current working state

The active Julia checkout is `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl`, branch `codex/arc1-gaussian-reliability-20261002`, HEAD `1cb996204e18acbea9e1e7ff9c7a73122d3c34bc`. It contains inherited uncommitted Arc 1 work, the intentionally failing profile-v4 regression, and protected `.claude/settings.json` and `.cursor/hooks.json` changes. Do not reset, clean, or overwrite them. The original Dropbox R checkout remains protected.

The isolated R lane is `/private/tmp/hsquared-arc1-r-20261003`, branch `codex/arc1-gaussian-reliability-20261003`, HEAD `a563ea88f3076819a4a5d8966e2644489efd1688`. Prior manual evidence records a mandatory-live R CMD check with `Status: OK`; that did not close canonical G7. The Oct 3 after-task report has the exact tarball hash and runtime details.

### Mission control

| Lane | Branch or location | Latest evidence | What shipped | Next step |
|---|---|---|---|---|
| Julia engine | `codex/arc1-gaussian-reliability-20261002` at `1cb9962` | Full `Pkg.test()` passed earlier; current canonical G7 attempt failed before tests; profile-v4 control is intentionally red | In-progress Arc 1 implementation and retained stop checkpoint | Fresh Ultra Plan should classify current source and failures before any implementation |
| R twin | `/private/tmp/hsquared-arc1-r-20261003`, `codex/arc1-gaussian-reliability-20261003` at `a563ea8` | Earlier mandatory-live `R CMD check`: `Status: OK`; not admitted by the failed current G7 run | R bridge and Arc 1 work remain experimental | Preserve the original Dropbox checkout; reconcile exact Julia/R contracts in the new plan |
| Coordinator | `docs/dev-log/coordination-board.md` Active Lane Split | No independent coordinator package check | Shared Julia/R status and handoff pointers | Keep both lane menus visible and reconcile them with the project-wide non-GPU plan |

## Files changed or carried over

The current Julia working-tree changes are:

```text
.claude/settings.json
.cursor/hooks.json
LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md
LOOP/lanes/arc1-gaussian-reliability-20261002/profile-v4-decision.md
docs/dev-log/after-task/2026-10-03-arc1-gaussian-reliability-handoff.md
docs/dev-log/check-log.md
docs/dev-log/coordination-board.md
docs/dev-log/handover/2026-10-03-h2-fresh-session.md
sim/arc1/execute_attempt.jl
sim/arc1/execution_identity.jl
sim/arc1/manifest-revisions.md
sim/arc1/manifests/arc1_seed_manifest.json
src/HSquared.jl
src/arc1_bootstrap.jl
src/arc1_fa.jl
src/arc1_interfaces.jl
src/arc1_profiles.jl
src/fa_rank_selection.jl
src/multivariate.jl
test/arc1_bootstrap.jl
test/arc1_fa_v2_contracts.jl
test/arc1_interfaces.jl
test/arc1_profiles_v4.jl
test/arc1_simulation_executor.jl
test/arc1_simulation_identity.jl
test/runtests.jl
tools/arc1_oracles.py
tools/arc1_package_checks.py
```

The ignored Arc 1 gate ledger and retained evidence are under `.unlazy/arc1-gaussian-reliability/`. The exact new-fork stop evidence is `.unlazy/arc1-gaussian-reliability/evidence/fork-stop-checkpoint-20261003/`. The R checkout has its own independent status and must be inspected from that path. This handover, the coordination-board lane pointers, and the `AGENTS.md` snapshot/archive edit are the documentation changes made for this handoff.

## Key decisions and blockers

- Keep all nine Arc 1 gates G0–G8 open. The authoritative ledger is `.unlazy/arc1-gaussian-reliability/GATES.md`.
- Keep the experimental capability boundary and public covered count at seven. Do not infer selector reliability or calibrated uncertainty from component tests, development witnesses, or package checks.
- Preserve every failure and consumed attempt. The profile-v4 red regression and G7 preflight failure are useful blockers.
- Reconcile the separate Julia and R working states before selecting a new implementation lane. The original R checkout and protected Julia configuration edits are not disposable scratch state.

## Next immediate steps

1. Start a fresh Codex lane from this checkout and run repository rehydration: `git status --short --branch`, `git remote -v`, `git log --oneline --decorate -5`, then `bash /Users/z3437171/shinichi-brain/tools/lane_preflight.sh /Users/z3437171/.codex/worktrees/b9ae/HSquared.jl`.
2. Read `AGENTS.md`, this handover, the coordination board, `ROADMAP.md`, the latest Arc 1 after-task report, the stop checkpoint, the current Arc 1 `GOAL.md`, `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`, `LOOP/lanes/arc1-gaussian-reliability-20261002/package-check-plan.md`, `.unlazy/arc1-gaussian-reliability/GATES.md`, the pinned Astra review, and the capability/debt ledgers.
3. Run a new Ultra Plan for all remaining non-GPU H2 work. Classify each item `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`, with evidence and one owner. The plan must preserve Julia, R, and coordinator lanes and must not equate H2 with Arc 1 alone.
4. Do not edit source, repair the red test, rerun G7, launch fits, or run a campaign until the new plan sets its scope and the user authorizes implementation. If later authorized, Codex owns the live Julia/R toolchain. For the isolated live R route, verify the checkout before setting `HSQUARED_ARC1_R_ROOT=/private/tmp/hsquared-arc1-r-20261003`; use the Julia 1.10 executable only after confirming its installed path. No toolchain is needed for the plan-only step.

## How to resume

From the repository root, paste this into the fresh Codex lane:

> Read `AGENTS.md` and `docs/dev-log/handover/2026-10-03-codex-handover.md`. Run the handover's read-only rehydration steps. Then perform a fresh Ultra Plan for the remaining HSquared project excluding GPU, using current repository evidence and preserving the separate Julia, R, and coordinator lanes. Do not implement or launch simulations in this planning pass.

## Landing state

The Julia branch has existing unpushed implementation commits and dirty in-flight files. The handover records those as `CARRIED-OVER`; do not commit or push them as part of a new plan. This handover, coordination-board pointer, and `AGENTS.md` snapshot/archive change are documentation-only. The GitHub API could not be reached during this handoff, so no PR or push was created. Do not treat the local handoff commit as remotely available.

FINDINGS-OF-RECORD: none. The current scientific findings are in the pinned Astra review; this handover adds no scientific claim.
