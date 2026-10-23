suppressMessages({library(asreml)})
S <- Sys.getenv("AUDIT_DIR"); P <- readRDS(file.path(S,"prepared.rds"))
dat <- P$dat_cs; Ainv <- P$Ainv_pruned
asreml.options(workspace="1gb", maxit=50, trace=FALSE)
fit <- asreml(clutch_size ~ year_f + round_f + exp_manip + female.age,
  random = ~ vm(animal, Ainv) + ide(animal), data = dat,
  na.action = na.method(x="include", y="omit"))
tt <- function(f,n=5) min(sapply(seq_len(n), function(i) system.time(f())["elapsed"]))
cat(sprintf("summary.asreml()$varcomp (SE extraction): %.4f s\n", tt(function() asreml::summary.asreml(fit)$varcomp)))
vc <- asreml::summary.asreml(fit)$varcomp
print(round(vc[, c("component","std.error")], 6))
cat("\nvpredict h2:\n")
print(vpredict(fit, h2 ~ V1/(V1+V2+V3)))
print(vpredict(fit, rep ~ (V1+V2)/(V1+V2+V3)))
