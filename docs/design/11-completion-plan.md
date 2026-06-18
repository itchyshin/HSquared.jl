# HSquared.jl Completion Plan

Status: living plan. Authored 2026-06-18 by the Julia-lane integrator (Ada role)
from repository state — `docs/design/capability-status.md`,
`docs/design/validation-debt-register.md`, `ROADMAP.md`, the R twin
(`hsquared`) roadmap/capability-status, and a read-only scout of the sister
engines. It is the ordered runway to finish `HSquared.jl` across all planned
phases, coordinating with the R twin. It does not itself claim any capability;
the status tables remain the source of truth.

This is the Julia-lane analogue of the R lane's
`docs/design/11-next-50-slices.md`.

## What "finished" means

A capability is **covered** (publicly claimable) only with: implementation +
tests + docs + capability-status row + validation-debt row +
comparator-or-fitted-textbook validation where a numeric claim is made + Rose
claim-vs-evidence audit + clean local checks (+ clean CI if pushed). "Finished"
for the package = every planned phase either covered or explicitly scoped out,
with the public R↔Julia contract honest at every step.

Release milestones map to the phases: v0.1 Gaussian animal model (**done**) →
v0.2 genomic → v0.3 standard QG → v0.4 multivariate (+4B FA) → v0.5 QTL/marker →
v0.6 non-Gaussian/GLLVM → v0.7 CPU/GPU → v0.8 HPC.

## Current reality (honest)

- **One fully public-covered capability**: the v0.1 univariate Gaussian animal
  model — the R default `hsquared()` fit by AI-REML through this engine,
  validated by the published gryphon anchor + sommer + a known-truth recovery
  study (`V1-AI-REML`, `V1-MRODE-FIT` external).
- **Everything else is experimental / validation-scale / engine-internal**:
  genomic (G/GBLUP/SNP-BLUP/single-step/GREML), standard-QG (repeatability,
  two-effect), multivariate REML + factor-analytic structured G, and the entire
  Phase-5 marker-scan stack. None is the public default.
- **Recurring blockers**: no external comparator parity (most phases); no fitted
  Mrode output validation; no production sparse fitting; multivariate
  recovery-calibration did **not** pass (unstructured 6/10, FA 8/10, low-rank
  9/10); and the Phase-5 work sits in an unmerged stacked draft-PR chain.

## Blocker to clear first — Phase 5 draft PR stack #26→#35

~10 stacked draft PRs (`codex/phase5-*`) carry all the Phase-5 marker work and
are **not merged to `main`**; each grows the reconcile cost.

**Recommendation:** merge the stack into `main` in dependency order now (CI is
green per PR), then delete the merged branches, so `main` reflects reality and
later slices branch from a clean base. Merging to the default branch is a
**user action** (direct push is policy-blocked), so this needs your go-ahead or
hands-on merge. If you prefer to keep stacking, the alternative is to land the
whole chain in one squash once Phase 5 reaches a natural close — but that defers
the growing-stack risk rather than removing it.

## Critical path (gate-closing before new capability)

| # | Slice | Lane | Gate to clear | Effort |
| --- | --- | --- | --- | --- |
| 0 | Merge Phase 5 stack #26→#35 → `main`, delete merged branches | coordinator / **user** | CI green per PR (already); `main` == reality | S |
| 1 | Finish profile-likelihood h² interval (in flight) | julia-only | testset GREEN; `V1-HERIT-CI` row | S |
| 2 | Fitted Mrode animal-model validation (published EBVs/β at supplied variance ratio; fitted VCs vs published) | julia + R comparator | matches Mrode Ch.3/4 numbers within tol; `nadiv`/`pedigreemm` cross-check | M |
| 3 | Genomic external-comparator parity (G/GBLUP/SNP-BLUP/GREML) | needs-R | agreement vs AGHmatrix/sommer/rrBLUP/BLUPF90; `V2-*` → covered | M–L |
| 4 | Multivariate recovery-calibration rerun (predeclared protocol) | julia-only | passing calibration **or** a revised, honest narrower claim | M |
| 5 | Multivariate external comparator (full residual; ASReml/BLUPF90) | needs-R | same-estimand agreement; `V4-*` → covered | M |
| 6 | Production sparse fitting + AI-REML large-pedigree hardening | julia-only | large/boundary fixtures; `V1-EBV`/`V1-REML` | L |
| 7 | Calibrated genome-wide thresholds + formula-driven mixed-model scan | julia-only | calibrated multiple-testing + simulation evidence; `V5-*` | L |
| 8 | Public genomic model-spec activation (`genomic()`/`single_step()`/`markers()`) through the bridge | needs-R | bridge contract + parity tests both lanes | M |
| 9 | Public standard-QG model-spec (`permanent()`/`common_env()`/`maternal_genetic()`) | needs-R | bridge contract + recovery/comparator | M |
| 10 | Phase 6 GLLVM-style: **Laplace + VA** (see reuse map) | julia-only | tiny non-Gaussian validation; LA/VA agreement; GLLVM.jl comparison | L |
| 11 | Phase 7 CPU/GPU acceleration (CPU baseline benchmarks → Metal/CUDA; agreement tests) | julia-only | CPU/GPU numerical-agreement + benchmark reports | L |
| 12 | Phase 8 HPC (checkpointing, disk-backed, streaming scans, distributed) | julia-only | restartable runs + machine/data/diagnostic reports | L |

Ordering logic: #0–#5 convert existing experimental work into covered/public
status (highest value, lowest new risk); #6–#9 make the engine production- and
bridge-real; #10–#12 are genuinely new phases.

## Per-phase completion requirements

- **P1 Gaussian AM** — covered for v0.1. To finish: fitted Mrode (#2), profile
  interval (#1), production sparse fitting + large-pedigree hardening (#6).
- **P2 Genomic** — engine utilities exist (experimental). To finish: external
  comparators (#3), public model-spec (#8), real-marker end-to-end, sparse/APY.
- **P3 Standard QG** — repeatability + two-effect exist (experimental). To
  finish: committed recovery harness, correlated direct–maternal 2×2 G, public
  model-spec (#9), comparators; then sire/dominance/UPG/random-regression.
- **P4 / 4B Multivariate + FA** — REML + structured G exist (experimental). To
  finish: passing calibration (#4), comparators (#5), covariance SEs/LRTs,
  rotation/interpretation convention, R-facing covariance syntax.
- **P5 QTL/GWAS/eQTL** — direct marker-scan suite exists (experimental). To
  finish: calibrated thresholds + formula-driven scans (#7), comparators,
  `marker_scan()`/`qtl_scan()` activation. (Heavy QTL infra may belong in an
  optional `HSquaredQTL.jl` extension — coordinate with the R lane's
  `hsquaredQTL` boundary note.)
- **P6 Non-Gaussian / GLLVM** — planned. Implement **both** Laplace and VA (#10).
- **P7 CPU/GPU** — vocabulary reserved only. Backend execution dispatch is the
  first real slice (#11).
- **P8 HPC** — planned (#12).

## Phase 6 reuse map — Laplace + VA (verified leads)

Per the user directive, Phase 6 implements **both** a Laplace and a variational
(VA/ELBO) marginal. Verified local sister-engine sources (adapt architecture and
process; verify license/provenance and validate independently before reusing
statistical code):

- **VA**: `DRM.jl/src/variational.jl` — a `Variational <: MarginalMethod` type
  with `method = :LA | :VA` dispatch (issue #136), a mean-field Gaussian ELBO
  with per-group profiled `(m, s)`, and per-family ELBO kernels (binomial, NB2,
  gamma, beta, Poisson). DRM.jl is MIT (already the provenance for our
  `takahashi_selinv` kernel), so reuse is licence-clean.
- **Laplace**: `GLLVM.jl` (241 Laplace lines — non-Gaussian families,
  `structured_schur.jl`, `postfit.jl`, profile CIs) is the closer reference for
  the wide-response, latent-factor GLLVM structure; `DRM.jl` per-family Laplace
  is the `:LA` default; the R sides (`gllvmTMB`, `drmTMB`) use TMB Laplace.
- **Architecture to adopt**: DRM.jl's `MarginalMethod` dispatch — one model
  spec, `method = :LA | :VA` — mapping to an R-facing `method = "laplace" | "va"`.
- **Caveat (not a blocker)**: DRM.jl's VA is mean-field over *disjoint* random-
  effect groups; the GLLVM animal model's latent field is *correlated* through
  the pedigree/relationship matrix and carries latent genetic factors across
  many responses. The per-family `E_q[log p]` and KL kernels port over; the `q`
  covariance structure for the correlated latent field is genuine new work.

This also satisfies the standing performance + missing-data directives: the
missing-data plan (FIML/Laplace, `mi(x)`) reuses `drmTMB`/`gllvmTMB` +
`DRM.jl`/`GLLVM.jl`; engine-speed work (AI-REML/EM/Newton, sparse-Cholesky vs
PCG, selected inverse) lands in #6/#11 with CPU baseline before GPU.

## Twin coordination — who owes what

- **Engine → R (this lane delivers, R surfaces)**: live `HSData` object
  marshalling; relationship marshalling beyond `Z`; production sparse fitting;
  calibrated marker thresholds; the Laplace/VA estimators.
- **R → engine (R activates once gates close)**: `marker_scan()`/`qtl_scan()`,
  `genomic()`/`single_step()`, standard-QG and covariance-structure formula
  syntax — each waits on the matching engine gate above.
- **Shared**: external comparators (sommer/ASReml/BLUPF90/JWAS) run in the R
  lane against engine targets; fitted Mrode; multivariate calibration. No row is
  promoted to covered in either twin until the comparator evidence chain exists.
- **Channel**: GitHub issue ledger — Julia #5/#6/#7 ↔ R #2/#5/#6. Repo state is
  the source of truth; this lane edits only `HSquared.jl`.

## Cadence

The live control centre (`~/.claude/hsquared-control-centre`, `:8791`) tracks
progress; `status.json` is refreshed at each slice/stage boundary. Each slice
follows the Definition of Done and updates the capability-status and
validation-debt rows before any public claim moves.
