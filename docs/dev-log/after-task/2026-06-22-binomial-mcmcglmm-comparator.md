# After-task report — Binomial MCMCglmm agreement comparator (#44 gate 2)

Date: 2026-06-22

Branch: `claude/binomial-mcmcglmm-comparator` (HSquared.jl, Julia engine lane;
isolated worktree from `main` `38286b1`. **Not committed/pushed at time of writing.**)

Active lenses: Curie (simulation), Fisher (inference/comparator), Jason (comparator
landscape), Rose (claim-vs-evidence)

Spawned subagents: none

Current lane: Julia engine (`HSquared.jl`)

## 1. Goal

Provide an external cross-method comparator for the per-record varying-trial
Binomial animal model (#44 gate 2): an independent MCMCglmm (Bayesian) fit vs the
engine `fit_laplace_reml` fit. Bayesian agreement, not same-estimand REML parity;
stays `partial`.

## 2. Implemented

- `comparator/binomial_mcmcglmm/generate.jl` — engine target + data (deterministic
  per-record varying-trial Binomial, q=345, seed 20260622).
- `comparator/binomial_mcmcglmm/run_mcmcglmm.R` — MCMCglmm fit + comparison
  (EBV correlation + animal-variance posterior, with the scale caveat).
- `comparator/binomial_mcmcglmm/README.md` + `.gitignore` (regenerable CSVs ignored).
- `docs/dev-log/recovery-checkpoints/2026-06-22-binomial-mcmcglmm-agreement.md`
  with the recorded result.

## 3a. Decisions and Rejected Alternatives

- **Engine lane (`HSquared.jl/comparator/`), mirroring the JWAS comparator** — my
  lane, no R-twin conflict; the comparator invokes Julia (gen) + Rscript (MCMCglmm).
- **Per-record varying-trial design** — directly cross-validates the new feature.
- **EBV correlation is the primary metric; variance magnitudes caveated.**
  MCMCglmm's binomial latent scale carries a fixed units residual (`R = 1`) the
  engine's Laplace binomial lacks, so `σ²a` magnitudes are on different latent
  scales. Rejected forcing `R → 0` (breaks MCMCglmm binomial mixing); EBV
  correlation is the scale-robust agreement metric.
- **Positional EBV alignment via `fit.breeding_values`** — the payload's
  `breeding_values.ids` are recoded (not the original string ids), so the field
  vector (ped.ids order, as the recovery sims use) is the reliable alignment.
- **Did NOT edit `validation-debt-register.md`** — PR #155 already edits the same
  `V6-BINOMIAL` row; editing it here would create a cross-PR conflict. The register
  note is a merge-time follow-up.

## 4. Files Touched

- `comparator/binomial_mcmcglmm/generate.jl` (new)
- `comparator/binomial_mcmcglmm/run_mcmcglmm.R` (new)
- `comparator/binomial_mcmcglmm/README.md` (new)
- `comparator/binomial_mcmcglmm/.gitignore` (new)
- `docs/dev-log/recovery-checkpoints/2026-06-22-binomial-mcmcglmm-agreement.md` (new)
- `docs/dev-log/after-task/2026-06-22-binomial-mcmcglmm-comparator.md` (this file)

No engine `src/` change; no test change. Generated data/result CSVs git-ignored.

## 5. Checks Run

- `generate.jl` (julia 1.10.0): engine σ²a 0.9512 (truth 1.0), q=345, mean n 15.1,
  converged.
- `run_mcmcglmm.R` short chain (nitt=13000, 2.76s): EBV cor 0.896, animal var 0.340.
- `run_mcmcglmm.R` full chain (nitt=130000/burnin=30000/thin=100, 18.5s): EBV cor
  **0.895**, animal variance mean 0.3352 [0.1574, 0.5464], **ESS 1139**.

## 6. Tests of the Tests

- ESS 1139 / 1000 samples → well-mixed posterior (not an artifact of poor mixing).
- Short vs full chain agree (EBV cor 0.896 vs 0.895) → result is stable.
- Both methods use the same Henderson A-inverse from the same pedigree → the
  comparison is on the same relationship structure.

## 7a. Issue Ledger

- #44 gate-2: MCMCglmm Bayesian-agreement comparator added (EBV cor 0.895). Stays
  `partial`; no promotion. The same-estimand REML comparator gate
  (BLUPF90/ASReml/WOMBAT) remains open (executables absent). Interval calibration
  deferred (no engine binomial interval).

## 8. Consistency Audit

- The variance-magnitude gap (0.951 vs 0.335) is the documented R=1 overdispersion
  convention, not a disagreement; reported as such, with EBV correlation as the
  robust metric. No "parity" or "validation" overclaim.

## 9. What Did Not Go Smoothly

- The payload `breeding_values.ids` are recoded → a KeyError on the original ids;
  switched to the positional `fit.breeding_values` field (as the recovery sims use).
- The worktree's Julia project was not instantiated (Manifest git-ignored) → ran
  `generate.jl` against the already-instantiated main project (same engine code).

## 10. Known Residuals

- **Not committed/pushed** (pending PR confirmation).
- The `V6-BINOMIAL` register note for this evidence is deferred (merge-time, to
  avoid a cross-PR conflict with #155).
- Single design / one MCMCglmm prior; no sensitivity sweep. Same-estimand REML
  parity + interval calibration remain the open gate-2 items.

## 11. Team Learning

For non-Gaussian GLMM cross-method checks where latent-scale variance conventions
differ (e.g. MCMCglmm's binomial units residual vs a no-overdispersion Laplace
fit), the **EBV correlation** is the scale-robust agreement metric; compare
variance magnitudes only with the residual convention made explicit.
