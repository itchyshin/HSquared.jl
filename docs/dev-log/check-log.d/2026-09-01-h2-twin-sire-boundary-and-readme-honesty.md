# check-log — 2026-09-01 h2-twin sire Julia-only boundary + Julia README understatement (Rose JL-2/JL-3)

**Arc:** B3 C2 (Julia-lane half) and Rose scrub findings **JL-2** / **JL-3**
**Lane:** `claude/lane-h2-twin-20260901` @ `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Trigger:** `~/local-scratch/h2-rose-prepublic-scrub-2026-09-01.md` §JL-2, §JL-3; B3 barrier C2
**Launch receipt:** `~/local-scratch/h2-overnight-pass3-launch-receipt.md`

## Part 1 — sire target: documented Julia-only boundary (B3 C2, Julia half)

The R lane owns the note itself
(`docs/dev-log/comparator-runs/2026-09-01-sire-julia-only-boundary.md`, and the R
lane's own check-log shard). This lane's changes:

| File | Change |
|---|---|
| `comparator/README.md` | new subsection "The one Julia-only target: `sire_model_fitted_target`" — 6 of 7 mirrored, this one not; points at the note; states that `test-mrode-sire-anchor.R` is a *supplied-variance* anchor and therefore not this mirror; states that documented ≠ `validated` |
| `comparator/run_targets.jl` | the sire adapter emits a `boundary_note` field; the emitter and entry builder carry it through to `manifest.json` (alongside the existing `unavailability_note` precedent) |
| `test/fixtures/comparator_targets.toml` | matching boundary text |

**The `gap` verdict was kept.** A comment in the adapter now says why: documenting a
boundary and discharging a debt are different acts, `--strict` should still refuse,
and the mirror-vs-permanent-boundary choice is an open owner decision, not the
harness's to assume.

```sh
julia --project=. comparator/run_targets.jl
#   exit 0; 7 targets; 6 agree / 0 drift / 1 not mirrored
#   sire_model_fitted_target: gap [external=none r_mirror=absent]
#   manifest boundary_note = docs/dev-log/comparator-runs/2026-09-01-sire-julia-only-boundary.md
```

## Part 2 — README understatement (JL-2, JL-3)

Rose graded both **medium, direction: understatement** — the README lists
implemented and covered work as planned. Nothing here widens a claim; the direction
of travel is toward what the ledger already says.

### The premise was checked before the claim was changed

Rose's JL-2 rests on `V5-MARKER-THRESHOLD` being covered. Verified against the live
ladder rather than the scrub:

```sh
julia --project=. -e 'using HSquared; for r in validation_status() ... end'
#   V5-MARKER-THRESHOLD | covered | permutation-calibrated genome-wide significance threshold
rg -n "genome_wide" src/HSquared.jl
#   124: genome_wide_pvalue,  125: genome_wide_threshold_from_null,  126: genome_wide_marker_scan
```

So the premise holds: exported, and `covered`.

### JL-2 — genome-wide multiple-testing calibration

`README.md` listed "genome-wide multiple-testing calibration" flatly under "Planned,
but not implemented yet". Two changes, both matched to the ledger row's own scope
rather than to the word "covered":

1. The planned bullet now names what *is* still planned — calibration for the
   **relatedness-corrected mixed-model/LOCO null**, broader-LD and
   covariate-adjusted calibration, and power/coverage characterization — and points
   at the correction below.
2. One added paragraph states what is covered and, at equal length, what is not:
   genome-wide significance for a **fixed-effect single-marker scan** under the
   exact per-dataset add-one permutation rule, **type-I control only**, on the
   validated designs (n ∈ 300–2000, m ∈ 100–10000, tested LD architecture), measured
   mean type-I 0.0542 / 0.0504 at α = 0.05, with the executed PLINK 1.9 max(T) leg.
   Fenced out: the mixed-model/LOCO null, power and coverage, broader-LD or
   covariate-adjusted (Freedman–Lane) calibration, the fixed-null-reuse shortcut
   (**failed its gate, banked as a negative result**), and the map-annotated
   formula-level `marker_scan()` / `qtl_scan()` API. Closes by naming
   `public_covered_count` = **5** and that covered *fitting* stays at the v0.1
   Gaussian animal model.

Every figure and fence in that paragraph is transcribed from the
`V5-MARKER-THRESHOLD` row in `src/validation_status.jl`; none is new.

### JL-3 — `pedigree_inverse` "not yet connected to a fitted animal model"

Replaced. That sentence was false: this `Ainv` is what an `animal_model_spec` is
built from, hence what the covered AI-REML fitter consumes.

**Two words were checked and dropped before committing them.** A first draft called
`fit_ai_reml` the "covered default path". It is covered, but it is *not* the
default — `fit_animal_model`'s default `target` is `:variance_components`
(`src/likelihood.jl:2422`). The wording now says "the covered AI-REML fitter
(`fit_ai_reml`) and the sparse MME path consume it", which is what is true. A
second draft attributed the throwing `hsquared()` to "the R twin"; it is this
package's own Phase 0 placeholder (`src/placeholders.jl:9`). Both corrected.

**Not touched:** the `README.md:370` sentence that `hsquared()` throws a Phase 0
not-implemented error. It is literally true, so it is staleness of tone, not a
claim defect, and softening tone is not what an understatement fix is for.

**Not touched:** the rest of JL-2's second half — the "Implemented now" list also
omits the direct–maternal 2×2 G model, random regression k=2, arbitrary-N
multi-effect, matrix-free MC-REML, the non-Gaussian families, metafounders, and the
evolvability suite. That is a list rewrite touching many claim rows at once, and
the pass brief asked for one honest paragraph, not a rewrite. Left as an open Rose
item.

## Rose re-scrub owed before push

These are Rose's own prescribed remedies for JL-2/JL-3, applied. But the *new*
README paragraph is itself a claim surface that Rose has not read. A re-scrub of it
is owed before push, and push is owner-gated anyway.

## Commands and outcomes

```sh
julia --project=. comparator/run_targets.jl                  # exit 0 (above)
julia --project=. tools/write_validation_status_page.jl      # rows: 56 (unchanged)
julia --project=. -e 'using Pkg; Pkg.test()'                 # PASSED — 143 testsets, 4252 assertions,
                                                             # 0 failures (the suite includes
                                                             # comparator/run_targets.jl, so the
                                                             # boundary_note plumbing is covered)
```

R lane, same slice: `testthat::test_local(filter = "comparator")` — `comparator-scripts`
and `comparator-targets-manifest` both clean, no failures. Full `devtools::check()`
was **not** re-run for this slice: the R-side change is TOML boundary prose plus two
`.Rbuildignore`d `docs/dev-log/` files, and the contract tests that read that TOML
are the ones that pass. Recording that as a scope decision rather than implying a
check was run.

## Ladder counts — UNCHANGED

Rows 56, `covered` 13, `partial` 39, `public_covered_count` **5**. No promotion, no
new row, no flip. The README now describes the ladder more accurately; it does not
change it.

## Prohibitions held

No push. No G10 sign. No covered flip. No Registrator, no version bump. No S5
re-run. No codex v07 merge. No `validation_status()` rows added for random
regression k=2 or direct–maternal (owner ASK #4, untouched). Sire mirror decision
not made.
