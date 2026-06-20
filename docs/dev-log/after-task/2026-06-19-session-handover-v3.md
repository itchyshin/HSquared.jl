# Session handover — 2026-06-19 (v3) · START HERE

A complete inheritance note for a fresh session. Repository state is truth; this
is the at-a-glance pointer. Supersedes the v2 handover (still useful for the
deeper backstory).

## Rehydrate path

Run the `hsquared-rehydrate` skill, then read in order: **this note** →
`docs/design/11-completion-plan.md` (the plan) → `AGENTS.md` (Live Phase Snapshot
+ lane-routing table) → `docs/design/capability-status.md` +
`docs/design/validation-debt-register.md` → `docs/dev-log/coordination-board.md`
→ the two newest after-tasks
(`2026-06-19-honesty-closeout-s1.md`, `2026-06-19-diagonal-bridge-payload.md`)
→ newest `docs/dev-log/check-log.d/*`. **The live cross-lane thread is GitHub
issue #61** — read all comments there first.

- **Dev docs site:** https://itchyshin.github.io/HSquared.jl/dev/ (rebuilt on merge).
- **Control-centre widget** (`~/.claude/hsquared-control-centre`, `:8791`): may be
  stale; refresh `status.json` (preserve `live_agents`) if you use it.

## The goal (standing)

Finish the next-phase programme plan (`docs/design/11-completion-plan.md`): three
Big Things + process + scout cadence. **BT1 done. BT2/BT3 in progress** — driven
this session by the R-lane joint critical path on **#61**.

## Hard constraints (unchanged)

- **Edit only `HSquared.jl`.** The R twin (`../hsquared`) is READ-ONLY; GitHub
  issues/comments on **both** repos are the sanctioned coordination channel.
- **Land via PR** (auto-classifier gates direct pushes to `main`). **Merge policy
  this session: auto-merge CI-green slice PRs** (user-set 2026-06-19), report each.
- TDD + full Definition of Done per slice. No fitting/genomics/GPU/GLLVM claim
  without the evidence chain. **Julia is at `~/.juliaup/bin/julia` (NOT on PATH).**
- Local checks before push: `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`
  and `~/.juliaup/bin/julia --project=docs docs/make.jl`.

## Current state (repo = truth)

- Branch **`main` @ `c30fca0`**. Working tree clean. **0 open PRs.** Remote heads:
  `main` + `gh-pages`. `main` CI + Documenter green.
- `Pkg.test()` green; `validation_status()` has **33 rows**.
- One fully public-covered capability: the v0.1 univariate Gaussian animal model.
  Everything else is `experimental` / `partial`.

## DONE this session (2 slices merged + cross-lane coordination)

- **S1 — honesty closeout** (PR #62, `d7c7ffa`): refreshed `validation_status()`
  V4-MV-REML/V4-FA rows so SEs/LRTs are no longer listed "missing" (**#47**;
  the functions shipped in PR #59, the in-code diagnostic had drifted); harmonized
  the retired "~0.99/250-animal" AI-REML claim at `03-engine-contract.md` (**#38**);
  added the citable **V6-LAPLACE (partial)** row (**#44** blocker-first). No engine
  behavior change.
- **S2 — diagonal multivariate bridge payload** (PR #63, `ad6006d`): exported
  **`multivariate_result_payload(result)`** — the boring bridge `NamedTuple`,
  scoped to the **rotation-free** `:unstructured`/`:diagonal` structures, rejecting
  `:lowrank`/`:factor_analytic` (rotation-nonidentified loadings never leak). New
  `test/fixtures/structured_covariance_parity/` (deterministic `:diagonal` target +
  CI self-consistency), `03-engine-contract.md` spec, capability-status row,
  validation-debt + validation_status **V4-BRIDGE** rows. Delivers the **#42**
  rotation-free subset; unblocks the R-lane diagonal-vs-unstructured LRT (**#47**).
- **Cross-lane:** four comments on **#61** — accepted the R-lane critical path
  (with verification), made the **#47 diagonal-only unblock decision** (yes,
  `:diagonal` alone), posted the build contract, and posted the S2-landed note +
  fixture path. The R lane is wiring the diagonal LRT now.

## Decisions locked (carry forward)

- **Bridge = coordinate LIVE with the R twin.** Julia owns the engine half +
  parity fixtures + specs; the R-twin session executes the R half.
- **#47 diagonal-only unblock:** DONE (S2). `:diagonal` is bridge-exposed;
  **lowrank/fa loadings stay gated on #42 + a rotation/interpretation convention**
  (a science decision — write the decision note and tag the R lane before exposing
  any loadings; pairs with #37 em_fa.jl calibration and #55 evolvability).
- **#46 fitted Mrode = R-twin** (nadiv/pedigreemm/published); Julia only serializes
  a target fixture. **Do NOT type published textbook EBVs from memory.**
- **#49 comparator = add JWAS.jl** as a Julia-native comparator (opt-in `comparator/`
  env; MCMC-vs-REML; report agreement honestly).
- **Recovery harness (#41/#34):** no engine change needed; the R lane runs
  `data-raw/multivariate-recovery-study.R` (`HSQUARED_RUN_MV_RECOVERY=true`) against
  the engine and records bias±2·MCSE + EBV accuracy + convergence.

## The plan — remaining BT2/BT3 (prioritized, from #61)

Ranked lowest-effort / highest-payoff first; each flips a pre-staged R surface.

1. **#43 (2b) — PEV/reliability into the standard `result_payload(AnimalModelFit)`**
   via `:selinv` (currently default `:dense` at `src/likelihood.jl` L1085/1105/1124/1138).
   Lowest-delta; the R enrichment is pre-drafted → closes hsquared#21. *(solo)*
2. **FA rotation-convention decision note** → unblocks #42 lowrank/fa loadings + #55
   evolvability; pair with **#37** (em_fa.jl EM warm-start to fix V4-FA calibration,
   FA 8/10 / LR 9/10). *(solo + science decision; tag R lane)*
3. **#45→#48 — post-fit marker scan.** Fix the **`Ainv = NULL` on the returned fit**
   so a post-fit `(fit, markers)` entry point can route to `mixed_model_marker_scan`
   (GLS, relatedness-corrected); then **#48 calibrated genome-wide thresholds**
   (solo sim) before any genome-wide-significance claim. Hold the R `gwas()` wrapper's
   significance wording until #48. *(solo)*
4. **#44 — `MarginalMethod` dispatch refactor + `NonGaussianFit` bridge shape**
   (the V6-LAPLACE citation row already landed in S1). Mirror DRM.jl
   `src/variational.jl`; value-preserving. Then the R family-acceptance fires. *(refactor)*
5. **#46→#49 — serialize Julia-native fitted-Mrode + gryphon + comparator targets**;
   add the JWAS.jl comparator. The R lane runs the confrontation. *(fixtures, cross-lane)*

Hardware-gated, NOT this lane: Phase 7 (CPU/GPU) and Phase 8 (HPC; #58 perf ideas).
Innovation backlog #50–#55; scout cadence #56.

## Smallest safe next actions

1. **#43** — promote PEV/reliability into `result_payload` (lowest-delta, solo, TDD).
2. Or the **FA rotation-convention decision note** (#42/#37/#55 unblock).
3. Or re-run the **adversarial review** of S2 (its agents were interrupted before
   returning; S2 was self-reviewed + green-suite-verified, see its after-task).

## Mirror pairs (don't double-track)

`#41↔hsquared#10`, `#37↔hsquared#17`, `#42↔hsquared#22`, `#43↔hsquared#21`;
`#46`+`#49` are one fixture-serialization workstream.

## Verification snapshot

- `gh pr list` → 0 open. `main` CI + Documenter green on `c30fca0`.
- `Pkg.test()` → green; `validation_status()` → 33 rows.
- #61 carries the live cross-lane thread (4 Julia-lane comments posted this session).
