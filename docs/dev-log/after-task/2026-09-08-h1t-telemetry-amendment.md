# After-task — 2026-09-08 H1T telemetry-only amendment

**Scope:** a fresh isolated Julia worktree amendment for
`H1T-DIAG-S10-FIXED-TINY-01`, committed as `7b811c75` on top of ratified S9
baseline `dd1bfa77579c9167e354a270986d205d2e36926e`. It adds private,
in-memory diagnostic telemetry and deterministic local tests only. It does not
rerun S10, create or alter an S10 fixture, use Totoro/DRAC, change R, change a
bridge payload or public API, change a capability claim, or authorize a
release.

## 1. Goal

Implement the separately authorized telemetry-only amendment while preserving
the established two-effect REML and interval public route. The amendment must
retain fit, finite-difference, and terminal-state facts for a future separately
authorized exact-input diagnostic—not infer the cause of the historical S10
failure or produce scientific evidence now.

## 2. Implemented

- Extracted the existing two-effect fit and interval bodies into private cores
  whose normal public wrappers keep their signatures and result fields.
- Added an unexported, in-memory diagnostic snapshot with provenance/input
  validation, canonical materialization hashes, optimizer telemetry, FD records,
  observed-information summaries, per-ratio terminal codes, and an immutable
  `claim_eligible = false` field.
- Retained the adverse paths required by the ratified protocol: a degenerate
  denominator suppresses dependent ratios/shares/FD information; an FD
  exception retains prior records and its exception; a post-FD failure is
  classified as delta/interval rather than FD failure.
- Added a deterministic local test file and included it in the ordinary Julia
  suite. Its existing interior fixture is fingerprint-pinned and explicitly is
  **not** the unavailable historical S10 `h1_two` materialization.

## 3a. Decisions and Rejected Alternatives

The helper has no fit/interval substitution keyword: even a private test hook
would let a caller replace the frozen optimizer or interval algorithm, which is
outside this amendment. Unit tests instead exercise the lower-level telemetry
recording/classification helpers directly.

Rejected: S10 driver inclusion, historical fixture regeneration, a source of
truth other than the ratified protocol, R/bridge/public-surface expansion,
artifact writing, remote execution, a smoke rerun, coverage interpretation,
promotion, versioning, tagging, and release work.

## 4. Files Touched

- `src/likelihood.jl` — private trace-aware cores and unexported H1T
  telemetry-only helpers.
- `test/runtests.jl` — includes the deterministic amendment test.
- `test/h1t_telemetry_amendment.jl` — same-build parity, frozen local
  materialization, adverse-path, and mutation controls.
- `docs/dev-log/after-task/2026-09-08-h1t-telemetry-amendment.md` — this
  closure report.
- `docs/dev-log/check-log.d/2026-09-08-h1t-telemetry-amendment.md` — paired
  receipt.

No exported-name list, public signature, public NamedTuple field order, bridge
file, R checkout, simulation driver, retained S10 artifact, capability/debt
ledger, version, tag, or release surface changed.

## 5. Checks Run

- Dedicated deterministic local telemetry suite: **PASS**, 79/79 assertions;
  markers include `H1T_PARITY_OK`, `H1T_MUTATION_OK`,
  `H1T_TELEMETRY_SCHEMA_OK`, `H1T_PUBLIC_API_FROZEN_OK`, and
  `H1T_TELEMETRY_TESTS_OK`.
- Normal local Julia suite: **PASS** —
  `/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`
  completed with `Testing HSquared tests passed`.
- Unlazy: **PASS**, root G0–G5, implementation leaf L1–L4, and closure leaf
  C1–C2 all met; each runnable code gate was re-verified under the supported
  300-second bound.
- `git diff --check`: **PASS**.
- Frozen-surface and clean-R checks: **PASS**; the sibling R candidate stayed
  clean at `e6a1ce4e8a691795487420668b349fb9e2670059`.
- Cross-baseline local public-output control: **PASS**. The deterministic
  existing small two-effect control produced the same SHA-256 of its complete
  public fit/interval representation at S9 and at this amendment:
  `da2b104d771e5c29e544f729b26a55ff4239d99693d82d4a49948236d7859612`.
- Independent reviews: Rose **CLEAN WITH LIMITATIONS** and Gauss **PASS**
  after a fresh re-audit of the final hook-free code. Both were review-only.

No S10 command, simulation campaign, benchmark, CI dispatch, Documenter build,
remote connection, scheduler action, or release action ran.

## 6. Tests of the Tests

The suite rejects a wrong derived seed, corrupt input fingerprint, missing or
duplicated ratio row, omitted optimizer terminal detail, nonfinite information
labeled finite/PD, non-PD kept information labeled PD, a boundary mislabeled
interior, and `claim_eligible = true`.

It also forces a degenerate total through the telemetry unit to verify NaN/
unattempted downstream fields. A real throwing objective is passed through
`_h1t_fd_evaluation`, proving the recorder retains its actual error record;
the partial-information summary then retains it. The delta-stage marker and
its terminal classifier are tested directly, so post-information failures do
not masquerade as FD failures.

## 7a. Issue Ledger

- Resolved: dependent telemetry could retain stale ratios after a degenerate
  total; it now records them as NaN and leaves FD/eigen/interval work
  unattempted.
- Resolved: an FD exception could discard earlier diagnostic records; partial
  steps, records, and exception detail now remain retained in memory.
- Resolved: a later delta error could be labeled as an FD error; the stage is
  explicitly advanced after information completion.
- Resolved before closeout: private test-time fit/interval substitution hooks
  would have weakened the no-substitution contract. They were removed, and the
  tests now exercise real telemetry primitives.
- Deferred: the literal frozen historical S10 materialization parity control.
  The exact arrays are absent from retained historical evidence and are not
  regenerated under this authorization.

## 8. Consistency Audit

The code, focused tests, normal suite, Unlazy receipts, and both independent
reviews agree that this is instrumentation only. Direct public calls and the
instrumented private route agree exactly on the deterministic existing control;
the separate baseline checksum agrees for a second existing small control.

The latter two controls are regression evidence, not an S10 result and not a
scientific calibration claim. The historical S10 status remains failed/held.

## 9. What Did Not Go Smoothly

The first internal design retained test-only substitution keywords and manually
constructed FD trace records. Gauss correctly identified that both could hide
an algorithm substitution or fail to test the real recorder. The final design
removes the hooks and tests the actual recorder/classifier. The full Julia
suite exceeds Unlazy's default 120-second bound on this host; it was run and
re-run under the supported 300-second bound without weakening the command.

The common coordination board was not edited: lane preflight reported active
foreign Codex lanes. This report and its paired check log have unique leased
paths instead, so no shared-board ownership was assumed.

## 10. Known Residuals

This amendment does not establish that the historical S10 `h1_two` input can
be reconstructed, that a future instrumented run will reproduce its terminal
state, or that any interval is calibrated, directional-conservative, or
scientifically fit for promotion.

Before any H1T diagnostic execution, a maintainer must separately authorize a
named exact-input pre-run after the required source/Manifest/harness/input
identities and duration estimate are available. G6–G10, R work, public claims,
versioning, tags, registry actions, and release remain held.

## 11. Team Learning

An unexported test hook can still be a contract breach when it lets a future
diagnostic replace a fixed scientific algorithm. For telemetry, test the real
observation mechanism—not only a prebuilt record that resembles its output.

No durable-memory update was authorized.

## 12. Cross-Product Coverage

Covers: private telemetry schema, provenance/input preflight, deterministic
local materialization fingerprints, optimizer terminal facts, finite-difference
record retention, terminal precedence, same-build public/private parity,
baseline public-control parity, regressions, and no-public/no-R/no-rerun
fences.

This amendment does NOT cover: historical S10 input identity or rerun, external comparator
agreement, simulation recovery/coverage/calibration, R–Julia parity, retained
campaign evidence, CI, public capability activation, promotion, versioning,
tagging, registry, or release.
