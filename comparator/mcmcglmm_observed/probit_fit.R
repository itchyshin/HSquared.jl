## MCMCglmm same-estimand h² comparator — MCMCglmm side (probit LIABILITY design).
## family="threshold" fixes the residual variance at 1 == the engine's probit
## liability convention (V_link=1). Same dataset probit_engine.jl produced.
## Agreement is DISTRIBUTIONAL (engine Laplace point inside the Bayesian 95% CrI /
## within MCMC error), NOT machine precision.
##
## Run from repo root (after probit_engine.jl):
##   Rscript comparator/mcmcglmm_observed/probit_fit.R
suppressMessages({library(MCMCglmm); library(QGglmm)})
a <- commandArgs(FALSE); sp <- dirname(sub("--file=", "", a[grep("--file=", a)]))
if (length(sp) == 0 || sp == "") sp <- "comparator/mcmcglmm_observed"
d <- read.csv(file.path(sp, "packet_data.csv")); d$group <- as.factor(d$group)
eng <- read.csv(file.path(sp, "engine_points.csv")); rownames(eng) <- eng$quantity

prior <- list(R = list(V = 1, fix = 1),
              G = list(G1 = list(V = 1, nu = 1, alpha.mu = 0, alpha.V = 1000)))
set.seed(20260701)
m <- MCMCglmm(y ~ 1, random = ~group, family = "threshold", data = d,
              prior = prior, nitt = 110000, burnin = 10000, thin = 100, verbose = FALSE)
VA <- as.numeric(m$VCV[, "group"]); mu <- as.numeric(m$Sol[, "(Intercept)"])
h2_liab <- VA / (VA + 1)
h2_obs  <- vapply(seq_along(VA), function(i)
  QGparams(mu[i], VA[i], VA[i], model = "binom1.probit", verbose = FALSE)$h2.obs, numeric(1))
eng_h2obs <- QGparams(eng["mu","engine_point"], eng["sigma_a2","engine_point"],
                      eng["sigma_a2","engine_point"], model = "binom1.probit", verbose = FALSE)$h2.obs

q <- function(x) quantile(x, c(.025,.975)); ins <- function(x,l,h) if (x>=l&&x<=h) "INSIDE" else "OUTSIDE"
cat(sprintf("MCMCglmm threshold (VR=1)  eff.size VA=%.0f\n", effectiveSize(m$VCV[,"group"])))
cat(sprintf("  sigma_a2     post %.4f [%.4f,%.4f]  engine %.4f  -> %s\n",
            mean(VA), q(VA)[1], q(VA)[2], eng["sigma_a2","engine_point"], ins(eng["sigma_a2","engine_point"],q(VA)[1],q(VA)[2])))
cat(sprintf("  h2_liability post %.4f [%.4f,%.4f]  engine %.4f  -> %s\n",
            mean(h2_liab), q(h2_liab)[1], q(h2_liab)[2], eng["h2_liability","engine_point"], ins(eng["h2_liability","engine_point"],q(h2_liab)[1],q(h2_liab)[2])))
cat(sprintf("  h2_observed  post %.4f [%.4f,%.4f]  engine %.4f  -> %s\n",
            mean(h2_obs), q(h2_obs)[1], q(h2_obs)[2], eng_h2obs, ins(eng_h2obs,q(h2_obs)[1],q(h2_obs)[2])))
