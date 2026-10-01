# HSquared twin programme handover to Codex

Date: 2026-10-01
From: Codex
To: Codex

## Critical context

Continue the approved bounded HSquared twin programme on the Julia candidate. The fixed-rank Gaussian FA and narrow genetic GLLVM work is experimental. No covered-count change, release, registry submission, tag, or GPU work is authorized. The user has approved the two public pushes associated with this programme. Do not interpret that as permission to merge or release.

The next planned capability arc is automatic FA rank selection, coordinated with the GLLVM project's `d = "auto"` work. However, the latest committed Julia acceptance record still lists V3 as open. Close or explicitly disposition that current-candidate gate before starting implementation of the next capability.

## What was accomplished

- The bounded FA route is Gaussian, four traits, one genetic factor, pedigree relationship, complete responses, trait intercepts, and estimated unstructured residual covariance. The expert-control route returns covariance, correlations, uniqueness limits, and diagnostics. Ordinary defaults and broader FA grammar remain closed.
- The bounded genetic GLLVM route is Poisson-log, three traits, two genetic factors, pure low-rank genetic covariance, balanced complete responses, and pedigree. Trait effects are reconstructed as factor effects times loadings plus supported specific effects. Its objective integrates fixed and genetic effects by Laplace approximation.
- The approved 200-seed FA primary is complete and immutable: 110 diagnostic recoveries, 20 genetic-error classifications, 11 residual-error classifications, and 59 nonconverged fits. All attempts remain in the denominator. This is bounded experimental evidence, not general reliability or calibration.
- Local exact-source R bridge, R package check, Julia package tests, and documentation checks passed in the recorded environment. All 24 tracked Julia source files have scoped dispositions, with residual debt recorded.
- The latest status report says the root ledger is 10/11 and V3 remains open for its final independent receipt, current-head hosted acceptance, and ordinary Julia landing. Read the exact status and limitations in `docs/dev-log/after-task/2026-09-30-bounded-twin-programme-local-acceptance.md` and its hosted-check follow-up.

## Current working state

- Candidate ref: `origin/codex/hsquared-fa-gllvm-20260927`, current local tip `365f173f`.
- This handover checkout is detached at that tip. The original candidate worktree has uncommitted changes to protected `.claude/settings.json` and `.cursor/hooks.json`. Preserve them and do not stage them.
- The main checkout at authoring time had unrelated untracked paths. Do not clean or stage them.
- Local `origin/main` was `829e86ce`, through PR #401. A live `gh pr view 402` check failed because `api.github.com` was unreachable. PR #402's current state and whether its changes are on remote main are therefore **unverified**. Refresh GitHub state before claiming merge or current-head hosted acceptance.
- No new simulation is authorized by this handover. Do not rerun the frozen 200-seed campaign.

## Key decisions and rationale

- Keep the FA acceptance cell fixed at T=4/K=1. Automatic rank selection is separate and has no HSquared implementation or validation accepted by the existing design note.
- Preserve the reported FA failures and nonconverged fits. Do not add a post hoc campaign pass threshold or restart the campaign.
- Do not copy GLLVM selection criteria or safeguards into HSquared without a separate model-specific estimand and recovery study.
- The user's ongoing `d = "auto"` work and the GLLVM project's related work require a read-only contract refresh and coordination before freezing the HSquared design.

## Files to read first

1. `AGENTS.md` and `/Users/z3437171/shinichi-brain/AGENTS.md`.
2. `docs/dev-log/after-task/2026-09-30-bounded-twin-programme-local-acceptance.md`.
3. `docs/dev-log/after-task/2026-09-30-reviewed-repair-integration.md`.
4. `docs/dev-log/after-task/2026-10-01-fa-objective-range-oracle.md`.
5. `docs/dev-log/phase-snapshot-archive.md` and `docs/dev-log/coordination-board.md`.
6. `docs/design/auto-fa-rank-follow-on.md` and `docs/design/capability-status.md`.
7. `docs/dev-log/check-log.d/2026-09-30-final-integrated/` and the later exact-current receipts named by the acceptance report.

## Next immediate steps

1. Refresh GitHub state for HSquared.jl PR #402 and inspect its checks, merge status, head SHA, and relationship to the local candidate. Also check PR #259 only if needed to confirm the paired R landing; its recorded merge is in the acceptance report.
2. Reconcile current source, hosted checks, and the V3 ledger. If #402 has not landed, continue the candidate's ordinary Julia landing gate. If it has landed, verify the exact landed SHA and required checks, then update the ledger from evidence.
3. Run a Rose claim-versus-evidence audit and complete the required after-task/check-log records. Leave `public_covered_count` at 7 and preserve the experimental status.
4. Once the current programme is accurately closed or its remaining gate explicitly owned, open the next bounded **auto-rank design/coordination arc**. First reread the GLLVM.jl `d = "auto"` contract and protected gllvmTMB lane state. Freeze HSquared's candidate range, criterion, tie/boundary behavior, failure table, uncertainty language, and acceptance tests before implementation.
5. Do not run campaigns estimated over three hours without a pre-run result and Shinichi's approval. Keep all simulation work off GitHub Actions. No GPU, release tag, registry submission, CRAN submission, or merge is included.

## Blockers and open questions

- Is PR #402 merged, and what exact head SHA has current hosted acceptance? GitHub was unreachable during this handover.
- Does the latest V3 final independent receipt exist outside the current committed acceptance note? Locate and verify it rather than inferring completion.
- What precise HSquared rank-selection criterion and rank range best serve this FA estimand? Do not assume the GLLVM criterion transfers.

## Gotchas and failed approaches

- The root checkout's branch and untracked paths are not the candidate worktree. Do not conflate their states.
- The candidate's protected local config edits are excluded from source landing.
- Local tests and documentation builds do not prove hosted acceptance or merge state.
- `docs/design/auto-fa-rank-follow-on.md` is explicit that GLLVM.jl is a design reference only. Its criteria, loading ridge, and thresholds are not HSquared evidence.

## Mission-control summary

| Repo | Branch / main | CI and landing | Shipped in scope | Next by leverage |
|---|---|---|---|---|
| HSquared.jl | Candidate `codex/hsquared-fa-gllvm-20260927` at `365f173f`; local `origin/main` observed at `829e86ce` | Local acceptance recorded; V3 hosted acceptance/landing open; PR #402 state unverified due network failure | Bounded experimental FA/GLLVM routes and source review | Verify #402 and finish V3, then freeze auto-rank design |
| hsquared | Paired R lane; PR #259 recorded merged | R Linux/Windows main CI recorded passing; verify only if paired closeout needs current evidence | Experimental R opt-in FA/GLLVM routes | Keep R/J contract aligned; no new release |
| GLLVM.jl / gllvmTMB | Separate project lanes | Existing auto-rank reference is not HSquared parity evidence | GLLVM.jl auto rank selection is a design reference; R-side work is separate | Read-only contract refresh and coordination |

## How to resume

You are Codex, picking up the HSquared Julia candidate. Start with `AGENTS.md` and this handover. Reconcile the handover against current GitHub state and the exact candidate refs before editing. Continue only the V3 closure steps above; preserve all protected and untracked work. Use the repository's Julia project for `julia --project=. -e 'using Pkg; Pkg.test()'`, and the docs project for `julia --project=docs docs/make.jl`. Use `bash tools/preamble_cap.sh` before closing. Codex owns live Julia/R fits, package checks, simulations, and rendering. Read `.codex/agents/rose.toml` and request Rose's audit before any public claim.

From the repo root, start a fresh Codex task and paste:

> Rehydrate from `docs/dev-log/handover/2026-10-01-codex-handover.md` and the `AGENTS.md` snapshot. Verify PR #402 and V3 against current hosted evidence, then continue only the owed closure steps. Preserve protected and untracked work. Do not start auto-rank implementation until V3 is closed or explicitly dispositioned.
