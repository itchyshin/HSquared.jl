S <- Sys.getenv("AUDIT_DIR"); P <- readRDS(file.path(S,"prepared.rds"))
dat_cs <- P$dat_cs; ped <- P$ped_analysis
X <- model.matrix(~ year_f + round_f + exp_manip + female.age, data = dat_cs)
y <- dat_cs$clutch_size
cat("n =", length(y), " p =", ncol(X), " q =", nrow(ped), "\n")
write.csv(data.frame(y = y, animal = as.character(dat_cs$animal)),
          file.path(S,"yid.csv"), row.names = FALSE)
write.csv(as.data.frame(X), file.path(S,"X.csv"), row.names = FALSE)
write.csv(ped, file.path(S,"ped.csv"), row.names = FALSE, na = "")
cat("exported\n")
