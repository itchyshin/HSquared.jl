# HSquared twin programme handover to Codex

Date: 2026-10-01
From: Codex
To: Codex

## Critical context

The approved bounded HSquared twin programme is closed by Julia PR #402, merged at `570f49ba`. Fixed-rank Gaussian FA and narrow genetic GLLVM remain experimental; `public_covered_count` stays 7. No release, registry submission, tag, or GPU work is authorized. The user approved the two public pushes for the implementation PRs; those PRs are now merged. That does not authorize a release.

The next bounded arc is automatic FA rank design and coordination with the GLLVM project's `d = "auto"` work. First refresh the current GLLVM.jl and protected gllvmTMB lane contracts, then freeze HSquared's selection rule and acceptance gates. This is design work; automatic rank remains unimplemented and unvalidated in HSquared.

## What was accomplished

- The bounded FA route is Gaussian, four traits, one genetic factor, pedigree relationship, complete responses, trait intercepts, and estimated unstructured residual covariance. The expert-control route returns covariance, correlations, uniqueness limits, and diagnostics. Ordinary defaults and broader FA grammar remain closed.
- The bounded genetic GLLVM route is Poisson-log, three traits, two genetic factors, pure low-rank genetic covariance, balanced complete responses, and pedigree. Trait effects are reconstructed as factor effects times loadings plus supported specific effects. Its objective integrates fixed and genetic effects by Laplace approximation.
- The approved 200-seed FA primary is complete and immutable: 110 diagnostic recoveries, 20 genetic-error classifications, 11 residual-error classifications, and 59 nonconverged fits. All attempts remain in the denominator. This is bounded experimental evidence, not general reliability or calibration.
- Local exact-source R bridge, R package check, Julia package tests, and documentation checks passed in the recorded environment. All 24 tracked Julia source files have scoped dispositions, with residual debt recorded.
- Julia PR #401 landed at `829e86ce`; R PR #259 landed at `e82f5c95`. Julia PR #402 closed the remaining V3 evidence gap and merged at `570f49ba`. The durable closeout is `docs/dev-log/after-task/2026-10-01-bounded-twin-final-closeout.md`.
- Hosted Julia CI passed on Julia 1.10 and latest Julia on Ubuntu and Windows; Julia docs deploy passed. R CMD check and pkgdown passed at the recorded merge SHA. The closeout report names the exact run IDs and limits.

## Current working state

- Current base: `origin/main` at `570f49ba`, including PR #401 and PR #402.
- Implementation candidate: `origin/codex/hsquared-fa-gllvm-20260927` at `365f173f`, landed by PR #401.
- This handover is on `codex/h2-codex-handover-20261001`; it has been rebased onto `origin/main` at `570f49ba`. The rebased commits still need to be pushed. GitHub API access remains unavailable, so the handover PR itself has not been opened.
- The original candidate worktree has uncommitted changes to protected `.claude/settings.json` and `.cursor/hooks.json`. Preserve them and do not stage them.
- The main checkout at authoring time had unrelated untracked paths. Do not clean or stage them.
- Local `origin/main` now points to merge commit `570f49ba`, whose first parent is `829e86ce` and second parent is `d7d50e9b` (`docs: close bounded twin programme landing gate`). The GitHub API query failed, but the refreshed remote-tracking ref and merged closeout record verify the landing. No status uncertainty remains for V3.
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

1. Start the bounded **auto-rank design/coordination arc**. Read the latest automatic-rank records in GLLVM.jl and the current protected gllvmTMB lane read-only. Do not alter those lanes.
2. Write the HSquared symbolic selection contract: candidate rank range, criterion, boundary and tie rules, complete attempt/failure table, diagnostics, and how selection uncertainty will be explained. Keep fixed-rank fitting available.
3. Define identifiability and recovery checks for rank-zero/no-signal, weak and separated factors, upper-bound selection, ordinary starts/restarts, trait order/units, and failure denominators. Specify same-model comparators and R-Julia parity before implementation.
4. Run a Rose claim/evidence review of the design, then implement only after the acceptance gates and ownership are clear. Keep the ordinary default route closed until its own gates pass.
5. Estimate each simulation before execution. Any run over three hours requires a pre-run result and Shinichi's approval. Keep campaigns off GitHub Actions. No GPU, release tag, registry submission, CRAN submission, or release is included.

## Blockers and open questions

- What current GLLVM.jl and gllvmTMB `d = "auto"` contracts can be reused as design references? Refresh them before making claims.
- What rank-selection criterion and candidate range best serve this HSquared FA estimand? Do not assume the GLLVM criterion transfers.
- How should HSquared report selection uncertainty and a failed/all-rejected candidate sweep?

## Gotchas and failed approaches

- The root checkout's branch and untracked paths are not the candidate worktree. Do not conflate their states.
- The candidate's protected local config edits are excluded from source landing.
- Local tests and documentation builds do not prove hosted acceptance or merge state.
- `docs/design/auto-fa-rank-follow-on.md` is explicit that GLLVM.jl is a design reference only. Its criteria, loading ridge, and thresholds are not HSquared evidence.

## Mission-control summary

| Repo | Branch / main | CI and landing | Shipped in scope | Prioritized next step |
|---|---|---|---|---|
| HSquared.jl | `origin/main` at `570f49ba`; PR #401 and #402 merged | V3 closed by exact merge/CI receipts in the final closeout | Bounded experimental FA/GLLVM routes and source review | Design automatic FA rank selection with explicit acceptance gates |
| hsquared | Paired R lane; PR #259 recorded merged | R Linux/Windows main CI recorded passing; verify only if paired closeout needs current evidence | Experimental R opt-in FA/GLLVM routes | Keep R/J contract aligned; no new release |
| GLLVM.jl / gllvmTMB | Separate project lanes | Existing auto-rank reference is not HSquared parity evidence | GLLVM.jl auto rank selection is a design reference; R-side work is separate | Read-only contract refresh and coordination |

## How to resume

You are Codex, starting the HSquared automatic-rank design arc. Read `AGENTS.md`, this handover, and `docs/dev-log/after-task/2026-10-01-bounded-twin-final-closeout.md`. The bounded FA/GLLVM programme is closed at the stated cells; do not reopen V3 or widen capability claims. Refresh GLLVM.jl and gllvmTMB rank-selection status read-only, then write and review HSquared's selection contract and acceptance plan. Preserve all protected and untracked work. Codex owns live Julia/R fits, package checks, simulations, and rendering. Read `.codex/agents/rose.toml`; Rose reviews the design and any later public claim.

From the repo root, start a fresh Codex task and paste:

> Rehydrate from `docs/dev-log/handover/2026-10-01-codex-handover.md` and the `AGENTS.md` snapshot. The bounded twin programme closed with PR #402 at `570f49ba`. Start the bounded auto-rank design/coordination arc: refresh GLLVM.jl and protected gllvmTMB `d = "auto"` status read-only, then define HSquared's selection rule, diagnostics, uncertainty statement, and acceptance gates before implementation. Preserve protected/untracked work and all release, GPU, simulation, and claim gates.
