# Independent likelihood profile, PEV and scalar review — 2026-09-30

## Verdict

**PASS for scoped LH11 root handling, LH12 PEV order/domain/arithmetic, and Gaussian summary/bootstrap-ratio LH13 at the exact proposed pin.** This is a component verdict; it does not close LH11 nuisance optimization, LH13 other summaries, LH17 bootstrap provenance/acceptance/calibration, full likelihood review, E1/A2, or any release gate. Parent owns composition, registration and live application. No live or author-proposal files were changed.

## Exact pin and replay evidence

Candidate HEAD `6271cfd58651e69cd27a64dcf02cb8960a29e260` was observed during the paired review. Live likelihood was measured unchanged at `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30`.

All **37** entries in `/private/tmp/hsq-likelihood-profile-pev-fix-20260930/pins.json` were independently SHA-256 verified, including every package dependency/source snapshot, baseline, source, patch, tests, contracts, report and retained author logs.

- Final proposed likelihood SHA-256: `0a0ed083e23f7e2131133ba238d65d1edcff45c7b516673f9e16148f14bd8019`.
- Patch: `31bbfdfb5c27987158f66e8359eb3e484d9d957bc37fc8e273ac632a444e03c1`.
- Primary contracts test: `12bb5e71235cca4f6317b1e4db7cef3626eb04a84aa46b8e8dc381250b58a828`.
- Author analytic controls: `2f0052579bcd63b2529d6979d9f58955d64381f9f75bee004cbe1b8df5ebfd42`.
- Existing bootstrap test: `ba4ae9c3dfa977dd156781102af708db4ca155ebb2adf6b79e4f6c81b2992df6`.

Ran git apply --check against exact baseline in owned scratch, applied there, and byte-compared replayed likelihood with author's source. Exact. Runtime package copied from the hash-verified author snapshot; this does not independently certify its other component bodies.

## Fresh runs

Owned scratch: `/private/tmp/e1-likelihood-profile-pev-independent-20260930/`.

`final-98.log`: Julia 1.10.0, measured JuliaThreads=1 and BLASThreads=1; **71/71** primary contracts (1.2 s), **23/23** author supplied-variance analytical controls (2.2 s), **4/4** unchanged bootstrap convergence controls (0.0 s); process exit 0. Log SHA-256 `5bf4de745851aa61493aba5196e0042f223dddf23d2490617520a0cbe81161c1`.

`challenge.log`: **52/52 independent challenges PASS**, test-body 1.2 s, process exit 0. Challenge source SHA-256 `be94a5c7701485048d1687f5789cd3eb21a1afab1c5eb35a2450b9191b9943dd`.

Independent controls cover multiple analytic left/right roots and legitimate clamps; anchor rejection before bound callback; exact bound crossing; explicit unresolved budget failure; overflow-safe negative-coordinate midpoint; Gaussian h² BigFloat oracles including minimum subnormal and maximum finite equal components; three distinct caller permutations for each of four reliability scale cases, including overflowing/underflowing denominator products and subnormal PEV; converted bootstrap acceptance at both floating-point scale extremes and refusal for underflow/overflow conversion/nonconvergence.

Each launch was estimated before launch below two minutes, with Julia/BLAS1, `--compiled-modules=no --startup-file=no`, and existing scratch/shared read-only depot paths. No resolve/update, actual optimizer, bootstrap simulation/refit, campaign, GPU, remote compute or Pkg.test ran.

## Independent challenge correction

The initial reviewer negative-coordinate root fixture had the wrong sign, making its anchor positive. It correctly threw the new anchor error after 13 passing controls; retained as `challenge-fixture-sign-error.log`. Corrected only the reviewer scratch fixture to `-x/1e308-1.3`, which is negative at -1e308 and crosses at -1.3e308. The exact corrected final script passed all 52 controls. This was a fixture defect, not a source failure; the proposed patch/tests were never edited.

## Profile assessment and caller compatibility

The helper now rejects nonfinite bound/anchor before target evaluation, requires a finite strictly negative anchor, rejects every nonfinite evaluated target, preserves an actual negative/positive bracket, uses `a/2+b/2`, and reports unresolved 200-step budget as an error. Both directions and clamps pass independent analytic controls. Returning an endpoint at adjacent floating-point values is the best representable numerical resolution; continuity, nuisance convergence and scientific maximum validity remain caller responsibilities.

Exact immediate Gaussian callers construct target(anchor) from the same profiled value as llmax, yielding -cutoff when finite. Current non-Gaussian `_laplace_profile_lrt` explicitly checks profile convergence and finite likelihood/deviance, and `laplace_reml_interval` checks point convergence/finite likelihood/boundary before using the root. The stricter anchor requirement correctly refuses a profile that does not contain the point. This is source/caller compatibility evidence only; no fitted Gaussian or non-Gaussian interval was run. Existing Gaussian nuisance optimizers and search rails are untouched, and a helper PASS cannot certify them.

## PEV and reliability assessment

The source preserves the caller PEV ID sequence while matching each relationship diagonal through the model-ID dictionary. Duplicate/missing/unknown IDs and nonfinite/negative converted PEV are rejected. Model IDs remain exact-ID matches; no new stripping or string coercion is introduced. Both AnimalModelFit and HendersonMMEResult dispatch through the same guarded ratio helper. Supplied-variance independent coefficient inverse controls cover dense, selinv and auto methods.

For finite positive Float64 additive component and diagonal, frexp mantissas lie in bounded ranges, so `mp/(ma*md)` cannot suffer the original product overflow/underflow. ldexp restores the correct exponent; nonfinite final ratios reject. Zero PEV correctly yields reliability one even when the mathematical denominator is below the smallest positive Float64. Negative reliability remains exposed rather than clipped. Caller-supplied relationship diagonals remain caller-certified; arbitrary container shape/types and conditioning/resource guarantees are outside this repair.

## Gaussian fraction and bootstrap assessment

Scaling both converted nonnegative finite components by their maximum preserves h² while avoiding total-variance overflow. The maximum normalized component equals one, so the final denominator is finite positive. Both zero-total and nonfinite converted inputs reject; a single zero component remains a valid point-summary boundary. Subnormal equality and extreme asymmetry agree with BigFloat oracles to Float64 precision.

Bootstrap accepted-refit predicate converts before finite/interior checks, so values whose conversion underflows to zero or overflows to infinity cannot be accepted. Both point and accepted-refit h² calculations call the scaled helper; accepted ratio is computed before any replicate vector append. This is static wiring and helper evidence only. The original-fit convergence check, broad catch/failure taxonomy, minimum survivor count, bootstrap simulation feasibility at extremes, and bootstrap coverage are untouched open debts.

## Scope integrity and integration

Patch inspection confines edits to the two Gaussian heritability overloads/new fraction helper, reliability overloads/new PEV helper, profile root helper and nearby documentation, converted bootstrap acceptance, and two bootstrap ratio sites. No likelihood objective, fit optimizer, nuisance-profile algorithm, parameterization, relationship precision builder, direct-maternal/repeatability/multivariate estimand, result schema, release or public capability status changed.

Apply the patch, not the entire likelihood snapshot. Register the primary and analytical tests once beside the existing bootstrap convergence include, preserving that unchanged existing test. Rerun the composed parent candidate's relevant checks under its final source pin; component snapshot PASS alone is not a final composed-tree PASS.

## Operational evidence

The parent's dedicated independent reviewer lane owns these scratch paths only. Graph callers were queried; cached graph positions drifted, so literal symbols located immediate current spans before reading the non-Gaussian/relationship helpers. Automatic graph-cache refresh was sandbox-denied; no live graph rebuild was attempted. Brain retrieval gave historical leads and was not used for numerical conclusions. Total graph tool-estimated avoided reading across both independent reviews: **1,552,433 tokens** (not measured model usage).
