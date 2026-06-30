# 2026-06-30 — V3-TWOEFFECT-REML promoted partial→covered (Rose PROMOTE-WITH-CHANGES applied)

- Atomic covered promotion of the v0.3 two-effect kernel on the doc-33 path-(b) substitutable gate (gate
  PASS + BLUPF90 comparator, both landed on `main` via PR #195, both Rose-CLEAN with independent reproduction).
- Maintainer authorized ("Yes merge and keep going"). 2nd validation-scale covered estimator (after V4-MV-REML).
- Flipped status `partial→covered` + covered framing on `src/validation_status.jl`,
  `docs/design/validation-debt-register.md`, `docs/design/capability-status.md`.

## Checks

- `Pkg.test()` (julia 1.10.0) PASS → `validation_status()` 48 rows, **covered 5→6**, V3TE=covered;
  status-partition guard (`test/runtests.jl:537`) holds.
- **Real Rose audit on the flip → PROMOTE-WITH-CHANGES**, all applied:
  - CHANGE 2 (must-fix): regenerated `tools/status_cache.json` → `covered: 6`, `public_covered_count: 1`.
  - CHANGE 1 (public doc): fixed the stale hand-maintained `docs/src/validation-status.md` table —
    V3-TWOEFFECT-REML `partial→covered` AND V4-MV-REML `partial→covered` (V4 was a PRE-EXISTING staleness,
    covered since 2026-06-22; fixed per "fix them all").
  - CHANGE 5 (rec): softened "Maintainer G10 ratified" → "Maintainer authorized (G10; 'Yes merge and keep going')".
- Board (`tools/control-centre/index.html`) roadmap rebuilt as a per-version Julia⇄R breakdown; served on :8791.
- `git diff --check` clean; foreign files never staged.

## Claim audit

Honest (Rose). Covered = experimental, validation-scale, opt-in; **NOT the public default**. Public-covered
FITTING stays 1 (v0.1 Gaussian). Standing debt retained (covered does NOT retire): ratio (σ1/σ2) intervals,
correlated direct–maternal 2×2 G, the R-facing model-spec. v0.3 NOT fully covered — repeatability + RR
kernels remain partial.
