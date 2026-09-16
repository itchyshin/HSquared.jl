# After-task — C1-ext H1/H3 coverage harness (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/09-h1-h3-harness-20260903`. Type: evidence scaffolding.

```
PLATFORM: cursor | LANE: cursor/09-h1-h3-harness-20260903
OTHER LANES: G5 #291 cite-only · 0.8 FA #292 cite-only · Codex DRAFT #274 cite-only
Active lenses: Ada · Shannon · Fisher · Curie · Rose fence
Spawned subagents: none
Current lane: Julia C1-ext worktree (~/local-scratch/lanes/HSquared.jl-09-h1-h3-20260903)
```

## Goal

Advance the 0.9 gap H1/H3 harness named in doc-34 §10
(`sim/phase1_interval_coverage_ext.jl`) from the 2026-09-03 intervals scout.
Write the missing driver + ADEMP table. Do not run a 2000-rep confirm. Do
not rescue repeatability `t`. Do not flip covered.

## What landed

- `sim/phase1_interval_coverage_ext.jl` — NEW driver, NEW TSV schema,
  include-safe. Campaigns: H1 two-effect / multi-effect ratios, H1 `t`
  (characterization only), H3 Fisher-z `r_g` / `r_am`.
- `test/test_phase1_interval_coverage_ext.jl` — thin parse/contract test;
  optional `HSQUARED_C1EXT_SMOKE=1`. Not wired into `runtests.jl`.
- ADEMP predeclaration + not-armed `sbatch` template.
- Symbolic-alignment table printed by the driver (design-36 §2.2).

## Public claim audit

Allowed: "C1-ext driver exists; gates are predeclared; smoke path ran."  
Blocked: coverage-calibrated intervals; `point`; covered flip; count 8;
repeatability rescue; genomic / FA / NG interval claims; 1.0 / CRAN.

## Checks this slice

See `docs/dev-log/check-log.d/2026-09-03-c1-ext-h1-h3-harness.md`.
Coordination board not edited (0.8 FA lane holds `docs/`).

## Lease / collision

Dropbox checkout was FOREIGN (Codex v0.7 branch). Work ran in a new
worktree off `origin/main` (`b45189b5`). G5/0.8 umbrella lease holds
`src/,docs/,sim/`; this slice added **new files only** and claimed
`test/test_phase1_interval_coverage_ext.jl`.

## Next

1. Totoro 1-task smoke + `seff` after G0 (not this slice).
2. DRAC fir confirm array after maintenance week, new SHA, new TSV.
3. Fisher map through doc-34 §4. No silent `point`.
4. H0 unpaid bank and NG-1 closeout remain compute-free coordinator work.
