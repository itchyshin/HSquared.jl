# Session handover — Retry-8 D0F: admission PASSED, draw blocked by Totoro JuliaCall env

**To:** the next Claude session · **From:** Claude · **Date:** 2026-07-17
**State:** Retry-8 sealed root built + admission-gate PASSED; the phenotype draw is blocked by a
Totoro-specific JuliaCall/RCall precompile defect that is **fixable** (JuliaCall works on the Mac).
No official seed spent; both roots pristine. **Handover is Claude→Claude** (user's explicit choice).

## Goals / mission

Produce a sealed, byte-identical **D0F adjudication receipt**
(`v07-genomic-recovery-v3-adjudication-2`) that survives its own `validate-final` — WHATEVER the
verdict (PASS or a bankable negative) — from the **validated `run-official` orchestrator path**, plus
a repo-visible close-out. A COMPLETE receipt keeps `public_covered_count` at **5** and only OPENS
D1/D2 (no route activation, no V2-GRM/GINV discharge). Do NOT shortcut the validated path (sysimage /
single-session runner were considered and rejected — they'd produce a non-contract-valid receipt).

## The ONE remaining blocker (and the key new evidence)

`run-one` builds K/Q via **JuliaCall** (embedded Julia in R). On Totoro's **fresh Julia 1.10.10**
install, JuliaCall's embedded `using HSquared` (and even RCall) **fail to precompile**
(`compilecache → mkpidlock`, worker error swallowed). **BUT the identical JuliaCall path WORKS on the
Mac (Julia 1.10.0): `MAC_JULIACALL_OK`.** And the original `-c` deployment ran JuliaCall fine under
1.10.10 (the synthetic lifecycle). So this is **NOT** a code/version incompatibility — it is a broken
RCall/JuliaCall *build* in the fresh Totoro 1.10.10 depot. **This is fixable; the next step is env
repair, not Codex.**

### Failed approaches (do NOT repeat — ~17 attempts, all exhausted)
stable `TMPDIR` (necessary, insufficient), warm standalone cache, `Pkg.precompile` (worked once then
degraded), pidfile clearing, full `~/.julia/compiled/v1.10` wipe (made it worse — broke RCall too),
`JULIA_NUM_PRECOMPILE_TASKS=1`, `JULIA_PROJECT`, `JULIA_HOME`, `JULIA_PKG_PRECOMPILE_AUTO=0`. Standalone
`julia --project -e 'using HSquared'` ALWAYS works; only the **embedded** JuliaCall precompile fails.

### The untried, highest-probability fix (START HERE)
**Rebuild RCall's C bindings for the fresh 1.10.10 depot**, which is almost certainly what's broken:
```
export JULIA_BIN=/home/snakagaw/.julia/juliaup/julia-1.10.10+0.x64.linux.gnu/bin/julia
R_HOME=/usr/lib/R "$JULIA_BIN" --startup-file=no -e 'using Pkg; Pkg.build("RCall"); Pkg.precompile()'
```
Then rebuild/precompile the HSquared side, then re-test `hs_julia_setup` (below). Other candidates if
that fails: inspect what RCall/JuliaCall build the working `-c` depot used (its cache worked under
1.10.10); or, last resort, a DRAC SLURM deployment (also an allowed compute host) with a clean env.

## What was accomplished this session

1. **Fixed two real bound-tool defects** that would have wasted the live campaign, neither catchable
   by any gate that bypasses `run-one`:
   - `v3d_validate_attempt` omitted the now-required `expected_route` arg (route-repair `b8096e5`
     missed this call site) → **fixed** (`hsquared` `96529fd`, passes `v3d_route`); RED→GREEN
     regression `tests/testthat/test-v07-recovery-v3-run-one-arity.R`; **Rose PROMOTE**.
   - The fix left the driver's tracked checksum **sidecar stale** → **fixed** (`a23b15b`).
2. **De-risked the adjudication tail** (where 6/6 prior retries died): +426 lines of R testthat
   regression at 576-cardinality multi-route (`test-v07-genomic-recovery-v3-recompute.R`, `4082df1`);
   **Rose PROMOTE + Hopper SOUND**; latent `v3p_compare_tables` LEFT-arg asymmetry traced
   campaign-safe.
3. **Rebuilt Retry-8 sealed root** under the repaired head and **PASSED the admission gate**:
   write-review×5 → prepare → preseal → materialize-bootstrap → **zero-seed preflight PASS**
   (manifest 576, fixed-panel 72, bootstrap 720000 — sha `f53967b5…`, byte-identical to `-c`).
   Pre-registration `6d82b7ac`. Independently re-verified.

## Current working state

- **Working / done:** everything upstream of the draw (above). The Retry-8 sealed root at
  `/home/snakagaw/hsq_work/retry8-prep/d0f` is built and admission-passed, ready for `run-official`.
- **Blocked:** the phenotype draw, solely by the Totoro JuliaCall env (see above). Both roots
  **PRISTINE** (no attempts/packets; verified). No seed spent, nothing forfeit.

## Key decisions & rationale

- **Executor = Claude** (both lanes, this session; user-authorized). Handover continues Claude→Claude.
- **Seed reuse 2042/2043** on the fresh Retry-8 root: the `-c` blocker was **pre-draw** (Rose
  close-out confirmed the forfeit clause is post-draw-scoped), so the seed space is unspent and the
  seed-lock still registers 2042/2043 as current; only the defective `-c` output root is set aside.
- **No shortcut around the broken precompiler** (sysimage / single-session runner) — they'd mint a
  non-validated receipt, defeating the pre-registration's byte-exact contract.
- **Host wall is real:** the campaign fits/draw/adjudication run ONLY on Totoro or a DRAC SLURM job
  (`_assert_execution_context`; preseal `host=totoro`). Not the Mac.

## Landing State

| Repo / branch | Committed | Pushed | State |
| --- | --- | --- | --- |
| `HSquared.jl` `codex/2026-07-13-v07-performance-localization` `bf423a78` (+ this handover) | yes | yes (0/0) | LANDED |
| `hsquared` same branch `a23b15b` (run-one fix + sidecar + tail tests) | yes | yes (0/0) | LANDED |
| Both twins: 2 protected retry5 carryover docs + untracked `sim/…downstream_replay.jl` | no | no | **CARRIED-OVER** — do NOT inspect/stage/edit/hash; resume only under original owner |
| Totoro: `retry8-prep/` deployment + sealed `d0f` root (admission-passed) | n/a (on Totoro) | n/a | READY for `run-official` once env fixed |

## Next immediate steps (for the next Claude)

1. Rehydrate: `hsquared-rehydrate`; read the AGENTS snapshot, this doc, and
   `docs/dev-log/check-log.d/2026-07-17-retry8-draw-blocked-juliacall-precompile.md` +
   `…-retry8-d0f-campaign-preregistration.md`.
2. **Fix the Totoro JuliaCall env** — try `Pkg.build("RCall")` first (above). Confirm success by
   running `hs_julia_setup` on Totoro (the exact failing path), env below:
   ```
   JBDIR=/home/snakagaw/.julia/juliaup/julia-1.10.10+0.x64.linux.gnu/bin
   export PATH=$JBDIR:$HOME/.juliaup/bin:$PATH JULIA_BIN=$JBDIR/julia
   export OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 R_LIBS="/home/snakagaw/R/v07-lib:/home/snakagaw/R/lib"
   export TMPDIR=/home/snakagaw/hsq_work/jltmp   # stable TMPDIR is mandatory
   W=/home/snakagaw/hsq_work/retry8-prep
   Rscript -e 's<-get("hs_julia_setup",envir=asNamespace("hsquared"),inherits=FALSE); s(paste0("'$W'/HSquared.jl")); JuliaCall::julia_command("println(1+1)"); cat("OK\n")'
   ```
   Green here means the draw can proceed.
3. Present a **fresh pre-draw GREEN assertion + get an explicit in-session user GO** (the draw is the
   irreversible point of no return under root-forfeit; seed base 2042000000).
4. `run-official` **smoke-first**: `smoke-n-ladder` then `smoke-16`, inspect the first attempts
   (converged, finite `scientific_ratio`), THEN `run-official <workers≤96>` → `lock-corpus` →
   `recompute-base-r` ∥ `replay-julia` → `verify-replay` → `summarize-r` → `summarize-julia` →
   `write-route-lineage` → `write-postrun-review`×5 → `adjudicate` → `validate-final`. Orchestrator:
   `retry8-prep/hsquared/tools/run-v07-genomic-recovery-v3.sh` (usage block documents every subcommand).
5. **Spawned-Rose close-out** (fresh context) — outcome-neutral; bank whatever the verdict; count
   stays 5. On a tail failure, retire the root + seed spaces per the pre-registration.

## Gotchas & failed approaches

- The three gates that FAIL to catch fit-entry defects (synthetic lifecycle, zero-seed preflight, tail
  tests all bypass real `run-one`) are why the two defects survived — a `run-one`-entry test now
  exists on the Mac; the live env is the last gap.
- `timeout` is not a macOS command (use the Bash tool's own timeout locally).
- Totoro Rscript is 4.5.3 (matches preseal); JULIA_BIN must be the 1.10.10 real binary (not the
  juliaup `release` shim = 1.12.6).
- The `-c` root is a banked pre-draw blocker (Retry-7); do NOT draw on it. Retry-8 (`retry8-prep`) is
  the live root.

## Mission control

| Repo | Branch / state | What shipped | Next by leverage |
| --- | --- | --- | --- |
| `HSquared.jl` | `codex/2026-07-13…` `bf423a78`, pushed | Retry-8 admission PASS + banked env blocker + this handover | fix Totoro JuliaCall env → draw |
| `hsquared` | same branch `a23b15b`, pushed | run-one fix + sidecar + 576-cardinality tail tests | (R lane consumed read-only by the campaign) |
| Totoro | `retry8-prep` sealed root, admission-passed | ready for `run-official` | `Pkg.build("RCall")` then run-official |

## How to resume

From `/Users/z3437171/Dropbox/Github Local/HSquared.jl`, paste into your own authenticated terminal:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-17-retry8-claude-handover.md + the AGENTS.md snapshot. First fix the Totoro JuliaCall/RCall 1.10.10 precompile env (try Pkg.build(\"RCall\")); when hs_julia_setup loads on Totoro, present a fresh pre-draw GREEN assertion for my GO, then run-official smoke-first through adjudicate + validate-final on the retry8-prep sealed root. Preserve the root-forfeit discipline; spawned-Rose close-out; public_covered_count stays 5."
```
