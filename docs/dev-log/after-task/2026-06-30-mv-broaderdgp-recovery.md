# After-task — V4-MV-REML broader-DGP recovery (full-sib + 3-trait) — 2026-06-30

## Task goal

Discharge the two still-owed *pure-Julia* recovery items on the already-covered `V4-MV-REML` row —
**full-sib design recovery** and **3+-trait recovery** — each via a pre-declared, committed 48-seed
cold-start gate run on Totoro. Additive evidence hardening the covered claim against the R9
covered-regression risk; NOT a new covered flip. Plan: `~/.claude/plans/plan-the-arc-concurrent-mccarthy.md`.

## Active lenses and spawned agents

- **Real subagents:** Curie (`curie-validation-tester`), Fisher (`fisher-inference-reviewer`),
  Mendel (`mendel-inheritance-specialist`) — the pre-run validation panel (all **PROCEED**). Rose
  (`rose-systems-auditor`) — the mandatory claim-vs-evidence audit → **PROMOTE-WITH-CHANGES**: all
  seven audit points verified independently (predeclaration ordering by timestamp, both gates PASS
  byte-for-byte vs the raw logs, byte-identical default re-run at `main` vs HEAD, honesty pins,
  lockstep reconciliation, misfire quarantine). Two citation-accuracy fixes applied: the 3-trait
  pre-declaration is `7e4a7d53` (not the amendments `4f3fcde6`) — corrected in the 3-trait
  checkpoint, the check-log, and the debt-register clause.
- **Perspectives (inline):** Ada (orchestration), Gauss/Henderson (t=3 REML), Falconer (h²
  interpretation), Karpinski (Totoro), Shannon (twin-lane: R untouched), Grace (CI).

## Live phase snapshot

- **As of 2026-06-30 (v0.4 MV broader-DGP recovery — full-sib + 3-trait both DISCHARGED, scoped;
  Claude solo; branch `feat/2026-06-30-v04-broaderdgp-recovery`, PR pending G10).** Two pure-Julia
  recovery items on the covered `V4-MV-REML` row discharged via pre-declared 48-seed cold-start
  gates that BOTH PASS all four criteria (full-sib t=2: 48/48, all 6 `|bias|≤2·MCSE`, EBV ≈0.90,
  R9-clean; 3-trait t=3 — the substantive 12-parameter cell: 48/48, all 12 `|bias|≤2·MCSE`, EBV
  ≈0.90, no off-diagonal MCSE inflation). Curie/Fisher/Mendel pre-run panel (PROCEED) + committed
  pre-declarations before the run. Harness generalized (full-sib pedigree; general-`t`); RNG-free
  self-test. `validation_status()` = **48 UNCHANGED**; **public-covered FITTING = 1 UNCHANGED**;
  covered status UNCHANGED (additive evidence). STILL OWED on the row: the in-suite `sommer` test
  (needs live R), the deep-inbreeding boundary. **NEXT: Rose audit → maintainer G10 → PR merge.**

## Files changed (this slice)

- `sim/phase4_multivariate_reml_recovery.jl` — `_fullsib_pedigree`, `PROGRAM_FILE` guard, `--design`,
  general-`t` sim, `_covariance_params(t)`, `--traits=3` + 3×3 truth, design-/t-aware `CELL` header.
- `sim/selftest_phase4_extensions.jl` (new) — RNG-free deterministic self-test.
- `docs/dev-log/decisions/2026-06-30-mv-reml-{fullsib,3trait}-gate.md` (new) — pre-declarations.
- `docs/dev-log/recovery-checkpoints/2026-06-30-mv-{fullsib,3trait}-{48seed.md,results.txt}` (new).
- `docs/design/validation-debt-register.md`, `docs/design/capability-status.md` — lockstep V4-MV-REML
  standing-debt update (full-sib + 3-trait discharged).
- `docs/dev-log/check-log.d/2026-06-30-mv-broaderdgp-recovery.md` (new).
- `tools/control-centre/index.html` — prep commit (v0.5-covered roadmap fix; unrelated to the gates).

## What changed

The MV recovery harness gained two non-overlapping DGP dimensions (full-sib design; general trait
count) with the estimator untouched (`fit_multivariate_reml`'s Kronecker MME is already `t`-general).
Both pre-declared gates were run cold-start over 48 seeds on Totoro and PASS all four criteria, so
the two owed recovery items are discharged (point-estimate, single fixture). No `src/` change.

## Checks run and exact outcomes

- `sim/selftest_phase4_extensions.jl` → **SELFTEST PASSED** (every TDD step).
- Full-sib gate: `GATE … aggregate_within_2mcse=true gate_pass=true seeds=48`; 48/48, all 6
  `|bias|≤2·MCSE`, EBV 0.898/0.903, G-MCSE ≤0.032.
- 3-trait gate: `GATE … aggregate_within_2mcse=true gate_pass=true seeds=48`; 48/48, all 12
  `|bias|≤2·MCSE`, EBV 0.893/0.903/0.899, G-diagonal MCSE ≤0.036.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → PASS incl. `length(validation) == 48`.
- `julia --project=docs docs/make.jl` → exit 0.

## Public claim audit

No public claim changed. `validation_status()` = 48; public-covered fitting = 1 (v0.1 Gaussian). The
R lane (`hsquared`) is untouched — engine-covered ≠ R-public-covered. "Covered" for V4-MV-REML is
unchanged; the discharge is of two standing-debt items, not a promotion. No "unbiased" wording.

## Tests of the tests

The self-test's closure-capture check builds a 3×3 mock and asserts each `_covariance_params` getter
reads its own `(i,j)` (guards the classic Julia loop-closure bug). The t=2 back-compat assertions
(param names/order, default truth byte-identity) guard the general-`t` refactor from changing the
covered 2-trait behavior. The full-sib `A`-PD assertion + Mendel's independent empirical check
(A=0.5 within family, F=0, d_i=0.5) guard the pedigree construction. The pre-run panel reviewed the
gate criteria *before* the run so a flawed gate could not be silently burned.

## Coordination notes

Julia-engine-lane, solo. No `hsquared` edits; no Codex baton (the deselected in-suite `sommer` test
was the only R-needing item). Maintainer G10 is the only remaining human gate.

## What did not go smoothly

The first Totoro campaign misfired: a stale pre-existing clone (`~/hsq_work/HSquared.jl` on a v0.5
branch @ `5a686ec`) was not switched to this branch because `git checkout <branch>` failed and
`set -e` does not abort on a failed middle-of-`&&`-chain command. The stale harness silently ignored
the unknown `--design`/`--traits` flags and reran the default half-sib/t=2 cell — both "cells"
returned identical numbers, which (with the `HEAD=` echo) exposed the misfire at ingestion. No
evidence was written from that run; pre-registration intact. Fixed by force-fetching + checking out
the branch and re-running under a hard `HEAD`/harness guard with a `CELL`-header design check.

## Known limitations

Point-estimate / single-fixture / pre-declared-48-seed-gate discharge only. Full-sib is the EASIER
identifiability regime (confirmatory, not a stress test). "No detectable bias" ≈6–7% floor at this
design/power — never "unbiased". STILL OWED on the row: the in-suite unstructured `sommer` test
(needs live R / a Codex baton), the deep-inbreeding boundary. Covered status, `validation_status()`
= 48, and public-covered fitting = 1 are all unchanged.

## Next actions

1. ✅ Real **Rose** audit (`rose-systems-auditor`) → PROMOTE-WITH-CHANGES (2 citation fixes applied).
2. Regenerate `status.json`; push; open PR to `main` (docs/sim-only).
3. **STOP for maintainer G10** — the standing-debt-clause edit is a covered-row change; no self-merge.
