# GOAL: HSquared.jl lane speed12-20260919 (Fable speed plan steps 1 and 2)

Immutable for the run. Re-read at the top of every arc.

## Mission
Measure where one AI-REML iteration spends its time, section by section, on the shipped pedigrees, and
settle the selected inverse by a pre-registered benchmark, without changing a single number the engine
reports and without touching src/.

## Invariants (never violated)
- src/ is Szymek's until his branch is on origin: no edit under src/ (gate G1.5).
- The package Project.toml never changes; SelectedInversion.jl lives only in bench/Project.toml (gate G2.3).
- Every timed fit is bitwise-equal to a plain fit_ai_reml in the same process (G1.1); the banked sigma_a2
  pins hold (G1.2): q=1000 0.149778, 5000 0.098201, 20000 0.132360, 50000 0.103807.
- Compute: Mac Studio, JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1, each run under 30 min (D-139). The
  q=20k fill-471 arm runs on Totoro and is a STOP gate (Shinichi's yes, with G1.4's number shown).
- Never push, never merge, never open a PR from inside this lane (settings deny it; the orchestrator does
  it after the verification slice). Never stage files you did not create.
- Julia 1.10.0 is the default (`julia`); `julia +1.10.12` and `+1.12` exist. Use `--project=.` for sim/
  and `--project=bench` for bench/.

## Definition of done
- leaf-S1 and leaf-S2 gates PASS under
  `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --reverify --timeout 1800 .unlazy/julia-speed-20260919/gates/leaf-S*.md`
  (exit 0). G1.4 and G2.6 may FAIL as a reported finding (the banked baseline not reproduced); that is
  a result, not a defect, and it stops the Totoro arm.
- sim/results/ and bench/results/ hold the TSVs; each header records git SHA, Julia version,
  BLAS.get_config(), thread counts, OS, CPU.
- LOOP/lanes/speed12-20260919/checkpoint.md states TRUTH LIVES IN with paths and the branch SHA.

## Arcs
See arcs.md. Order: S1 (profiler) -> checkpoint -> S2 Mac arms -> STOP for the Totoro arm.

## Gates (STOP and surface)
The Totoro arm; any src/ edit; any package Project.toml change; a gate failing twice on the same cause;
a G1.4 FAIL (report it, do not launch Totoro).

## Pre-authorised
Scoped edits under sim/ and bench/; local Julia runs under 30 min; local commits on
claude/lane-speed12-20260919; .unlazy ledgers.

## Resume order
LOOP/lanes/speed12-20260919/GOAL.md -> checkpoint.md -> ultra-plan.md -> AGENTS.md (repo) ->
.unlazy/julia-speed-20260919/GATES.md and gates/.
