#!/usr/bin/env Rscript
# Same-estimand EXTERNAL comparator for the GAMMA data/observation-scale h²
# (V6-NS-H2 / doc-19 §2.2; the NS-2017 multiplicative data scale). Compares HSquared.jl's
# `nongaussian_heritability(V_A, μ, GammaResponse(ν); predictor_variance=V_fixed).h2_observation`
# against QGglmm's CUSTOM Gamma-log model (QGglmm 0.8.0 has no built-in Gamma model).
#
# The QGglmm custom model is MATHEMATICALLY DETERMINED by the Gamma-log family (no convention choice):
#   inv.link(η)   = exp(η)           (μ = e^η)
#   var.func(η)   = e^{2η} / ν       (Var(y|η) = μ²/ν, the Gamma conditional variance)
#   d.inv.link(η) = exp(η)           (dμ/dη = e^η)
# with var.p = V_A + V_fixed (predictor variance; doc-19 §2.2). The engine's closed form
#   h²_obs = V_A / [e^{V_pred}(1 + 1/ν) − 1]   (μ CANCELS)
# is the lognormal reduction of Ψ²V_A / (Var(μ) + E[μ²/ν]); this comparator confirms it against the
# independent QGglmm cubature of the same custom model.
#
# Run: Rscript comparator/qgglmm_gamma_observed/compare.R engine_h2obs.csv
#   CSV rows: `mu,V_A,V_fixed,shape,engine_h2_observation`
# Exits 0 and prints PASS iff max |engine − QGglmm| < 1e-4 over all rows.

suppressMessages(library(QGglmm))
args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[1] else "engine_h2obs.csv"
d <- read.csv(path, header = FALSE, stringsAsFactors = FALSE)
maxdiff <- 0
cat(sprintf("%-20s %-8s %-14s %-14s %-9s\n", "mu,V_A,V_fixed", "shape", "engine", "QGglmm", "abs_diff"))
for (i in seq_len(nrow(d))) {
  mu <- as.numeric(d[i, 1]); va <- as.numeric(d[i, 2]); vf <- as.numeric(d[i, 3])
  nu <- as.numeric(d[i, 4]); e <- as.numeric(d[i, 5])
  cm <- list(inv.link = function(x) exp(x),
             var.func = function(x) exp(2 * x) / nu,
             d.inv.link = function(x) exp(x))
  r <- QGparams(mu = mu, var.a = va, var.p = va + vf, custom.model = cm, verbose = FALSE)
  df <- abs(r$h2.obs - e); maxdiff <- max(maxdiff, df)
  cat(sprintf("%-20s %-8.2f %-14.7f %-14.7f %.2e\n", paste(mu, va, vf, sep = ","), nu, e, r$h2.obs, df))
}
cat(sprintf("\nmax |engine - QGglmm custom Gamma| = %.2e  (threshold 1e-4)\n", maxdiff))
if (maxdiff < 1e-4) {
  cat("PASS: engine Gamma data-scale h2 == QGglmm custom Gamma-log model\n")
  quit(status = 0)
} else {
  cat("FAIL: mismatch — investigate the var.func / integration convention\n")
  quit(status = 1)
}
