#!/usr/bin/env Rscript
# Direct same-estimand REML comparator for the SPARSE single-effect AI-REML fitter (`fit_ai_reml`)
# — the F8 comparator leg of the Wave-F production-scale evidence (S6). sommer::mmer runs an
# INDEPENDENT REML optimizer on the SAME data + A the engine fitted, so both maximize the same
# single-effect REML likelihood and must converge to the same (σ²a, σ²e).
#
#   1) julia --project=. comparator/prepare_sommer_aireml.jl   # writes comparator/sommer_aireml/*
#   2) Rscript comparator/run_sommer_aireml.R

suppressMessages(library(sommer))

dir <- "comparator/sommer_aireml"
d <- read.csv(file.path(dir, "data.csv"))
A <- as.matrix(read.csv(file.path(dir, "A.csv"), row.names = 1, check.names = FALSE))
d$animal <- factor(as.character(d$animal), levels = rownames(A))

fit <- mmer(y ~ 1,
            random = ~ vsr(animal, Gu = A),
            rcov = ~ units,
            data = d, verbose = FALSE)

vc <- summary(fit)$varcomp
getvc <- function(pat) {
  hit <- vc$VarComp[grepl(pat, rownames(vc), ignore.case = TRUE)]
  if (length(hit) == 0) NA_real_ else hit[1]
}
s_a <- getvc("animal")
s_e <- getvc("units|residual")

tg <- read.csv(file.path(dir, "engine_target.csv"), stringsAsFactors = FALSE)
val <- function(k) as.numeric(tg$value[tg$quantity == k])
e_a <- val("sigma_a2"); e_e <- val("sigma_e2")

reldiff <- function(a, b) abs(a - b) / max(abs(a), abs(b), 1e-8)
rows <- rbind(c("sigma_a2", e_a, s_a), c("sigma_e2", e_e, s_e))
cat(sprintf("%-9s %14s %12s %10s\n", "component", "engine(AIREML)", "sommer", "rel.diff"))
rds <- numeric(nrow(rows))
for (i in seq_len(nrow(rows))) {
  eng <- as.numeric(rows[i, 2]); som <- as.numeric(rows[i, 3])
  rds[i] <- reldiff(eng, som)
  cat(sprintf("%-9s %14.6f %12.6f %10.2e\n", rows[i, 1], eng, som, rds[i]))
}
h2_e <- e_a / (e_a + e_e); h2_s <- s_a / (s_a + s_e)
cat(sprintf("h2        %14.6f %12.6f %10.2e\n", h2_e, h2_s, reldiff(h2_e, h2_s)))

tol <- 0.02
agree <- all(is.finite(rds)) && all(rds < tol)
cat(sprintf("COMPARATOR: %s  (max rel.diff %.2e, tol %.0e)\n",
            ifelse(agree, "AGREE", "DISAGREE"), max(rds), tol))
quit(status = ifelse(agree, 0L, 1L))
