# After-task — 0.8 S2 FA recovery-gate prereg FROZEN (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-fa-20260903`. Type: SHA-locked prereg (not a campaign).

```
PLATFORM: cursor | LANE: cursor/08-fa-s2-prereg-20260903
OTHER LANES: G5 #157/#291 cite-only · Codex DRAFT #137/#274 cite-only · cursor/08-ss AGHmatrix
Active lenses: Ada · Shannon · Rose fence · Curie/Fisher · Kirkpatrick
Spawned subagents: none
Current lane: Julia 0.8 WT S2 freeze only
```

## Goal

Freeze an in-repo S2 recovery gate now that S1 is classified. No covered flip.

## What landed

- Decision + driver + predeclaration + check-log.d + this report + board row.
- **Freeze SHA: `eff57e3d`.**
- Gate DGP: **`t=4 K=1`**, `ledermann_slack=4`. `t=5 K=2` rejected (rank confound).
- Pass: converged + banked `rel_g ≤ 0.45` / `rel_r ≤ 0.25` + **`min(ψ̂) ≥ 1e-4`**
  + `slack > 0`. Old G/R gates are recorded as accepting collapsed uniqueness.
- S4 seeds `20260914:20260923` predeclared. **Not run.**
- S1 files / diagnose driver left untouched.

## Public claim audit

Allowed: "S2 prereg is SHA-locked; S1 showed old G/R gates accept Heywood;
the new gate uses t=4 K=1 and a uniqueness floor."
Blocked: FA / single-step covered; `cov=fa`; loadings+SE; WOMBAT parity;
0.8.0 / count 8; 1.0 / CRAN; Rose CLEAN (not requested, not written, not forged).

## Checks this slice

```sh
# laptop wiring only — one seed, no fit
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  julia --project=. sim/v08_fa_s2_prereg.jl \
  --mode=truth-only --cell=d4-k1 --seeds=20260914
# exit 0 in ~7 s (julia 1.10.0)
# t=4 K=1 ledermann_slack=4  loglik_truth=-1029.61156914  class=truth_only
```

No `--mode=fit`. No S3 engine edit. No S4 campaign. Did not touch G5,
`comparator/`, or `docs/design/capability-status.md` (other-lane lease).

## Tests of the tests

Driver asserts `ledermann_slack == 4` and PD `G`/`R` at construction. Smoke
exercised that path. Classification of fits is not tested here on purpose.

## What did not go smoothly

Scratch S2 outline existed; this slice is the first in-repo SHA. Coordination
board is a many-lane file — prepended a Current Rule row only.

## Known limitations

WOMBAT still absent. S3 bound is not implemented. S4 8/10 bar is predeclared
only. Rose CLEAN is absent.

## Next

S3: uniqueness-interior bound and/or Ledermann-saturation guard in the FA
fitter. **Not** EM warm-start. Then Totoro S4 on this frozen driver. No flip
until design-41 §3 + Rose CLEAN.
