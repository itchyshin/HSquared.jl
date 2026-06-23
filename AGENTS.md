# HSquared.jl Agent Instructions

`HSquared.jl` is the Julia computational twin of the R package `hsquared`.
The R package owns the public user language; this Julia package owns the
engine reality.

## Live Phase Snapshot

> Refresh this block in every after-task report (GLLVM.jl pattern). Repo state
> is truth; this is the at-a-glance pointer.

- **As of 2026-06-23 (Wave F kickoff on DRAC; main at `d5d2b9b1`/#180).** Stood up DRAC HPC
  (Fir CPU `def-snakagaw_cpu`; tamia GPU `aip-snakagaw`, 4× H100 verified) and opened **Wave F**
  (production sparse foundation + genomic GPU, two co-equal tracks,
  `docs/design/17-wave-F-foundation-and-genomic-gpu.md`) by **measure-first** on real q=10⁵–10⁶
  pedigrees. **Two engine slices landed:** **F1** (#179) Meuwissen–Luo O(n) inbreeding —
  `_meuwissen_luo_inbreeding` replaces the dense O(n²) inbreeding that capped `pedigree_inverse`
  at q=10⁴; exact vs the dense oracle; Ainv build at q=300k = 0.337 s (was impossible past 10⁴).
  **F3** (#180) scale-invariant AI-REML convergence — the q=300k wall was NOT factorization
  (measured 0.15 s; METIS gives ~1% fill, **not implemented**) but `fit_ai_reml` running to its
  100-iter cap on a non-scale-invariant `hypot(score)<tol` check (the score scales with n);
  fixed by also stopping on the relative VC change → **q=300k 35.6 s/non-converged → 2.3 s/
  converged (15.5×)**. **Track B G0 verified** (tamia 4× H100 `functional=true`, matmul OK);
  genomic-GPU slices unblocked. **Real Rose audits on both** (F1 PROMOTE-WITH-CHANGES → fixed a
  vacuous test fixture; F3 CLEAN on the core fix — but its "green suite" claim was wrong for a
  guarded variant, caught by CI + verify). Two F3 mis-steps (a boundary guard, an `iterations<50`
  assertion) broke CI and were removed; the core convergence fix was correct throughout.
  **Nothing promoted to `covered`** (public default still v0.1 Gaussian). Banked: the Wave F
  spec, the citation-backed algorithm scout doc (`docs/dev-log/scout/2026-06-23-production-sparse-algorithms.md`;
  **METIS overturned by measurement**), the DRAC harness (`sim/drac/`), and the cross-project
  DRAC runbook (`shinichi-brain/tools/drac-setup.md`, incl. the verified CUDA-binding fix).
  **START HERE:** `docs/dev-log/handover/2026-06-23-wave-f-session-handover.md`.

- **As of 2026-06-23 (backlog grind, session 3; main at `a33e50f3`/#176).** Finished the
  six planned backlog slices + resolved the J1 landmine, each full-DoD, one PR per slice,
  self-merged on green CI under pre-authorization. **Six engine slices merged:** **H2**
  (#170) beta-binomial overdispersed-logit Laplace family (added `_lbeta`/`_digamma`,
  `BetaBinomialResponse`, Fisher-information weight `Σ_k score(k)²P(k|η,ρ)`, `dispersion`
  field on `NonGaussianFit`); **H3** (#171) Bernoulli probit / liability-threshold family
  (`BernoulliProbitResponse`, tail-stable `_norm_logcdf`/Mills-ratio weight); **H6** (#172)
  non-Gaussian interval coverage characterization (generalized `laplace_reml_interval`
  cross-family contract test + opt-in uniform-family coverage sim); **H7** (#173) NEW EXPORT
  `nongaussian_heritability` (latent vs observation-scale h², integrating over `N(μ, V_A+
  V_fixed)` — corrected TWO spec errors: the integration variance must NOT include π²/3, and
  Poisson h²_obs is NOT monotone in σ²a); **C2** (#174) NEW EXPORT
  `genetic_correlation_interval` (`:delta` Fisher-z, reuses the MV SE path; extends
  V4-MV-REML, stays `covered`); **C6** (#175) NEW EXPORT `bootstrap_variance_component_interval`
  (parametric-bootstrap percentile CI for σ²a/σ²e/h², `n_converged` honesty hinge; promoted
  `Random` to `[deps]`; extends V1-HERIT-CI). **`validation_status()` 44→47** (3 NEW `partial`
  rows: V6-BETABINOMIAL, V6-PROBIT, V6-NS-H2; C2/C6/H6 APPENDED clauses to existing rows).
  **J1** (#176, LANDMINE) resolved as **docs-only "derived + dual-lens ratified, kernel
  awaiting maintainer ratification"** — the design spec's haplodiploid anchor set is provably
  IMPOSSIBLE (√2 positive-diagonal-congruence contradiction; non-PSD); Mendel + Falconer
  ratified `A = 2θ` with haploid-drone self = 2 (`docs/dev-log/decisions/2026-06-22-
  haplodiploid-relationship-convention.md`); NO kernel shipped, NO capability row.
  **SEVEN real Rose audits** (one per slice; H6/C6/J1 PROMOTE-WITH-CHANGES → addressed;
  J1's one factual Rose flag was itself wrong — a 46-vs-47 count — and was rejected after
  verification). `Pkg.test()` + `docs/make.jl` green locally per slice; CI green on every
  merge. **Public-default covered count UNCHANGED (1 = Gaussian); nothing promoted to
  covered this session** — all new non-Gaussian/interval rows are `partial`
  (coverage/recovery NOT calibrated to a gate). **MAINTAINER DECISION PENDING:** ratify (or
  revise) the J1 `A = 2θ`/drone-diagonal-2 scale + construction-only fence before the
  haplodiploid kernel can land. START HERE: the per-slice after-task reports
  `docs/dev-log/after-task/2026-06-22-{h2,h3,h6,h7,c2,c6,j1}-*.md` and check-log entries
  (H2–C6 in `check-log.md`; J1 in `check-log.d/`).
- **As of 2026-06-22 (backlog grind, session 2; main at `4d4c0f4a`).** Continued the
  100-slice program. Merged the two green PRs the prior handover flagged — **#164**
  (I1 fitted sire-model fixture; honest self-consistency target, not external parity)
  and **#165** (H1 negative-binomial NB2 Laplace family; NB2 loglik/score/weight
  independently re-derived). Then **#166** closed the prior session's DEFERRED
  ledger/evidence follow-ups (C5/C10/I1/H1): +3 `partial` `validation_status()` rows
  (`C10-LRT`, `V1-SIRE-FIT`, `V6-NBINOM`; count 41→44), the C5 genomic-σ²a `.md`
  mirrors + V2-GBLUP cross-ref, the sire comparator-manifest entry, a NEW opt-in NB
  recovery sim (σ²a magnitude honestly REPORTED-NOT-GATED — the Bernoulli information
  effect, NO gate relaxation), and doc-14 ✅ marks. Then **#167** landed **L1**
  (HSquaredMakieExt drawing-only): 5 new Makie `kind`s (`:manhattan`, `:qq`,
  `:rr_variance`, `:rr_surface`, `:rr_eigenfunctions`) consuming existing `*_plot_data`
  preparers; Makie stays OUT of CI, the stub testset is 11 assertions, the LOAD-BEARING
  local CairoMakie draw passed ALL 30 checks (Florence figure-honesty CLEAN). **Two
  real Rose audits CLEAN.** `Pkg.test()` + `docs/make.jl` green on each; CI green on
  each merged PR. **Nothing promoted to covered; public-default covered count UNCHANGED
  (1 = Gaussian); Julia `validation_status()` 41→44 (all new rows `partial`).** START
  HERE: `docs/dev-log/handover/2026-06-22-backlog-grind-session2-handover.md` — the
  complete session-2 handover with the H2 (beta-binomial) spec digested (incl. its two
  correctness traps: the Fisher-vs-observed information weight, and the `NonGaussianFit`
  field blast radius) and the remaining 7 slices (H2 → H3 → H6 → H7 → C2 → C6 → J1-last).
- **As of 2026-06-22 (one-owner consolidation; main at `964448a5`).** The R lane
  CLOSED; one owner now develops BOTH repos (`hsquared` + `HSquared.jl`) from a single
  lane (one cross-repo DoD; review lenses kept, Rose mandatory). Landed: the R stack
  `hsquared#98→#108` merged + live-verified (1445 pure-R + 116 live-bridge); the engine
  PRs `#155→#159` merged (`Pkg.test` green); the 100-slice cross-repo program backlog
  (`docs/design/14-program-backlog.md`, #160); and — the first NEW covered model beyond
  v0.1 Gaussian — **`V4-MV-REML` promoted `partial→covered`** (experimental,
  validation-scale, OPT-IN; NOT the public default) on the doc-33 substitutable gate: a
  PRE-REGISTERED bias/MCSE recovery gate (`a7b1f9ad`) + a fresh 48-seed cold-start run
  that PASSED (`24ee2d9c`) + a real Rose audit (PROMOTE-WITH-CHANGES) + B1/B2 honesty
  fixes + maintainer sign-off (`#161`, merge-commit `964448a5`). Public-default covered
  count UNCHANGED (1 = Gaussian); `validation_status()` covered 7→8; nothing else
  promoted. Retained debts: a 2nd same-estimand REML comparator, the in-suite
  unstructured-`sommer` test, broader-DGP recovery, the deep-inbreeding boundary. START
  HERE: `docs/dev-log/handover/2026-06-22-backlog-grind-handover.md` (the complete
  next-session handover: consolidation, the V4-MV-REML covered close-out, and the
  100-slice backlog grind — 6 of the first 14 done/PR'd, 8 remaining + deferred
  ledger follow-ups + correctness caveats).
- **As of 2026-06-20 (autonomous segment — ULTRACODE; 4 substantive PRs, main at `11e9909`/#121).**
  On top of the committed plotting-layer runway (`*_plot_data` preparers #91/#92/#94/#95/#116,
  CPU benchmark #115, threshold calibration #112, GLLVM consumability #113), this segment
  landed **3 full-DoD PRs**, each adversarially verified before merge:
  **(1) `HSquaredMakieExt`** (PR #117) — the Julia **drawing** half of the plotting layer:
  a `Makie` weak-dep package extension (`/src` stays dependency-free; stub `hsquared_figure`
  throws `MethodError` until a backend loads) that draws sets B/C (`variance_components` forest,
  EBV caterpillar, G-scree) with the #93 honest-status behaviors rendered ON the figure
  (raw whiskers no-clamp, `[0,1]` on the h² panel only, scree-not-biplot guard, non-PD-G
  %-suppression). Makie is deliberately OUT of CI (cost discipline) — CI gates the stub, the
  full draw is local-verified (CairoMakie, PNG). Rose: CLEAN.
  **(2) Binomial per-record `n_trials`** (PR #118) — generalized the Binomial family from a
  common scalar to a per-record `n_trials[i]` (the general `cbind(successes, failures)` GLMM
  the R lane flagged on **#61**), via `BinomialVectorResponse` + a `_fam_record` resolver
  threaded through all 10 kernel sites; constant-vector==scalar to ~1e-12, an independent
  per-record Gauss–Hermite oracle gate, mixed-regime recovery (n∈1..30, q=345: 5/5, rel≤0.062).
  5-agent Gauss/Noether/Curie+Rose Workflow: code clean, fixed a stale-negative register claim.
  **(3) Binomial/Bernoulli profile-LRT σ²a interval** (PR #119) — extended `laplace_reml_interval`
  to all single-component families with self-describing `lower_clamped`/`upper_clamped`/`converged`
  flags; `:variational` rejected (ELBO≠LRT). Fisher+Rose review corrected an over-generalized
  "two-sided" claim and caught two stale "Poisson-only" doc claims — all fixed before landing.
  **(4) HSquaredMakieExt genetic-correlation heatmap** (PR #121, after the v13 closeout) —
  the set-C `D⁻¹GD⁻¹` heatmap kind (rotation-invariant gated, low-/NaN-h² flagged); a
  Florence figure-honesty review caught a silent NaN-h² flag gap (fixed). Drawing-only.
  `Pkg.test()` + Documenter green on each; all 4 CI-green on clean checkout (**CI on a clean
  checkout is the authoritative gate**); `validation_status()` has **41 rows** (4 covered);
  **nothing promoted to covered**. Cross-lane **#61 engine side is now resolved** (per-record
  `n_trials` built) — draft answers for #38/#61/#93 are prepared but **NOT posted** (outward
  posting is the user's call; the auto-mode classifier blocks issue comments without explicit
  per-issue authorization). **Next:** the metafounder R-bridge (gated on #61 Q1–Q4), the
  eigenbasis bridge for `:lowrank`/`:factor_analytic` (#42, after R ratifies the FA convention),
  HSquaredMakieExt follow-on figure kinds (genetic-correlation heatmap, Manhattan/QQ, RR
  reaction-norm/surface), the Gaussian two-component interval (nuisance profiling), or —
  highest-leverage but cross-lane — the R-lane external comparator runs.
  Read `docs/dev-log/after-task/2026-06-21-session-handover-v14.md` (START HERE).
- **Covered (public):** v0.1 univariate Gaussian animal model only. Everything
  else is `experimental`/`partial` — nothing was promoted to covered this session.
- **Active programme (next-phase plan):** BT1 clean base = **done**. BT2 engine
  bridge-readiness (#42 diagonal done; #43/#44/#45 **done**; #42 lowrank/fa eigenbasis
  exposure gated on R ratification of the FA convention) and BT3 Julia-native
  validation (#46 fitted target + #49 JWAS scaffold **done** as a serialized target +
  opt-in scaffold; #47 SEs/LRTs done; #48 threshold machinery **done**, calibration
  evidence opt-in) are **landed**. **#54 random regression is now slices 1+2+3
  complete** (descriptors → supplied-covariance MME → REML estimation); the
  multivariate REML recovery is now characterised (no detectable bias + accurate EBVs,
  robust to cold vs warm start — the "6/10" was G sampling variance, not bias), still
  `partial` pending an external comparator. **Innovation backlog: #53 metafounders
  (supplied-Γ construction) DONE; PCG MME solver (production-path primitive) DONE.**
  Remaining: external-comparator EVIDENCE + fitted-Mrode confrontation (R-lane + opt-in
  JWAS run), multivariate recovery calibration (#4, gate not re-declared); innovation
  backlog #50 genetic GLLVM + CRN + APY genomic scaling + a matrix-free PCG operator
  (the actual large-scale enabler — edges into performance-claim territory needing
  benchmarks); RR slice 4 (eigen-function / PE term / R `rr()` spec); the metafounder
  R-bridge + single-step H^Γ (gated on #61 Q1–Q4); scout cadence #56; Phase 7/8
  hardware-gated.

## Core Scope

- Sparse pedigree, genomic, and custom relationship precision matrices.
- REML/ML/AI-REML mixed-model fitting for quantitative-genetic models.
- EBVs/BLUPs, heritability, variance components, G matrices, and diagnostics.
- Later: factor-analytic G matrices, GLLVM-style high-dimensional responses,
  non-standard inheritance systems, and accelerator-aware computation.

Phase 0 is complete. Phase 1 has started with pedigree normalization, sparse
`Ainv` construction, and an experimental dense validation path. Production
model fitting is not implemented.

## Twin Boundary

- `hsquared` speaks to applied R users.
- `HSquared.jl` computes.
- R syntax must not promise Julia capabilities that are not implemented,
  tested, documented, and recorded in `docs/design/capability-status.md`.

## Standing Review Lenses

These are review perspectives, not always-running agents. Say explicitly when
actual subagents are running.

| Name | Role |
| --- | --- |
| Ada | Orchestrator, phase planner, final integrator |
| Shannon | Coordination manager, lane checks, handoffs |
| Boole | Formula grammar and user-facing syntax |
| Hopper | R-to-Julia bridge and model-spec parity |
| Emmy | Package architecture and fitted-object design |
| Gauss | Numerical estimation, REML, sparse linear algebra |
| Karpinski | Julia performance, dispatch, allocations, type stability |
| Noether | Equation/syntax/implementation consistency |
| Fisher | Inference, identifiability, intervals, comparators |
| Curie | Simulation, recovery tests, edge cases |
| Jason | Literature and package scout |
| Darwin | Ecology/evolution audience and biological framing |
| Pat | Applied user tester and error-message reader |
| Florence | Figures and visual diagnostics |
| Grace | CI, Documenter, release, reproducibility |
| Rose | Systems auditor and claim-vs-evidence gate |
| Henderson | Mixed-model equations, BLUPs, sparse Ainv |
| Mendel | Non-standard inheritance systems |
| Falconer | Quantitative-genetic interpretation |
| Kirkpatrick | G matrices and factor-analytic genetic covariance |
| Mrode | Textbook animal-model validation canon |

## Current Member Routing

- **Ada + Shannon**: keep the programme aligned across `HSquared.jl`,
  `hsquared`, `DRM.jl`, `GLLVM.jl`, `drmTMB`, and `gllvmTMB`.
- **Henderson + Mrode + Gauss**: own the Phase 1 pedigree/Ainv and later
  animal-model equation checks.
- **Karpinski + Grace**: own Julia package hygiene, CI, Documenter, dispatch,
  and sparse performance review.
- **Hopper + Boole + Emmy**: keep Julia engine utilities compatible with the
  future R formula and bridge contract.
- **Jason + Rose**: scout sister packages and comparator tools, then prevent
  unsupported public claims.
- **Pat + Darwin + Florence**: keep docs readable for applied quantitative
  geneticists and ecological/evolutionary users.

These names remain review lenses unless an actual subagent is spawned and named
separately.

### Lane routing (which lens reviews which change)

Adopted 2026-06-19 (DRM.jl lane-boundary pattern). Charters live in
`.claude/agents/*.md` and `.codex/agents/*.toml`.

| Change class | Required lens(es) |
| --- | --- |
| `src/` numerics, REML, sparse linear algebra | Gauss + Karpinski + Noether |
| Formula / bridge / result-payload contract | Hopper + Boole + Emmy |
| Validation evidence, fixtures, recovery, comparators | Curie + Fisher + Mrode |
| Non-standard inheritance, quant-gen interpretation | Mendel + Falconer |
| G matrices / factor-analytic covariance | Kirkpatrick |
| **Any public claim / pre-publish / repo-visibility** | **Rose (mandatory)** |
| CI / Documenter / release / reproducibility | Grace |
| Cross-repo / cross-lane coordination | Ada + Shannon |

Scripted Workflow macros (run only on explicit opt-in / ultracode): an
engine-quality pass (Gauss/Karpinski/Noether over `src/`), an R-bridge-parity pass
(Hopper over payload + fixtures), and a validation-gate pass (Curie/Fisher/Mrode +
Rose) before any `experimental→covered` move.

## Sister Project Boundaries

Use the local sister projects as references:

- `DRM.jl`: Julia twin operating model, DocumenterVitepress setup, quality
  gates, and R-bridge discipline.
- `GLLVM.jl`: Julia engine structure, status-page discipline, performance claim
  gates, and high-dimensional design patterns.
- `drmTMB`: R package process, formula grammar discipline, validation debt,
  after-task reporting, and fitted/planned/missing separation.
- `gllvmTMB`: long/wide documentation discipline, covariance grammar, and
  reader-first public docs.

Code reuse rule: adapt architecture and process patterns freely, but do not copy
statistical code or public claims from sister projects without checking license,
provenance, tests, and fit for `HSquared.jl`.

## Memory Rules

Private memory may suggest where to look. Repository state, tests, docs,
issues, PRs, and check logs decide what is true.

Maintain repo-visible memory in:

- `ROADMAP.md`
- `docs/design/`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/`
- `docs/dev-log/recovery-checkpoints/`
- `docs/dev-log/decisions/`
- `docs/dev-log/scout/`

## Development Rules

1. Keep status language honest: no model-fitting claims without code and
   validation.
2. Do not change the public R-Julia contract without updating both twins.
3. Do not add a fitted capability without tests, documentation, capability
   status, validation-debt rows, and a Rose audit.
4. Do not copy statistical claims or code from sibling projects; adapt
   process patterns and record provenance.
5. Keep changes narrow and reviewable.

## Standard Commands

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
git status --short --branch
gh run list --limit 3
```

## Definition Of Done

A slice is done only when the relevant items are present:

- implementation;
- tests;
- documentation;
- example or explicit not-public-yet note;
- check-log evidence;
- after-task report;
- capability-status row;
- validation-debt row;
- Rose claim-vs-evidence audit;
- clean local checks;
- clean CI if pushed.
