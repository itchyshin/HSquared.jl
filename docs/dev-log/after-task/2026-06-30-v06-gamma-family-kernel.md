# After-task — v0.6 Gamma (log-link) family kernel (row deferred) — 2026-06-30

## Task goal

Build the v0.6 plan's next non-Gaussian family after the ordinal kernel: the **Gamma (log-link)**
Laplace family for strictly-positive continuous traits. EXPERIMENTAL/`partial`, INTERNAL. Autonomous
(maintainer away, "keep working"), on a NEW branch off `main`, staged for review — NOT merged. The
`validation_status()` row is DEFERRED to respect the `one-row-adding-PR-at-a-time` count-guard while
#212 is unmerged (so this slice does not conflict with #212 on the count/status surfaces).

## Active lenses and spawned agents

- Perspectives (inline): Gauss/Noether (kernel numerics), Curie (oracle).
- **Rose** (`rose-systems-auditor`) — mandatory audit → **PROMOTE (clean, no changes)**: re-derived the
  Gamma kernel and checked the engine loglik against an independent `SpecialFunctions.loggamma`
  transcription of the true density (match ~1e-10; score/weight match FD of the TRUE density), ran the
  31/31 testset + count guard 48 live, verified the deferred-row decision as honest merge-sequencing,
  no overclaim, the glmmTMB-`Gamma(link=log)` comparator note correct, and hygiene clean (3 files, no
  foreign files).

## Live phase snapshot

- **As of 2026-06-30 (v0.6 Gamma family kernel authored, experimental/partial, row deferred; Claude
  solo, autonomous; branch `feat/2026-06-30-v06-gamma-family` off `main` @ `c2b5babc`, PR pending).**
  `GammaResponse(shape)` (internal, log-link, supplied shape) with exact log-concave kernels
  (observed-info weight), validated by the ν=1→Exponential reduction + finite-difference gates + a
  finite end-to-end marginal. `validation_status()` = **48 UNCHANGED** (row DEFERRED); public-covered
  fitting = 1 UNCHANGED. Same-estimand comparator = glmmTMB `Gamma(link="log")` (valid here — a
  correct contrast to the ordinal case). NEXT: the deferred row (post merge-sequencing) + joint shape
  estimation + resolver/fit/R wiring + a recovery gate.

## Files changed (this slice)

- `src/nongaussian.jl` — `GammaResponse` struct + kernels + `_check_counts`.
- `test/runtests.jl` — the T-Gamma testset (no count-guard/row change).
- `docs/dev-log/check-log.d/2026-06-30-v06-gamma-family-kernel.md` + this after-task.

## What changed

A new internal Gamma log-link Laplace family kernel. No status row (deferred), no export, no resolver
wiring, no R, no covered claim. Consumed via the `ResponseFamily` object through `laplace_marginal_loglik`.

## Checks run and exact outcomes

- Kernel smoke + T-Gamma testset (31 assertions): ν=1 exponential reduction exact; finite-diff
  score/weight (observed, `> 0`); end-to-end marginal finite; guards throw.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → PASS at count **48** (unchanged).
- `julia --project=docs docs/make.jl` → exit 0.

## Public claim audit

`public-covered fitting = 1` UNCHANGED; `validation_status()` = 48 UNCHANGED (row deferred). No
export, default, R, or covered change. Honest fences in the struct docstring + check-log.

## Tests of the tests

The ν=1→Exponential reduction is an analytic oracle independent of the Gamma code path (compares to a
hand-written exponential form). The finite-difference gates validate score AND observed weight against
the loglik directly. Log-concavity (observed info > 0) is asserted across a (ν, y, η) grid.

## Coordination notes

Julia-engine-lane, solo, autonomous. Independent of #211/#212/#213 (separate branch off `main`); the
deferred-row choice specifically avoids the count-guard conflict with #212.

## What did not go smoothly

Nothing notable — the pattern is now well-worn from the ordinal slice. (One care point: used explicit
`git add <paths>`, not `git add -A`, to avoid staging the 3 foreign never-stage files — the mistake
caught earlier this session.)

## Known limitations

SUPPLIED shape only (no joint shape estimation); Laplace-only; internal (not exported/wired/R); the
`validation_status()` row is DEFERRED (add post merge-sequencing); no same-estimand comparator run
yet (glmmTMB `Gamma(link=log)` is the valid leg); no recovery gate; no observation-scale h²; NOT a
covered claim; public-covered fitting = 1 unchanged.

## Next actions

1. Rose audit outcome (recorded on completion).
2. Push + PR staged for maintainer review; do NOT merge.
3. On merge-sequencing (after #212), add the deferred `V6-GAMMA` `partial` row (three surfaces) +
   the count-guard bump.
