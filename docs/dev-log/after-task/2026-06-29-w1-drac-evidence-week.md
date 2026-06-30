# After-task — W1 DRAC evidence week (Claude, end-to-end) — 2026-06-29

## Task goal

Execute the approved ultraplan's locked Week 1 (`docs/design/18-programme-plan-2026-06.md`): the A6
status-board generator, the two harness fixes (S1 bootstrap, S2 V4 factorial), the predeclared DRAC
campaigns (interval coverage + broader-DGP V4 recovery), end-to-end on DRAC — Claude driving, Codex out.
Produce gated, recorded TRIAGE evidence; promote nothing without Rose + maintainer G10.

## Active lenses and spawned agents

Lenses: Gauss, Curie, Fisher, Noether, Rose, Grace, Ada, Shannon. No subagents spawned this session
(the 3 meetings + 3 ultraplan panels were in the planning session that produced doc-18).

## Live phase snapshot

Branch `w1/2026-06-29-evidence-week-setup` (pushed; PR not opened — no auto-merge), 9 commits off `main`
`5e37cb53`. `validation_status()` unchanged (48 rows); **public-covered fitting = 1** (v0.1 Gaussian);
`V1-HERIT-TCAL` stays `planned`. Nothing promoted. The held docs PRs #191/#193 are untouched.

## Files changed (branch)

`docs/design/18-programme-plan-2026-06.md` (+ ROADMAP pointer); `tools/gen_status_json.jl`,
`tools/status_cache.json`, `tools/control-centre/index.html` (S0); `sim/phase1_small_sample_interval_calibration.jl`
(S1); `sim/phase4_multivariate_reml_recovery.jl` (S2); `sim/drac/{phase1_interval_coverage.sbatch,
phase4_v4_recovery.sbatch,phase4_v4_cells.tsv}`; `docs/dev-log/recovery-checkpoints/2026-06-29-w1-*`
(ADEMP + C1/C2 evidence + summaries).

## What changed

- **S0 — generated board.** `tools/gen_status_json.jl` emits `status.json` from machine state
  (cached `validation_status()` count + live `git`/`gh`), hard-pinning `public_covered_count=1`; a lean
  `tools/control-centre/index.html` polls it. Replaced the week-stale hand-typed control-centre data
  (R1) and re-pointed the `:8791` server at it (my ad-hoc preview server was the prior occupant, not the
  canonical board — verified by PID before touching).
- **S1 — interval bootstrap draw-once.** The phase1 harness re-drew the bootstrap inside the level loop
  (level-dependent seed) → crossed 90/95% intervals + per-level cost. Now drawn once per replicate; both
  levels read off the shared `.replicates` via the in-package `_empirical_upper_quantile`. Verified: 90%
  nests in 95%.
- **S2 — V4 DGP factorial + aggregate gate.** Parameterized the recovery DGP (`--g11..r22`, design,
  `--cell`), made the authoritative gate the printed AGGREGATE bias/MCSE block (machine-readable `GATE`
  line) not the per-seed Frobenius exit, and added a near-singular-G guard (`--max-cond`). Defaults
  reproduce the legacy cell. Verified (parameterized cell runs; `cond=1999` rejected at `--max-cond=100`).
- **DRAC execution (fir).** Preserved a dirty prior Wave-F checkout (`.waveF-backup-20260629`), cloned a
  clean W1 checkout, instantiated the shared depot, smoked end-to-end.
  - **Campaign 2 (V4 recovery):** 8 cells × 50 cold-start seeds, 50/50 converged. R9 CLEAN
    (`base_inside` passes → no regression). 5/8 pass; 3 honest boundaries (the known ~5% σ²a bias made
    detectable at larger n; single-record × extreme-r_g identifiability).
  - **Campaign 1 (interval coverage):** re-sized pre-launch for feasibility (tiny+small, 1000 reps,
    n_boot=99). σ²a delta/Wald under-covers (~0.84–0.92 vs 0.95) → confirms the `V1-HERIT-TCAL`
    small-sample mis-calibration; profile-LRT best-calibrated; bootstrap under-covers; tiny/low-h²
    boundary-non-interpretable.

## Checks run and exact outcomes

- `validation_status()` live → `rows=48, covered=5, covered_external=3, partial=39, planned=1` (seeded the
  generator cache; matches the `test/runtests.jl:174` guard).
- Local S1 smoke → 90% nests in 95% for h² and σ²a, both off the same 16/16-converged draw.
- Local S2 smoke → `CELL`/`GATE` lines emitted; `cond(G0)=1999` rejected at `--max-cond=100`.
- A6 generator → `status.json` validates as JSON; `public_covered_count=1`; counts match live; `:8791`
  serves the new board (title verified).
- fir smoke job `46235170` COMPLETED → `HSquared loaded ok`, both harnesses ran.
- C2 array `46235637` COMPLETED (8 cells); C1 array `46236262` COMPLETED (20 tasks, 176,001 detail rows).
- `git diff --check` clean; foreign files never staged (verified each commit).
- NOT run locally by me: `Pkg.test()` / `docs/make.jl` (engine `src/` unchanged this session — only `sim/`,
  `tools/`, `docs/`; CI on the branch is the gate when a PR opens).

## Public claim audit

Clean. Two campaigns of recorded, gated TRIAGE evidence; **nothing promoted**. No interval method
implemented; no default/API change; `validation_status()` unchanged; `V1-HERIT-TCAL` stays `planned`;
public-covered = 1. R9 regression rule honored (base_inside passed; no regression to flag). The board
now pins covered=1 and derives counts (kills the R1 honesty drift).

## Tests of the tests

Each harness fix was smoke-verified on the property it targets (bootstrap nesting; cell parameterization
+ cond guard). DRAC evidence carries committed seeds/versions and the pre-declared gate (ADEMP), with
coverage on `interval_success` and a non-interpretable flag, and the aggregate (not per-seed) gate for V4.

## Coordination notes

No R files touched. Codex out — this was Claude solo end-to-end. A Codex handoff is written
(`2026-06-29-codex-handover.md`) for the maintainer-decision + follow-up items. The prior dirty fir
checkout is preserved (not lost) and worth the maintainer's review.

## What did not go smoothly

- The fir checkout was dirty from a prior Wave-F session (uncommitted `src/` mods); handled
  non-destructively (backup + fresh clone).
- Campaign 1's predeclared grid (medium + n_boot=199 × 2000 reps) was infeasible; re-sized pre-launch
  (R4) and recorded in the ADEMP. Medium-design coverage deferred.

## Known limitations

- C1 evidence excludes the medium design + larger n_boot (deferred follow-up).
- C2 broader-DGP recovery is mixed (3/8 fail) — it characterizes the envelope, it does not support a
  universal-recovery claim; the σ²a bias and single-record×extreme-rg boundary are real.
- The interval coverage stays characterization-only; no calibration method exists.

## Next actions

1. **Maintainer (G10, non-delegable):** decide the V4 path — a *scoped* finish of `V4-MV-REML` (document
   the σ²a bias + the single-record×extreme-rg boundary) vs. a follow-up; then a real Rose audit before
   any covered move.
2. Re-size + run the **C1 medium-design** coverage follow-up.
3. Open the W1 PR when ready (Rose pass first; no auto-merge); review the preserved fir Wave-F backup.
4. Consider whether the C1 result motivates moving profile-LRT toward the default (a separate, gated slice).
