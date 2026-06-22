# After-task report — non-Gaussian gate-2 depth (#44): interval coverage + Poisson comparator

Date: 2026-06-22

Branch: `claude/binomial-... ` → `claude/nongaussian-gate2-depth` (HSquared.jl,
isolated worktree from `main` `38286b1`). **Not committed at time of writing.**

Active lenses: Curie (simulation), Fisher (inference/intervals), Jason (comparator
landscape), Rose (claim-vs-evidence)

Spawned subagents: none

Current lane: Julia engine (`HSquared.jl`)

## 1. Goal

Two gate-2 depth slices for HSquared.jl #44 (non-Gaussian): (#4) a coverage
characterization for the `sigma_a2` profile-LRT interval, and (#5) an MCMCglmm
Bayesian-agreement comparator for the Poisson family. Both stay `partial`; no
promotion.

## 2. Implemented

- **#4** `sim/phase6_nongaussian_interval_coverage.jl` — opt-in coverage harness
  for `laplace_reml_interval` (Poisson + Binomial). Checkpoint
  `docs/dev-log/recovery-checkpoints/2026-06-22-nongaussian-interval-coverage.md`
  records a PRELIMINARY 10-rep smoke (conservative; see Known Residuals).
- **#5** `comparator/poisson_mcmcglmm/` (`generate.jl`, `run_mcmcglmm.R`, README,
  `.gitignore`) — Poisson MCMCglmm agreement comparator, mirroring the binomial
  one. Checkpoint `docs/dev-log/recovery-checkpoints/2026-06-22-poisson-mcmcglmm-agreement.md`.

## 3a. Decisions and Rejected Alternatives

- **Engine lane (`HSquared.jl`)**, mirrors the existing sim/comparator patterns.
- **#5 EBV correlation is the primary metric; variance magnitudes caveated**
  (MCMCglmm's Poisson units residual R=1 vs the engine's no-overdispersion Laplace).
- **#4 ran a 10-rep smoke, not the planned 50-rep run** — the profile interval is
  BLAS-heavy (~10s/rep: a point fit + two root-finds); the multithreaded 50-rep
  background job pegged ~16 cores, so it was **killed at the maintainer's request**
  to free CPU. The harness now caps BLAS threads in the sim's run note.
- **No `validation-debt-register.md` edit** — PRs #155/#156 already touch the
  `V6-BINOMIAL`/`V6-FIT` rows; the register note is a merge-time follow-up.

## 4. Files Touched

- `sim/phase6_nongaussian_interval_coverage.jl` (new)
- `comparator/poisson_mcmcglmm/generate.jl`, `run_mcmcglmm.R`, `README.md`,
  `.gitignore` (new)
- `docs/dev-log/recovery-checkpoints/2026-06-22-nongaussian-interval-coverage.md` (new)
- `docs/dev-log/recovery-checkpoints/2026-06-22-poisson-mcmcglmm-agreement.md` (new)
- `docs/dev-log/after-task/2026-06-22-nongaussian-gate2-depth.md` (this file)

No engine `src/` change; no test change. Generated comparator CSVs git-ignored.

## 5. Checks Run

- **#5 generate** (julia 1.10.0): engine σ²a 0.836 (truth 1.0; mild Poisson Laplace
  downward bias, as documented), q=345, mean count 1.77, converged.
- **#5 MCMCglmm** full chain (nitt=130000/30000/100): EBV correlation **0.928**,
  animal variance mean 0.303 [0.084, 0.557], ESS 1000.
- **#4** 10-rep smoke: Poisson + Binomial each 10/10 covered at 95%, no endpoint
  clamping, mean widths 0.652 / 0.467 → conservative (preliminary).

## 6. Tests of the Tests

- #5 uses the same Henderson A-inverse as the engine (same pedigree) → like-for-like
  relationship; ESS 1000 → well-mixed.
- #4 reports endpoint-clamp rates alongside coverage so a one-sided/degenerate
  interval would be visible (here: 0 clamping at σ²a=1, m=20 → genuinely two-sided).

## 7a. Issue Ledger

- #44 gate-2 depth: a 2nd-family (Poisson) Bayesian-agreement comparator + a
  preliminary interval-coverage signal. Stays `partial`; no promotion. The
  same-estimand REML parity gate (BLUPF90/ASReml/WOMBAT, absent) and a calibrated
  coverage run remain open.

## 8. Consistency Audit

- Variance-scale caveat is identical and consistent across the binomial (#156) and
  Poisson (#5) comparators; both lean on EBV correlation. No parity/coverage overclaim.

## 9. What Did Not Go Smoothly

- The coverage sim is CPU-heavy and multithreaded → pegged the machine; killed the
  50-rep job and added a thread-cap note. The smoke is the recorded preliminary.
- Two small authoring bugs fixed: a `$`-interpolation in the sim docstring (Julia
  treated `$HOME` as interpolation), and dead placeholder code in the Poisson
  `generate.jl` (leftover from adapting the binomial one).

## 10. Known Residuals

- **Not committed/pushed** at time of writing.
- **#4 coverage is preliminary (10 reps)** — a fuller, thread-capped calibrated run
  is future work.
- `V6-*` register note deferred to merge (cross-PR conflict avoidance).

## 11. Team Learning

Profile-likelihood-interval coverage studies are expensive (a point fit + two
root-finds per rep). Cap BLAS threads, use a smaller design, and/or background with
limits — do not launch a default-rep multithreaded coverage run on a shared machine.
