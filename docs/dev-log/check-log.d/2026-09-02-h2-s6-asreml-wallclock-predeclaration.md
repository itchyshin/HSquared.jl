# 2026-09-02 — S6 ASReml comparator: pre-declaration frozen, **NOT RUN**

**Arc:** A32 (spine `~/local-scratch/h2-post-050-spine-mv4-s6.md` §3, Track 2).
**Lane:** Julia (`HSquared.jl`) only. No R-lane commit — this changes no
shared R–Julia contract fact.
**Worktree:** `~/local-scratch/lanes/HSquared.jl-h2-twin-20260901`
**Branch:** `claude/lane-h2-twin-20260901`. **Not pushed.**

## Goal

Freeze the design of the S6 ASReml-R comparator — the **at-scale estimand leg**
(validation-debt item (2) for `V1-MATFREE-REML`) and the **wall-clock ladder** —
as two independently gated legs in one document, before any compute and before a
licensed host exists. Block 1 remains PROCEED pending owner DP-1; this is Block 2
preparation that consumes no compute and asks for none.

## What was written

| Path | Kind |
|---|---|
| `docs/dev-log/recovery-checkpoints/2026-09-02-s6-asreml-wallclock-ladder-predeclaration.md` | pre-declaration — FROZEN-NOT-RUN |
| `sim/phase_s6_asreml_wallclock_ladder.jl` | skeleton — frozen constants + assertions only; no campaign implementation |

## Commands and outcomes

| Command | Result |
|---|---|
| `HSQ_S6_DRYRUN=1 julia --project=. sim/phase_s6_asreml_wallclock_ladder.jl` | printed the frozen plan, **exit 0**. No dataset drawn, no fit performed |
| `julia --project=. sim/phase_s6_asreml_wallclock_ladder.jl out.tsv` | stopped on the missing-ASReml prerequisite with the intended message, **non-zero exit**. No fallback path exists |
| **the grid** | **NOT RUN.** No cell, no seed, no SMOKE mode, no feasibility probe |

`Pkg.test()` was **not** run and is not owed: no `src/` file, no test, and no
`Project.toml` was touched. The skeleton is `sim/`-only, opt-in, and not wired
into CI — matching the S5 gate's own position.

## Three prerequisites, measured not assumed

| # | Prerequisite | State |
|---|---|---|
| P1 | licensed ASReml-R on a drivable host | **OPEN — owner action (arc A33).** Not on the campaign laptop. A NO parks the ladder and is a legitimate outcome |
| P2 | `comparator/prepare_asreml_matfree.jl` + `sim/drac/f0_adversarial_fill.jl` | **OPEN — they exist only on `refs/heads/codex/2026-07-13-v07-performance-localization`** (verified by walking every ref's tree). That is a foreign codex lane (GOAL I4). They must be PORTED with provenance, as `f261165e` ported the fitter. The `adversarial()` generator itself is separately available locally at `sim/phase_s5_matfree_tail_recovery_gate.jl:95` |
| P3 | `fit_eigen_reml` | **ABSENT from `src/` on this branch** — `src/HSquared.jl` exports `fit_ai_reml` and `fit_matrix_free_reml` only. The spine's "three fitters" grid is not executable here as written; the eigen arm is declared OPTIONAL and reports `ABSENT`, never blank |

## Claim boundary

Freezing a design licenses nothing. Explicitly unchanged by this commit:

- `V1-MATFREE-REML` stays **experimental**; debt item (2) stays **OPEN**.
- `public_covered_count` stays **5**; no capability-status or validation-debt row
  was edited.
- **No ASReml wall-clock claim exists or is implied.** One estimand-agreement run
  exists, at q = 2,000 / fill 75.2, and **zero** wall-clock ASReml comparisons
  anywhere. The honest answer to "can HSquared beat ASReml" remains **cannot say**.
- The standing Rose fences (pre-declaration §8) are **restated, not lifted**.

## Fence

No push · no compute routed (no Totoro, no DRAC, no laptop run) · no S5 re-run ·
no covered flip · no G10 · no Registrator · no version bump · no capability or
debt row moved · no `comparator_targets.toml` change · no CI wiring.
