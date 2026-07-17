# Retry-8 D0F — admission gate PASSED; live draw BLOCKED by a JuliaCall precompile env issue

**Date:** 2026-07-17 · **Executor:** Claude (user-authorized) · **Outcome:** admission gate PASS,
draw **blocked (infrastructure)**, no seed spent, both roots pristine. `public_covered_count` stays
**5**.

## What succeeded (repaired-head rebuild + admission gate)

Retry-8 fixed the two defects Retry-7's draw surfaced and rebuilt cleanly:
1. **run-one arity bug** — `v3d_validate_attempt` now passes `expected_route` (`hsquared` `96529fd`;
   RED→GREEN regression `test-v07-recovery-v3-run-one-arity.R`; Rose PROMOTE).
2. **stale checksum sidecar** — the fix changed the driver but left its tracked `.sha256` stale,
   which fail-closed the preseal self-integrity check; regenerated (`a23b15b`).
Fresh sealed root `retry8-prep/d0f` under repaired R head `a23b15b` + Julia `976814393043`:
write-review ×5 → prepare → preseal → materialize-bootstrap → **zero-seed preflight PASS** (all
green; manifest 576, fixed-panel 72, bootstrap 720000 — byte-identical to `-c`, confirming
seed-reuse determinism). Pre-registration committed (`6d82b7ac`). Independently re-verified.

## What blocked the draw (infrastructure, not science)

`run-one` builds K/Q via **JuliaCall** (`v3d_engine_construction`), which does `hs_julia_setup` →
`Pkg.activate(project); using HSquared`. On the **fresh Retry-8 `HSquared.jl` deployment** (a copy at
a new path, so no pre-existing JuliaCall-built cache), the lazy `using HSquared` fails to precompile:
```
Failed to precompile HSquared … compilecache → mkpidlock/trymkpidlock … Execution halted
```
The precompile worker's actual error is **swallowed by JuliaCall's captured `internal_stderr`**.
Findings from ~12 diagnostic attempts (none drew a seed):
- **Standalone** `julia --project -e 'using HSquared'` succeeds; **JuliaCall's** lazy `using` fails.
- The earlier Retry-7 blocker on this class was R's ephemeral `TMPDIR` — fixed with a stable
  `TMPDIR=/home/snakagaw/hsq_work/jltmp` (that fix let the `-c` deployment work). For Retry-8 the
  TMPDIR fix is **necessary but not sufficient**.
- `Pkg.precompile()` inside a JuliaCall session **succeeded at least once** (built a valid cache), but
  the smoke's fresh `using` still re-precompiled and failed; repeated attempts appear to have
  **degraded the depot's HSquared compiled cache** (even `Pkg.precompile` later failed).
- `-c` worked only because its HSquared cache was **pre-built by the original synthetic-lifecycle
  deployment**; the copied Retry-8 project has no such cache.
Root cause: a JuliaCall + Julia-1.10 **embedded-precompile mkpidlock** interaction on a
freshly-deployed project path. This is an environment/deployment problem, not a campaign-logic or
scientific defect.

## State (pristine — nothing irreversible)

- Retry-8 root `retry8-prep/d0f`: `attempts/`+`packets/` **ABSENT**, manifest sha stable
  (`73656022…`). **No official seed spent.**
- Sealed `-c` root: untouched (bootstrap mtime `2026-07-16 19:16`, unchanged).
- Both roots fully recoverable.

## Recovery path (draw remains reachable)

1. **Clean-slate the Julia depot cache** from a clean session:
   `rm -rf ~/.julia/compiled/v1.10` then a single serial `Pkg.instantiate()` + `Pkg.precompile()` on
   the Retry-8 `HSquared.jl` (repeated mid-flail rebuilds corrupt it — do it once, clean).
2. **Pre-build the JuliaCall cache before the run**: get one clean JuliaCall `Pkg.precompile()` to
   succeed, then run `run-official` (the run-one `using` will hit a valid cache).
3. If it persists, it is a known-gnarly JuliaCall+Julia-1.10 embedded-precompile issue — reconcile
   the exact Julia patch / JuliaCall config the **original working deployment** used (Codex built the
   synthetic lifecycle deployment that had a working cache), or pin that Julia build.
4. All env steps must export the stable `TMPDIR` + `JULIA_BIN` (1.10.10) + threads=1.

## Discipline

The de-risk + code fixes are correct and landed; this is an infra blocker with **zero cost to any
sealed root**. `public_covered_count` stays 5; the ordinary route is not activated; V2-GRM/GINV stay
partial. Two real bound-tool defects were caught and fixed before spending a campaign — the process
worked.
