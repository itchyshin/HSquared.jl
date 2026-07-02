#!/usr/bin/env Rscript
# Same-estimand REML comparator for the k=2 random-regression estimator
# `fit_random_regression_reml` (V3-RR-REML; RR k=2 covered evidence, Leg 2). Fits
# the SAME pedigree-A animal + Legendre random-regression model on the SAME data
# (predeclared seed 20261000) with sommer::mmer and checks the 2×2 coefficient
# genetic covariance K_g + residual σ²e agree with the engine's REML fit — both
# maximize the same REML likelihood, so they must converge to the same optimum.
#
#   1) julia --project=. comparator/prepare_sommer_rr.jl   # writes sommer_rr/*
#   2) Rscript comparator/run_sommer_rr.R
#
# THE NORMALIZATION TRAP (load-bearing): sommer's leg() Legendre normalization
# could differ from the engine's φ_n(t)=sqrt((2n+1)/2)·P_n(t). If so, basis_sommer
# = basis_engine · D for a diagonal D, and K_g are in different scales. We extract
# sommer's actual leg(t,1) basis and compare it column-by-column to the engine's
# dumped design, recover the diagonal D, put BOTH K_g in the SAME (engine) basis
# via K_g_sommer_in_engine = D · K_g_sommer · D, and compare the VARIANCE entries
# K_g[1,1], K_g[2,2] AND the covariance K_g[1,2] — NOT just the correlation ρ
# (ρ is invariant to diagonal rescaling, so a ρ-only match would be a FALSE PASS).

suppressMessages(library(sommer))
suppressMessages(library(orthopolynom))   # required by sommer's leg()

dir <- "comparator/sommer_rr"
d <- read.csv(file.path(dir, "rr.csv"))
A <- as.matrix(read.csv(file.path(dir, "A.csv"), row.names = 1, check.names = FALSE))
d$id <- factor(as.character(d$id), levels = rownames(A))

# ── (1) NORMALIZATION CHECK: sommer leg(t,1) vs engine legendre_design ──────────
# leg order 1 = linear = 2 coefficients (leg0, leg1) → k = 2.
eng_leg <- read.csv(file.path(dir, "engine_legendre.csv"))  # t, phi0, phi1 (unique t)
t_u <- eng_leg$t
B_som <- leg(t_u, 1)                     # sommer's evaluated Legendre design (nrow(t_u) x 2)
B_eng <- as.matrix(eng_leg[, c("phi0", "phi1")])
stopifnot(ncol(B_som) == 2L, nrow(B_som) == length(t_u))

# Column-wise scale ratio sommer/engine. If bases match, D = I; if they differ by a
# diagonal rescaling B_som = B_eng %*% diag(D), recover D per column by regression
# through the origin (robust to any single near-zero row).
D <- numeric(2)
for (j in 1:2) {
  # least-squares scalar s minimizing || B_som[,j] - s * B_eng[,j] ||
  D[j] <- sum(B_som[, j] * B_eng[, j]) / sum(B_eng[, j]^2)
}
# residual of the diagonal-rescaling model (0 ⇒ pure diagonal relationship)
resid_norm <- max(abs(B_som - B_eng %*% diag(D)))
col_max <- apply(abs(B_eng %*% diag(D)), 2, max)
rel_resid <- resid_norm / max(col_max, 1e-12)

cat("=== NORMALIZATION CHECK (sommer leg(t,1) vs engine normalized Legendre) ===\n")
cat(sprintf("  diagonal D (sommer/engine per column): D = [%.8f, %.8f]\n", D[1], D[2]))
cat(sprintf("  max |B_sommer - B_engine * diag(D)| = %.3e  (rel %.3e)\n",
            resid_norm, rel_resid))
is_diagonal <- rel_resid < 1e-8
if (!is_diagonal) {
  cat("  WARNING: relationship is NOT a clean diagonal rescaling — normalization",
      "cannot be reconciled by a diagonal D.\n")
}
if (all(abs(D - 1) < 1e-8)) {
  cat("  RESULT: bases MATCH (D = I2); sommer leg() uses the SAME sqrt((2n+1)/2) normalization.\n")
} else {
  cat(sprintf("  RESULT: bases DIFFER by diagonal D = diag(%.6f, %.6f); back-transforming K_g.\n",
              D[1], D[2]))
}

# ── (2) sommer REML fit: pedigree-A animal RR + homogeneous residual ────────────
# sommer 4.4.5 current interface (mmes + vsm/usm/ism; the older mmer/vsr rejects the
# usm(leg(...)) form). vsm(usm(leg(t,1)), ism(id), Gu = A) = an UNSTRUCTURED 2×2
# genetic covariance (K_g) over the normalized-Legendre leg basis, grouped by animal
# id with relationship A — the pedigree-A animal random regression, same estimand as
# the engine's fit_random_regression_reml.
fit <- mmes(y ~ 1,
            random = ~ vsm(usm(leg(t, 1)), ism(id), Gu = A),
            rcov = ~ units,
            data = d, verbose = FALSE)

vc <- summary(fit)$varcomp
rn <- rownames(vc)
cat("\n=== sommer varcomp rows ===\n")
print(vc)

pick <- function(pat) {
  hit <- vc$VarComp[grepl(pat, rn, ignore.case = TRUE)]
  if (length(hit) == 0) NA_real_ else hit[1]
}
# The 2×2 K_g over the leg basis: variance of leg0 (intercept), variance of leg1
# (slope), covariance leg0:leg1. sommer names them "...:leg0:leg0", "...:leg0:leg1",
# "...:leg1:leg1".
s11 <- pick("leg0:leg0")
s22 <- pick("leg1:leg1")
s12 <- pick("leg0:leg1|leg1:leg0")
s_e <- pick("units|residual")

cat(sprintf("\n  sommer K_g (native leg basis): [%.6f %.6f; %.6f %.6f]  sigma_e2=%.6f\n",
            s11, s12, s12, s22, s_e))

# ── (3) Put sommer K_g in the ENGINE basis: K_eng = D * K_som * D ────────────────
Ksom <- matrix(c(s11, s12, s12, s22), 2, 2)
Keng_from_som <- diag(D) %*% Ksom %*% diag(D)

# ── engine target ───────────────────────────────────────────────────────────────
tg <- read.csv(file.path(dir, "engine_target.csv"), stringsAsFactors = FALSE)
val <- function(k) as.numeric(tg$value[tg$quantity == k])
e11 <- val("Kg_11"); e22 <- val("Kg_22"); e12 <- val("Kg_12"); e_e <- val("sigma_e2")

reldiff <- function(a, b) abs(a - b) / max(abs(a), abs(b), 1e-8)

cat("\n=== ENGINE vs SOMMER (both in the ENGINE normalized-Legendre basis) ===\n")
rows <- list(
  c("K_g[1,1]", e11, Keng_from_som[1, 1]),
  c("K_g[2,2]", e22, Keng_from_som[2, 2]),
  c("K_g[1,2]", e12, Keng_from_som[1, 2]),
  c("sigma_e2", e_e, s_e)
)
cat(sprintf("%-10s %12s %12s %10s\n", "component", "engine", "sommer", "rel.diff"))
rds <- numeric(length(rows))
for (i in seq_along(rows)) {
  eng <- as.numeric(rows[[i]][2]); som <- as.numeric(rows[[i]][3])
  rds[i] <- reldiff(eng, som)
  cat(sprintf("%-10s %12.6f %12.6f %10.2e\n", rows[[i]][1], eng, som, rds[i]))
}
# genetic correlation (reported; invariant to D — NOT the pass criterion)
rho_e <- e12 / sqrt(e11 * e22)
rho_s <- Keng_from_som[1, 2] / sqrt(Keng_from_som[1, 1] * Keng_from_som[2, 2])
cat(sprintf("  ρ_g:  engine=%.6f  sommer=%.6f  (REPORTED; invariant to D)\n", rho_e, rho_s))

# ── (4) Agreement verdict ────────────────────────────────────────────────────────
# sommer AI-REML vs engine NelderMead-REML: same estimand, same REML optimum. Expect
# ~1e-2 or better on the identified variance entries. The slope variance K_g[2,2] is
# the noisiest coefficient; a slightly looser tol there is acceptable and reported.
tol <- 0.02
agree_norm <- is_diagonal
agree_vc <- all(is.finite(rds)) && all(rds < tol)
agree <- agree_norm && agree_vc
cat(sprintf("\nCOMPARATOR: %s  (normalization %s; max rel.diff %.2e on variance/cov/σ²e, tol %.0e)\n",
            ifelse(agree, "AGREE", "DISAGREE"),
            ifelse(is_diagonal, ifelse(all(abs(D - 1) < 1e-8), "D=I2 identical", "diagonal D reconciled"),
                   "NON-DIAGONAL (unreconciled)"),
            max(rds), tol))
quit(status = ifelse(agree, 0L, 1L))
