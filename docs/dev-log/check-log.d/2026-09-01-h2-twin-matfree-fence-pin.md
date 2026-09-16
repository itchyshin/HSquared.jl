# check-log — 2026-09-01 h2-twin `V1-MATFREE-REML` opt-in fence PIN

**Arc:** discharge of the "owed pin" left open by the JL-1 ledger-home work
**Lane:** `claude/lane-h2-twin-20260901` @ `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Trigger:** `docs/dev-log/check-log.d/2026-09-01-h2-twin-matfree-ledger-home.md`
("Still owed: port the v0.7 fence tests so the fence is pinned, not merely true")
**Launch receipt:** `~/local-scratch/h2-overnight-pass3-launch-receipt.md`

## The debt

The ledger-home slice recorded that `fit_matrix_free_reml`'s **opt-in fence** held
structurally on this branch but that **no test pinned it**, so re-wiring a route in
would not have failed loudly. That is the whole debt this slice discharges.

## The v0.7 tests could NOT be ported — the API differs

The debt was phrased as "port the v0.7 fence tests". Reading them first showed that
porting is the wrong move, because their assertions are **false here**:

```sh
git show 33ab68f6:test/runtests.jl | sed -n '4508,4512p'
#   @test fit_animal_model(specm; target = :matrix_free, nprobe = 32, seed = 3).target ==
#         :matrix_free_reml
```

On v0.7, `fit_animal_model` **accepted** `target = :matrix_free`, and the fence was
that its `_auto_reml_route` would never *choose* it. On this branch the target is
refused outright and `_auto_reml_route` does not exist, so the v0.7 fence is both
stronger here and differently shaped. Copying the v0.7 testset across would have
required **re-admitting `:matrix_free` as a target** — widening the very surface the
fence exists to keep closed.

So the debt is discharged in the form this branch's API takes, and the testset says
so, to stop a future porter "repairing" it back to the v0.7 shape.

## API measured before writing any assertion

```
rejected  matrix_free              :: ArgumentError :: target must be :variance_components, :sparse_reml, :ai_reml, or :henderson_mme
rejected  matrix_free_reml         :: ArgumentError :: (same)
rejected  auto                     :: ArgumentError :: (same)
rejected  matrix_free_mc_em_reml   :: ArgumentError :: (same)
rejected  "matrix_free" (String)   :: ArgumentError :: (same)
_auto_reml_route defined?  false
_coerce_fit_target: 7 aliases -> 4 canonical targets
direct call ok; target = matrix_free_reml, source = estimated_matrix_free_mc_reml
ML guard: ArgumentError "fit_matrix_free_reml requires spec.method == :REML"
```

## What was pinned

New testset `V1-MATFREE-REML opt-in fence (fit_matrix_free_reml reachable only by
name)` in `test/runtests.jl`, **20 assertions**, all deterministic:

1. `fit_animal_model` refuses `:matrix_free`, `:matrix_free_reml`,
   `:matrix_free_mc_em_reml`, and `:auto`, as Symbol **and** as String.
2. The accepted target surface is pinned **closed**: the 7 known aliases map to
   exactly 4 canonical targets, so a silent *widening* also goes red, not only the
   specific spellings in (1).
3. `_auto_reml_route` is asserted **absent** — reintroducing an `:auto` REML router
   forces a revisit of the fence rather than silently enabling one.
4. No other engine module reaches the fitter: the only `src/*.jl` files naming
   `fit_matrix_free_reml` are `iterative_solve.jl` (definition), `HSquared.jl`
   (export), and `validation_status.jl` (ledger prose). Wiring a call into
   `likelihood.jl` or `bridge_payload_v2.jl` grows that set and goes red.
5. Opt-in, not banned: a direct call works and self-labels
   (`target = :matrix_free_reml`, `variance_components_source =
   :estimated_matrix_free_mc_reml`).
6. The REML-only guard refuses an ML spec.

**No stochastic assertion is added to CI.** (5) runs **one** EM step with
`compute_loglik = false` and asserts only tags, never a number. The accuracy claim
belongs to the frozen S5 gate at q = 25,000, opt-in, off CI — which is the standing
lesson from the 2026-08-04 RNG-fragility class fix, and it is not being re-broken
here for the convenience of a shorter test.

## SCOPE — the wider claim would have been FALSE

The task framing included "`:auto` never selects matrix-free". **Measured: that is
false as a package-wide claim, and the testset says so explicitly.**

`fit_multi_effect(method = :auto)` (`src/iterative_solve.jl:1130`) routes to
`:matrix_free` whenever `K ≥ 2` and `N > direct_max_n`, dispatching to
`fit_multi_effect_mc_reml` — a **different** estimator under a **different** ledger
row (`V3-NEFFECT-MATFREE-FIT`). That routing is deliberate, documented, and already
tested (`fit_multi_effect :auto/:exact/:matrix_free dispatch`, the testset
immediately above the new one). The payload-v2 bridge can reach it too, via the
**non-default, opt-in** `scale_method = :auto`; the bridge default is `:dense`, and
the bridge's single-pedigree `:animal` dispatch calls `fit_animal_model` with no
`target`, so it takes the default `:variance_components` and cannot reach
`fit_matrix_free_reml` either.

The fence pinned here is therefore scoped to the **animal-model target router**,
which is the only router that could ever have reached this fitter. Stating it more
broadly would have been an overclaim in the opposite direction from the usual one.

## Surfaces updated so the fix does not create fresh drift

Four surfaces asserted "no test pins that" or "holds structurally, not by test".
All four now describe the pin and its scope:

| File | Change |
|---|---|
| `src/validation_status.jl` | `V1-MATFREE-REML` description: fence pin recorded with its scope; `missing`: the fence is no longer listed as owed (the v0.7 **numeric** gates still are); caveat: "pinned in CI since 2026-09-01, not merely structural" |
| `docs/design/capability-status.md` | "holds STRUCTURALLY, not by test" → "PINNED IN CI as of 2026-09-01", with the `fit_multi_effect` scope caveat |
| `docs/design/validation-debt-register.md` | item (3): "no test pins that" → pinned, with why the v0.7 tests could not be ported |
| `src/iterative_solve.jl` | `fit_matrix_free_reml` docstring "OPT-IN ONLY" paragraph now names the pinning testset and its scope |
| `docs/src/validation-status.md` | regenerated by `tools/write_validation_status_page.jl` (the boundary cell changed) |

## Commands and outcomes

```sh
# API probe (before writing assertions)
julia --project=. /tmp/fence_probe.jl                       # output transcribed above

# new testset, scoped
julia --project=. test/zz_tmp_fence_probe.jl                # 20 pass / 20 total, 7.0s
                                                            # (temporary extraction, deleted)

# generated status page
julia --project=. tools/write_validation_status_page.jl      # rows: 56  (UNCHANGED)

# full suite
julia --project=. -e 'using Pkg; Pkg.test()'                 # PASSED — 143 testsets, 4252 assertions,
                                                             # 0 failures; the new testset reports
                                                             # 20/20 in-suite; ~3 min, Julia 1.10.0
```

**Interpreter note, since the S5 slice made this a live question:** local runs were on
**Julia 1.10.0** (`~/.juliaup`). Every assertion here is deterministic — no RNG,
no numeric tolerance — so unlike the S5 gate this testset carries no
version-portability exposure. CI (1.10 + 1) is nevertheless **unverified**, because
nothing is pushed.

## Ladder counts — UNCHANGED, deliberately

| | before | after |
|---|---|---|
| `validation_status()` rows | 56 | **56** |
| `covered` | 13 | **13** |
| `partial` | 39 | **39** |
| `public_covered_count` | **5** | **5** |

Nothing was promoted. `V1-MATFREE-REML` stays `partial` / experimental. A pin is
evidence that a fence holds, not evidence that the estimator is validated.

## Still owed on this row (unchanged by this slice)

The v0.7 in-CI **deterministic numeric** gates (exact-loglik identity to 1e-12, seed
determinism and seed sensitivity, extractor shapes, the `compute_loglik = false` NaN
skip) were still not ported — the fence was the pin owed, not those. Plus, as before:
S6 the at-scale external comparator, S4 a fresh promote-specific Rose audit, S7 the R
bridge, and **S3 the G10 maintainer sign-off, which remains UNSIGNED**.

## Prohibitions held

No push. No G10 sign. No covered flip. No `public_covered_count` change. No S5
re-run. No frozen-gate edit. No Registrator, no version bump. No codex v07 merge.
