## MCMCglmm ORDINAL same-estimand comparator — MCMCglmm side (K=3).
## family="threshold" (NOT "ordinal"): the engine :ordered_probit IS a unit-residual
## threshold/liability model; MCMCglmm "threshold" with VR=1 is the matching estimand.
## ("ordinal" uses a different residual scaling -> a ~2x mismatch; documented in README.)
## Compares sigma_a2, theta2, liability h2, and the PER-CATEGORY observed h2 vector
## (via QGglmm model="ordinal") to the engine points.
##
## Run (from repo root, after ordinal_engine.jl): Rscript comparator/mcmcglmm_observed/ordinal_fit.R
suppressMessages({library(MCMCglmm); library(QGglmm)})
a <- commandArgs(FALSE); sp <- dirname(sub("--file=", "", a[grep("--file=", a)]))
if (length(sp) == 0 || sp == "") sp <- "comparator/mcmcglmm_observed"
d <- read.csv(file.path(sp, "ordinal_data.csv")); d$group <- factor(d$group); d$yo <- as.ordered(d$y)
eng <- read.csv(file.path(sp, "ordinal_engine.csv")); rownames(eng) <- eng$quantity

prior <- list(R = list(V = 1, fix = 1),
              G = list(G1 = list(V = 1, nu = 1, alpha.mu = 0, alpha.V = 1000)))
set.seed(20260701)
m <- MCMCglmm(yo ~ 1, random = ~group, family = "threshold", data = d,
              prior = prior, nitt = 210000, burnin = 20000, thin = 100, verbose = FALSE)
VA <- as.numeric(m$VCV[, "group"]); mu <- as.numeric(m$Sol[, "(Intercept)"])
CP <- if (!is.null(m$CP)) as.numeric(m$CP[, 1]) else rep(eng["theta2","engine_point"], length(VA))
S <- length(VA); h2_liab <- VA / (VA + 1)
obs <- matrix(NA, S, 3)
for (i in 1:S) obs[i, ] <- QGparams(mu = mu[i], var.a = VA[i], var.p = VA[i],
    model = "ordinal", cut.points = c(-Inf, 0, CP[i], Inf), verbose = FALSE)$h2.obs

q <- function(x) quantile(x, c(.025,.975)); ins <- function(x,l,h) if (x>=l&&x<=h) "INSIDE" else "OUTSIDE"
cat(sprintf("MCMCglmm threshold K=3 (VR=1)  eff.size VA=%.0f\n", effectiveSize(m$VCV[,"group"])))
row <- function(nm,post,lo,hi,e) cat(sprintf("  %-12s post %.4f [%.4f,%.4f]  engine %.4f -> %s\n", nm,post,lo,hi,e,ins(e,lo,hi)))
row("sigma_a2",    mean(VA), q(VA)[1], q(VA)[2], eng["sigma_a2","engine_point"])
row("theta2",      mean(CP), q(CP)[1], q(CP)[2], eng["theta2","engine_point"])
row("h2_liability",mean(h2_liab), q(h2_liab)[1], q(h2_liab)[2], eng["h2_liability","engine_point"])
for (k in 1:3) row(sprintf("h2obs_cat%d",k), mean(obs[,k]), q(obs[,k])[1], q(obs[,k])[2], eng[sprintf("h2obs_cat%d",k),"engine_point"])
