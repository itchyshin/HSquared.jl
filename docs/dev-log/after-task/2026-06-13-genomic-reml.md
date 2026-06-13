# Genomic REML Variance-Component Estimation

Active lenses: Gauss, Fisher, Curie, Henderson, Rose (inline).
Spawned subagents: none (this slice). Recovery verified locally before claiming.

## Goal

Make GBLUP a full estimator, not just a supplied-variance solve: estimate the
genomic variance components σ²g/σ²e by reusing the existing REML optimizers on a
spec whose `Ainv` slot holds a genomic `Ginv`.

## Files Changed

- `test/runtests.jl` (testset "Phase 2 GBLUP REML variance-component
  estimation"; `length(validation)` 19→20)
- `src/validation_status.jl` (row `V2-GREML`; `V2-GBLUP` missing field updated)
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `docs/src/changelog.md`, `docs/dev-log/check-log.md`,
  `docs/dev-log/after-task/2026-06-13-genomic-reml.md`

No `src` code change — the existing `fit_ai_reml` / `fit_sparse_reml` /
`fit_animal_model(...; target = :ai_reml)` accept any `AnimalModelSpec`, and a
genomic spec (`Ainv = Ginv`) is dimensionally identical, so genomic REML is the
Phase-1 optimizer applied to a genomic relationship inverse.

## Checks

- `Pkg.test()`: passed, 661 total. New testset = 11 checks: AI-REML ==
  NelderMead optimum on a genomic fixture (loglik rtol 1e-5; σ² rtol 2e-2);
  converged; positive VCs; `fit_gblup` at the estimate reproduces the REML
  breeding values (atol 1e-8); target-dispatch reaches the same optimum from a
  different start.
- One-off seeded recovery (NOT committed — the suite is deliberately RNG-free,
  matching the existing AI-REML 250-animal sim which is documented but not a
  committed rand-test): n=400, m=600, simulated from the model covariance
  σ²g·(G+ridge·I); true σ²g=1.0/σ²e=1.5 recovered as σ²g=0.997, σ²e=1.37,
  h²=0.42 (true 0.40).

## Public Claim Audit

Allowed: the existing REML optimizers estimate the genomic variance components on
a `Ginv` spec (experimental); AI and NelderMead agree, and a seeded simulation
recovers σ²g/h² near truth.

Blocked: external-comparator VC parity (sommer/rrBLUP/BLUPF90 — R lane); a
committed recovery study; production sparse-`G` scaling.

## Tests Of The Tests

The AI==NelderMead agreement is two independent optimizers on the same genomic
objective (catches an optimizer or objective bug); `fit_gblup` at the estimate
reproducing the REML breeding values ties the supplied-variance solve to the
estimated optimum; the recovery sim (one-off) confirms the estimator is unbiased
near truth.

## Coordination Notes

Engine-internal; no bridge / `result_payload` / model-spec change. The R-facing
`genomic()` model-spec mapping and external VC comparators remain in the Phase-2
coordination ask.

## Known Limitations

- Dense `Ginv` REML (no sparse/APY-`G` scaling).
- No external comparator; recovery sim is one-off, not committed.

## Next Actions

1. Shared serialized comparator fixture (markers, `p`, expected `G`, pedigree)
   for the R-lane AGHmatrix/sommer/BLUPF90 checks.
2. R-twin coordination on the genomic model-spec contract (issue #6 ask).
