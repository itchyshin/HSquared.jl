## 1. Goal

Run the one user-approved G2 N80/null outer32 attempt, retain its result, and repair its artifact-serialization error. Arc 1 remains active; this record covers one bounded attempt.

## 2. Implemented

The approved attempt ran once on Totoro using seed `18043834289602542821`, candidate SHA-256 `a3e0066897e8fd8fab55d3b9e4e963c442cfe0ae03627457f0ca780be772b729`, and source-lock SHA-256 `3463c8a621318e06bbf3c63b7561c538e7f27d17c54c033245b0dd9ae9407af9`. It returned `success=false` after 46.437 seconds because `Vector{NamedTuple}` was rejected at `raw_selection[18][]`. The attempt is retained and counts once in the v14 all-attempt denominator; it gets no fit or gate credit. No further seed was launched.

The serializer now permits abstract `NamedTuple` element declarations while recursively validating concrete values. Tests cover heterogeneous named tuples, container round-tripping, the affected artifact field, and continued rejection of unsupported `Set` values. The targeted executor test passed 4/4. The broader file run passed its first 348 assertions, then was interrupted in a subsequent subprocess test; the whole file is not a pass.

## 3a. Decisions and Rejected Alternatives

Preserved the failed attempt as evidence rather than rerunning or replacing its seed. The v14 pins are stale after the serializer repair, so they cannot admit another attempt. G7 was reopened because the repaired source differs from its last frozen package-check source.

## 4. Files Touched

- `sim/arc1/artifact_container.jl`
- `test/arc1_simulation_executor.jl`
- `.unlazy/arc1-gaussian-reliability/GATES.md`
- `docs/design/arc1-gaussian-reliability-20261002.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `.unlazy/arc1-gaussian-reliability/evidence/attempts/g2-v14-first-launch-refusal.json`
- `.unlazy/arc1-gaussian-reliability/evidence/attempts/g2-v14-outer32/`
- `docs/dev-log/after-task/2026-10-10-g2-v14-outer32-and-artifact-fix.md`

Other pre-existing dirty files in the shared worktree were not part of this change.

## 5. Checks Run

- Totoro exact-source admission preflight passed before the single authorized run.
- The run returned a retained error receipt; the same-host artifact inspector verified source and execution identity, raw and derived error agreement, embedded summary, and recomputed semantic identity.
- Focused serializer/executor tests passed 4/4, including the failure-path control for `Set`.
- Independent Astra source review passed for `sim/arc1/artifact_container.jl` SHA-256 `0a029e654117b113ab6a4a6e931eb44f4828d93b65b435a5945ba9a4e47ed934` and `test/arc1_simulation_executor.jl` SHA-256 `65b04e3ca800202b9afb5c384a90fdb8c6fbfa894f64ec3786d470ad3fd3ec61`. The review confirmed the exact abstract-type exception and recursive rejection of unsupported nested values. The reviewer did not rerun Julia.
- Broader `test/arc1_simulation_executor.jl` produced 348/348 in its first testset, then was interrupted in a later subprocess test. No whole-file pass is claimed.
- `git diff --check` passed for the touched source, test, and status files.
- After-task structure validation passed. The full closeout check correctly refused completion because the Arc 1 and related project ledgers still contain unmet gates.

## 6. Tests of the Tests

The regression test first reproduced the exact `unsupported Arc1 container type NamedTuple at raw_selection[18][]` failure. After the fix, it verified successful named-tuple serialization and round-trip while confirming unsupported `Set` values remain rejected.

## 7a. Issue Ledger

- Fixed: valid heterogeneous `Vector{NamedTuple}` artifact values were refused before recursive value validation.
- Open: G2 ordinary-fit reliability and selection criteria; G3/G4 FA selection and interval validation; G5 all repeatability intervals; G7 fresh package verification; G8 independent closeout.
- The v14 candidate has 268 allocations remaining, but its source pins are obsolete after the fix. Any further attempt needs a fresh candidate, exact review, source lock, and separately bound approval.

## 8. Consistency Audit

The gate ledger, design page, coordination board, check log, and lane checkpoint record the same failed-attempt status, no-credit decision, and G7 reopening. Capability remains experimental; covered count remains seven. No pilot or confirmation study has run.

## 9. What Did Not Go Smoothly

The local macOS preflight rejected the host path before fitting. The first Totoro launcher invocation rejected a stale source tree before sampling and consumed no seed. After exact source staging, the authorized attempt reached fitting but failed during artifact serialization. The broad local test file later stalled in a subprocess test and was interrupted; its passing first testset does not establish a full pass.

## 10. Known Residuals

Arc 1 remains incomplete. G0, G1, and G6 remain met at their recorded scopes; G2 through G5 and G8 remain open, and G7 is reopened. No new simulation attempt or campaign is authorized by this checkpoint. The exact next action is to freeze the repaired source as a new candidate, run its regression and package checks, obtain independent review, and request a new singleton approval before any additional seed is launched.

## 11. Team Learning

Memory receipt: applied the repo lane ownership and source-freeze rules; retained the failed attempt and did not reuse its seed. No durable brain-memory change was requested.

Golden Set: not in scope for this bounded engineering and evidence checkpoint.

## 12. Cross-Product Coverage

Covers: Julia Arc 1 artifact container behavior and the retained G2 singleton attempt record.

Does NOT cover: R parity, scientific selection or interval acceptance, pilot qualification, confirmation, GPU, releases, or completion of the HSquared project.
