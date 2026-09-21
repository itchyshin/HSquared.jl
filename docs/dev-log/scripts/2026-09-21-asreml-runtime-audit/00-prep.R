# Shared prep for the runtime audit. Replicates dev-test/great_tit_animal_model.qmd,
# then freezes the objects so every timing arm uses identical inputs.
suppressMessages({library(asreml); library(nadiv); library(readr); library(dplyr)})
S  <- Sys.getenv("AUDIT_DIR")
DT <- file.path(Sys.getenv("TWIN_DIR"), "dev-test")

pheno   <- suppressWarnings(read_csv(file.path(DT,"great_tit_breeding_data.csv"), show_col_types=FALSE))
ped_raw <- suppressWarnings(read_csv(file.path(DT,"great_tit_pedigree.csv"), show_col_types=FALSE))[,1:3]
ped_raw <- ped_raw |> mutate(across(everything(), ~ na_if(as.character(.), "NA")))
ped <- prepPed(as.data.frame(ped_raw))[, 1:3]

dat <- pheno |>
  rename(animal = female_ID) |>
  filter(animal %in% ped$id) |>
  mutate(animal = factor(animal), year_f = factor(year),
         round_f = factor(round), exp_manip = factor(experimental_manipulation))
dat_cs <- dat |> filter(!is.na(clutch_size)) |> droplevels()
dat_cs$animal2 <- dat_cs$animal

analysis_ids <- unique(as.character(dat_cs$animal)); pedigree_ids <- analysis_ids
repeat {
  rows <- match(pedigree_ids, ped$id)
  parents <- unique(c(ped$dam[rows], ped$sire[rows]))
  expanded <- unique(c(pedigree_ids, parents[!is.na(parents)]))
  if (length(expanded) == length(pedigree_ids)) break
  pedigree_ids <- expanded
}
ped_analysis <- ped[ped$id %in% pedigree_ids, c("id","dam","sire")]
stopifnot(all(analysis_ids %in% ped_analysis$id))

Ainv_full   <- ainverse(ped)           # notebook-faithful: ALL 111,645 pedigree levels
Ainv_pruned <- ainverse(ped_analysis)  # like-for-like with what hsquared is given

cat(sprintf("records=%d females=%d ped_full=%d ped_pruned=%d Ainv_full_nnz=%d Ainv_pruned_nnz=%d\n",
            nrow(dat_cs), nlevels(dat_cs$animal), nrow(ped), nrow(ped_analysis),
            nrow(Ainv_full), nrow(Ainv_pruned)))
saveRDS(list(dat_cs=dat_cs, ped_analysis=ped_analysis, ped=ped,
             Ainv_full=Ainv_full, Ainv_pruned=Ainv_pruned), file.path(S,"prepared.rds"))
cat("saved\n")
