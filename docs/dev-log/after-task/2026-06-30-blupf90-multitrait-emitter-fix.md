# After-task — BLUPF90 multitrait `renumf90.par` emitter fix — 2026-06-30

## Task goal

Close the 2026-06-29 v0.4 after-task **Next-action #3**: `comparator/prepare_blupf90_multitrait.jl`
emitted a `renumf90.par` that real `renumf90` 1.166 rejects, forcing the manual `renumf90_fixed.par`
workaround during the BLUPF90 comparator leg for `V4-MV-REML`. Make the committed packet run through
`renumf90` → `blupf90+` directly. Small, focused, tooling-only — promote nothing.

## Active lenses and spawned agents

Lenses: Gauss + Noether (renumf90 format / emitter correctness), Curie + Fisher + Mrode (comparator
evidence), Grace (CI), Rose (mandatory — repo-visibility / merged to `main`). Spawned: ONE real
`rose-systems-auditor` subagent on the slice (merged diff + close-out docs) → **PROMOTE-WITH-CHANGES**:
core claims verified honest (emitter format byte-for-byte, `#49` 42/42 live, `validation_status()` = 48
live, tooling-only, CI green, validator relaxation justified — not a silent weakening, end-to-end boundary
correctly fenced); three evidence-hygiene edits required — all applied (see Files changed + Public claim
audit).

## Live phase snapshot

`main` @ `c43e37c9` (PR #197 merged; the other lane's v0.3 two-effect work #195/#196 landed concurrently
and #197 stacked cleanly on top). `validation_status()` = 48 rows — UNCHANGED. Public-covered FITTING = 1
(v0.1 Gaussian). Nothing promoted; no API / default / R-wording / capability / validation-debt change. The
2026-06-29 next-action #3 (this emitter fix) is CLOSED.

## Files changed (this slice)

Merged in PR #197 (`a693f974`):
- `comparator/prepare_blupf90_multitrait.jl` — `renum_lines` emitter rewritten to the verified format;
  `validate_blupf90_multitrait_packet` reconciled (dropped the incorrect no-blank rule, split `DATAFILE`,
  added `FILE_POS`).
- `test/runtests.jl` — `#49` preflight token assertions updated to the new shape.
- `docs/dev-log/check-log.d/2026-06-30-blupf90-multitrait-emitter-fix.md` — NEW check-log entry.
- `docs/dev-log/recovery-checkpoints/2026-06-29-v4-blupf90-comparator.md` — RESOLVED note closing the
  follow-up.

Close-out commit (this report + the Rose-required sweeps):
- `docs/dev-log/after-task/2026-06-30-blupf90-multitrait-emitter-fix.md` (this report).
- `AGENTS.md` — Live Phase Snapshot refreshed (new 2026-06-30 top entry; discharges the now-stale "fix is a
  follow-up" framing in the 2026-06-29 entry — Rose #2).
- `docs/dev-log/coordination-board.md` — current-slice note.
- `src/validation_status.jl` — swept a stale runtime string: the V4-MV-REML evidence text still said the bug
  was "corrected in `renumf90_fixed.par`"; it now records the emitter fix / PR #197. Runtime STRING only —
  no status code, row count, or logic change; `validation_status()` stays 48 (Rose #1).
- `docs/dev-log/recovery-checkpoints/2026-06-29-v4-blupf90-comparator.md` — "byte-identical to the sibling"
  → "format-identical" precision (Rose non-blocking).

## What changed

- **Emitter**: now emits the verified format — byte-for-byte vs the manually-corrected `renumf90_fixed.par`,
  and the same `renumf90.par` format as the sibling `prepare_blupf90_two_effect.jl` — via
  (1) `DATAFILE` keyword and value on SEPARATE lines (the original inline `"DATAFILE blupf90_multitrait.dat"`
  made renumf90 read `TRAITS` as the datafile → `Data file is not found. file=TRAITS`); (2) `FIELDS_PASSED TO
  OUTPUT` + blank value-line and a new `WEIGHT(S)` + blank value-line (empty value-lines are how renumf90
  encodes "none"); (3) `EFFECT … cross alpha` (was the invalid `cross numer`, ×2); (4) new `FILE_POS` /
  `1 2 3 0 0`.
- **Validator**: removed the blanket "no blank records" rejection — it encoded a FALSE belief (renumf90
  requires those empty value-lines, so the rule would have rejected the correct format); added an explanatory
  comment; split the `DATAFILE` required-token; added `FILE_POS`.
- **`#49` preflight**: replaced stale-token asserts with positional checks (`DATAFILE`→value,
  `FIELDS_PASSED`/`WEIGHT(S)`→`""`, `cross alpha` ×2, `FILE_POS`→`1 2 3 0 0`); removed the now-wrong
  `!any(isempty…)` no-blank assertion (superseded by the precise `== ""` checks).
- **Gap closed end-to-end (this session)**: re-downloaded `renumf90` 1.166 + `blupf90+` 2.60 from UGA
  (Mac x86_64; `otool -L` → only `libSystem`, MKL-free; Rosetta) into the session scratchpad and RAN the
  regenerated packet — renumf90 accepts the emitted `renumf90.par` directly (no manual fix), and `blupf90+`
  AI-REML converges to the fixture optimum. An independent NEUTRAL start (G0=[0.3,0.05;·,0.3],
  R0=[0.5,0.02;·,0.5]) converged in 7 rounds (9.6e-13) to the same optimum (G0/R0 ~1e-5 vs target).

## Checks run and exact outcomes

- `julia comparator/prepare_blupf90_multitrait.jl` → validator PASS (`Validated packet: 80 phenotype rows,
  20 pedigree rows`); emitted `renumf90.par` confirmed (via `cat -e`) byte-for-byte the verified format.
- `Pkg.test()` (julia 1.10.0) → `Testing HSquared tests passed`; `BLUPF90 multivariate starter packet
  preflight (#49)` → **42/42**. Targeted mirror of the changed assertions (incl. negatives that old tokens
  are gone) → 12/12. Re-run after the close-out `src/validation_status.jl` string sweep → still green (the
  48-row count + status-set guards re-pass; no test asserts the swept substring).
- End-to-end: `renumf90` exit 0 (wrote `renf90.par`/`renf90.dat`/`renadd03.ped`); `blupf90+` exit 0,
  converged; G0 `[0.60362, 0.11195; ·, 0.27036]`, R0 `[0.26311, 3.06e-4; ·, 0.090660]` (~1e-5 vs the fixture
  `expected_*.csv`). Neutral-start run = 7 rounds to the same optimum.
- CI on PR #197 → ALL GREEN: Julia 1 (4m31s), Julia 1.10 (3m7s), docs (2m15s), documenter/deploy.
- `git status` clean; generated packet files + downloaded binaries are git-ignored / scratchpad-only.

## Public claim audit

Tooling / evidence-hygiene only. **No** capability-status row, **no** validation-debt row, **no**
`validation_status()` row-count or status-code change (stays 48 rows; one row's runtime evidence-string was
swept to remove a now-stale `renumf90_fixed.par` reference — Rose #1, a string sweep with no status/count
change); nothing promoted; public-covered FITTING = 1 unchanged. The end-to-end run CONFIRMS the committed
packet now runs without the manual workaround, and reproduces the single-fixture REML point estimate — it is
NOT a new V4-MV-REML covered claim and adds no comparator coverage beyond the executed 2026-06-29 leg.
V4-MV-REML stays validation-scale `covered` (NOT public-default); its standing debts (full-sib + 3+-trait
recovery, in-suite unstructured `sommer` test, deep-inbreeding boundary) are UNCHANGED. Real
`rose-systems-auditor` verdict: PROMOTE-WITH-CHANGES — the three required edits were the evidence-hygiene
cleanups above, all applied in this commit; the merged engineering claims were verified honest and not
overclaimed.

## Tests of the tests

The `#49` preflight now POSITIVELY pins the corrected tokens and pins the blank value-lines by exact
position (`== ""`), not by a blanket no-blank rule; the negative checks confirm the old `cross numer` /
inline-`DATAFILE` tokens are gone. The emitter ↔ validator ↔ test triangle is consistent: the validator runs
inside the generate path AND standalone, and the test mirrors it. The strongest test-of-the-test is external:
the real `renumf90` 1.166 accepts exactly what the preflight asserts, and `blupf90+` completes the chain —
so the preflight is validated against the real consumer, not just an internal model of it. The close-out
`src` string sweep is covered by the existing `validation_status()` row-count + status-set guards (48 rows;
no test asserts the swept text), re-run green.

## Coordination notes

Julia-lane only; no `hsquared` (R) files touched; no R-facing contract change (internal comparator tooling,
no bridge/payload/formula surface). No cross-lane action owed. The other lane's v0.3 two-effect covered
promotion (#196) merged concurrently; the narrow surface meant #197 stacked on `main` with zero conflict —
the "don't crash the other lane" caution held.

## What did not go smoothly

- The task's 3-item summary (DATAFILE split, `cross alpha`, `FILE_POS`) was narrower than the pasted
  verified format, which also needed the `FIELDS_PASSED`→blank change and a new `WEIGHT(S)` line. Resolved by
  treating the pasted end-to-end-verified block as authoritative and cross-checking against the sibling
  `prepare_blupf90_two_effect.jl` + renumf90's keyword/value-line semantics.
- The validator's no-blank rule had to be relaxed; it was a pre-existing false-belief check that would have
  rejected the correct format.
- Binaries were not on PATH; downloaded them to the scratchpad and ran end-to-end (network reachable without
  disabling the sandbox; Rosetta present).
- Rose caught that the slice closed the loop in the emitter but left a now-stale `renumf90_fixed.par`
  reference in the public `validation_status()` runtime string (`src/validation_status.jl`) and a stale
  "follow-up" in the AGENTS.md snapshot, and that this report initially asserted a close-out it had not yet
  executed — all sweeps applied in the close-out commit.

## Known limitations

- The end-to-end confirmation is ONE deterministic fixture / point estimate (same boundary as the 2026-06-29
  leg). The committed packet seeds starting values at the engine target by design (it is a *starter* packet);
  the independence is established by the separate neutral-start run, not by the default run.
- The downloaded binaries are NOT committed (regenerable from UGA); the obsolete manual `renumf90_fixed.par`
  remains git-ignored and harmless.
- `comparator/run_blupf90_multitrait.jl` still requires `airemlf90` on PATH, whereas the checkpoint and this
  run used `blupf90+` (both are valid BLUPF90-family AI-REML programs). Minor inconsistency — noted, not
  fixed (out of scope).

## Next actions

1. **CLOSED:** the 2026-06-29 next-action #3 (emitter fix) — done, merged green (#197); close-out + Rose
   sweeps merged separately.
2. Minor follow-up (optional, not done): align `run_blupf90_multitrait.jl` to `blupf90+` or document the
   `airemlf90`/`blupf90+` equivalence; optionally drop the obsolete `renumf90_fixed.par` mention from the
   recovery checkpoint once the packet is trusted.
3. Unchanged (not in scope): V4-MV-REML still-owed debt — full-sib + 3+-trait recovery, in-suite `sommer`
   test, deep-inbreeding boundary; D2 interval-default (profile-LRT, needs Codex + G10); maintainer G10 for
   the v0.4 scoped covered + BLUPF90 discharge.
