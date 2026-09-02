# 2026-09-02 — S6 P2 ASReml scaffold ported with provenance, **NOT RUN**

**Arc:** P2 discharge after A32 (spine Track 2; pre-declaration §1).
**Lane:** Julia campaign only —
`~/local-scratch/lanes/HSquared.jl-h2-twin-20260901` on
`claude/lane-h2-twin-20260901`. **Not pushed.**
**Foreign lane:** `codex/2026-07-13-v07-performance-localization` at tip
`853bcc12a25dee4445374754b048662576df2fef` — **READ ONLY**; no foreign edits.

## Goal

Port the ASReml comparator scaffold and high-fill generator named by S6
prerequisite P2 onto the campaign branch with provenance headers, so A34/A35
are not blocked by a missing file once a licensed host exists. Do **not** run
the S6 grid, the prepare script, the R runner, or F0.

## Files ported

| Path | Introducing SHA | Date | Blob SHA |
|---|---|---|---|
| `comparator/prepare_asreml_matfree.jl` | `29d04a1d…` | 2026-07-28 | `8a5a44da…` |
| `comparator/run_asreml_matfree.R` | `29d04a1d…` | 2026-07-28 | `295b718d…` |
| `sim/drac/f0_adversarial_fill.jl` | `533cf0f8…` | 2026-07-24 | `24a5edf1…` |

Also: `.gitignore` gains `/comparator/asreml_matfree/` (matches foreign); skeleton
`sim/phase_s6_asreml_wallclock_ladder.jl` marks P2 discharged and checks file
presence only; pre-declaration §1 P2 records the port receipt.

## Commands and outcomes

| Command | Result |
|---|---|
| `HSQ_S6_DRYRUN=1 julia --project=. sim/phase_s6_asreml_wallclock_ladder.jl` | printed frozen plan + **P2 SCAFFOLD: PORTED (not run)** with three `present` rows; **exit 0**. No data drawn, no fit |
| `julia --project=. sim/phase_s6_asreml_wallclock_ladder.jl out.tsv` | stopped on missing `HSQ_S6_ASREML_CMD` (P1), **non-zero**. No HSquared-only fallback |
| `comparator/prepare_asreml_matfree.jl` / `run_asreml_matfree.R` / `f0_adversarial_fill.jl` | **NOT RUN** |
| **S6 grid** | **NOT RUN.** No cell, no seed, no SMOKE, no Totoro/ASReml |

`Pkg.test()` was **not** run and is not owed: no `src/` change, no test change,
no `Project.toml` change.

## P3 (eigen) — recorded, not newly invented

`fit_eigen_reml` remains **ABSENT** from `src/` on this branch. Pre-declaration
§1 P3 / §4.2 already declare the eigen arm **OPTIONAL** and report `ABSENT`,
never blank. Dry-run restates that line. No eigen fitter was added.

## Claim boundary

- P2 **DISCHARGED** (files present with provenance).
- P1 **OPEN** (licence). Legs E/W **NOT IMPLEMENTED**.
- `V1-MATFREE-REML` stays **experimental**; debt item (2) stays **OPEN**.
- `public_covered_count` stays **5**.
- **No ASReml wall-clock claim.** Honest answer remains **cannot say**.
- Rose §8 fences **restated, not lifted**.

## Fence

No push · no Totoro/ASReml/S6 grid run · no covered flip · no foreign-lane edit ·
no G10 · no Registrator · no version bump · no CI wiring.
