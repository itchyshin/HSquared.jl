#!/usr/bin/env Rscript
# MCMCglmm Bayesian-agreement comparator for the per-record varying-trial Binomial
# animal model. Compares against the engine `fit_laplace_reml` target written by
# `generate.jl`. This is Bayesian/MCMC AGREEMENT, NOT same-estimand REML parity
# (the same-estimand REML comparator gate remains BLUPF90/ASReml/WOMBAT, absent).
#
# Run (after generate.jl):
#   Rscript comparator/binomial_mcmcglmm/run_mcmcglmm.R [nitt burnin thin]

suppressPackageStartupMessages({
  library(MCMCglmm)
  library(Matrix)
})

args <- commandArgs(trailingOnly = TRUE)
nitt <- if (length(args) >= 1) as.integer(args[1]) else 130000L
burnin <- if (length(args) >= 2) as.integer(args[2]) else 30000L
thin <- if (length(args) >= 3) as.integer(args[3]) else 100L

fargs <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("^--file=", "", fargs[grep("^--file=", fargs)])))

ped <- read.csv(file.path(here, "pedigree.csv"), stringsAsFactors = FALSE)
phen <- read.csv(file.path(here, "phenotypes.csv"), stringsAsFactors = FALSE)
tgt <- read.csv(file.path(here, "engine_target.csv"), stringsAsFactors = FALSE)
summ <- read.csv(file.path(here, "engine_summary.csv"), stringsAsFactors = FALSE)
eng_sa2 <- as.numeric(summ$value[summ$field == "sigma_a2"])

# Same relationship as the engine: MCMCglmm builds the standard Henderson A-inverse
# from the pedigree. Parents are exchangeable for the additive relationship, so the
# id/dam/sire column order does not affect A.
ped$id <- as.character(ped$id)
ped$sire <- as.character(ped$sire)
ped$dam <- as.character(ped$dam)
ped$sire[ped$sire %in% c("NA", "")] <- NA
ped$dam[ped$dam %in% c("NA", "")] <- NA
ped3 <- data.frame(animal = ped$id, dam = ped$dam, sire = ped$sire,
                   stringsAsFactors = FALSE)

phen$id <- as.character(phen$id)
phen$animal <- factor(phen$id, levels = ped3$animal)

# Binomial cbind(successes, failures), one additive random effect on the pedigree.
# The units residual R is FIXED = 1 (the standard MCMCglmm binomial setup);
# a parameter-expanded prior on the additive variance G.
prior <- list(
  R = list(V = 1, fix = 1),
  G = list(G1 = list(V = 1, nu = 1, alpha.mu = 0, alpha.V = 1000))
)

set.seed(20260622)
m <- MCMCglmm(cbind(successes, failures) ~ 1, random = ~animal,
              family = "multinomial2", pedigree = ped3, data = phen,
              prior = prior, pr = TRUE,
              nitt = nitt, burnin = burnin, thin = thin, verbose = FALSE)

# Additive (animal) variance posterior on the latent logit scale.
va <- m$VCV[, "animal"]
va_mean <- mean(va)
va_hpd <- HPDinterval(va)
va_ess <- effectiveSize(va)

# EBVs: posterior means of the animal random effects, aligned to the engine target.
sol <- m$Sol
acols <- grep("^animal\\.", colnames(sol))
ebv_mc <- colMeans(sol[, acols, drop = FALSE])
names(ebv_mc) <- sub("^animal\\.", "", colnames(sol)[acols])
common <- intersect(tgt$id, names(ebv_mc))
ebv_eng <- tgt$ebv[match(common, tgt$id)]
ebv_cor <- cor(ebv_eng, ebv_mc[common])

cat("\n=== MCMCglmm Bayesian-agreement comparator (per-record varying-trial Binomial) ===\n")
cat(sprintf("chain: nitt=%d burnin=%d thin=%d (effective samples %d)\n",
            nitt, burnin, thin, length(va)))
cat(sprintf("engine sigma_a2 (Laplace REML, no units residual):     %.4f\n", eng_sa2))
cat(sprintf("MCMCglmm animal variance (latent, R units fixed=1):    mean %.4f, 95%% HPD [%.4f, %.4f], ESS %.0f\n",
            va_mean, va_hpd[1], va_hpd[2], va_ess))
cat(sprintf("EBV correlation (engine vs MCMCglmm, n=%d):           %.4f\n",
            length(common), ebv_cor))
cat("\nNOTE: Bayesian/MCMC AGREEMENT, not same-estimand REML parity. MCMCglmm's\n")
cat("binomial latent scale carries a fixed units residual (R=1) that the engine's\n")
cat("Laplace binomial does not, so the additive-variance MAGNITUDES sit on different\n")
cat("latent scales and are not expected to match numerically; the EBV correlation is\n")
cat("the scale-robust cross-method agreement metric.\n")

out <- data.frame(
  metric = c("engine_sigma_a2", "mcmcglmm_animal_var_mean",
             "mcmcglmm_animal_var_hpd_low", "mcmcglmm_animal_var_hpd_high",
             "mcmcglmm_animal_var_ess", "ebv_correlation", "n_common",
             "nitt", "burnin", "thin"),
  value = c(eng_sa2, va_mean, va_hpd[1], va_hpd[2], va_ess, ebv_cor,
            length(common), nitt, burnin, thin)
)
write.csv(out, file.path(here, "mcmcglmm_agreement.csv"), row.names = FALSE)
cat("\nwrote ", file.path(here, "mcmcglmm_agreement.csv"), "\n", sep = "")
