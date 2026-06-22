# Program backlog — the next ~100 slices (R + Julia)

Cross-repo backlog of record for the consolidated `hsquared` (R interface) +
`HSquared.jl` (engine) project. As of **2026-06-22** one owner develops both
repos from a single lane (the separate R lane closed); one cross-repo Definition
of Done; review-lens roster kept (Rose mandatory).

## Honest status snapshot

- **User-facing covered:** 1 model — the v0.1 univariate Gaussian animal model
  (REML), in `hsquared`.
- **R `capability-status.md`:** 8 covered / 34 partial / 4 planned (46 rows).
- **Julia `validation_status()`:** 4 covered + 3 covered-external / 33 partial /
  1 planned (41 rows).
- **Done in the consolidation session:** R stack #98→#108 merged to hsquared
  `main` (live-verified 1445 pure-R + 116 live-bridge, 0 fail); engine PRs
  #155→#159 merged to HSquared.jl `main` (full `Pkg.test()` green); unified
  mission control.
- **Rule:** nothing reaches `covered` without implementation + tests + docs +
  status-row + validation-row + check-log + Rose audit + (if pushed) clean CI.

Slices vary in size (one PR to a multi-PR capability). Tags: **[R]** hsquared ·
**[JL]** HSquared.jl · **[bridge]** both / round-trip. Flags: *(gated)* waits on
a contract answer · *(install)* comparator binary · *(hardware)* GPU · *(OK)*
outward posting.

## Recommended first wave (unblocked, highest-leverage)

A1 → A2 → A3 (land + reconcile what is built), then **E1 + E2** (multivariate
recovery + comparator → the first *new* covered model), **E3** (eigenbasis
R-side → unblocks FA→GLLVM), **I1** (fitted-Mrode → hardens the covered Gaussian
claim).

> A1 (merge engine PRs #155→#159) is **DONE** (2026-06-22, `main` @ 99059106,
> `Pkg.test()` green).

## A · Consolidation & unified infra

- **A1** ✅ Merge engine PRs #155→#159 to HSquared.jl main, CI-gated. [JL]
- **A2** Refresh Julia `validation_status()` rows that still say "missing" now
  that the evidence is merged (V6 non-Gaussian gradient+MCMCglmm, V1-HERIT-CI,
  V4-BRIDGE). [JL]
- **A3** Apply deferred `capability-status.md` (R) mirrors: σ²a interval,
  structured payload, non-Gaussian per-record. [R]
- **A4** One unified cross-repo Definition-of-Done doc. [bridge]
- **A5** Retire/redirect the 8781 R-only mission-control board → single board. [infra]
- **A6** Generator: regenerate `status.json` from `capability-status.md` +
  `validation_status()` each session. [infra]
- **A7** pkgdown ↔ Documenter "same covered/partial/planned story" cross-check. [bridge]
- **A8** Trim CI to PR + `workflow_dispatch` + Linux-only routine; multi-OS only
  pre-release. [infra]
- **A9** Post the drafted JL#61 / #44 / #38 cross-lane answers. [bridge] *(OK)*
- **A10** This doc — ROADMAP backlog of record. [bridge]

## B · Gaussian hardening → production sparse (Phase 1 finish)

- **B1** Production (non-experimental) sparse REML path (V1-REML production row). [JL]
- **B2** Large/real-pedigree conditioning + deep-inbreeding stress (V1-DENSE-COND). [JL]
- **B3** Meuwissen–Luo O(n) inbreeding in the production Ainv path. [JL]
- **B4** Fill-reducing ordering (AMD/METIS) for the sparse MME factorization. [JL]
- **B5** AI-REML convergence hardening (step control, restarts, PD guards). [JL]
- **B6** SQUAREM / augmented AI-REML accelerators (R#24/#25, JL#58). [JL]
- **B7** Surface production-fit diagnostics (convergence, conditioning) in `summary()`. [R]
- **B8** Promote V1 production EBV row once large-pedigree evidence lands. [bridge]

## C · Inference — SEs / intervals / LRTs / coverage

- **C1** Multivariate variance-component SEs (incl. genetic-correlation SE). [JL]
- **C2** Genetic-correlation interval (delta + profile) + bridge. [bridge]
- **C3** Repeatability interval promotion + coverage calibration (V3-REPEAT). [JL]
- **C4** Two-component Gaussian σ²a/σ²e joint interval (nuisance profiling). [JL]
- **C5** ✅ Extend `variance_component_interval` profile-LRT to genomic σ²a. [JL] (code merged #162; ledger/V2-GBLUP-cross-ref/.md mirrors closed in the deferred-ledger close-out)
- **C6** Parametric-bootstrap CIs as a check on delta/profile. [JL]
- **C7** Scale the coverage harness (#157) to 200-rep per-family runs. [JL]
- **C8** Publishable h² interval coverage study (Gaussian). [JL]
- **C9** `summary()`/`print()` surfacing of all intervals with honest clamp flags. [R]
- **C10** ✅ Generalized nested-model LRT (df + boundary correction) machinery. [JL] (`nested_lrt` merged #163; `C10-LRT` validation row + .md mirrors closed in the deferred-ledger close-out)

## D · Standard QG models (Phase 2/3)

- **D1** Promote repeatability/PE to covered (REML + recovery + comparator). [bridge]
- **D2** Promote common-environment two-effect (V3-TWOEFFECT-REML). [bridge]
- **D3** Maternal-genetic two-effect promotion. [bridge]
- **D4** Correlated direct–maternal 2×2 G — engine + bridge + recovery. [bridge]
- **D5** Sire and sire-MGS models. [JL]
- **D6** Unknown-parent groups (UPG) fitting + bridge (distinct from metafounders). [bridge]
- **D7** Inbreeding-as-covariate + inbreeding-depression estimation. [bridge]
- **D8** Random-regression slice 4: PE term + R `rr()` spec + eigen-function surface (JL#54). [bridge]
- **D9** Covariance Reaction Norms (CRN) prototype (JL#52). [JL]
- **D10** Dominance variance (D-matrix) animal model. [JL]

## E · Multivariate + structured covariance (Phase 3/4)

- **E1** Multivariate t≥2 known-truth recovery gate (V4-MV-REML). [JL]
- **E2** Second same-estimand MV comparator — substitutable gate (doc 33), `sommer` in-suite. [R]
- **E3** Eigenbasis payload widening — R-side activation of `structured_genetic_payload` (R#22/JL#42). [bridge]
- **E4** FA recovery calibration (V4-FA; `em_fa` warm-start, JL#37). [JL]
- **E5** Low-rank G recovery calibration. [JL]
- **E6** Genetic-PCA / g_max / evolvability R extractors + figures (V4-EVOLVE). [R]
- **E7** 3+-trait stress + missing-trait patterns. [JL]
- **E8** Multivariate EBV accuracy + cross-trait reliability bridge. [bridge]
- **E9** Structured-vs-unstructured model selection (AIC/LRT) helper. [bridge]
- **E10** Promote multivariate to covered once E1+E2 align. [bridge]

## F · Genomic & single-step (Phase 5 genomic)

- **F1** Supplied-frequency VanRaden G *value*-match vs a supplied-p tool (genomic value gate). [JL]
- **F2** Promote GBLUP/GREML once F1 lands (V2-GBLUP/GREML). [bridge]
- **F3** APY genomic inverse for large m (JL#51) + accuracy vs full G. [JL]
- **F4** Single-step H^Γ (metafounder single-step) engine + R bridge. [bridge]
- **F5** Metafounder R-bridge (supplied-Γ; gated on JL#61 Q1–Q4). [bridge] *(gated)*
- **F6** Single-step *construction* bridge (R builds Hinv from markers). [bridge]
- **F7** Weighted / WSSGBLUP. [JL]
- **F8** Marker- vs pedigree-EBV correlation diagnostics. [bridge]
- **F9** AGHmatrix / sommer / BLUPF90 genomic comparator suite. [bridge] *(install)*
- **F10** Known-truth genomic recovery study. [JL]

## G · Marker scans — GWAS / QTL / eQTL (Phase 5 scan)

- **G1** Calibrated genome-wide thresholds (V5-MARKER-THRESHOLD, JL#48). [JL]
- **G2** R `gwas()`/`marker_scan()` formula activation once G1 calibrated (R#23). [R]
- **G3** LOCO scan promotion (V5-MARKER-LOCO). [JL]
- **G4** cis/trans eQTL scan + mapping. [JL]
- **G5** Interval mapping (QTL) prototype. [JL]
- **G6** Manhattan / QQ / λ_GC plot-data + figures, both lanes. [bridge]
- **G7** Honest multiple-testing reporting (BH / Bonferroni / permutation-max). [JL]
- **G8** Marker variance-explained + polygenic score. [bridge]
- **G9** GWAS comparator agreement (GCTA / rrBLUP / statgenGWAS). [bridge]
- **G10** Genomic-coordinate-aware scan tables + region queries. [R]

## H · Non-Gaussian & GLLVM (Phase 6)

> Note: genetic-GLLVM #50 slices 1–3 are already built on the engine
> (descriptors, Gaussian + non-Gaussian latent solve, REML over G_lat, per-trait
> families). H8/H9 build on that.

- **H1** ✅ Negative-binomial family + overdispersion (Laplace). [JL] (`NegativeBinomialResponse` + joint `(σ²a,θ)` profile + oracle merged #165; `V6-NBINOM` row + recovery sim + .md mirrors closed in the deferred-ledger close-out; partial)
- **H2** Beta-binomial family. [JL]
- **H3** Ordinal / threshold (probit) model. [bridge]
- **H4** Zero-inflated + hurdle families. [JL]
- **H5** Variational (VA) method end-to-end (reuse DRM.jl/gllvmTMB, JL#44). [JL]
- **H6** Non-Gaussian σ²a interval for all single-component families (extend #119). [JL]
- **H7** Latent-scale / Nakagawa–Schielzeth non-Gaussian h² + bridge. [bridge]
- **H8** Genetic GLLVM: R-side bridge + ordination consumability (engine slices landed). [bridge]
- **H9** GLLVM ordination + latent-axis figures. [bridge]
- **H10** Non-Gaussian comparator depth (MCMCglmm/INLA agreement; REML parity where possible). [bridge]

## I · Comparators & validation canon

- **I1** 🟡 Fitted Mrode Ch.3/4 native fixture (JL#46/#16) + R confrontation. [bridge] (Ch.3 #46 existed; Ch.4 sire fixture merged #164; `V1-SIRE-FIT` row + comparator-manifest registration + .md mirrors closed in the deferred-ledger close-out. The R-lane same-estimand REML sire confrontation remains OPEN — standing debt.)
- **I2** JWAS.jl comparator run (opt-in agreement, JL#49). [JL]
- **I3** Install + run a free BLUPF90-family REML binary for same-estimand parity. [bridge] *(install/OK)*
- **I4** ASReml comparison policy doc + (if licensed) runs (R#7). [R]
- **I5** Expand external comparator target fixtures (JL#49 covered gate). [JL]
- **I6** nadiv / pedigreemm Ainv + inbreeding confrontation. [R]
- **I7** Tiny-example canon expansion (Mrode beyond 3.1; Lynch–Walsh). [bridge]
- **I8** Recovery-study dashboard (bias ± 2·MCSE per estimand, all models). [JL]
- **I9** ✅ Validation-debt burn-down tracker auto-generated from `validation_status()`. [JL] (merged #162; `V0-DEBT-TRACKER` covered)
- **I10** ✅ Per-capability promotion-gate predicate doc (what `covered` requires). [bridge] (merged #162; `docs/design/16-promotion-gate-predicates.md`)

## J · Non-standard inheritance (Phase 7)

- **J1** Haplodiploid relationship kernel + canon. [JL]
- **J2** Polyploid (auto/allo) kernel. [JL]
- **J3** Selfing / clonal / partial-selfing kernels (finish + canon). [JL]
- **J4** Cytoplasmic / maternal-effect relationship. [JL]
- **J5** X-linked / sex-linked relationship. [JL]
- **J6** Epistatic (A#A, A#D) relationship matrices. [JL]
- **J7** R grammar + honest gates for inheritance kernels (Mendel/Boole). [R]

## K · Performance & scale (Phase 8)

- **K1** Matrix-free PCG operator (no assembled C) — the real large-scale enabler + benchmark. [JL]
- **K2** Honest CPU benchmark suite vs sommer/pedigreemm/BLUPF90 (wall-clock + memory). [JL]
- **K3** Threading + BLAS tuning + allocation/type-stability pass (Karpinski). [JL]
- **K4** GPU (Metal/CUDA) marker-scan + low-rank genomic AI-REML, agreement + benchmark. [JL] *(hardware)*

## L · Figures, docs, UX, release

- **L1** Complete the plotting catalog (forest, caterpillar, scree, G-heatmap, Manhattan, QQ, RR surface) in ggplot2 + Makie ext. [bridge]
- **L2** gryphon + Mrode worked-example vignettes. [R]
- **L3** Applied-user error-message audit (Pat lens). [R]
- **L4** Public "what's working / honest status" page on both sites. [bridge]
- **L5** CRAN-readiness pass for `hsquared` (v0.1 surface). [R]
- **L6** JOSS / methods paper draft. [R]

## Maintenance

Update this file as slices land (mark ✅ + the merge commit). Keep it consistent
with `capability-status.md` (R), `validation-debt-register.md` + `validation_status()`
(Julia), and the unified mission control. No promotion to `covered` without the
full evidence chain + Rose audit.
