#!/usr/bin/env Rscript
# ASReml-R same-estimand REML comparator for the F6 matrix-free fitter — RUNNER.
#
# ESTIMAND COMPARISON ONLY. This script must never time ASReml. The standing ASReml honesty fence
# (§4, docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md) records that no
# head-to-head performance comparison against ASReml has been run in this project; a timing leg
# would need its own pre-declaration and its own fencing. Variance components only.
#
# Two comparisons, because the two engine estimators are different KINDS of thing:
#   1. ASReml vs the EXACT fit_ai_reml    -> both deterministic, so a tight relative tolerance.
#   2. ASReml vs the MATRIX-FREE fitter   -> stochastic, so the across-seed mean +/- SD, with the
#                                            gap reported in UNITS OF SD (the honest way to
#                                            compare a point estimate against a noisy one).
# The script's EXIT STATUS is the verdict, matching the sommer comparators.
#
# Usage:  julia --project=. comparator/prepare_asreml_matfree.jl && Rscript comparator/run_asreml_matfree.R

suppressMessages(library(asreml))

dir <- "comparator/asreml_matfree"
d    <- read.csv(file.path(dir, "data.csv"))
ped  <- read.csv(file.path(dir, "pedigree.csv"))
tgt  <- read.csv(file.path(dir, "engine_target.csv"))
meta <- read.csv(file.path(dir, "meta.csv"))
mval <- function(k) meta$value[meta$key == k]

# ASReml builds its OWN A-inverse from the pedigree -- an independent check of our Henderson Ainv,
# not just of the REML optimiser. ainverse() needs parents before progeny, which
# normalize_pedigree() already guarantees; unknown parents are 0.
ped$animal <- as.factor(ped$animal)
ped$sire   <- as.factor(ped$sire)
ped$dam    <- as.factor(ped$dam)
ainv <- ainverse(ped)

d$animal <- factor(as.character(d$animal), levels = levels(ped$animal))

fit <- asreml(fixed    = y ~ 1,
              random   = ~ vm(animal, ainv),
              residual = ~ idv(units),
              data     = d,
              trace    = FALSE)
fit <- update(fit, trace = FALSE)          # one extra round for a settled REML optimum

vc <- summary(fit)$varcomp
cat("\n--- ASReml varcomp ---\n"); print(vc)

pick <- function(pattern) {
  i <- grep(pattern, rownames(vc))
  if (length(i) != 1L) {
    stop("could not uniquely identify component '", pattern, "' among: ",
         paste(rownames(vc), collapse = ", "))
  }
  vc$component[i]
}
as_a <- pick("^vm\\(animal")
# `residual = ~ idv(units)` yields TWO residual rows: `units!units` (the estimated residual
# variance) and `units!R` (the scale parameter, FIXED at 1 -- bound "F"). Match the estimated one
# exactly; a loose "units" pattern hits both.
as_e <- pick("^units!units$")

cat(sprintf("\nASReml   : sigma_a2=%.8f  sigma_e2=%.8f  (asreml %s, R %s)\n",
            as_a, as_e, as.character(packageVersion("asreml")), getRversion()))

reldiff <- function(a, b) abs(a - b) / max(abs(a), abs(b), 1e-8)
ok <- TRUE

# ---- 1. ASReml vs the EXACT engine: both deterministic, tight tolerance ----
TOL_EXACT <- 1e-3
ex <- tgt[tgt$estimator == "exact", ]
rd_a <- reldiff(as_a, ex$sigma_a2[1]); rd_e <- reldiff(as_e, ex$sigma_e2[1])
cat(sprintf("\n--- ASReml vs EXACT fit_ai_reml (tol %.0e) ---\n", TOL_EXACT))
cat(sprintf("  sigma_a2  engine=%.8f  asreml=%.8f  rel.diff=%.3e\n", ex$sigma_a2[1], as_a, rd_a))
cat(sprintf("  sigma_e2  engine=%.8f  asreml=%.8f  rel.diff=%.3e\n", ex$sigma_e2[1], as_e, rd_e))
exact_ok <- is.finite(rd_a) && is.finite(rd_e) && max(rd_a, rd_e) < TOL_EXACT
cat(sprintf("  => %s\n", ifelse(exact_ok, "AGREE", "DISAGREE")))
ok <- ok && exact_ok

# ---- 2. ASReml vs the STOCHASTIC matrix-free fitter: mean +/- SD, gap in units of SD ----
# The criterion is deliberately expressed in SD units rather than as a relative difference: a
# Monte-Carlo estimator is not expected to hit a point value, it is expected to be CENTRED on it.
SD_TOL <- 3.0
cat(sprintf("\n--- ASReml vs MATRIX-FREE (across-seed mean +/- SD, %s seeds; |gap| <= %.1f SD) ---\n",
            mval("nseed"), SD_TOL))
for (np in unique(tgt$nprobe[tgt$estimator == "matfree"])) {
  mn <- tgt[tgt$estimator == "matfree" & tgt$nprobe == np & tgt$stat == "mean", ]
  sd <- tgt[tgt$estimator == "matfree" & tgt$nprobe == np & tgt$stat == "sd", ]
  for (cmp in c("sigma_a2", "sigma_e2")) {
    asv <- if (cmp == "sigma_a2") as_a else as_e
    gap <- abs(mn[[cmp]][1] - asv); nsd <- gap / sd[[cmp]][1]
    cat(sprintf("  nprobe=%-4s %-9s matfree=%.6f+/-%.6f  asreml=%.6f  |gap|=%.6f (%.2f SD)\n",
                np, cmp, mn[[cmp]][1], sd[[cmp]][1], asv, gap, nsd))
    if (!is.finite(nsd) || nsd > SD_TOL) ok <- FALSE
  }
}

cat(sprintf("\nCOMPARATOR: %s\n", ifelse(ok, "AGREE", "DISAGREE")))
quit(status = ifelse(ok, 0L, 1L))
