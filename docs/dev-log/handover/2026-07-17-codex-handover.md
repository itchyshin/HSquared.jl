# Session handover — Retry-7 phenotype-admission gate (plan only)

**To:** Codex (live Julia/Totoro toolchain)
**From:** Claude (planning/review lane)
**Date:** 2026-07-17
**State:** admission gate authorized and planned; **hard stop before phenotype admission**.

## Critical context

Retry-7 is NOT activated. The sole official RNG operation to date is the
create-once D0F bootstrap-index materialization. This session did **no live
execution** — it ran a read-only Rose pre-admission audit (PASS) and produced
the plan below. Do **not** infer permission to draw a phenotype or run the
576-fit campaign from this handover: those need their own separate
authorization. This gate stops at zero-seed preflight + chronology audit.

## Goals / mission

Reach a defensible public genomic-activation path while the ordinary no-control
R route stays **held** until covered evidence exists. `public_covered_count`
stays **5** (only the supplied-`Ginv` validation-scale genomic REML estimator is
covered). This gate advances *provenance and readiness*, not capability.

## Plans / roadmap (beyond this gate)

Later, and each separately authorized: (1) phenotype generation from the sealed
bootstrap index; (2) the 576-fit official campaign + independent base-R
recompute + exact Julia replay; (3) sealed adjudication → receipt; only then a
covered-evidence decision on the R route. None of that is in scope here.

## What was accomplished (this session)

- Rehydrated from live repo state + `docs/dev-log/handover/2026-07-17-claude-handover.md`.
- **Rose read-only pre-admission audit → ADMISSIBLE** (conducted as the Rose
  review lens; the `rose-systems-auditor` subagent spawn was blocked by a
  transient classifier outage, so the audit was done inline read-only). Five
  points:
  1. **Sole ownership** — CONFIRMED. Retry 1–6 and recovery-v3 roots all
     declared retired/immutable non-evidence (`docs/design/capability-status.md:112`).
  2. **Canonical root** — CONFIRMED. `/home/snakagaw/hsq_work/retry7-preseal-9f7ed27-97681439-c/d0f`,
     bound to Julia commit `976814393043d3a4af5ce343d8ac4b05c43eac41`, R repair
     head `9f7ed27263b19a486a595f81b1c0b1a8b94702f6`; consistent across
     check-log + handover.
  3. **Exact hashes** — CONFIRMED, byte-identical, zero divergent occurrences:
     preseal `be42dc7d58f8747fdc7bff44c553a630bba4da48c05b9ce8faae97b32e87a312`,
     manifest `f53967b5496aef51fcbac166e8dc5a00aaa6d69f8a8eb68cca42c05adbff7162`,
     sidecar `ac49fb10a2b2cb9969b8ce2adc7030934f2c719afda29dfc0d7ceda0d634fc78`,
     rows `720000`.
  4. **No live worker** — CONFIRMED from repo (`no live Retry-7 worker should
     remain`; materializer ran exactly once). **Live Totoro process check is
     YOUR leg** (delegated to Codex — see preflight step L5).
  5. **No forbidden output** — CONFIRMED. No phenotype/attempt/fit/replay/
     adjudication artifact tracked or staged; `public_covered_count` = 5; R
     no-control route still not activated/merged/released.

## Current working state

- **Working:** canonical bootstrap receipt + cross-twin docs committed/pushed;
  admission gate audited clean.
- **In progress:** nothing live. No Retry-7 worker should be running.
- **Blocked by design:** phenotype admission awaits a *separately authorized*
  gate. No scientific/technical failure blocks it; this is a governance stop.

## The plan Codex executes — zero-seed Julia preflight + chronology audit

**Design principle:** every preflight check below targets a *specific documented
failure* that killed a prior retry. The point of a zero-seed pass is to catch
those exact contract defects **before** any phenotype is drawn or any seed is
consumed — at zero campaign cost. "Zero-seed" = dry contract validation; no RNG
stream is advanced, no phenotype/fit is produced.

Live env (Totoro), per repo conventions:
```sh
export PATH="$HOME/.juliaup/bin:$PATH"
export HSQUARED_JULIA_PROJECT="$HOME/hsq_work/HSquared.jl"   # adjust to the deployed checkout
# attach to the existing passwordless ControlMaster socket (do NOT open a new campaign worker):
SOCK=$(ls ~/.ssh/cm-*totoro* 2>/dev/null | head -1)
ssh -o ControlPath="$SOCK" -o ControlMaster=no -o BatchMode=yes -o ConnectTimeout=15 totoro '...'
```

### A. Zero-seed Julia preflight (harness at commit `976814393043…`)
Pass = ALL of the following hold and **no phenotype/seed was drawn**:

- **P1 — Load/type check.** Harness loads at the bound commit; D0F-consuming
  entrypoints type-check and dry-run.
- **P2 — Manifest re-verify (fail-closed).** Re-hash manifest + sidecar; must
  equal `f53967b5…` / `ac49fb10…`, rows `720000`, **before** any downstream
  stage. Mismatch ⇒ hard stop.
- **P3 — Fixed-panel cardinality.** Prove the replay reads panel cardinality
  correctly. *(recovery-v3 replays stopped before row 1 on this contract.)*
- **P4 — Concrete-`Cmd` typing.** Prove command construction is concretely
  typed. *(recovery-v3 failure mode.)*
- **P5 — Successful-gradient contract.** Prove the gradient-success contract is
  representable and validated. *(recovery-v3 failure mode.)*
- **P6 — Endpoint one-ULP representation.** Prove endpoint representation is
  contract-clean. *(Retry-4 stopped after 455 admitted rows on a one-ULP
  endpoint-representation defect.)*
- **P7 — Post-preseal tree validation + contract-clean admission proof.** Prove
  the preseal tree validates AND the admission proof is contract-clean.
  *(Retry-5 stopped on a post-preseal tree-validation blocker; its admission
  proof was later found not contract-clean.)*
- **P8 — Adjudicator route-binding + serialization.** Prove the receipt/
  adjudication route binds and serializes at zero seed, so a future minted
  receipt won't die post-campaign. *(Retry-6 completed all 576 fits+replays but
  the receipt writer stopped on an adjudicator route-binding defect; offset-7101
  died on a logical serialization defect.)*

Any Pn failure ⇒ **STOP**, do not draw a phenotype, report the contract defect.

### B. Post-bootstrap chronology audit (live Totoro filesystem/logs)
Pass = ALL hold:

- **L1 — Ordering.** Preseal (`be42dc7d…`) materialized before manifest
  (`f53967b5…`); both post-date bound commit `976814393043…`.
- **L2 — Create-once.** Exactly one `materialize-bootstrap` invocation;
  deterministic regeneration reproduces exact bytes on the live tree.
- **L3 — Seed-space isolation.** Bootstrap seed space is the ONLY consumed RNG
  space; no phenotype/attempt/fit space touched; no out-of-order/duplicate op.
- **L4 — Sole root.** No competing active root under `~/hsq_work`; earlier retry
  roots present only as immutable retired non-evidence.
- **L5 — No live worker.** Confirm no live Retry-7 process on Totoro (the leg
  Rose delegated to you).

Any anomaly ⇒ **STOP**, report; do not proceed to phenotype admission.

### C. Hard stop
After A + B return, hand the evidence back for review (Claude reviews; Rose
re-audits any claim). **STOP there.** Phenotype generation and the 576-fit
campaign require separate explicit authorization. Do not draw a phenotype.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `HSquared.jl` `codex/2026-07-13-v07-performance-localization` — this handover + `AGENTS.md` snapshot edit | pending this commit | pending | #274 OPEN | LANDED after commit/push |
| `docs/dev-log/after-task/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md` (M), `docs/dev-log/check-log.d/2026-07-15-…-retry5-…md` (M), `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` (??) | no | no | none | **CARRIED-OVER** — unrelated protected carryover in this branch's tree; do NOT inspect, stage, edit, or hash. Resume only under original owner/lane. |
| ~16 other local branches with unpushed commits (see `handoff_gate.sh` output) | n/a | no | various | **CARRIED-OVER** — pre-existing unrelated lane work, not this session's; owners resume in their lanes. |

## Next immediate steps (for Codex)

1. Read `AGENTS.md` (native), this doc, `docs/dev-log/handover/2026-07-17-claude-handover.md`,
   and `docs/dev-log/check-log.d/2026-07-16-retry7-9f7ed27-bootstrap-materialization.md`.
2. Confirm the user's authorization still covers **only** the phenotype-admission
   gate (this repo's active `/goal`).
3. Run the **A. zero-seed preflight** on Totoro at commit `976814393043…`
   (fail-closed on P2). Record a check-log entry with per-check verdicts.
4. Run the **B. chronology audit** on the live tree; record verdicts incl. L5
   (no live worker).
5. Hand the evidence back for review + write the hard-stop handover. **Do NOT
   draw a phenotype or run the 576-fit campaign.**

## Blockers / open questions

- Governance stop only: phenotype admission needs separate authorization.
- If A or B fails, the defect (not a phenotype) becomes the next work item.

## Gotchas & failed approaches

- The old canonical preseal cannot be reused: a preseal-bound tool byte changed
  (this is why everything was rebuilt under `9f7ed27`).
- Early fresh preparation roots are non-evidence; do not repair in place.
- The optional Julia `Manifest.toml` must remain in the Git comparison even when
  absent; filtering it out is not fail-closed.
- The carried-over protected paths are declared above; never stage them.
- Each Pn check exists because a prior retry died there — do not skip any as
  "obviously fine"; that assumption is exactly what banked prior campaigns.

## Mission control

| Repo | Branch / PR | What shipped | Highest-leverage next plan |
| --- | --- | --- | --- |
| `HSquared.jl` | `codex/2026-07-13-v07-performance-localization`, #274 | Rose admission audit PASS + zero-seed preflight/chronology plan | Codex runs A+B on Totoro; hard stop before phenotype |
| `hsquared` | same branch, #137 | repaired preseal gate + bootstrap receipt | mirror the gate verdicts on the R twin |

## How to resume

From `/Users/z3437171/Dropbox/Github Local/HSquared.jl`, start Codex (reads
`AGENTS.md` natively) and paste:

```
Rehydrate from docs/dev-log/handover/2026-07-17-codex-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps. Run the zero-seed preflight and chronology audit on Totoro; preserve the hard stop and do not draw a phenotype.
```
