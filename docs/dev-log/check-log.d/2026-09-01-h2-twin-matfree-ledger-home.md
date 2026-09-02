# check-log — 2026-09-01 h2-twin `V1-MATFREE-REML` ledger home (Rose JL-1)

**Arc:** pre-push remediation of Rose finding JL-1
**Lane:** `claude/lane-h2-twin-20260901` @ `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Trigger:** `~/local-scratch/h2-rose-prepublic-scrub-2026-09-01.md` §JL-1
**Launch receipt:** `~/local-scratch/h2-matfree-ledger-home-launch.md`

## The finding

The A07 S5 evidence (48 seeds, q = 25,000, PASS) discharged a validation-debt item
against `V1-MATFREE-REML`, an id absent from every ledger on this branch. The
estimator `fit_matrix_free_reml` — defined `src/iterative_solve.jl:1010`, exported
`src/HSquared.jl:140` — had no row in `src/validation_status.jl`,
`docs/design/capability-status.md`, or `docs/design/validation-debt-register.md`.

## Root cause — this was a PORT GAP, not a missing id

The scrub offered two options: invent the row, or refile the evidence. Reading the
history showed a third and better answer. `V1-MATFREE-REML` **already exists** on the
v0.7 lineage:

```sh
git show 33ab68f6:src/validation_status.jl | rg -n "V1-MATFREE-REML"          # 129
git show 33ab68f6:docs/design/capability-status.md | rg -n "MATFREE-REML"      # 91
git show 33ab68f6:docs/design/validation-debt-register.md | sed -n '57p'       # the row
git show 33ab68f6:test/runtests.jl | rg -n "length\(validation\) =="           # 56
```

The campaign branch is `main`-based; `main` never carried the v0.7 F6 slice. A07's
`f261165e` ported the **fitter and its export** so the frozen gate could run, and did
not port the **ledger rows** that came with it. Verified the port is faithful:

```sh
diff <(git show 33ab68f6:src/iterative_solve.jl | sed -n '/^function fit_matrix_free_reml/,/^end/p') \
     <(sed -n '/^function fit_matrix_free_reml/,/^end/p' src/iterative_solve.jl)
# empty — fit_matrix_free_reml body is byte-identical to 33ab68f6
```

Row-id delta between the two ladders is exactly one — `V1-MATFREE-REML` — so this is a
port completion, not a new claim. No commit after `33ab68f6` on that branch touched the
three ledger files, so the ported wording is that lineage's latest.

## What was NOT ported, and is now said out loud

The v0.7 row's evidence text asserts an in-CI deterministic testset (exact-loglik
identity to 1e-12, seed determinism, extractor shapes, REML-only guard) and an `:auto`
opt-in fence. **None of it is on this branch** — `rg -c fit_matrix_free_reml test/runtests.jl`
returns 0 against 8 on v0.7. Copying the v0.7 wording verbatim would have been an
overclaim, so the new row states the gap in its `missing` field.

The fence itself still holds here, and holds *more* strongly — structurally rather than
by test. Measured, not assumed:

```
rejected matrix_free      -> ArgumentError: target must be :variance_components, :sparse_reml, :ai_reml, or :henderson_mme
rejected matrix_free_reml -> ArgumentError: (same)
rejected auto             -> ArgumentError: (same)
_auto_reml_route defined? false
fit_matrix_free_reml exported? true
```

So `fit_matrix_free_reml` is reachable **only** by direct call; nothing can route a user
into it. But no test pins that, so a future re-wiring would not fail loudly here. That is
recorded in the row's `missing` field as owed work.

## Changes

| File | Change |
|------|--------|
| `src/validation_status.jl` | new `V1-MATFREE-REML` row, `partial`, Phase 1, inserted after `V1-AI-REML` |
| `docs/design/capability-status.md` | new row, `experimental`, beside `V3-NEFFECT-MATFREE-FIT` |
| `docs/design/validation-debt-register.md` | new row, `partial`, items (1)–(6) preserved from the v0.7 numbering so the gate's "item (1)" / "item (3)" pointers resolve |
| `docs/src/validation-status.md` | regenerated from `validation_status()` |
| `tools/status_cache.json` | refreshed: rows 55 → 56, partial 38 → 39 |
| `test/runtests.jl` | row count 55 → 56; four new assertions pinning the id, `partial`, the q-scale in evidence, and the count sentence in the claim boundary |
| `src/iterative_solve.jl` | docstring honesty repair (below) |

### Docstring repair

The ported `fit_matrix_free_reml` docstring carried three statements that are false on
this branch: it cited in-CI recovery fixtures that were not ported; it told the reader to
reach the fitter via `fit_animal_model(spec; target = :matrix_free)`, which throws here;
and it still called the tail-scale recovery gate **OWED** after S5 passed. All three
rewritten to what is true on this branch.

## Commands

```sh
julia --project=. tools/write_validation_status_page.jl        # rows: 56
julia --project=. tools/gen_status_json.jl --refresh-count     # rows=56 covered=13, public_covered=5
julia --project=. -e '<scoped V1-MATFREE-REML testset>'        # 11/11 pass
julia --project=. -e 'using Pkg; Pkg.test()'                   # full suite
```

## Honesty pins — verified, not asserted

| Quantity | Before | After |
|----------|--------|-------|
| `validation_status()` rows | 55 | **56** |
| `covered` | 13 | **13 (unchanged)** |
| `covered_external` | 3 | **3 (unchanged)** |
| `partial` | 38 | **39** |
| `planned` | 1 | **1 (unchanged)** |
| **`public_covered_count`** | 5 | **5 (unchanged)** |

## Claim boundary

- **Nothing is promoted.** The new row lands at `partial` / `experimental` — the status
  the G10 S3 dossier already described it as having.
- `public_covered_count` stays **5**, confirmed from the regenerated cache, not quoted.
- G10 S3 remains **UNSIGNED**. S6 (at-scale comparator), S4 (fresh promote-specific Rose),
  and S7 (R bridge) remain open and are named in the row.
- No `:auto` routing change. No push. No version bump.
- The S5 evidence is unchanged; only its filing changed.

## Known stale pointer, deliberately not fixed

`sim/phase_s5_matfree_tail_recovery_gate.jl:524` and the emitted TSV header say
"discharges validation-debt-register.md:**57** item (1)". Line 57 of the register on this
branch is `C10-LRT`; the new `V1-MATFREE-REML` row is at line 88. The line number was
correct against the frozen v0.7 register and is now a cross-lineage artifact. **The gate
script is frozen and was not edited** — editing a frozen gate after its run is the
post-hoc change its own predeclaration forbids. The id in that sentence now resolves,
which is what the audit trail needs; the line number does not, and this note is the
record of why.

## Follow-up owed

1. Port the v0.7 in-CI deterministic testset and `:auto`-fence tests, or write branch-native
   equivalents, so the structural fence is pinned rather than merely true.
2. `AGENTS.md` Live Phase Snapshot states "rows **55**" under its own "As of 2026-07-08"
   header. That was true then and is now superseded by 56. Not edited here: the snapshot
   block has an archive-first replacement rule, and Rose JL-4 already owns replacing it.
   Whoever does JL-4 should carry 56 forward.
