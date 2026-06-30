# After-task — V3-TWOEFFECT-REML promoted partial→covered (v0.3, 2nd validation-scale covered model) — 2026-06-30

## Task goal

Finish the v0.3 two-effect kernel: promote `V3-TWOEFFECT-REML` `partial → covered` after both doc-33
path-(b) pieces landed (a pre-declared bias/MCSE recovery gate PASS + an executed BLUPF90 same-estimand
REML comparator). Maintainer authorized the promotion ("Yes merge and keep going"). This is the **2nd
validation-scale covered estimator** (after V4-MV-REML); the public-default fitting surface stays 1 (v0.1).

## Active lenses and spawned agents

Real `rose-systems-auditor` subagents this v0.3 arc: (1) comparator → CLEAN; (2) covered-readiness → CLEAN
(git forensics + independent 48-seed reproduction); (3) **the promotion flip → PROMOTE-WITH-CHANGES**
(applied: regenerate the count cache, fix a stale public Documenter row, soften the G10 wording).

## Live phase snapshot

Branch `feat/2026-06-30-v03-twoeffect-covered-promotion` (off `main` `100f7dd4`, which already has the
comparator + gate from merged PR #195). `validation_status()` = 48 rows; **covered 5→6**
(V3-TWOEFFECT-REML joins V4-MV-REML); **public-covered FITTING = 1** (v0.1 Gaussian) — UNCHANGED.

## Files changed

- `src/validation_status.jl` — V3-TWOEFFECT-REML status `partial→covered` + covered framing (doc-33 gate,
  "covered means engine correctly implements two-effect REML, NOT small-sample-accurate on σ1²").
- `docs/design/validation-debt-register.md` + `docs/design/capability-status.md` — same flip + framing.
- `docs/src/validation-status.md` — fixed the stale public Documenter table: V3-TWOEFFECT-REML `partial→covered`
  AND V4-MV-REML `partial→covered` (a PRE-EXISTING staleness Rose caught — V4 has been covered since
  2026-06-22 but this hand-maintained table was never synced).
- `tools/status_cache.json` — regenerated (covered 6; public_covered 1).
- `tools/control-centre/index.html` — mission-control board roadmap rebuilt as a per-version **Julia
  (HSquared.jl engine) ⇄ R (hsquared public language)** breakdown with ✓done/○owed; stale phases fixed
  (P4 done, P2/P3 current). Served on the existing `:8791` board.

## What changed (the promotion basis)

- doc-33 path-(b) substitutable gate, identical construction to V4-MV-REML: a same-estimand external REML
  comparator (`blupf90+` 2.60, neutral start, ~1e-5) + a pre-declared 48-seed bias/MCSE recovery gate
  (PASS: 48/48 converged, all three `|bias| ≤ 2·MCSE`; σ1² −2.15%/0.57·MCSE the largest, read as no
  detectable bias, never "unbiased"). Both Rose-CLEAN with independent reproduction.

## Checks run and exact outcomes

- `Pkg.test()` (julia 1.10.0) PASS after the flip → `validation_status()` 48 rows, covered=6, V3TE=covered;
  the status-set/partition guard (`test/runtests.jl:537`) holds (covered may carry owed `missing`, as V4 does).
- Re-run PASS after the Rose wording/cache fixes.
- `git diff --check` clean; the two foreign files never staged.

## Public claim audit

Rose PROMOTE-WITH-CHANGES → all changes applied. The covered flip is honest and correctly bounded
(experimental, validation-scale, opt-in; NOT the public default). **Public-covered FITTING = 1** (still
v0.1 Gaussian). Standing debt retained on all surfaces (covered does NOT retire): ratio (σ1/σ2) intervals,
correlated direct–maternal 2×2 G, the R-facing model-spec.

## Tests of the tests

The covered-count change (5→6) is exercised by the partition guard. The gate predeclaration (`41bd18f6`)
was committed before the run with zero result leakage (Rose git-forensics + independent reproduction).

## Coordination notes

Claude solo. No R (`hsquared`) files changed — the R-facing two-effect model-spec activation remains OWED
(v0.3 R-lane work). Board roadmap now makes the R-vs-Julia split explicit per version.

## What did not go smoothly

- Rose caught a PRE-EXISTING stale `partial` for V4-MV-REML in the public Documenter table — fixed here
  (scope creep accepted because it's a public page being touched in the same slice).

## Known limitations

- v0.3 is NOT fully covered: only the two-effect kernel. Repeatability REML (σa/σpe split ill-conditioned)
  and random-regression REML remain `partial` (comparator + gate owed each).
- Covered is validation-scale/opt-in, not a public-default R model — the R model-spec activation is owed.

## Next actions

1. Merge this promotion (maintainer authorized).
2. v0.2 genomic comparator (BLUPF90 GBLUP on a generated dataset + pre-declared gate).
3. v0.5 QTL groundwork (marker_scan + a pre-declared DRAC threshold sim).
4. v0.3 remainder: repeatability + RR comparators/gates; the R-lane model-spec activations.
