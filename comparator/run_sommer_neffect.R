#!/usr/bin/env Rscript
# Same-estimand REML comparator for the arbitrary-N (K=3) independent-effect estimator
# `fit_multi_effect_reml` (V3-NEFFECT-REML, ultraplan Phase 2). Fits the SAME model on the
# SAME data (predeclared seed 20260800) with sommer::mmer and checks the variance
# components agree with the engine's fit — both maximize the same REML likelihood, so they
# must converge to the same optimum.
#
#   1) julia --project=. comparator/prepare_sommer_neffect.jl   # writes sommer_neffect/*
#   2) Rscript comparator/run_sommer_neffect.R

suppressMessages(library(sommer))

dir <- "comparator/sommer_neffect"
d <- read.csv(file.path(dir, "neffect.csv"))
A <- as.matrix(read.csv(file.path(dir, "A.csv"), row.names = 1, check.names = FALSE))
d$animal <- factor(as.character(d$animal), levels = rownames(A))
d$g1 <- as.factor(d$g1)
d$g2 <- as.factor(d$g2)

fit <- mmer(y ~ 1,
            random = ~ vsr(animal, Gu = A) + vsr(g1) + vsr(g2),
            rcov = ~ units,
            data = d, verbose = FALSE)

vc <- summary(fit)$varcomp
getvc <- function(pat) {
  hit <- vc$VarComp[grepl(pat, rownames(vc), ignore.case = TRUE)]
  if (length(hit) == 0) NA_real_ else hit[1]
}
s_a  <- getvc("animal")
s_g1 <- getvc("(^|[^0-9])g1")
s_g2 <- getvc("(^|[^0-9])g2")
s_e  <- getvc("units|residual")

tg <- read.csv(file.path(dir, "engine_target.csv"), stringsAsFactors = FALSE)
val <- function(k) as.numeric(tg$value[tg$quantity == k])
e_a <- val("sigma_a2"); e_g1 <- val("sigma_g1_2"); e_g2 <- val("sigma_g2_2"); e_e <- val("sigma_e2")

reldiff <- function(a, b) abs(a - b) / max(abs(a), abs(b), 1e-8)
rows <- rbind(
  c("sigma_a2",  e_a,  s_a),
  c("sigma_g1_2", e_g1, s_g1),
  c("sigma_g2_2", e_g2, s_g2),
  c("sigma_e2",  e_e,  s_e)
)
cat(sprintf("%-11s %12s %12s %10s\n", "component", "engine", "sommer", "rel.diff"))
rds <- numeric(nrow(rows))
for (i in seq_len(nrow(rows))) {
  eng <- as.numeric(rows[i, 2]); som <- as.numeric(rows[i, 3])
  rds[i] <- reldiff(eng, som)
  cat(sprintf("%-11s %12.6f %12.6f %10.2e\n", rows[i, 1], eng, som, rds[i]))
}
tol <- 0.02
agree <- all(is.finite(rds)) && all(rds < tol)
cat(sprintf("COMPARATOR: %s  (max rel.diff %.2e, tol %.0e)\n",
            ifelse(agree, "AGREE", "DISAGREE"), max(rds), tol))
quit(status = ifelse(agree, 0L, 1L))
