# check-log — 2026-09-02 wave-2 `V1-MATFREE-REML` in-CI NUMERIC pins

**Arc:** campaign wave-2 slice #5 — port the v0.7 in-CI deterministic numeric
gates that the fitter-body port (`f261165e`) left owed
**Lane:** `claude/lane-h2-twin-20260901` @ `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Trigger:** `docs/dev-log/check-log.d/2026-09-01-h2-twin-matfree-fence-pin.md`
("Still owed on this row: the v0.7 in-CI deterministic numeric gates")
**Lease:** `test/test_matfree_reml_inci_pins.jl` (exclusive new file)

## The debt

The fence pin (pass 3 / JL-8) closed the router. The ledger still said the
**fitter path itself** had no in-CI numeric pin: exact-loglik identity to
1e-12, seed determinism and seed sensitivity, extractor shapes, and the
`compute_loglik = false` NaN skip. Those lived on v0.7 / PR #274 and were
not on this branch. Re-breaking the adapter (wrong tags, a stochastic
loglik, a non-deterministic seed, a silent `NaN` skip) would not have gone
red.

## What was ported — and what was not

Ported from the v0.7 testset
`fit_matrix_free_reml (F6 matrix-free MC EM-REML) recovers the AI-REML optimum`
(read-only, Dropbox / PR #274): items (a)–(g). Fixture class is the same
(deterministic half-sib + `detnoise`; no `randn`). Size is CI-budgeted
(n = 80, nprobe = 32), not the v0.7 n = 400 / nprobe = 256 recovery-scale
fixture — identity pins do not need that scale.

**Not ported**, because the assertions are false here:

- (h) `fit_animal_model(spec; target = :matrix_free)` — this branch refuses it
- (i) `_auto_reml_route` kwarg MethodError — the function is absent

Those stay on the existing fence testset. Copying them would require
re-admitting `:matrix_free` as a target.

**Not added:** any recovery-to-truth or AI-REML agreement number. S5 owns
that, off CI. No stored numeric. The 2026-08-04 RNG-fragility lesson holds.

## Commands and outcomes

```sh
julia --project=. -e 'using Test; include("test/test_matfree_reml_inci_pins.jl")'
# Test Summary: ... | Pass  Total  Time
# V1-MATFREE-REML in-CI pins ... |   17     17  5.8s
# Julia 1.10.0

# test-of-tests: invert the loglik identity to `≈ 0.0`
# 16 pass / 1 fail (evaluated -95.82 ≈ 0.0) — the pin is not vacuous
# restore → 17/17 in 5.7s
```

Interpreter: Julia 1.10.0 (`~/.juliaup`). Assertions are same-process
identities (no stored expected VC), so Julia-version RNG streams do not
enter.

## Ladder counts — UNCHANGED, deliberately

| | before | after |
|---|---|---|
| `validation_status()` rows | 56 | **56** |
| `covered` | 13 | **13** |
| `covered_external` | 3 | **3** |
| `partial` | 39 | **39** |
| `V1-MATFREE-REML` status | `partial` | **`partial`** |
| `public_covered_count` | **5** | **5** |

Nothing was promoted. A path pin is evidence that the adapter still
returns an `AnimalModelFit` with the documented identities, not evidence
that the estimator is validated.

## Surfaces updated so the fix does not create fresh drift

| File | Change |
|---|---|
| `test/test_matfree_reml_inci_pins.jl` | new dedicated pin file (17 assertions) |
| `test/runtests.jl` | one `include` after the fence testset |
| `src/validation_status.jl` | `V1-MATFREE-REML` evidence: numeric gates now pinned; `missing`: no longer lists them as owed. `claim_boundary` and status **unchanged** (`partial`, count 5) |
| `docs/design/capability-status.md` | same wording repair |
| `docs/design/validation-debt-register.md` | same wording repair |

`docs/src/validation-status.md` was **not** regenerated: `claim_boundary`
did not change, and the page test pins that field only.

## Still owed on this row (unchanged by this slice)

S6 the at-scale external comparator (parked after A33 ASReml ABSENT),
S4 a fresh promote-specific Rose audit, S7 the R bridge, recovery between
q = 25,000 and the q ≥ 50,000 regime, and **S3 the G10 maintainer
sign-off, which remains UNSIGNED**.

## Prohibitions held

No covered flip. No `public_covered_count` change. No S5 re-run. No
frozen-gate edit. No force-push. No merge of PR #277. No Registrator, no
version bump. No codex v07 merge. Foreign-lane `test/runtests.jl` on
PR #274 was read, not edited.

## Follow-up — CI RED on Julia 1 (1.12.7), run 33625908497

`test/test_matfree_reml_inci_pins.jl:97` `seed=99` threw
`ArgumentError: PCG hit non-positive curvature (pᵀCp = 0.0)` on the
Julia 1 matrix; Julia 1.10 stayed green. Local probe of the same fixture:

| seed | 1.10.12 | 1.12.6 |
|---|---|---|
| 99 | OK, σ²a moves | `PosDefException` |
| 7 | OK, σ²a moves | OK, σ²a moves |
| 13 | PCG pᵀCp≈0 | `PosDefException` |
| 17 | OK, σ²a moves | OK, σ²a moves |
| 42 | OK, σ²a moves | OK, σ²a moves |

Fix: swap the sensitivity pin to `seed=7`. Identity pins (a/b/d/e/f/g)
and the same-seed determinism pin are unchanged. Not a covered flip;
`public_covered_count` stays 5.

```sh
julia +1.10.12 --project=. -e 'using Test; include("test/test_matfree_reml_inci_pins.jl")'
# 17/17 in 6.2s

julia +1.12 --project=. -e 'using Test; include("test/test_matfree_reml_inci_pins.jl")'
# 17/17 in 8.1s  (local 1.12.6; CI matrix is 1.12.7)
```
