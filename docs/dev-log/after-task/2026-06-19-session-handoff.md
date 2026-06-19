# Session handoff — 2026-06-19 (new session: start here)

Crisp orientation for a fresh session. The big living report is
`2026-06-18-overnight-session.md`; the ordered plan is
`docs/design/11-completion-plan.md` (reconciled to current reality). The live
widget is http://127.0.0.1:8791/ (mission control; just had its reload-loop bug
fixed).

## State (repository = source of truth)

- Branch `codex/phase5-gwas-qtl-eqtl-tables`, **pushed 2026-06-19 to
  `origin/codex/phase5-gwas-qtl-eqtl-tables`** (was 40 unpushed; pushed after a
  clean local suite + docs build). Full suite **1792/1792 green**. Edits confined
  to `HSquared.jl`; R twin read-only.
- One fully public-covered capability: the v0.1 Gaussian animal model. Everything
  else is experimental / validation-scale (honest status throughout).

## Done this session (engine work promoted to usable + honestly stated)

Phase-6 GLLVM arc end-to-end (4 families × Laplace+VA, exported `fit_laplace_reml`
+ `NonGaussianFit` extractor object + `laplace_reml_interval` + recovery);
genomic + SNP-BLUP **REML** (`fit_gblup_reml`/`fit_snp_blup_reml`); single-step
H-matrix construction+fitting (`single_step_inverse`/`fit_single_step[_reml]`);
VanRaden **method-2** + **weighted** G; the Phase-3 inheritance relationship
family (`additive_/dominance_/epistatic_/cytoplasmic_/clonal_relationship`,
`allow_selfing`); `mendelian_sampling_variances`; `repeatability_interval`;
deep-inbreeding stress test (V1-DENSE-COND); genomic docstring drift fixes; a
Phase-4B twin-flagged fix; twin coordination handoff in the coordination board.

## What's left, by blocker class (refocus here)

1. **Your decisions (zero engineering):** push the 40 commits; **merge the
   Phase-5 stack #26→#35 to `main`** (the plan's blocker #0 — unblocks the whole
   Phase-5 R activation chain).
2. **Needs external packages / the R twin (not solo):** external comparator
   parity (sommer/ASReml/BLUPF90/AGHmatrix/JWAS/GLLVM.jl) + fitted Mrode — the
   common gate to move anything from "experimental" to "covered"; and the R-facing
   model-spec activation (`genomic()`/`single_step()`/`marker_scan()`/
   standard-QG/non-Gaussian `family()`), incl. R extractors that currently read
   fields no bridge populates.
3. **Substantial solo builds (deliberate, + a comparator to validate):**
   production sparse fitting + large-pedigree hardening; calibrated genome-wide
   scan thresholds; random regression; interval mapping/LOD; multivariate
   recovery-calibration rerun + covariance SEs/LRTs.
4. **Hardware-gated (structurally not this lane):** Phase 7 (CPU/GPU) and Phase 8
   (HPC) require GPU/HPC hardware + benchmarks their gates mandate.

## Rehydrate path (the `hsquared-rehydrate` skill reads these)

`git status`/`git log`, `AGENTS.md`, `ROADMAP.md`,
`docs/design/11-completion-plan.md`, `docs/design/capability-status.md`,
`docs/design/validation-debt-register.md`, `docs/dev-log/coordination-board.md`,
`docs/dev-log/check-log.md`, this file + `2026-06-18-overnight-session.md`.
