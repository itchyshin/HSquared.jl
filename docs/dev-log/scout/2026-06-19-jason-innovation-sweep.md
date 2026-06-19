# Scout — 2026-06-19 innovation sweep (Jason lens)

First sweep of the standing innovation-scout cadence (issue #56 ↔ R #20).
Read-only literature + web + sister-package scout to seed innovation, not
incremental coding. Tags: LEARN / AVOID / DEFER / VALIDATE.

## Ranked candidates → issues

| Idea | Verdict | Effort/Phase | Seeded |
| --- | --- | --- | --- |
| APY-style sparse Ginv (limited-dimensionality genomic inverse) | LEARN | M / P2 | #51 (stack) |
| Deflated PCG matrix-free MME solver (large pedigrees) | LEARN | M / P2 | #51 |
| Monte-Carlo REML for VCs at scale (MC-ss-GREML; published, closed-source) | LEARN | L / P2 | #51 |
| **Genetic GLLVM** (latent genetic factors, relationship-structured) | LEARN, novel | L / P6→7 | **#50** |
| Covariance SEs + LRTs | LEARN, mandatory | M / P4 | #47 (BT3) |
| Metafounders / UPG for ssGBLUP | LEARN | M / P3 | #53 |
| Random regression / reaction-norm (RRM) | LEARN | L / P3 | #54 |
| **Covariance Reaction Norms (CRN)** in sparse REML | LEARN, novel | L / P3 | **#52** |
| Reduced-rank G & evolvability tooling | LEARN | S–M / P4 | #55 |
| Bayesian alphabet (BayesR/C) | DEFER (JWAS owns it) | L / P5 | — (validate vs JWAS) |
| GPU genotype-product kernels | DEFER (after PCG) | L | — |
| Calibrated genome-wide thresholds | LEARN | M / P5 | #48 (BT3) |
| Genomic dominance/epistasis models | LEARN | M / P3∩P5 | — (backlog) |

## Top 3 innovation bets

1. **Genetic GLLVM (#50).** Clearest white space — HSquared owns both halves
   (FA-REML + non-Gaussian Laplace/VA); no package marries latent-factor GLLVM
   with a relationship-structured latent layer. Risk: identifiability/rotation.
2. **Open matrix-free scaling stack: PCG + APY + MC-REML (#51).** Turns the
   large-pedigree gap into a flagship; MC-ss-GREML is published but closed-source.
3. **Covariance Reaction Norms in sparse REML (#52).** Eco-evo frontier;
   currently Stan/brms-only and slow.

## Strategic note

The lane to win is "open-source, sparse, scriptable Julia REML at scale + eco-evo
inference." Do **not** chase JWAS on Bayesian-alphabet MCMC or GPU early —
interoperate and **validate against JWAS** instead. Every bet must clear the full
Definition-of-Done evidence chain before any public claim; the MC-REML and
genetic-GLLVM bets are research-grade, not coding tasks.

## Key sources

MC-ss-GREML [PMC12577077]; deflated-PCG [GSE 2018 s12711-018-0429-3], PCG
strategies [GSE 2020 s12711-020-00543-9]; APY [Genetics 2016 PMC4858800];
metafounders review [PMID 34799109]; JWAS.jl (Julia MCMC competitor);
gllvm 2.0 [PMC12704334]; CRN [MEE 2025 10.1111/2041-210X.70125]; Runcie BSFG-of-G
[Genetics 2013]; miraculix GPU [PMC10470110].
