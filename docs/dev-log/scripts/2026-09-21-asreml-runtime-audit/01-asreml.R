suppressMessages({library(asreml)})
S <- Sys.getenv("AUDIT_DIR"); P <- readRDS(file.path(S,"prepared.rds"))
dat_cs <- P$dat_cs
asreml.options(workspace="1gb", maxit=50, trace=FALSE)

run <- function(Ainv, label, reps=3) {
  ts <- numeric(reps); fit <- NULL
  for (i in seq_len(reps)) {
    t <- system.time({
      fit <<- asreml(fixed = clutch_size ~ year_f + round_f + exp_manip + female.age,
                     random = ~ vm(animal, Ainv) + ide(animal),
                     data = dat_cs, na.action = na.method(x="include", y="omit"))
    })
    ts[i] <- t["elapsed"]
    cat(sprintf("  %s rep%d: %.2f s\n", label, i, ts[i]))
  }
  vc <- tryCatch(asreml::summary.asreml(fit)$varcomp, error = function(e) NULL)
  cat(sprintf("  %s -> converged=%s  niter=%s  loglik=%.4f\n", label,
              fit$converge, as.character(fit$nit), fit$loglik))
  if (!is.null(vc)) print(round(vc[, c("component","std.error")], 6)) else print(fit$vparameters)
  list(label=label, times=ts, vc=vc)
}

cat("=== ASReml 4.2 | pruned pedigree (10,937) — LIKE FOR LIKE ===\n")
a_pruned <- run(P$Ainv_pruned, "pruned")
cat("\n=== ASReml 4.2 | full pedigree (111,645) — NOTEBOOK-FAITHFUL ===\n")
a_full <- run(P$Ainv_full, "full")

saveRDS(list(pruned=a_pruned, full=a_full), file.path(S,"asreml.rds"))
cat("\nR threads/BLAS:\n"); print(sessionInfo()$BLAS)
