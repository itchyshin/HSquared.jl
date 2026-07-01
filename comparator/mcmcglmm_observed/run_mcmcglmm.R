#!/usr/bin/env Rscript
# Same-estimand EXTERNAL comparator for the non-Gaussian OBSERVATION-scale h²
# (V6-NS-H2 / doc-19 §2.2, §5): the MCMCglmm leg. Complements the deterministic
# QGglmm transform comparator (comparator/qgglmm_probit_observed/) with an
# END-TO-END Bayesian fit + transform.
#
# It fits an MCMCglmm Poisson GLMM to the A = I / repeated-records dataset written by
# generate.jl, pushes the WHOLE posterior through de Villemereuil's documented
# QGglmm -> observed-scale workflow (QGglmm vignette "Integrating over a posterior
# prediction": var.a = VCV[,"id"], var.p = rowSums(VCV) = id + units; QGparams per
# draw), and checks that the engine's nongaussian_heritability(...).h2_observation
# POINT falls within the MCMCglmm 95% credible interval of that observation-scale h².
#
# THIS IS A DISTRIBUTIONAL AGREEMENT (a Bayesian posterior vs the engine's asymptotic
# point), NOT machine precision, and NOT a validation of unbiasedness: the Laplace
# engine and MCMCglmm share the Poisson-GLMM information limit, so agreement means
# "the engine's point sits within MCMC error of an independent Bayesian fit", nothing
# stronger. The var.p convention is unambiguous for Poisson.log (no link constant is
# added to var.p); the only latent-scale difference from the engine is MCMCglmm's
# units residual, which the repeated-records / no-over-dispersion design drives ~0.
#
# Run (after generate.jl):
#   Rscript comparator/mcmcglmm_observed/run_mcmcglmm.R [nitt burnin thin]

suppressPackageStartupMessages({
  library(MCMCglmm)
  library(QGglmm)
})

args <- commandArgs(trailingOnly = TRUE)
nitt <- if (length(args) >= 1) as.integer(args[1]) else 260000L
burnin <- if (length(args) >= 2) as.integer(args[2]) else 60000L
thin <- if (length(args) >= 3) as.integer(args[3]) else 100L

fargs <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("^--file=", "", fargs[grep("^--file=", fargs)])))

dat <- read.csv(file.path(here, "data.csv"), stringsAsFactors = FALSE)
dat$id <- factor(dat$id)
eng <- read.csv(file.path(here, "engine_h2.csv"), stringsAsFactors = FALSE)
getf <- function(f) as.numeric(eng$value[eng$field == f])
eng_h2 <- getf("h2_observation"); eng_sa2 <- getf("sigma_a2"); eng_mu <- getf("mu")

# Poisson (log link), one iid `id` random effect (A = I). The units residual is
# ESTIMATED (repeated records identify it separately from σ²a); a parameter-expanded
# prior on the id variance and a weak inverse-gamma on the residual.
prior <- list(
  R = list(V = 1, nu = 0.002),
  G = list(G1 = list(V = 1, nu = 1, alpha.mu = 0, alpha.V = 1000))
)

set.seed(20260701)
m <- MCMCglmm(count ~ 1, random = ~id, family = "poisson",
              data = dat, prior = prior,
              nitt = nitt, burnin = burnin, thin = thin, verbose = FALSE)

# --- de Villemereuil's documented MCMCglmm -> observed-scale posterior workflow ---
# var.a = id-variance draw; var.p = TOTAL latent variance draw = rowSums(VCV) (id +
# units). For Poisson.log the link carries no constant, so nothing is added to var.p.
mu_post <- as.vector(m$Sol[, "(Intercept)"])
va_post <- as.vector(m$VCV[, "id"])
vunits_post <- as.vector(m$VCV[, "units"])
vp_post <- va_post + vunits_post

post <- do.call("rbind", lapply(seq_along(mu_post), function(i) {
  QGparams(mu = mu_post[i], var.a = va_post[i], var.p = vp_post[i],
           model = "Poisson.log", verbose = FALSE)
}))
h2post <- post$h2.obs

h2_mean <- mean(h2post); h2_med <- median(h2post); h2_sd <- sd(h2post)
h2_ci <- as.numeric(quantile(h2post, c(0.025, 0.975)))
inside <- eng_h2 >= h2_ci[1] && eng_h2 <= h2_ci[2]
p_below <- mean(h2post < eng_h2)                 # posterior mass below the engine point
z_off <- (eng_h2 - h2_mean) / h2_sd              # engine point offset in posterior SDs
ess_va <- effectiveSize(m$VCV[, "id"])
ess_units <- effectiveSize(m$VCV[, "units"])

cat("\n=== MCMCglmm observation-scale h2 comparator (Poisson log-link, A = I) ===\n")
cat(sprintf("chain: nitt=%d burnin=%d thin=%d (effective samples %d; ESS[id]=%.0f, ESS[units]=%.0f)\n",
            nitt, burnin, thin, length(h2post), ess_va, ess_units))
cat(sprintf("MCMCglmm latent variances:   V_id mean %.4f, V_units mean %.4f (units≈0 ⇒ var.p≈V_A)\n",
            mean(va_post), mean(vunits_post)))
cat(sprintf("engine (Laplace REML) point:  sigma_a2=%.4f  mu=%.4f  h2_observation=%.6f\n",
            eng_sa2, eng_mu, eng_h2))
cat(sprintf("MCMCglmm h2_observation:      mean %.6f  median %.6f  sd %.6f\n",
            h2_mean, h2_med, h2_sd))
cat(sprintf("             95%% credible interval: [%.6f, %.6f]\n", h2_ci[1], h2_ci[2]))
cat(sprintf("engine point vs posterior:    %.1f%% of posterior mass below it; offset %+.2f posterior SD\n",
            100 * p_below, z_off))
cat("\nNOTE: DISTRIBUTIONAL (Bayesian vs asymptotic-point) AGREEMENT within MCMC error,\n")
cat("NOT machine precision and NOT a validation of unbiasedness (shared Poisson-GLMM\n")
cat("information limit). Transform: de Villemereuil QGglmm posterior workflow,\n")
cat("var.p = rowSums(VCV) (no link constant added for Poisson.log).\n")

out <- data.frame(
  metric = c("engine_h2_observation", "engine_sigma_a2", "engine_mu",
             "mcmcglmm_h2obs_mean", "mcmcglmm_h2obs_median", "mcmcglmm_h2obs_sd",
             "mcmcglmm_h2obs_ci_low", "mcmcglmm_h2obs_ci_high",
             "engine_inside_95ci", "posterior_mass_below_engine", "engine_offset_sd",
             "mcmcglmm_V_id_mean", "mcmcglmm_V_units_mean",
             "ess_id", "ess_units", "n_samples", "nitt", "burnin", "thin"),
  value = c(eng_h2, eng_sa2, eng_mu,
            h2_mean, h2_med, h2_sd, h2_ci[1], h2_ci[2],
            as.numeric(inside), p_below, z_off,
            mean(va_post), mean(vunits_post),
            ess_va, ess_units, length(h2post), nitt, burnin, thin)
)
write.csv(out, file.path(here, "mcmcglmm_h2_agreement.csv"), row.names = FALSE)
cat("\nwrote ", file.path(here, "mcmcglmm_h2_agreement.csv"), "\n", sep = "")

if (inside) {
  cat("\nPASS: engine observation-scale h2 point lies within the MCMCglmm 95% credible interval\n")
  quit(status = 0)
} else {
  cat("\nATTENTION: engine point OUTSIDE the 95% CI — inspect over-dispersion / design / chain\n")
  quit(status = 1)
}
