suppressMessages({library(asreml)})
S <- Sys.getenv("AUDIT_DIR"); P <- readRDS(file.path(S,"prepared.rds"))
dat_cs <- P$dat_cs; Ainv <- P$Ainv_pruned
fitn <- function(maxit) {
  asreml.options(workspace="1gb", maxit=maxit, trace=FALSE)
  ts <- sapply(1:3, function(i) system.time({
    f <<- asreml(clutch_size ~ year_f + round_f + exp_manip + female.age,
      random = ~ vm(animal, Ainv) + ide(animal), data = dat_cs,
      na.action = na.method(x="include", y="omit")) })["elapsed"])
  cat(sprintf("maxit=%-2d  best %.3f s  converged=%s\n", maxit, min(ts), f$converge))
  min(ts)
}
t1 <- fitn(1); t2 <- fitn(2); t7 <- fitn(7); t50 <- fitn(50)
cat(sprintf("\nimplied per-iteration (t2-t1):  %.3f s\n", t2-t1))
cat(sprintf("implied setup (t1 - periter):   %.3f s\n", t1-(t2-t1)))
cat(sprintf("implied per-iteration (t7-t2)/5:%.3f s\n", (t7-t2)/5))
