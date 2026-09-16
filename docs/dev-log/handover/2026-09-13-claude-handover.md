# Session Handoff: HSquared.jl 0.9.0 release closed; performance claim held

Meta: 2026-09-13 · from Codex · to Claude · released source: `b1f8f14acbeaae645dd24096adc3415f79b62526`

## Critical Context

`HSquared.jl` 0.9.0 is a public GitHub release, intentionally experimental and
evidence-bounded. It is **not** an ASReml replacement, and there is no committed,
matched ASReml timing benchmark. Do not describe it as faster than, or nearly as
fast as, ASReml. The current code and roadmap explicitly retain backend
benchmarking and production sparse optimisation as future work.

The paired R package `hsquared` 0.9.0 is also publicly released on GitHub only;
it was deliberately not submitted to CRAN. The post-0.9 adversarial hardening
campaign is a separate future project and is not owed by this handover.

## Goals / Mission

Keep the R-facing `hsquared` language and Julia engine reality aligned. Preserve
experimental, validation-scale claims unless code, tests, validation evidence,
and the capability ledger support a stronger statement.

## Plans / Roadmap

If a later owner asks for a speed claim, first prepare a separate benchmark
protocol: same data/pedigree/model and convergence target; declared hardware and
thread count; cold and warm timings; memory; numerical agreement; matched ASReml
version/settings. Do not run a campaign or change public wording without a new
owner decision and the project compute gates.

## What Was Accomplished

- Merged PR #324 into Julia `main` at `b1f8f14` after all PR checks settled green.
- Ran exact-main CI workflow `34667219579`: Julia 1 / 1.10 on Ubuntu and Windows
  all passed; the opt-in plotting job was intentionally skipped.
- Exact-main Documenter workflow `34667207341` passed.
- Created annotated tag `v0.9.0` resolving to `b1f8f14` and published the GitHub
  release: <https://github.com/itchyshin/HSquared.jl/releases/tag/v0.9.0>.
- Rechecked the held R source artifact only: its SHA-256 is
  `7dec0d641db13b744956e0f0a02c6f8d7833166d1624c69e176deba3f16a7e2e`;
  no CRAN upload or submission was made.
- The user-facing capability overview was checked against `README.md`,
  `ROADMAP.md`, and capability/validation ledgers. The honest conclusion is that
  Julia has valuable experimental sparse components, but no end-to-end ASReml
  performance evidence.

## Current Working State

- Working: no active source, benchmark, simulation, or hardening lane is owed.
- In progress: none.
- Protected: historical local-only branches and the untracked `graft/` cache in
  an older shared worktree. They were not deleted, reset, force-pushed, staged,
  or interpreted as released work.

## Key Decisions & Rationale

- Public status: experimental 0.9.0, not production; no capability promotion
  beyond the evidence-bounded contract.
- Speed status: no ASReml parity/superiority claim. Sparse MME, selected inverse,
  and experimental AI-REML are implementation ingredients, not performance proof.
- Registry status: HSquared.jl is not registered in Julia General; hsquared was
  not submitted to CRAN.
- Future hardening: deliberately separate from the finished release programme.

## Mission Control

| Repository | Released state | Verification | Next work by leverage |
| --- | --- | --- | --- |
| HSquared.jl | `main` / `v0.9.0` → `b1f8f14` | 4-platform CI + Documenter passed | Only a new, approved matched benchmark protocol can address speed. |
| hsquared | `main` / `v0.9.0` → `e54d052` | R-CMD-check + pkgdown passed | GitHub-only release; CRAN remains explicitly unsubmitted. |

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `HSquared.jl` `main` `b1f8f14` | yes | yes | #324 merged | LANDED |
| `HSquared.jl` tag `v0.9.0` | yes | yes | GitHub release published | LANDED |
| `handover/2026-09-13-claude` `e483f503` | yes | yes | #325 open | CARRIED-OVER until a maintainer merges the documentation-only PR |
| historical local branches listed below | yes, local only | no | none | PROTECTED / CARRIED-OVER; do not delete, push, merge, or infer scope without inspection |

FINDINGS-OF-RECORD: none. The protected local branches have not been audited in
this handover; their contents are not promoted into a durable claim.

### Protected local-only branch inventory

The following branches contain commits not reachable from a remote reference.
They are retained as historical evidence and are outside the completed release:

```text
claude/adoring-germain-750929 (3)
codex/blupf90-packet-numeric-handoff (1)
codex/claude-cross-lane-handover (2)
codex/hsq09-a3-julia-plan-7770 (17)
codex/hsq09-a3a4-integration-20260910 (6)
codex/hsq09-h1t-telemetry-amendment (8)
codex/hsq09-h1two-identified-20260909 (43)
codex/hsq09-h3-materialization-20260909 (39)
codex/hsq09-h3-prerun-20260909 (38)
codex/hsq09-h3-s10-replacement-20260909 (42)
codex/hsq09-h3-s11-authorized-20260910 (52)
codex/hsq09-h3-s11-prereg-20260909 (43)
codex/hsq09-ng-contract-julia (1)
codex/hsq09-ng-contract-julia-repair (4)
codex/hsq09-release-julia-20260911 (3)
codex/hsq09-release-julia-20260911-docs (13)
codex/hsq09-s10-hardening-20260909 (28)
codex/hsq09-s2-evidence-infra (12)
codex/hsq09-s2-full-input-materialization (13)
codex/hsq09-s2-materialization (14)
codex/hsq09-s8-julia-claim-surface (5)
codex/hsq09-s9-evidence-manifest (6)
codex/hsq09-s9a4-evidence-manifest (18)
codex/innovation-gate-issue-sync (1)
codex/metafounder-single-step-hgamma (1)
codex/mv-comparator-evidence (1)
codex/mv-second-comparator-target (1)
codex/mv-validation-comparator-gate (1)
codex/nongaussian-parity-fixture (3)
codex/parent-issue-ledger-sync (1)
codex/pev-reliability-ledger-closeout (1)
codex/r-extractor-status-sync (1)
feat/2026-07-01-v06-mcmcglmm-h2-comparator (3)
feat/2026-07-01-v06-ordinal-liability-h2 (3)
shannon-install (1)
sim/2026-07-09-c8-mv-recovery-breadth (1)
```

## Files Created / Modified

- `docs/dev-log/handover/2026-09-13-claude-handover.md` — this handover only.

No numerical source, tests, capability ledger, release version, or public claim
was changed in this handover branch. Do not stage the unrelated local cache
`graft/` from the older shared worktree.

## Next Immediate Steps

1. Read `AGENTS.md`, this handover, `ROADMAP.md`, and
   `docs/design/capability-status.md`.
2. Run the lane preflight and compare this document with current `origin/main`.
   Classify every item as `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`.
3. Treat the 0.9.0 release as `DONE` and historical local branches as
   `PROTECTED`; do not restart the deferred hardening campaign.
4. Only if Shinichi explicitly asks about speed, prepare a plan/protocol rather
   than an ASReml-speed assertion. Claude may plan/review prose and logic;
   Codex should run any live Julia/R fits or benchmark campaign.

## Blockers / Open Questions

- There is no matched, committed ASReml performance benchmark. That is an
  evidence gap, not a known performance deficit or advantage.
- The local historical branch inventory needs a separate archaeological review
  before any branch is pushed, merged, or deleted.

## Gotchas / Failed Approaches

- Do not infer end-to-end performance from CI, sparse primitives, or a single
  small fixture.
- Do not call experimental low-level engine utilities a production R interface.
- Do not submit `hsquared` to CRAN without a new, explicit decision.
- Do not run `git clean`, `git reset --hard`, branch deletion, or mass pushes to
  make the old shared checkout look tidy.

## How to Resume

From a fresh Claude session at the repository root:

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-13-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
