#!/usr/bin/env Rscript
# Same-estimand EXTERNAL comparator for the ORDINAL (K>2) PER-CATEGORY observation-scale h²
# (V6-NS-H2 / doc-19). Compares HSquared.jl's
# `nongaussian_heritability(V_A, μ, OrderedProbitResponse(θ); predictor_variance=V_fixed).h2_observation_by_category`
# (a K-vector) against QGglmm's built-in ordinal model
# `QGparams(mu, var.a, var.p=V_A+V_fixed, model="ordinal", cut.points=c(-Inf, θ, Inf))$h2.obs` (also a K-vector).
#
# Engine formula (per category k, over η ~ N(μ, V_A+V_fixed); θ_0=−∞, θ_K=+∞):
#   p_k = E[Φ(θ_k−η) − Φ(θ_{k-1}−η)],  Ψ_k = E[φ(θ_{k-1}−η) − φ(θ_k−η)],  h²_k = Ψ_k²·V_A/[p_k(1−p_k)].
# var.p = V_A + V_fixed (predictor variance; the probit unit residual is baked into Φ, doc-19 §2.2).
#
# Run: Rscript comparator/qgglmm_ordinal_observed/compare.R engine_h2obs.csv
#   CSV rows: `mu,V_A,V_fixed,cuts(|-separated),engine_h2_by_category(|-separated)`
# Exits 0 and prints PASS iff max |engine − QGglmm| < 1e-4 over all categories of all rows.

suppressMessages(library(QGglmm))
args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[1] else "engine_h2obs.csv"
d <- read.csv(path, header = FALSE, stringsAsFactors = FALSE)
maxdiff <- 0
cat(sprintf("%-16s %-12s %-26s %-26s %-9s\n", "mu,V_A,V_fixed", "cuts", "engine h2_by_cat", "QGglmm h2.obs", "max|diff|"))
for (i in seq_len(nrow(d))) {
  mu <- as.numeric(d[i, 1]); va <- as.numeric(d[i, 2]); vf <- as.numeric(d[i, 3])
  cuts <- as.numeric(strsplit(trimws(d[i, 4]), "\\|")[[1]])
  eng <- as.numeric(strsplit(trimws(d[i, 5]), "\\|")[[1]])
  r <- QGparams(mu = mu, var.a = va, var.p = va + vf, model = "ordinal",
                cut.points = c(-Inf, cuts, Inf), verbose = FALSE)
  qg <- r$h2.obs
  rowmax <- max(abs(eng - qg)); maxdiff <- max(maxdiff, rowmax)
  cat(sprintf("%-16s %-12s %-26s %-26s %.2e\n", paste(mu, va, vf, sep = ","),
              paste(round(cuts, 2), collapse = ","),
              paste(round(eng, 5), collapse = ","), paste(round(qg, 5), collapse = ","), rowmax))
}
cat(sprintf("\nmax |engine - QGglmm ordinal| = %.2e  (threshold 1e-4)\n", maxdiff))
if (maxdiff < 1e-4) {
  cat("PASS: engine ordinal per-category observed h2 == QGglmm model=ordinal\n")
  quit(status = 0)
} else {
  cat("FAIL: mismatch — investigate the cut.points / integration convention\n")
  quit(status = 1)
}
