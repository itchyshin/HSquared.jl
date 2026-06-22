# After-task report — Binomial information-gradient study (#44 gate 2 evidence)

Date: 2026-06-22

Branch: `codex/claude-cross-lane-handover` (HSquared.jl, Julia engine lane; worked
in place — this repo has no concurrent session. **Not committed/pushed.**)

Active lenses: Curie (simulation/recovery), Gauss (numerics), Fisher (inference
honesty), Rose (claim-vs-evidence)

Spawned subagents: none

Current lane: Julia engine (`HSquared.jl`)

## 1. Goal

Provide the headline gate-2 evidence for HSquared.jl #44: characterize how
Laplace-REML recovery of the latent additive variance `σ²a` improves with trials
per record (the information effect that motivates the per-record varying-trial
activation landed in hsquared PR #101). Stays `partial`; no promotion.

## 2. Implemented

- `sim/phase6_binomial_information_gradient.jl` — opt-in (outside CI) study that
  reuses the SAME simulated `u` across an `n_trials` ladder so each rung differs
  only in trials/record. Sweeps m ∈ {1, 2, 5, 10, 20} + per-record n ∈ 1:30.
- Ran it live (julia 1.10.0, 5 seeds); recorded results in the checkpoint.
- Checkpoint `docs/dev-log/recovery-checkpoints/2026-06-22-phase6-binomial-information-gradient.md`.
- Added a concise gradient-evidence note to the `V6-BINOMIAL` row of
  `docs/design/validation-debt-register.md`.

## 3a. Decisions and Rejected Alternatives

- **Engine lane (`HSquared.jl`), not the R bridge:** the gradient is an estimator
  property, best characterized at the engine; and `HSquared.jl` is the lane this
  session owns (no R-twin conflict, no worktree needed). The R bridge inherits the
  validated behavior.
- **Fixed-`u` paired ladder:** rejected re-drawing `u` per rung; pairing on the
  genetic signal isolates the information (trials) effect cleanly.
- **Descriptive, not a CI gate:** the gated single-point endpoints already exist
  (`phase6_bernoulli_recovery.jl` m=1, `phase6_binomial_recovery.jl` m=20 +
  per-record). This study fills the intermediate rungs to show the trend.
- **New script, not folding into the gated recovery script:** keeps the pass/fail
  recovery gate separate from descriptive characterization.

## 4. Files Touched

- `sim/phase6_binomial_information_gradient.jl` (new)
- `docs/dev-log/recovery-checkpoints/2026-06-22-phase6-binomial-information-gradient.md` (new)
- `docs/design/validation-debt-register.md` (V6-BINOMIAL note)
- `docs/dev-log/after-task/2026-06-22-binomial-information-gradient.md` (this file)

No engine `src/` change; no test change.

## 5. Checks Run

- `julia --project=. sim/phase6_binomial_information_gradient.jl` (PATH-wired
  juliaup julia 1.10.0, single-threaded). Result: all rungs converged 5/5; mean
  σ̂²a rel-bias 0.417 (m=1) → 0.085 (m=20); EBV cor 0.623 → 0.908; per-record
  (mean n=15.2) σ̂²a 0.954, rel 0.139, cor 0.869. Full table in the checkpoint.
- No `src/` changed, so the test suite is unaffected (not re-run); the sim is
  opt-in and outside CI.

## 6. Tests of the Tests

- Fixed-`u` pairing makes the ladder a controlled experiment in trials only.
- 5/5 convergence at every rung; the gradient is monotone in rel-bias and cor.
- The per-record case (mean n ≈ 15) lands between the m=10 and m=20 rungs, as
  expected — an internal consistency check on the per-record path.

## 7a. Issue Ledger

- HSquared.jl #44 gate-2: information-gradient evidence added (engine). Stays
  `partial`; no promotion. Remaining gate-2: an external MCMCglmm *agreement*
  comparator (Bayesian, not same-estimand REML parity) and interval calibration
  (deferred — `laplace_reml_interval` is Poisson-only; no binomial interval yet).
- No GitHub post (awaits OK).

## 8. Consistency Audit

- `V6-BINOMIAL` already documented the m=20 and per-record endpoints; this
  completes the gradient and does not change the status.
- Recovery-checkpoint convention followed (mirrors the existing phase6 sims).

## 9. What Did Not Go Smoothly

- Nothing notable. julia is off the non-interactive PATH (juliaup); wired via
  `PATH=$HOME/.juliaup/bin:$PATH` to run.

## 10. Known Residuals

- **Not committed/pushed** (pending finalize decision).
- Engine-only characterization; no R-bridge gradient run (the R path inherits the
  engine behavior; a bridge-level repeat would be redundant).
- Gate-2 MCMCglmm agreement comparator + interval calibration outstanding.
- The cross-lane #44 coordination note / ledger sync remains unposted (needs OK).

## 11. Team Learning

A fixed-`u` paired ladder turns two single-point recovery gates into a
demonstrated monotone information effect at low cost — reuse this pattern for
other "more data ⇒ better recovery" characterizations (e.g. records-per-group).
