#!/usr/bin/env Rscript
# Same-estimand estimated-VC comparator for 0.7-S0b (design-52).
# Shared kernel is K_lambda = G + 0.01 I from the Julia export — NOT the
# 2026-06-22 supplied-variance run.
#
#   1) julia --project=. sim/recipes/exact_G_estimated_vc_comparator.jl \
#        --mode=export --out=sim/recipes/exact_G_packet
#   2) Rscript sim/recipes/run_exact_G_estimated_vc.R sim/recipes/exact_G_packet
#
# PASS = engine vs sommer within Fisher-ratified tols (rel VC <= 0.02,
# |d r_G| <= 0.02). rrBLUP is secondary; a miss is OPTIMISER_DISAGREEMENT,
# not a post-hoc widen.

args <- commandArgs(trailingOnly = TRUE)
dir <- if (length(args) >= 1L) args[[1]] else "sim/recipes/exact_G_packet"

suppressMessages({
  if (!requireNamespace("sommer", quietly = TRUE)) {
    stop("sommer is required for the primary S0b leg", call. = FALSE)
  }
  library(sommer)
})
has_rrblup <- requireNamespace("rrBLUP", quietly = TRUE)
if (has_rrblup) {
  suppressMessages(library(rrBLUP))
}

reldiff <- function(a, b) abs(a - b) / max(abs(a), abs(b), 1e-8)

phen <- read.csv(file.path(dir, "phen.csv"), stringsAsFactors = FALSE)
K <- as.matrix(read.csv(file.path(dir, "K.csv"), row.names = 1, check.names = FALSE))
tg <- read.csv(file.path(dir, "engine_target.csv"), stringsAsFactors = FALSE)
meta <- read.csv(file.path(dir, "meta.csv"), stringsAsFactors = FALSE)
gebv_e <- read.csv(file.path(dir, "engine_gebv.csv"), stringsAsFactors = FALSE)

val <- function(tbl, k, col = "value") as.numeric(tbl[[col]][tbl[[names(tbl)[1]]] == k])
meta_val <- function(k) meta$value[meta$key == k]

ids <- phen$id
stopifnot(nrow(K) == nrow(phen), all(rownames(K) == ids))
phen$id <- factor(phen$id, levels = ids)

e_g <- val(tg, "sigma_g2")
e_e <- val(tg, "sigma_e2")
e_r <- val(tg, "r_G")
e_conv <- val(tg, "converged") == 1
tol_rel <- as.numeric(meta_val("tol_rel_vc"))
tol_abs <- as.numeric(meta_val("tol_abs_rG"))

pkg_ver <- function(p) {
  if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p)) else "MISSING"
}

cat("RECIPE 0.7-S0b-exact-G-estimated-VC\n")
cat(sprintf("packet=%s n=%d kernel=%s seed=%s\n",
            dir, nrow(phen), meta_val("kernel"), meta_val("seed")))
cat(sprintf("sommer=%s rrBLUP=%s\n", pkg_ver("sommer"), pkg_ver("rrBLUP")))
cat(sprintf("engine sigma_g2=%.6f sigma_e2=%.6f r_G=%.6f converged=%s\n",
            e_g, e_e, e_r, e_conv))
flush.console()

# mmes henderson=FALSE requires Gu = raw K_lambda, not inverse.
cat("\n=== sommer mmes vsm(ism(id), Gu=K_lambda) ===\n")
flush.console()
t0 <- proc.time()[[3]]
fit_s <- mmes(
  y ~ 1,
  random = ~ vsm(ism(id), Gu = K),
  rcov = ~ units,
  data = phen,
  verbose = FALSE,
  nIters = 100,
  dateWarning = FALSE
)
sommer_s <- proc.time()[[3]] - t0
vc <- summary(fit_s)$varcomp
rn <- rownames(vc)
cat("sommer varcomp rows:\n")
print(vc)

pick_first <- function(pat) {
  hits <- vc$VarComp[grepl(pat, rn, ignore.case = TRUE)]
  if (length(hits) == 0) NA_real_ else hits[[1]]
}
# Univariate: the genomic VC is the non-units row; residual is units.
s_e <- pick_first("^units")
s_g <- {
  hits <- vc$VarComp[!grepl("^units", rn, ignore.case = TRUE)]
  if (length(hits) == 0) NA_real_ else hits[[1]]
}
s_r <- s_g / (s_g + s_e)
s_conv <- isTRUE(fit_s$convergence) || isTRUE(fit_s$converged)
if (is.null(s_conv) || is.na(s_conv)) {
  s_conv <- is.finite(s_g) && is.finite(s_e)
}

cat(sprintf("sommer sigma_g2=%.6f sigma_e2=%.6f r_G=%.6f seconds=%.1f\n",
            s_g, s_e, s_r, sommer_s))

rd_g <- reldiff(e_g, s_g)
rd_e <- reldiff(e_e, s_e)
d_r <- abs(e_r - s_r)
primary_ok <- isTRUE(e_conv) && is.finite(s_g) && is.finite(s_e) &&
  rd_g <= tol_rel && rd_e <= tol_rel && d_r <= tol_abs

cat(sprintf("\nPRIMARY engine vs sommer: rel.s_g=%.4e rel.s_e=%.4e |d r_G|=%.4e  %s\n",
            rd_g, rd_e, d_r, ifelse(primary_ok, "PASS", "FAIL")))

secondary_label <- "SKIPPED"
rd_g2 <- rd_e2 <- d_r2 <- NA_real_
r_g2 <- r_e2 <- r_r2 <- NA_real_
if (!has_rrblup) {
  cat("\nSECONDARY rrBLUP: MISSING package — not a primary FAIL\n")
  secondary_label <- "MISSING"
} else {
  cat("\n=== rrBLUP mixed.solve(K=K_lambda) ===\n")
  flush.console()
  t1 <- proc.time()[[3]]
  y <- phen$y
  X <- matrix(1, nrow = length(y), ncol = 1)
  fit_r <- mixed.solve(y = y, K = K, X = X, method = "REML")
  rr_s <- proc.time()[[3]] - t1
  r_g2 <- as.numeric(fit_r$Vu)
  r_e2 <- as.numeric(fit_r$Ve)
  r_r2 <- r_g2 / (r_g2 + r_e2)
  rd_g2 <- reldiff(e_g, r_g2)
  rd_e2 <- reldiff(e_e, r_e2)
  d_r2 <- abs(e_r - r_r2)
  secondary_ok <- is.finite(r_g2) && is.finite(r_e2) &&
    rd_g2 <= tol_rel && rd_e2 <= tol_rel && d_r2 <= tol_abs
  secondary_label <- if (secondary_ok) "PASS" else "OPTIMISER_DISAGREEMENT"
  cat(sprintf("rrBLUP sigma_g2=%.6f sigma_e2=%.6f r_G=%.6f seconds=%.1f  %s\n",
              r_g2, r_e2, r_r2, rr_s, secondary_label))
  cat(sprintf("SECONDARY engine vs rrBLUP: rel.s_g=%.4e rel.s_e=%.4e |d r_G|=%.4e\n",
              rd_g2, rd_e2, d_r2))
}

# EBV correlation is a target, not a FAIL bit (design-52).
ebv_r <- NA_real_
if (!is.null(fit_s$u) || !is.null(fit_s$U)) {
  u_try <- tryCatch({
    uobj <- if (!is.null(fit_s$u)) fit_s$u else fit_s$U
    if (is.list(uobj)) uobj[[1]] else uobj
  }, error = function(e) NULL)
  if (!is.null(u_try)) {
    u_num <- as.numeric(unlist(u_try))
    if (length(u_num) == nrow(gebv_e)) {
      ebv_r <- suppressWarnings(cor(u_num, gebv_e$gebv))
      cat(sprintf("EBV r engine vs sommer (target > 0.999, not a FAIL bit)=%.6f\n", ebv_r))
    }
  }
}

gate <- if (primary_ok) "PASS" else "FAIL"
cat(sprintf("\nGATE: %s  primary=%s  secondary=%s\n", gate, ifelse(primary_ok, "PASS", "FAIL"), secondary_label))

out <- data.frame(
  recipe_id = "0.7-S0b-exact-G-estimated-VC",
  seed = meta_val("seed"),
  n = nrow(phen),
  G_sha256 = meta_val("G_sha256"),
  K_sha256 = meta_val("K_sha256"),
  engine_sigma_g2 = e_g,
  engine_sigma_e2 = e_e,
  engine_r_G = e_r,
  sommer_sigma_g2 = s_g,
  sommer_sigma_e2 = s_e,
  sommer_r_G = s_r,
  rel_sigma_g2 = rd_g,
  rel_sigma_e2 = rd_e,
  abs_d_r_G = d_r,
  rrblup_sigma_g2 = r_g2,
  rrblup_sigma_e2 = r_e2,
  rrblup_r_G = r_r2,
  ebv_r_sommer = ebv_r,
  sommer_version = pkg_ver("sommer"),
  rrblup_version = pkg_ver("rrBLUP"),
  primary = ifelse(primary_ok, "PASS", "FAIL"),
  secondary = secondary_label,
  gate = gate,
  stringsAsFactors = FALSE
)
utils::write.csv(out, file.path(dir, "verdict.csv"), row.names = FALSE)
quit(status = ifelse(identical(gate, "PASS"), 0L, 1L))
