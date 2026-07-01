#!/usr/bin/env Rscript
# Same-estimand EXTERNAL comparator for the non-Gaussian OBSERVATION-scale h²
# (V6-NS-H2 / doc-19 §2.2–2.3, §5). Compares HSquared.jl's
# `nongaussian_heritability(V_A, μ, <family>; predictor_variance=V_fixed).h2_observation`
# against de Villemereuil's QGglmm package `QGparams(..., model=<model>)$h2.obs`.
#
# Covers the two engine observation-scale families that map onto a QGglmm binom1 model:
#   • :bernoulli (logit)  ↔  model = "binom1.logit"
#   • :bernoulli_probit   ↔  model = "binom1.probit"
#
# CALIBRATION NOTE (the load-bearing convention): QGglmm's `var.p` for the observation-scale
# integration is the PREDICTOR variance V_A + V_fixed — the link's unit/π²-residual is baked into
# the inverse link, NOT a `var.p` component (doc-19 §2.2). Passing var.p = V_A + V_link + V_fixed
# gives the WRONG integration spread and disagrees. This is exactly the convention the external
# comparator pins that the internal cross-checks cannot.
#
# Run: Rscript comparator/qgglmm_probit_observed/compare.R engine_h2obs.csv
#   CSV rows: `mu,V_A,V_fixed,model,engine_h2_observation`  (model = binom1.logit | binom1.probit)
# Exits 0 and prints PASS iff max |engine − QGglmm| < 1e-4 over all rows.

suppressMessages(library(QGglmm))
args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[1] else "engine_h2obs.csv"
d <- read.csv(path, header = FALSE, stringsAsFactors = FALSE)
maxdiff <- 0
cat(sprintf("%-16s %-15s %-13s %-13s %-9s\n", "mu,V_A,V_fixed", "model", "engine", "QGglmm", "abs_diff"))
for (i in seq_len(nrow(d))) {
  mu <- as.numeric(d[i, 1]); va <- as.numeric(d[i, 2]); vf <- as.numeric(d[i, 3])
  model <- trimws(d[i, 4]); e <- as.numeric(d[i, 5])
  r <- QGparams(mu = mu, var.a = va, var.p = va + vf, model = model, verbose = FALSE)
  df <- abs(r$h2.obs - e); maxdiff <- max(maxdiff, df)
  cat(sprintf("%-16s %-15s %-13.7f %-13.7f %.2e\n", paste(mu, va, vf, sep = ","), model, e, r$h2.obs, df))
}
cat(sprintf("\nmax |engine - QGglmm| = %.2e  (threshold 1e-4)\n", maxdiff))
if (maxdiff < 1e-4) {
  cat("PASS: engine observation-scale h2 == QGglmm same-estimand external comparator (logit + probit)\n")
  quit(status = 0)
} else {
  cat("FAIL: mismatch — investigate the var.p / integration convention\n")
  quit(status = 1)
}
