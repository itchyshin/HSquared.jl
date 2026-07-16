# Retry-7 architecture and seed-contract checkpoint

## 1. Goal

Close the Julia half of the research-informed Retry-7 route/adjudicator and
seed-contract checkpoint without invoking official RNG.

## 2. Implemented

- Added internal `EvidenceRoute` and `EvidenceRow{R}` typing to the tracked
  D0F/D1 replay script. Route is excluded from payloads and derived from type
  during serialization.
- Updated D1 predecessor and pre-RNG review parsing to the R adjudicator's v2
  schemas, including route lineage, adjudication key, and exact tool hashes.
- Mirrored the new Retry-7 phenotype/bootstrap reservations and regenerated the
  deterministic cross-language parity pin.
- Replaced the stale ultra-plan with the research-informed Retry-7 plan and
  preserved the strict pre-RNG chronology.

## 3a. Decisions and Rejected Alternatives

Typing is limited to the tracked operational replay because the public engine
API and TSV boundary must not change. R owns the primary serialization-boundary
protection; Julia typing is defence-in-depth. No `src/HSquared.jl`, public
payload, formula, numerical estimator, or result shape was changed.

## 4. Files Touched

- `AGENTS.md`
- `docs/dev-log/after-task/2026-07-16-retry7-architecture-seed-contract-checkpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/handover/2026-07-16-codex-handover.md`
- `docs/dev-log/phase-snapshot-archive.md`
- `docs/superpowers/plans/2026-07-15-retry7-pre-rng-readiness-ultraplan.md`
- `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl`
- `sim/phase2_v07_genomic_recovery_v3_stage_replay.jl.sha256`

The two modified Retry-5 draft reports and the untracked downstream replay
scaffold are protected foreign/quarantined state and were not inspected,
edited, staged, or included.

## 5. Checks Run

- Operational replay `--mode=selftest`: PASS, synthetic only, explicitly no
  official RNG or seed consumed.
- Full `julia --project=. -e 'using Pkg; Pkg.test()'`: PASS.
- `julia --project=docs docs/make.jl`: PASS with pre-existing docstring/assets
  warnings and no deployment.
- Replay sidecar and `git diff --check`: PASS.
- Cross-language canonical lifecycle: D0F `PASS/COMPLETE` and D1
  `PASS/ELIGIBLE=12`, each with five CLEAN reviews, exact receipt retry, and
  final validation.

## 6. Tests of the Tests

Typed negative controls reject raw rows, ordinary-route rows in Julia summary,
route mutation, wrong predecessor schema/bindings, and full-cardinality parity
mutation. The R twin's mutation campaign independently rejects route forgery,
lineage drift, tool-hash drift, and receipt-byte drift.

## 7a. Issue Ledger

- Fixed: Julia D1 predecessor still admitted only the retired receipt schema.
- Fixed: pre-RNG reviews omitted exact tool-byte bindings.
- Fixed: stale Retry-6 seed and bootstrap SHA pins after Retry-7 reservation.
- Deferred: `R CMD check`, clean Totoro launcher rehearsal, exact-head CI and
  reviews, preseal, chronology, and official D0F campaign.

## 8. Consistency Audit

R and Julia ordered schemas, route types, D0F/D1 summary dispatch, predecessor
bindings, seed constants, sidecars, and public-surface diffs were checked. No
changes exist under `src/`, `ext/`, `Project.toml`, `Manifest.toml`, `test/`, or
public docs source for this arc.

## 9. What Did Not Go Smoothly

The first selftest invocation used `--selftest` rather than the supported
`--mode=selftest` and correctly fell into the compute guard. After seed
reservation, the cross-language bootstrap SHA pin remained Retry-6 and was
regenerated from the R-owned deterministic fixture.

## 10. Known Residuals

The synthetic lifecycle does not replace clean Totoro deployment, real
recomputation/replay, or a production preseal. This checkpoint authorizes no
official RNG, adjudication claim, activation, D1 compute, merge, or release.

## 11. Team Learning

Memory receipt: loaded `hsquared-rehydrate`, `ultra-plan`,
`engine-contract-review`, and `after-task-audit`; they kept the public engine
surface frozen and required exact twin-schema evidence.

Golden Set: not in scope; no brain retrieval behavior changed.

## 12. Cross-Product Coverage

Covers: the tracked D0F/D1 operational replay's internal route typing,
serialized route conservation, v2 predecessor/review bindings, parity
selftests, and Retry-7 seed constants.

Does NOT cover: `src/HSquared.jl`, public engine/API/result payloads, formula
grammar, numerical methods, default R routing, public activation, G10, actual
D1-D4 compute, merge, or release.
