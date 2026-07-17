# Session handover — Retry-7 after D0F bootstrap materialization

**To:** Claude Code
**From:** Codex
**Date:** 2026-07-17
**State:** bootstrap-only arc landed; hard stop before phenotype admission.

## Critical context

Retry-7 is not activated and has no official phenotype, attempt, fit, replay,
or adjudication output. The sole official RNG operation so far is the
create-once D0F bootstrap-index materialization. Do not infer permission to
continue from its successful receipt.

## Goals and roadmap

The programme seeks a defensible public genomic activation path while keeping
the ordinary R route held until covered evidence exists. The immediate
next arc is a **phenotype-admission gate only**: validate the post-bootstrap
state, run Julia zero-seed preflight, run the chronology audit, and obtain
read-only review. Phenotype generation and the 576-fit campaign require a
subsequent explicit authorization.

## What was accomplished

- Repaired the R preseal validator's optional stable `Manifest.toml` handling;
  exact R repair head: `9f7ed27263b19a486a595f81b1c0b1a8b94702f6`.
- R tests, R-CMD-check CI `29546332451`, and Julia tests passed; fresh Totoro
  deployment and zero-fit synthetic D0F-to-D1 lifecycle passed.
- Fresh canonical D0F preseal at
  `/home/snakagaw/hsq_work/retry7-preseal-9f7ed27-97681439-c/d0f`:
  `be42dc7d58f8747fdc7bff44c553a630bba4da48c05b9ce8faae97b32e87a312`.
- Invoked `materialize-bootstrap` once. Bootstrap manifest SHA-256:
  `f53967b5496aef51fcbac166e8dc5a00aaa6d69f8a8eb68cca42c05adbff7162`;
  sidecar SHA-256:
  `ac49fb10a2b2cb9969b8ce2adc7030934f2c719afda29dfc0d7ceda0d634fc78`.
  It has 720,000 data rows and exact deterministic regeneration passed.

## Current working state

- **Working:** canonical bootstrap receipt and its R/Julia cross-twin docs are
  committed and pushed.
- **In progress:** nothing; no live Retry-7 worker should remain.
- **Blocked by design:** phenotype admission awaits a separately authorized
  gate; no scientific or technical failure currently blocks that gate.

## Key decisions and rationale

- The R validator repair invalidated the prior preseal, so all exact-head
  evidence was rebuilt under the repaired commit; old roots remain immutable
  non-evidence.
- Treat bootstrap materialization as provenance only. It changes neither
  capability status nor `public_covered_count` (still 5).
- Claude should plan/review/prose-check the next gate. Codex must perform any
  live R/Julia execution on Totoro; do not run campaign compute from Claude.

## Files created or modified

| Repository | Paths | State |
| --- | --- | --- |
| `hsquared` | `tools/v07_genomic_recovery_v3_preseal.R`; `tests/testthat/test-v07-genomic-recovery-v3-driver.R` | LANDED, pushed (`9f7ed27`) |
| `hsquared` | `docs/dev-log/check-log.d/2026-07-16-retry7-9f7ed27-bootstrap-materialization.md`; `docs/dev-log/handover/2026-07-16-codex-retry7-bootstrap-handover.md`; `docs/dev-log/after-task/2026-07-16-retry7-9f7ed27-bootstrap-materialization.md` | LANDED, pushed |
| `HSquared.jl` | `docs/dev-log/check-log.d/2026-07-16-retry7-9f7ed27-bootstrap-materialization.md`; this handover; `AGENTS.md`; `docs/dev-log/phase-snapshot-archive.md` | this handover commit |

## Landing state

| Repository / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `hsquared` `codex/2026-07-13-v07-performance-localization` `cb7391d` | yes | yes | #137 open | LANDED |
| `HSquared.jl` `codex/2026-07-13-v07-performance-localization` | handover pending | handover pending | #274 open | LANDED after this commit/push |
| both twins: protected carryover paths and Julia downstream replay scaffold | no | no | none | CARRIED-OVER — unrelated protected work; do not inspect, stage, edit, or hash. Resume only under its original owner/lane. |

## Next immediate steps

1. Run `hsquared-rehydrate`; read this handover, the R bootstrap handover and
   receipt, both AGENTS snapshots, and current git state in both twins.
2. Before any claim, ask Rose for a read-only pre-admission review. Confirm
   sole ownership, canonical root, exact hashes, no live worker, and no
   forbidden output.
3. If and only if the user expressly authorizes this next gate, make an
   ultra-plan for the zero-seed Julia preflight and post-bootstrap chronology
   audit. Claude may review/plan; hand live Totoro execution to Codex.
4. Stop after the gate's review and hard-stop handover. Do not draw a phenotype.

## Gotchas and failed approaches

- The old canonical preseal cannot be reused: a preseal-bound tool byte changed.
- The early fresh preparation roots are non-evidence; do not repair in place.
- The optional Julia `Manifest.toml` must remain in Git comparison even when
  absent; filtering it out is not fail-closed.
- The handoff gate reports unrelated protected carryover in both twins. It is
  deliberately declared above, never staged.

## Mission control

| Repo | Branch / PR | What shipped | Highest-leverage next plan |
| --- | --- | --- | --- |
| `hsquared` | `codex/2026-07-13-v07-performance-localization`, #137 | repaired preseal gate + bootstrap receipt | plan/review phenotype-admission gate; no live execution in Claude |
| `HSquared.jl` | same branch, #274 | cross-twin bootstrap receipt | review zero-seed preflight contract; hand Totoro execution to Codex |

## How to resume

From `/Users/z3437171/Dropbox/Github Local/HSquared.jl`, paste:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-17-claude-handover.md + the AGENTS.md snapshot, then continue only with the Next Immediate Steps. Preserve the hard stop and do not run Totoro compute yourself."
```
