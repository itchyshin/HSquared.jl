# Session Handoff — D1 recovery-v3 terminal evidence → Claude

**Meta:** 2026-07-20 · **from:** Codex · **to:** Claude · **branch:**
`codex/2026-07-13-v07-performance-localization` · **mode:** planning/refactor only

## Goals / mission

Preserve the genomic recovery-v3 evidence boundary honestly. D1 was intended to add a byte-reproducible,
post-D0F recovery evidence tree for the held ordinary genomic route; it did **not** succeed and must not be
represented as a capability result. The immediate objective is now to retain the exact failed contract and,
only after explicit authorization, plan a seed-free repair path that can be proved before another official draw.

## Critical context

**STOP: do not connect to Totoro or launch/restart/resume any D1 stage.** `d1-reseal4` is terminal
negative evidence. It passed `prepare → preseal → preflight` seed-free and an all-GREEN pre-draw panel, then
drew four official smoke seeds and stopped at `RC=21`: `fewer than 16 completed smoke attempts`. The root
`/home/snakagaw/hsq_work/d1-reseal4` and **all** D1 offsets `2028000000/101:148` are immutable retired
evidence: do not repair, restart, resume, subset, pool, read as a diagnostic input, or reuse them.

The durable governing decision is brain **D-68**: D1 is paused; no fifth attempt may be designed until the
failure mode is named. Brain **D-70** now preserves the verified failure mechanism and retirement boundary.
That source-level diagnosis is complete, but it does **not** authorize a successor.

## What was accomplished

- Banked the post-draw terminal retirement. D0F reseal4 remains PASS/COMPLETE at R `5325e95` / Julia
  `418be984`, receipt `e88207e5…`; D1 has no corpus lock, base-R recomputation, Julia replay, summary,
  post-run review, adjudication, or final receipt.
- Added Julia-side synthetic marker-ratio manifest regression coverage (`21fd2425`): accepts `+5e-13` and
  rejects `>1e-12` and the stated manifest mutations. Its synthetic selftest passed; it consumed no official
  RNG.
- Diagnosed the exact deterministic terminal cause at the sealed R head `5325e95`:
  `SMOKE_N_LADDER_RECOMMEND_WORKERS_CARDINALITY_MISMATCH`.
  `smoke-n-ladder` receives `16` as a **worker count**, selects one pair per distinct `n` (four D1 rows),
  then the controller calls `recommend-workers`, which rejects fewer than 16 attempt TSVs. This is a
  producer/consumer arity mismatch, not evidence of seed quality, model-fit failure, capacity exhaustion, or
  a Totoro fault.
- Rose performed a read-only claim audit of the diagnosis: **CLEAN-WITH-LIMITATIONS**. The one wording
  limitation—launcher tests contain unrelated behavioral checks, while their relevant smoke assertions are
  textual—was applied.

## Current working state

- **Working:** branch head `e7187d58` is pushed and synchronized with origin. D1 status is documented in
  `ROADMAP.md`, the coordination board, check logs, the retirement report, and the recovery checkpoint.
- **In progress:** none. D1 is deliberately paused.
- **Blocked:** a future successor cannot be designed or implemented without a separately authorized,
  preregistered planning decision. The key unresolved design choice is the intended smoke cardinality and
  layout; the current source does not establish it.

## Key decisions and rationale

- `d1-reseal4` / `2028000000/101:148` are permanently retired, including unobserved offsets. Four observed
  smoke seeds are official spent seeds, not a seed-free smoke.
- No route/count/capability moved: `public_covered_count=5`; `ordinary_auto_genomic` held;
  V2-GRM/V2-GINV remain partial.
- The static cause corrects an early inference: the consumer does **not** require a complete four-rung ladder
  per seed. It requires a global minimum of 16 attempt files and separately checks all-rung coverage.
- A possible future plan may consider a 16-row balanced layout, but that is a new design choice and must not
  be silently inferred from the failed implementation.

## Plans / roadmap

If Shinichi separately authorizes a planning-only **Smoke-Gate Contract Remediation** slice, its first steps
are—not another D1 run:

1. Decide and preregister the intended smoke-cardinality semantics.
2. Specify distinct CLI contracts for worker count and attempt count.
3. Add a composed, seed-free regression test proving the producer's selected rows satisfy the immediate
   consumer's denominator and rung-coverage conditions before any draw.
4. Obtain Rose/Curie/Gauss review of that design and test boundary.
5. Only with a later explicit authorization, create a fresh successor root, new seed space, admission, panel,
   and controller. This handover authorizes none of steps 1–5.

No D2–D4 work, public activation, capability promotion, or retired-root repair is in scope.

## Files created / modified

The last landed D1 diagnostic commit is `e7187d58` (`docs: diagnose D1 smoke contract arity`):

- `ROADMAP.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-07-20-v07-d1-smoke-contract-arity-diagnosis.md`
- `docs/dev-log/recovery-checkpoints/2026-07-20-d1-smoke-contract-arity-diagnosis.md`
- `docs/dev-log/after-task/2026-07-20-v07-d1-smoke-contract-arity-diagnosis.md`
- `docs/dev-log/after-task/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md`

This handover additionally refreshes `AGENTS.md` and archives its superseded snapshot verbatim in
`docs/dev-log/phase-snapshot-archive.md`.

## Landing state

`handoff_gate.sh` was run before this handover. It correctly reports protected/foreign local state and old
unrelated unpushed branches; none belongs to this D1 handover.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| D1 retirement + diagnosis, `codex/2026-07-13-v07-performance-localization` @ `e7187d58` | yes | yes | do not open/merge for this D1 handover | LANDED |
| This handover + snapshot refresh, same branch | pending | pending | do not open/merge for this D1 handover | will land with this handover |
| Retry-5 protected docs (two modified files below) | no | no | none | CARRIED-OVER — foreign protected work; leave untouched |
| `docs/dev-log/2026-07-18-two-lever-news-fit-laplace-reml-is-the-cox-reid-lever.md` | no | no | none | CARRIED-OVER — foreign untracked WIP; leave untouched |
| `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` | no | no | none | CARRIED-OVER — D2/D3/D4 scaffold; explicitly out of scope |
| Other locally unpushed historical branches reported by the gate | no change | no change | varied | CARRIED-OVER — unrelated historical branches; do not clean up from this D1 lane |

The protected files are:

- `docs/dev-log/after-task/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`
- `docs/dev-log/check-log.d/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`

An existing PR may be reported by repository tooling; do **not** open, update intentionally, or merge a PR as
part of this D1 handover. The standing D1 instruction is no new PR / no merge to `main` without Shinichi.

## Next immediate steps

1. Run `hsquared-rehydrate`; read `AGENTS.md`, this handover, `ROADMAP.md`, the coordination board,
   capability status, validation-debt register, and the two D1 reports below.
2. Treat D-68 and the retirement boundary as load-bearing. Do not inspect or manipulate the retired Totoro
   root or D1 seed space.
3. Ask Shinichi whether to authorize a planning-only contract-remediation slice. Only if he does: write its
   ultra-plan and ask the one material question, what smoke-cardinality/layout should the future design
   target? Recommend a balanced 16-row, four-per-`n` layout, but label it as a recommendation rather than
   recovered intent.
4. Spawn Rose before any public-facing statement. If Shinichi approves a future repair plan, bring in Curie
   and Gauss for the composed-test and resource-contract review before implementation.

## Blockers / open questions

- **Owner decision needed:** intended smoke cardinality/layout for any fresh successor. The failed scripts do
  not resolve this semantic contract.
- **Authority needed:** explicit approval of a separately preregistered remediation plan before changing the
  launcher or designing a successor. The completed diagnosis alone does not supply it.
- **Not blocked:** D0F reseal4 evidence is PASS/COMPLETE; no downstream public capability depends on D1.

## Gotchas / failed approaches

- Do not call a four-row selector with `16` and assume it creates 16 rows. In `smoke-n-ladder`, positional
  argument 1 is workers; `manifest_n_ladder()` selects `!seen[n]++` (one pair per `n`).
- The distinct `smoke-16` mode does assert 16 missing rows, but its presence does not make
  `smoke-n-ladder` produce 16. The required test is the **composed** selector-to-consumer contract.
- Do not revive the three retracted Claude-lane false leads: no missing green panel, no one-artifact count,
  and no post-hoc Totoro-idleness inference.
- Do not stage protected retry-5 files or untracked D2/D3/D4 scaffolding.
- Claude should plan/refactor/prose-review and run pure logic checks; do not send it to execute live Totoro
  work. Any future live R/TMB/Julia campaign belongs with the platform that has explicit authority and a
  live toolchain.

## Evidence to read first

- `docs/dev-log/recovery-checkpoints/2026-07-20-d1-smoke-contract-arity-diagnosis.md`
- `docs/dev-log/after-task/2026-07-20-v07-d1-smoke-contract-arity-diagnosis.md`
- `docs/dev-log/after-task/2026-07-20-v07-d1-reseal4-postdraw-smoke-retirement.md`
- `docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md`
- Brain: `[[DECISIONS#D-68]]`, `[[DECISIONS#D-70]]`, `[[journal/2026-07-20]]`, and `[[AGENT_LOG]]`.

## How to resume

From the repository root, paste:

```sh
claude "Rehydrate with the hsquared-rehydrate skill from docs/dev-log/handover/2026-07-20-claude-handover.md and the AGENTS.md snapshot. Keep D1 paused; read the static diagnosis and retirement reports, then ask Shinichi whether to authorize a planning-only Smoke-Gate Contract Remediation slice before preparing any ultra-plan. Do not connect to Totoro, change a launcher, allocate seeds, or design/run a successor without Shinichi's explicit approval."
```

## Mission-control summary

| Repo / lane | Branch / state | What shipped | Plan by leverage |
|---|---|---|---|
| HSquared.jl D1 | `codex/2026-07-13-v07-performance-localization` @ `e7187d58`, pushed; D1 paused | Retirement boundary, marker-ratio regression, static smoke-contract diagnosis | Planning-only cardinality decision → composed seed-free test design → review; no successor without approval |
| hsquared R twin | sealed source reference `5325e95`; local sibling may be dirty | Source of the launcher mismatch; no edits in this handover | Future approved remediation must update R-side launcher/tests in a fresh scoped arc |
| Public capability | `public_covered_count=5`; route held | No promotion | Keep fence unchanged |

> Related: `docs/dev-log/recovery-checkpoints/2026-07-20-d1-smoke-contract-arity-diagnosis.md` ·
> `docs/dev-log/after-task/2026-07-20-v07-d1-smoke-contract-arity-diagnosis.md` ·
> `docs/dev-log/handover/2026-07-20-d1-reseal4-postdraw-retirement.md`
