# Retry-7 D0F campaign — BLOCKED at run-one by a bound-tool defect (banked negative)

**Date:** 2026-07-17 · **Executor:** Claude (both lanes, user-authorized) · **Outcome:** NEGATIVE /
BLOCKER, banked per the pre-registration's outcome-neutral DoD. `public_covered_count` stays **5**.
No official seed persistently spent; **the sealed `-c` root is pristine and NOT forfeit.**

## Result

All pre-seed gates passed (PRE-0..5 green; tail regression-covered + Rose/Hopper verified; real
720000-row bootstrap consumable). With the user's explicit GO, the campaign began at the smoke draw.
The smoke — doing its job — surfaced two infrastructure/code issues **before any phenotype was
persistently drawn**. The first was an environment issue (fixed); the second is a **confirmed
bound-tool defect** that stops every official fit and cannot be repaired on the sealed root.

## Finding 1 (fixed): JuliaCall precompile failed under an ephemeral TMPDIR

`run-one` builds the genomic relationship K/Q via `JuliaCall` (`v3d_engine_construction`,
`v07_genomic_recovery_v3.R:789`). Under a fresh Julia 1.10.10, the JuliaCall-spawned precompile
worker failed with `SystemError: opening file "/tmp/jl_*.ji": No such file or directory` — R's
per-session `TMPDIR` is not reliably visible to the worker. **Fix (environment only, no tool/root
change):** `export TMPDIR=/home/snakagaw/hsq_work/jltmp` (stable dir). Verified:
`using HSquared` via JuliaCall then loads (`HSQUARED_VIA_JULIACALL_OK`). Also warmed the RCall +
HSquared precompile caches and cleared stale precompile pidfiles left by the interrupted attempts.
**The successor run must export a stable `TMPDIR`.**

## Finding 2 (BLOCKER): `v3d_validate_attempt` omits the required `expected_route`

Every official `run-one` fails-closed with:
```
v3d_run_one -> v3d_validate_attempt -> v3p_validate_results:
  argument "expected_route" is missing, with no default
```
- Driver `v07_genomic_recovery_v3.R:1162` calls `v3p_validate_results(attempt, manifest,
  manifest_columns, label, binding)` — **5 args**.
- Preseal `v07_genomic_recovery_v3_preseal.R:1588` declares
  `v3p_validate_results(attempts, manifest, manifest_columns, label, binding, expected_route)` —
  **6 required; `expected_route` has no default.**

Root cause: the route-binding repair `b8096e5` (which PRE-1 confirmed present in the bound head, and
which makes wrong/omitted routes fail LOUD — exactly as Gauss/Curie predicted) made `expected_route`
required in `v3p_validate_results` but **did not update this `run-one` attempt-validation call
site.** The defect is in **both** the bound head `9f7ed27` and the local head `cb7391d` (bound tools
byte-identical; the two later commits are docs-only).

**Why no prior gate caught it:** the zero-seed preflight, the synthetic lifecycle
(`v07_genomic_recovery_v3_synthetic_lifecycle.R`, which fabricates attempts), and this session's
tail-de-risk tests (which target the adjudicator/recompute path) **all bypass the real `run-one`
fit-entry path.** The historical failure locus was the post-fit tail (retries 1–6); this defect sits
at the fit *entry*, a blind spot none of the gates exercised.

## Root state: PRISTINE (proof)

- `-c/d0f` contains only preseal inputs + `receipts/`; **`attempts/` and `packets/` ABSENT.**
- preseal `be42dc7d…` / manifest `f53967b5…` **unchanged**.
- Julia `--mode=preflight --stage=d0f` **re-PASSes**: "sealed inputs only; no official RNG or seed
  consumed." The failed `run-one` calls wrote nothing (create-once, errored before write). The root
  is uncontaminated and fully recoverable; no seed persistently spent.

## Why this is not patch-and-continue

`v07_genomic_recovery_v3.R` is a **preseal-bound tool** (`r_driver_sha256` is bound into the sealed
`-c` preseal and the adjudication receipt schema). Editing it changes that sha, invalidating the
sealed preseal binding — the `-c` root cannot be adjudicated against a changed driver. So the fix
requires a **repaired-head rebuild**, not an edit on this root.

## Recovery path (a repaired-head successor — "Retry-8"; its own authorization + gate)

1. **Fix the bound driver** (R twin): `v3d_validate_attempt` must pass `expected_route` to
   `v3p_validate_results` — the official public route (`ordinary_auto_genomic` / the binding's
   official route) for a real fit. Confirm the exact value against the binding.
2. **Close the blind spot**: add a regression test that exercises `v3d_run_one` /
   `v3d_validate_attempt` (a synthetic-marker run-one, no official seed) so a driver-vs-preseal arg
   mismatch fails on the Mac, never on the live draw. (This session's tests covered the tail, not
   the fit entry.)
3. **Rebuild + re-admit**: new preseal under the repaired R head (fresh `r_driver` sha), re-run the
   admission gate (chronology + zero-seed preflight), fresh seed allocation per discipline.
4. **Then** the campaign, with `TMPDIR` exported (Finding 1).

## Discipline

Outcome-neutral: a bankable blocker is an admissible result; the smoke-first + bound-tool-edit
guard worked exactly as designed — a real defect caught before spending a campaign, at zero cost to
the sealed root. `public_covered_count` stays 5; the ordinary R route is NOT activated; V2-GRM/GINV
stay partial; nothing merged or released.
