suppressMessages({library(asreml); library(nadiv); library(readr); library(dplyr)})
DT <- file.path(Sys.getenv("TWIN_DIR"), "dev-test")
S  <- Sys.getenv("AUDIT_DIR"); P <- readRDS(file.path(S,"prepared.rds"))
ped_raw <- suppressWarnings(read_csv(file.path(DT,"great_tit_pedigree.csv"), show_col_types=FALSE))[,1:3] |>
  mutate(across(everything(), ~ na_if(as.character(.), "NA")))
t_prep <- min(sapply(1:3, function(i) system.time(prepPed(as.data.frame(ped_raw)))["elapsed"]))
ped <- prepPed(as.data.frame(ped_raw))[,1:3]
pruned_ids <- P$ped_analysis$id
ped_pruned <- ped[ped$id %in% pruned_ids, ]
t_full   <- min(sapply(1:3, function(i) system.time(ainverse(ped))["elapsed"]))
t_pruned <- min(sapply(1:3, function(i) system.time(ainverse(ped_pruned))["elapsed"]))
cat(sprintf("nadiv::prepPed(full 111,645):    %.3f s\n", t_prep))
cat(sprintf("asreml::ainverse(full 111,645):  %.3f s\n", t_full))
cat(sprintf("asreml::ainverse(pruned 10,937): %.3f s  (nnz %d)\n", t_pruned, nrow(ainverse(ped_pruned))))
